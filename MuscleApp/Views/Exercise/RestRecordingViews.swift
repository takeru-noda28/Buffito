//
//  RestRecordingViews.swift
//  MuscleApp
//

import SwiftUI
import SwiftData

// レスト中バナー（タイマー作動中・完了アラート中に表示）
struct RestBanner: View {
    let remainingSeconds: Int
    let isAlerting: Bool
    let onStop: () -> Void

    var body: some View {
        HStack {
            Image(systemName: isAlerting ? "bell.fill" : "timer")
                .foregroundColor(.appTextPrimary)
            Text(isAlerting ? "レスト終了！" : "レスト中  \(formatTime(remainingSeconds))")
                .font(.subheadline.bold())
                .foregroundColor(.appTextPrimary)
            Spacer()
            Button(action: onStop) {
                Text(isAlerting ? "停止" : "スキップ")
                    .font(.subheadline.bold())
                    .foregroundColor(.appTextPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.appBorder)
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(isAlerting ? Color.red : Color.green.opacity(0.8))
    }

    private func formatTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// レスト時間の編集シート（今日のセット一覧 + 編集可能なStepper）
struct RestEditSheet: View {
    let exercise: Exercise
    let sets: [WorkoutSet]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if sets.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("編集できるセットがありません")
                            .foregroundColor(.gray)
                    }
                } else {
                    List {
                        ForEach(Array(sets.enumerated()), id: \.element.persistentModelID) { index, set in
                            RestEditRow(index: index + 1, set: set, onSave: saveContext)
                                .listRowBackground(Color.appBackground)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("レスト時間を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                }
            }
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    private func saveContext() {
        modelContext.saveOrLog("セット編集")
    }
}

// 1セット分の編集行
struct RestEditRow: View {
    let index: Int
    @Bindable var set: WorkoutSet
    let onSave: () -> Void

    @State private var input: Int
    @State private var showInputSheet: Bool = false

    init(index: Int, set: WorkoutSet, onSave: @escaping () -> Void) {
        self.index = index
        self.set = set
        self.onSave = onSave
        _input = State(initialValue: set.restSeconds ?? 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(index)セット目")
                    .foregroundColor(.gray)
                    .font(.subheadline)
                Spacer()
                Text(formatSet(set))
                    .foregroundColor(.appTextPrimary)
                    .font(.subheadline.bold())
            }

            HStack(spacing: 8) {
                Image(systemName: "timer")
                    .foregroundColor(.gray)
                // 表示部分（タップでホイール入力シートを開く）
                Text(input > 0 ? formatRest(input) : "未記録")
                    .foregroundColor(input > 0 ? .white : .gray)
                    .underline()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showInputSheet = true
                    }
                Spacer()
                // 30秒刻みのStepper
                Stepper("", value: $input, in: 0...3600, step: 30)
                    .labelsHidden()
                    .onChange(of: input) { _, new in
                        set.restSeconds = new > 0 ? new : nil
                        onSave()
                    }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCard)
        )
        .sheet(isPresented: $showInputSheet) {
            RestTimeInputSheet(
                initialSeconds: input,
                onSave: { newValue in
                    input = newValue
                    showInputSheet = false
                },
                onCancel: { showInputSheet = false }
            )
        }
    }

    private func formatSet(_ set: WorkoutSet) -> String {
        let weight = set.weight.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(set.weight))
            : String(format: "%.1f", set.weight)
        return "\(weight)kg × \(set.reps)回"
    }

    private func formatRest(_ totalSeconds: Int) -> String {
        if totalSeconds < 60 {
            return "\(totalSeconds)秒"
        }
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return s == 0 ? "\(m)分" : String(format: "%d分%02d秒", m, s)
    }
}

// レスト時間入力シート（プリセット + ホイールピッカー）
struct RestTimeInputSheet: View {
    let initialSeconds: Int
    let onSave: (Int) -> Void
    let onCancel: () -> Void

    @State private var minutes: Int
    @State private var seconds: Int

    // よく使うレスト時間
    private let presets: [Int] = [30, 60, 90, 120, 180, 240]
    private let presetColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    init(initialSeconds: Int, onSave: @escaping (Int) -> Void, onCancel: @escaping () -> Void) {
        self.initialSeconds = initialSeconds
        self.onSave = onSave
        self.onCancel = onCancel
        _minutes = State(initialValue: initialSeconds / 60)
        _seconds = State(initialValue: initialSeconds % 60)
    }

    // 現在の合計秒数
    private var totalSeconds: Int { minutes * 60 + seconds }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 20) {
                    // プリセットボタン
                    VStack(alignment: .leading, spacing: 8) {
                        Text("プリセット")
                            .font(.caption)
                            .foregroundColor(.gray)

                        LazyVGrid(columns: presetColumns, spacing: 8) {
                            ForEach(presets, id: \.self) { sec in
                                Button {
                                    minutes = sec / 60
                                    seconds = sec % 60
                                } label: {
                                    Text(formatPreset(sec))
                                        .font(.subheadline.bold())
                                        .foregroundColor(.appTextPrimary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            totalSeconds == sec
                                                ? Color.appBorder
                                                : Color.appField
                                        )
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // 区切り線
                    HStack {
                        Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
                        Text("または細かく設定")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
                    }
                    .padding(.horizontal)

                    // ホイールピッカー
                    HStack(spacing: 0) {
                        Picker("分", selection: $minutes) {
                            ForEach(0..<11) { value in
                                Text("\(value) 分").tag(value).foregroundColor(.appTextPrimary)
                            }
                        }
                        .pickerStyle(.wheel)

                        Picker("秒", selection: $seconds) {
                            ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { value in
                                Text("\(value) 秒").tag(value).foregroundColor(.appTextPrimary)
                            }
                        }
                        .pickerStyle(.wheel)
                    }
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .navigationTitle("レスト時間")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { onSave(totalSeconds) }
                }
            }
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    private func formatPreset(_ totalSeconds: Int) -> String {
        if totalSeconds < 60 {
            return "\(totalSeconds)秒"
        }
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return s == 0 ? "\(m)分" : String(format: "%d:%02d", m, s)
    }
}
