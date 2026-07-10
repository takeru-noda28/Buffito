//
//  AnalyticsMiniCard.swift
//  MuscleApp
//
//  相棒ホームの分析ミニカード。
//  直近7日のトレ日数・総ボリューム・先週比をひと目で見せ、タップで分析タブへ誘導する。
//

import SwiftUI

struct AnalyticsMiniCard: View {
    let allSets: [WorkoutSet]
    let onTap: () -> Void

    private static let windowDays = 7

    private struct WeekStats {
        let trainingDays: Int
        let volume: Double
        let previousVolume: Double
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("今週のトレーニング")
                        .font(.headline)
                        .foregroundColor(.appTextPrimary)

                    Spacer()

                    HStack(spacing: 3) {
                        Text("分析を見る")
                            .font(.caption)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .foregroundColor(.gray)
                }

                let stats = weekStats
                HStack(spacing: 0) {
                    statColumn(value: "\(stats.trainingDays)", unit: "日", label: "トレ日数", color: .orange)
                    statColumn(value: WorkoutFormat.volume(stats.volume), unit: "kg", label: "総ボリューム", color: .white)
                    deltaColumn(stats)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.appCard)
            )
        }
    }

    // MARK: - 集計（直近7日と、その前の7日）

    private var weekStats: WeekStats {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let weekStart = calendar.date(byAdding: .day, value: -(Self.windowDays - 1), to: today),
              let prevStart = calendar.date(byAdding: .day, value: -Self.windowDays, to: weekStart) else {
            return WeekStats(trainingDays: 0, volume: 0, previousVolume: 0)
        }

        var trainingDays = Set<Date>()
        var volume = 0.0
        var previousVolume = 0.0
        for set in allSets {
            let day = calendar.startOfDay(for: set.date)
            if day >= weekStart {
                trainingDays.insert(day)
                volume += set.weight * Double(set.reps)
            } else if day >= prevStart {
                previousVolume += set.weight * Double(set.reps)
            }
        }
        return WeekStats(trainingDays: trainingDays.count, volume: volume, previousVolume: previousVolume)
    }

    // MARK: - 表示部品

    private func statColumn(value: String, unit: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(.title3, design: .rounded).bold())
                    .foregroundColor(color)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }

    // 先週比：前週の記録がなければ「ー」、あれば増減率を色付きで表示
    private func deltaColumn(_ stats: WeekStats) -> some View {
        let (text, color) = deltaTextAndColor(stats)
        return statColumn(value: text, unit: "", label: "先週比", color: color)
    }

    private func deltaTextAndColor(_ stats: WeekStats) -> (String, Color) {
        guard stats.previousVolume > 0 else { return ("ー", .gray) }
        let percent = Int(((stats.volume - stats.previousVolume) / stats.previousVolume * 100).rounded())
        if percent > 0 { return ("+\(percent)%", .green) }
        if percent < 0 { return ("\(percent)%", .red) }
        return ("±0%", .gray)
    }

}
