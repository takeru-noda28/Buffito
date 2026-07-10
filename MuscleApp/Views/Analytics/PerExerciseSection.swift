//
//  PerExerciseSection.swift
//  MuscleApp
//
//  分析タブの「種目別分析」セクション（A+Bハイブリッド）。
//  - 上部：種目セレクター + 選択した種目のミニ詳細カード
//  - 下部：全種目クイックビュー（記録のある種目だけリスト表示）
//

import SwiftUI
import SwiftData
import Charts

struct PerExerciseSection: View {
    @Query private var allSets: [WorkoutSet]
    @Query(sort: [SortDescriptor(\Exercise.sortOrder)]) private var allExercises: [Exercise]

    @State private var selectedExerciseID: PersistentIdentifier? = nil

    // 1セット以上記録のある種目だけ表示対象
    private var trainedExercises: [Exercise] {
        let trainedIDs = Set(allSets.compactMap { $0.exercise?.persistentModelID })
        return allExercises.filter { trainedIDs.contains($0.persistentModelID) }
    }

    private var selectedExercise: Exercise? {
        if let id = selectedExerciseID,
           let match = trainedExercises.first(where: { $0.persistentModelID == id }) {
            return match
        }
        return trainedExercises.first
    }

    var body: some View {
        VStack(spacing: 16) {
            if trainedExercises.isEmpty {
                Text("まだ種目別のデータがありません")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.appCard)
                    )
            } else {
                selectorAndDetail
                quickList
            }
        }
    }

    // MARK: - 上部：セレクター + ミニ詳細

    private var selectorAndDetail: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.orange)
                Text("種目別分析")
                    .font(.subheadline)
                    .foregroundColor(.appTextPrimary)
                Spacer()
            }

            // 種目選択メニュー
            Menu {
                ForEach(trainedExercises) { exercise in
                    Button {
                        selectedExerciseID = exercise.persistentModelID
                    } label: {
                        HStack {
                            Text(exercise.name)
                            if exercise.persistentModelID == selectedExercise?.persistentModelID {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Circle()
                        .fill(selectedExercise?.bodyPart.color ?? .gray)
                        .frame(width: 8, height: 8)
                    Text(selectedExercise?.name ?? "種目を選択")
                        .font(.subheadline.bold())
                        .foregroundColor(.appTextPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.appField)
                )
            }

            if let exercise = selectedExercise {
                ExerciseMiniDetailCard(
                    exercise: exercise,
                    sets: setsFor(exercise: exercise)
                )
            }
        }
    }

    // MARK: - 下部：全種目クイックビュー

    private var quickList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "list.bullet.rectangle")
                    .foregroundColor(.blue)
                Text("全種目クイックビュー")
                    .font(.subheadline)
                    .foregroundColor(.appTextPrimary)
                Spacer()
            }

            VStack(spacing: 0) {
                ForEach(Array(trainedExercises.enumerated()), id: \.element.persistentModelID) { idx, exercise in
                    NavigationLink {
                        ExerciseHistoryView(exercise: exercise)
                    } label: {
                        ExerciseQuickRow(
                            exercise: exercise,
                            sets: setsFor(exercise: exercise)
                        )
                    }
                    .buttonStyle(.plain)
                    if idx < trainedExercises.count - 1 {
                        Divider().background(Color.gray.opacity(0.2))
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appCard)
            )
        }
    }

    private func setsFor(exercise: Exercise) -> [WorkoutSet] {
        let id = exercise.persistentModelID
        return allSets.filter { $0.exercise?.persistentModelID == id }
    }
}

// MARK: - ミニ詳細カード（選択中の種目）

struct ExerciseMiniDetailCard: View {
    let exercise: Exercise
    let sets: [WorkoutSet]

    private var maxOneRM: Double {
        sets.map { OneRMCalculator.estimate(weight: $0.weight, reps: $0.reps) }.max() ?? 0
    }

    private var maxWeight: Double {
        sets.map { $0.weight }.max() ?? 0
    }

    // 過去30日の最大重量推移
    private var recentDailyMaxes: [DailyMaxItem] {
        let calendar = Calendar.current
        guard let cutoff = calendar.date(byAdding: .day, value: -30, to: Date()) else { return [] }
        let recent = sets.filter { $0.date >= cutoff }
        let grouped = Dictionary(grouping: recent) { calendar.startOfDay(for: $0.date) }
        return grouped.map { day, daySets in
            DailyMaxItem(date: day, maxWeight: daySets.map { $0.weight }.max() ?? 0)
        }.sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                metric(label: "推定1RM", value: format(maxOneRM), unit: "kg", color: .yellow)
                metric(label: "最大重量", value: format(maxWeight), unit: "kg", color: .orange)
                metric(label: "セッション数", value: "\(sessionCount)", unit: "回", color: .blue)
            }

            if recentDailyMaxes.count >= 2 {
                Chart(recentDailyMaxes) { item in
                    LineMark(
                        x: .value("日付", item.date),
                        y: .value("重量", item.maxWeight)
                    )
                    .foregroundStyle(Color.orange)
                    PointMark(
                        x: .value("日付", item.date),
                        y: .value("重量", item.maxWeight)
                    )
                    .foregroundStyle(Color.orange)
                }
                .frame(height: 100)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 3)) { _ in
                        AxisValueLabel(format: .dateTime.month().day())
                            .foregroundStyle(Color.gray)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel().foregroundStyle(Color.gray)
                    }
                }
            } else {
                Text("グラフを表示するには2セッション以上の記録が必要です")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.vertical, 8)
            }

            NavigationLink {
                ExerciseHistoryView(exercise: exercise)
            } label: {
                HStack {
                    Text("履歴を見る")
                        .font(.caption.bold())
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundColor(.orange)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCard)
        )
    }

    private var sessionCount: Int {
        Set(sets.map { Calendar.current.startOfDay(for: $0.date) }).count
    }

    private func metric(label: String, value: String, unit: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3.bold())
                    .foregroundColor(color)
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func format(_ value: Double) -> String {
        if value <= 0 { return "—" }
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
}

// MARK: - クイック1行（全種目リスト用）

struct ExerciseQuickRow: View {
    let exercise: Exercise
    let sets: [WorkoutSet]

    private var maxOneRM: Double {
        sets.map { OneRMCalculator.estimate(weight: $0.weight, reps: $0.reps) }.max() ?? 0
    }

    // 直近30日と それ以前の最大1RMの差
    private var growthDelta: Double {
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) else {
            return 0
        }
        let recent = sets.filter { $0.date >= cutoff }
        let prior = sets.filter { $0.date < cutoff }
        guard !recent.isEmpty, !prior.isEmpty else { return 0 }
        let recentMax = recent.map { OneRMCalculator.estimate(weight: $0.weight, reps: $0.reps) }.max() ?? 0
        let priorMax = prior.map { OneRMCalculator.estimate(weight: $0.weight, reps: $0.reps) }.max() ?? 0
        return recentMax - priorMax
    }

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(exercise.bodyPart.color)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.subheadline)
                    .foregroundColor(.appTextPrimary)
                Text("\(exercise.bodyPart.displayName)")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(format(maxOneRM))
                        .font(.subheadline.bold())
                        .foregroundColor(.appTextPrimary)
                    Text("kg")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                growthBadge
            }
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var growthBadge: some View {
        if growthDelta > 0.001 {
            Text("+\(format(growthDelta))kg")
                .font(.caption2)
                .foregroundColor(.green)
        } else if growthDelta < -0.001 {
            Text("\(format(growthDelta))kg")
                .font(.caption2)
                .foregroundColor(.red)
        } else {
            Text("±0kg")
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }

    private func format(_ value: Double) -> String {
        let abs = Swift.abs(value)
        if abs.truncatingRemainder(dividingBy: 1) == 0 {
            return value < 0 ? "-\(Int(abs))" : String(Int(abs))
        }
        return value < 0 ? String(format: "-%.1f", abs) : String(format: "%.1f", abs)
    }
}

// チャート用データ構造
private struct DailyMaxItem: Identifiable {
    let date: Date
    let maxWeight: Double
    var id: Date { date }
}
