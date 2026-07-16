//
//  ExerciseListView.swift
//  MuscleApp
//

import SwiftUI
import SwiftData

// 種目一覧画面（部位ごとに表示、並び替え可能）
struct ExerciseListView: View {
    let bodyPart: BodyPart
    let targetDate: Date?  // nil = 今日として記録 / それ以外 = 指定日に記録

    // 該当部位のExerciseを並び順で取得
    @Query private var exercises: [Exercise]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // 種目追加シート表示用
    @State private var isAddingExercise: Bool = false

    // 名前変更中の種目（nilなら未編集）
    @State private var renamingExercise: Exercise? = nil
    @State private var renameInput: String = ""

    // 編集モード（並び替え用）
    @Environment(\.editMode) private var editMode

    // 編集モード中かどうか
    private var isEditing: Bool {
        editMode?.wrappedValue.isEditing == true
    }

    init(bodyPart: BodyPart, targetDate: Date? = nil) {
        self.bodyPart = bodyPart
        self.targetDate = targetDate
        let raw = bodyPart.rawValue
        _exercises = Query(
            filter: #Predicate<Exercise> { $0.bodyPartRaw == raw },
            sort: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)]
        )
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            List {
                ForEach(exercises) { exercise in
                    rowView(for: exercise)
                        .listRowBackground(Color.appBackground)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                }
                .onMove(perform: moveExercises)
                .onDelete(perform: deleteExercises)

                AddExerciseButton { isAddingExercise = true }
                    .listRowBackground(Color.appBackground)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .environment(\.colorScheme, .dark)
        }
        .navigationTitle(bodyPart.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.appTextPrimary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
                    .foregroundColor(.appTextPrimary)
            }
        }
        .onAppear {
            seedDefaultsIfNeeded()
            migrateSortOrderIfNeeded()
        }
        .sheet(isPresented: $isAddingExercise) {
            AddExerciseSheet(bodyPart: bodyPart) { name in
                addExercise(name: name)
                isAddingExercise = false
            } onCancel: {
                isAddingExercise = false
            }
        }
        .alert("種目名を変更", isPresented: Binding(
            get: { renamingExercise != nil },
            set: { if !$0 { renamingExercise = nil } }
        )) {
            TextField("種目名", text: $renameInput)
            Button("キャンセル", role: .cancel) {
                renamingExercise = nil
            }
            Button("保存") {
                confirmRename()
            }
        }
    }

    // 名前変更を確定
    private func confirmRename() {
        let trimmed = renameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if let exercise = renamingExercise, !trimmed.isEmpty {
            exercise.name = trimmed
            modelContext.saveOrLog("種目名変更")
        }
        renamingExercise = nil
    }

    // 初期種目を投入（既に存在すればスキップ）
    private func seedDefaultsIfNeeded() {
        guard exercises.isEmpty, let names = defaultExercisesByPart[bodyPart] else { return }
        for (index, name) in names.enumerated() {
            modelContext.insert(Exercise(name: name, bodyPart: bodyPart, isDefault: true, sortOrder: index))
        }
        modelContext.saveOrLog("初期種目投入")
    }

    // 既存データが全て sortOrder=0 だったら、現在の並び順を保存（旧データ互換）
    private func migrateSortOrderIfNeeded() {
        guard !exercises.isEmpty, exercises.allSatisfy({ $0.sortOrder == 0 }) else { return }
        for (index, exercise) in exercises.enumerated() {
            exercise.sortOrder = index
        }
        modelContext.saveOrLog("種目並び順移行")
    }

    // ユーザー追加の種目を保存（末尾に追加）
    private func addExercise(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let nextOrder = (exercises.map(\.sortOrder).max() ?? -1) + 1
        modelContext.insert(Exercise(name: trimmed, bodyPart: bodyPart, isDefault: false, sortOrder: nextOrder))
        modelContext.saveOrLog("種目追加")
    }

    // 1行ぶんのView（編集モード中はスワイプ無効）
    @ViewBuilder
    private func rowView(for exercise: Exercise) -> some View {
        if isEditing {
            ExerciseRow(exercise: exercise, targetDate: targetDate)
        } else {
            ExerciseRow(exercise: exercise, targetDate: targetDate)
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        renameInput = exercise.name
                        renamingExercise = exercise
                    } label: {
                        Label("名前変更", systemImage: "pencil")
                            .labelStyle(.iconOnly)
                    }
                    .tint(.blue)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button {
                        deleteExercise(exercise)
                    } label: {
                        Label("削除", systemImage: "trash")
                            .labelStyle(.iconOnly)
                    }
                    .tint(.red)
                }
        }
    }

    // 種目と配下セットを削除し、ウィジェットも最新状態へ同期する
    private func deleteExercise(_ exercise: Exercise) {
        withAnimation(.easeInOut(duration: 0.25)) {
            modelContext.delete(exercise)
        }
        saveDeletionAndSynchronize(operation: "種目削除")
    }

    // 編集モードの一括削除（赤い「－」ボタン経由）
    private func deleteExercises(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(exercises[index])
        }
        saveDeletionAndSynchronize(operation: "種目一括削除")
    }

    private func saveDeletionAndSynchronize(operation: String) {
        guard modelContext.saveOrLog(operation) else { return }
        BuffitoWidgetSynchronizer.synchronize(using: modelContext, operation: "\(operation)後")
    }

    // ドラッグで並び替えたとき
    private func moveExercises(from source: IndexSet, to destination: Int) {
        var items = exercises
        items.move(fromOffsets: source, toOffset: destination)
        for (index, item) in items.enumerated() {
            item.sortOrder = index
        }
        modelContext.saveOrLog("種目並び替え")
    }
}

// 種目1つを表示する行（タップで記録画面へ遷移）
struct ExerciseRow: View {
    let exercise: Exercise
    var targetDate: Date? = nil

    var body: some View {
        ZStack {
            // 透明なNavigationLink（タップ判定だけ担当、システム標準の>を隠す）
            NavigationLink {
                ExerciseDetailView(
                    exercise: exercise,
                    backLabel: exercise.bodyPart.displayName,
                    targetDate: targetDate
                )
            } label: {
                EmptyView()
            }
            .opacity(0)

            // 見た目はこちらだけが担当
            HStack {
                Text(exercise.name)
                    .font(.title3.bold())
                    .foregroundColor(.appTextPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appField)
            )
        }
    }
}

// 種目追加ボタン（一覧の末尾）
struct AddExerciseButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "plus")
                Text("種目を追加")
                    .font(.title3.bold())
            }
            .foregroundColor(.appTextPrimary)
            .frame(maxWidth: .infinity)
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.appBorder, style: StrokeStyle(lineWidth: 1, dash: [4]))
            )
        }
    }
}

// 種目追加シート（名前入力）
struct AddExerciseSheet: View {
    let bodyPart: BodyPart
    let onSave: (String) -> Void
    let onCancel: () -> Void

    @State private var name: String = ""
    @FocusState private var isNameFocused: Bool

    private var suggestions: [String] {
        popularExercisesByPart[bodyPart] ?? []
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // 種目名入力
                        VStack(alignment: .leading, spacing: 8) {
                            Text("種目名")
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            TextField("", text: $name, prompt: Text("例：インクラインダンベルプレス").foregroundColor(.gray))
                                .textFieldStyle(.plain)
                                .foregroundColor(.appTextPrimary)
                                .padding()
                                .background(Color.appField)
                                .cornerRadius(12)
                                .focused($isNameFocused)
                        }

                        // 主要な種目から選ぶ
                        if !suggestions.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("主要な種目から選ぶ")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("タップで入力")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }

                                VStack(spacing: 0) {
                                    ForEach(Array(suggestions.enumerated()), id: \.element) { idx, suggestion in
                                        Button {
                                            name = suggestion
                                            isNameFocused = false
                                        } label: {
                                            HStack {
                                                Text(suggestion)
                                                    .foregroundColor(.appTextPrimary)
                                                Spacer()
                                                if name == suggestion {
                                                    Image(systemName: "checkmark")
                                                        .foregroundColor(.green)
                                                }
                                            }
                                            .padding(.vertical, 12)
                                            .padding(.horizontal, 14)
                                            .contentShape(Rectangle())
                                        }
                                        if idx < suggestions.count - 1 {
                                            Divider()
                                                .background(Color.gray.opacity(0.3))
                                                .padding(.leading, 14)
                                        }
                                    }
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.appField)
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("\(bodyPart.displayName)の種目を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") { onSave(name) }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear { isNameFocused = true }
        }
    }
}
