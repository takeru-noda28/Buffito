//
//  HomeView.swift
//  MuscleApp
//

import SwiftUI
import SwiftData

// ホーム画面のサブルート（今日のトレーニング / ストリーク詳細 / 過去日詳細）
enum HomeRoute: Hashable {
    case today
    case streakDetail
    case dayDetail(Date)
}

// ホーム画面（部位選択 + 右上に設定アイコン）
struct HomeView: View {
    @State private var showSettings: Bool = false
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        BuffitoSpeechCard(onOpenDetail: { path.append(HomeRoute.streakDetail) })
                        TodayTrainingButton()
                        ContinueLastButton()
                    }
                    .padding()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.appTextPrimary)
                    }
                }
            }
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.appBackground, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .navigationDestination(for: BodyPart.self) { part in
                ExerciseListView(bodyPart: part)
            }
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .today:
                    TodayTrainingView()
                case .streakDetail:
                    StreakDetailView()
                case .dayDetail(let date):
                    PastDayView(date: date)
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(onClose: { showSettings = false })
        }
    }
}

// 部位選択リスト（ドラッグで並び替え可能）
struct BodyPartList: View {
    @AppStorage("body_part_order") private var bodyPartOrder: String = BodyPart.defaultOrderString

    private var orderedParts: [BodyPart] {
        let parts = bodyPartOrder.split(separator: ",").compactMap { BodyPart(rawValue: String($0)) }
        let missing = BodyPart.allCases.filter { !parts.contains($0) }
        return parts + missing
    }

    var body: some View {
        VStack(spacing: 12) {
            ForEach(orderedParts) { part in
                BodyPartRow(part: part)
                    .draggable(part.rawValue) {
                        Text(part.displayName)
                            .padding(10)
                            .background(Color.appField)
                            .cornerRadius(8)
                            .foregroundColor(.appTextPrimary)
                    }
                    .dropDestination(for: String.self) { items, _ in
                        guard let draggedRaw = items.first,
                              draggedRaw != part.rawValue else { return false }
                        swap(draggedRaw: draggedRaw, target: part)
                        return true
                    }
            }
        }
    }

    private func swap(draggedRaw: String, target: BodyPart) {
        var parts = orderedParts
        guard let from = parts.firstIndex(where: { $0.rawValue == draggedRaw }),
              let to = parts.firstIndex(of: target) else { return }
        parts.swapAt(from, to)
        bodyPartOrder = parts.map { $0.rawValue }.joined(separator: ",")
    }
}

// 今日のトレーニング画面用：3列の部位選択グリッド（タップで種目一覧へ遷移）
struct BodyPartCompactGrid: View {
    @AppStorage("body_part_order") private var bodyPartOrder: String = BodyPart.defaultOrderString

    private var orderedParts: [BodyPart] {
        let parts = bodyPartOrder.split(separator: ",").compactMap { BodyPart(rawValue: String($0)) }
        let missing = BodyPart.allCases.filter { !parts.contains($0) }
        return parts + missing
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("部位を選んで記録")
                .font(.subheadline)
                .foregroundColor(.gray)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(orderedParts) { part in
                    NavigationLink(value: part) {
                        VStack(spacing: 6) {
                            Image(systemName: part.iconName)
                                .font(.title2)
                                .foregroundColor(.appTextPrimary)
                            Text(part.displayName)
                                .font(.subheadline.bold())
                                .foregroundColor(.appTextPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.appField)
                        )
                    }
                }
            }
        }
    }
}

// 部位を1つ表示する行（タップで種目一覧へ遷移）
struct BodyPartRow: View {
    let part: BodyPart

    var body: some View {
        NavigationLink(value: part) {
            HStack {
                Image(systemName: part.iconName)
                    .font(.title2)
                    .foregroundColor(.appTextPrimary)
                    .frame(width: 32)

                Text(part.displayName)
                    .font(.title3.bold())
                    .foregroundColor(.appTextPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.appField)
            .cornerRadius(12)
        }
    }
}

// 「ワークアウト」ボタン（タップで今日のサマリ画面へ）
struct TodayTrainingButton: View {
    @Query private var allSets: [WorkoutSet]

    private var todayStats: (exercises: Int, sets: Int) {
        let todays = allSets.filter { Calendar.current.isDateInToday($0.date) }
        let uniqueExercises = Set(todays.compactMap { $0.exercise?.persistentModelID }).count
        return (uniqueExercises, todays.count)
    }

    var body: some View {
        NavigationLink(value: HomeRoute.today) {
            HStack(spacing: 14) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.appTextPrimary)
                VStack(alignment: .leading, spacing: 4) {
                    Text("ワークアウト")
                        .font(.title2.bold())
                        .foregroundColor(.appTextPrimary)
                    if todayStats.sets > 0 {
                        Text("\(todayStats.exercises) 種目 ・ \(todayStats.sets) セット")
                            .font(.subheadline)
                            .foregroundColor(.appTextPrimary)
                    } else {
                        Text("タップして開始")
                            .font(.subheadline)
                            .foregroundColor(.appTextPrimary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(.appTextPrimary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 22)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            )
        }
    }
}

// 「続きを記録」ボタン：今日の最後の種目に直接遷移
struct ContinueLastButton: View {
    @Query private var allSets: [WorkoutSet]

    // 今日の最後に記録した種目
    private var lastTodayExercise: Exercise? {
        allSets.filter { Calendar.current.isDateInToday($0.date) }
            .sorted { $0.date > $1.date }
            .first?
            .exercise
    }

    var body: some View {
        if let exercise = lastTodayExercise {
            NavigationLink {
                ExerciseDetailView(exercise: exercise, backLabel: "ホーム")
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.uturn.right.circle.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("続きを記録")
                            .font(.subheadline.bold())
                            .foregroundColor(.appTextPrimary)
                        Text(exercise.name)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.appCard)
                )
            }
        }
    }
}

// ワークアウト画面（部位選択グリッド + 今日のサマリ）
struct TodayTrainingView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    BodyPartCompactGrid()
                    WeeklyHeatmap()
                    DaySummaryView(date: Date(), backLabel: "ワークアウト", showsAddButton: false)
                }
                .padding()
            }
        }
        .navigationTitle("ワークアウト")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.appTextPrimary)
                }
            }
        }
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}
