//
//  GrowthSummaryCard.swift
//  MuscleApp
//

import SwiftUI
import SwiftData

// 種目詳細ページ用の成長サマリーカード
struct GrowthSummaryCard: View {
    let exercise: Exercise

    @Query private var allSets: [WorkoutSet]

    init(exercise: Exercise) {
        self.exercise = exercise
        let exerciseId = exercise.persistentModelID
        _allSets = Query(
            filter: #Predicate<WorkoutSet> { $0.exercise?.persistentModelID == exerciseId },
            sort: [SortDescriptor(\.date, order: .reverse)]
        )
    }

    // 推定1RMの最大
    private var maxOneRM: Double {
        allSets.map { OneRMCalculator.estimate(weight: $0.weight, reps: $0.reps) }.max() ?? 0
    }

    // 最大重量を挙げたセット
    private var maxWeightSet: WorkoutSet? {
        allSets.max(by: { $0.weight < $1.weight })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.orange)
                    .font(.caption)
                Text("成長サマリー")
                    .font(.caption.bold())
                    .foregroundColor(.gray)
                Spacer()
            }

            HStack(spacing: 12) {
                metric(label: "推定1RM", value: formatNumber(maxOneRM), unit: "kg", color: .yellow)
                metric(
                    label: "最大重量",
                    value: maxWeightSet.map { formatNumber($0.weight) } ?? "—",
                    unit: maxWeightSet != nil ? "kg" : "",
                    color: .orange
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCard)
        )
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

    private func formatNumber(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
}
