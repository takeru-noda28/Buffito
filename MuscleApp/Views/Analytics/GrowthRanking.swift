//
//  GrowthRanking.swift
//  MuscleApp
//
//  分析タブに表示する「成長中の種目」「停滞中の種目」ランキング。
//  直近30日の推定1RMと、それ以前の推定1RMを比較してデルタを算出。
//

import SwiftUI
import SwiftData

struct GrowthRankingCard: View {
    @Query private var allSets: [WorkoutSet]

    private let windowDays = 30

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            growingSection
            stagnantSection
        }
    }

    // 成長中の種目（直近30日でデルタ > 0）
    private var growingItems: [GrowthItem] {
        rankedItems().filter { $0.delta > 0.001 }.prefix(5).map { $0 }
    }

    // 停滞中の種目（直近30日でデルタ <= 0、ただし最近トレしている種目だけ）
    private var stagnantItems: [GrowthItem] {
        rankedItems().filter { $0.delta <= 0.001 }.prefix(5).map { $0 }
    }

    // MARK: - セクション

    private var growingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.right.circle.fill")
                    .foregroundColor(.green)
                Text("成長中の種目（直近30日）")
                    .font(.subheadline)
                    .foregroundColor(.appTextPrimary)
                Spacer()
            }

            if growingItems.isEmpty {
                emptyMessage("まだ成長中の種目はありません")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(growingItems.enumerated()), id: \.offset) { idx, item in
                        rankRow(item, positive: true)
                        if idx < growingItems.count - 1 {
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
    }

    private var stagnantSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.orange)
                Text("停滞中の種目（直近30日）")
                    .font(.subheadline)
                    .foregroundColor(.appTextPrimary)
                Spacer()
            }

            if stagnantItems.isEmpty {
                emptyMessage("停滞中の種目はありません 🎉")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(stagnantItems.enumerated()), id: \.offset) { idx, item in
                        rankRow(item, positive: false)
                        if idx < stagnantItems.count - 1 {
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
    }

    private func emptyMessage(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appCard)
            )
    }

    private func rankRow(_ item: GrowthItem, positive: Bool) -> some View {
        HStack {
            Circle()
                .fill(item.bodyPart.color)
                .frame(width: 8, height: 8)
            Text(item.exerciseName)
                .font(.subheadline)
                .foregroundColor(.appTextPrimary)
            Spacer()
            Text(formatDelta(item.delta))
                .font(.subheadline.bold())
                .foregroundColor(positive ? .green : (item.delta < 0 ? .red : .gray))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - データ計算

    // 全種目の成長度をランキング
    private func rankedItems() -> [GrowthItem] {
        let calendar = Calendar.current
        guard let recentCutoff = calendar.date(byAdding: .day, value: -windowDays, to: Date()) else {
            return []
        }

        // 種目別にセットをグループ化
        let grouped = Dictionary(grouping: allSets) { $0.exercise?.persistentModelID }

        var result: [GrowthItem] = []
        for (_, sets) in grouped {
            guard let exercise = sets.first?.exercise else { continue }

            let recent = sets.filter { $0.date >= recentCutoff }
            // 直近30日に1回もトレしていない種目はスキップ
            guard !recent.isEmpty else { continue }

            let prior = sets.filter { $0.date < recentCutoff }
            let priorMaxOneRM = maxOneRM(of: prior)
            let recentMaxOneRM = maxOneRM(of: recent)

            // 比較対象がない場合（初トレ種目）はスキップ
            guard priorMaxOneRM > 0 else { continue }

            let delta = recentMaxOneRM - priorMaxOneRM
            result.append(GrowthItem(
                exerciseName: exercise.name,
                bodyPart: exercise.bodyPart,
                delta: delta
            ))
        }
        return result.sorted { $0.delta > $1.delta }
    }

    private func maxOneRM(of sets: [WorkoutSet]) -> Double {
        sets.map { OneRMCalculator.estimate(weight: $0.weight, reps: $0.reps) }.max() ?? 0
    }

    private func formatDelta(_ delta: Double) -> String {
        let abs = Swift.abs(delta)
        let formatted = abs.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(abs))
            : String(format: "%.1f", abs)
        if delta > 0.001 { return "+\(formatted)kg" }
        if delta < -0.001 { return "-\(formatted)kg" }
        return "±0kg"
    }
}

// 成長ランキングの1項目
private struct GrowthItem {
    let exerciseName: String
    let bodyPart: BodyPart
    let delta: Double  // 推定1RMの変化量（kg）
}
