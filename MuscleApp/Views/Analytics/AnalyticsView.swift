//
//  AnalyticsView.swift
//  MuscleApp
//

import SwiftUI
import SwiftData
import Charts

// グラフ用データ構造
struct DailyVolume: Identifiable {
    var id: Date { date }
    let date: Date
    let volume: Double
}

struct BodyPartFrequency: Identifiable {
    var id: String { part.rawValue }
    let part: BodyPart
    let days: Int
}

// 分析画面（統計サマリ + グラフ）
struct AnalyticsView: View {
    @Query private var allSets: [WorkoutSet]

    // 総トレーニング日数
    private var totalDays: Int {
        Set(allSets.map { Calendar.current.startOfDay(for: $0.date) }).count
    }

    // 総トレーニング量（重量 × 回数 の合計）
    private var totalVolume: Double {
        allSets.reduce(0) { $0 + $1.weight * Double($1.reps) }
    }

    // 過去7日間の平均（トレーニング日あたり）
    private var weekAverage: Double {
        averageVolume(daysBack: 7)
    }

    // 過去30日間の平均（トレーニング日あたり）
    private var monthAverage: Double {
        averageVolume(daysBack: 30)
    }

    private func averageVolume(daysBack: Int) -> Double {
        guard let since = Calendar.current.date(byAdding: .day, value: -daysBack, to: Date()) else { return 0 }
        let recent = allSets.filter { $0.date >= since }
        let days = Set(recent.map { Calendar.current.startOfDay(for: $0.date) }).count
        guard days > 0 else { return 0 }
        let volume = recent.reduce(0) { $0 + $1.weight * Double($1.reps) }
        return volume / Double(days)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        StatCard(title: "総トレーニング日数", value: "\(totalDays)", unit: "日", color: .blue)
                        StatCard(title: "総負荷量", value: formatTons(totalVolume), unit: "t", color: .green)
                        StatCard(title: "今週の平均", value: WorkoutFormat.volume(weekAverage), unit: "kg/日", color: .orange)
                        StatCard(title: "今月の平均", value: WorkoutFormat.volume(monthAverage), unit: "kg/日", color: .red)

                        askBuffitoLink
                        DailyVolumeChartCard(volumes: last30DaysVolumes)
                        BodyPartFrequencyChartCard(items: bodyPartFrequencyLast30Days)
                        GrowthRankingCard()
                        PerExerciseSection()
                    }
                    .padding()
                }
            }
            .navigationTitle("分析")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.appBackground, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
        }
    }

    private var askBuffitoLink: some View {
        NavigationLink {
            AIChatView()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundColor(.orange)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Buffitoに聞く")
                        .font(.headline)
                        .foregroundColor(.appTextPrimary)
                    Text("AIがトレーニング履歴を見てアドバイス")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.18))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // kg を t に換算してフォーマット（小数1桁、末尾.0は省略）
    private func formatTons(_ kgValue: Double) -> String {
        let tons = kgValue / 1000.0
        if tons == floor(tons) {
            return String(Int(tons))
        }
        return String(format: "%.1f", tons)
    }

    // 直近30日の日別トレーニング量（空の日は0で埋める）
    private var last30DaysVolumes: [DailyVolume] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let cutoff = cal.date(byAdding: .day, value: -29, to: today) else { return [] }

        var totals: [Date: Double] = [:]
        for set in allSets where set.date >= cutoff {
            let day = cal.startOfDay(for: set.date)
            totals[day, default: 0] += set.weight * Double(set.reps)
        }

        var result: [DailyVolume] = []
        var date = cutoff
        while date <= today {
            result.append(DailyVolume(date: date, volume: totals[date] ?? 0))
            date = cal.date(byAdding: .day, value: 1, to: date) ?? date.addingTimeInterval(86400)
        }
        return result
    }

    // 直近30日で各部位を鍛えた日数
    private var bodyPartFrequencyLast30Days: [BodyPartFrequency] {
        let cal = Calendar.current
        guard let cutoff = cal.date(byAdding: .day, value: -29, to: cal.startOfDay(for: Date())) else { return [] }

        return BodyPart.orderedAll.map { part in
            let setsForPart = allSets.filter {
                $0.date >= cutoff && $0.exercise?.bodyPart == part
            }
            let days = Set(setsForPart.map { cal.startOfDay(for: $0.date) }).count
            return BodyPartFrequency(part: part, days: days)
        }
    }
}

// 直近30日のトレーニング量推移グラフ
struct DailyVolumeChartCard: View {
    let volumes: [DailyVolume]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("直近30日のトレーニング量")
                .font(.headline)
                .foregroundColor(.appTextPrimary)

            Chart {
                ForEach(volumes) { item in
                    BarMark(
                        x: .value("日付", item.date, unit: .day),
                        y: .value("kg", item.volume)
                    )
                    .foregroundStyle(Color.blue.gradient)
                }
            }
            .frame(height: 180)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { value in
                    AxisGridLine().foregroundStyle(Color.gray.opacity(0.3))
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day(), centered: true)
                        .foregroundStyle(Color.gray)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine().foregroundStyle(Color.gray.opacity(0.3))
                    AxisValueLabel().foregroundStyle(Color.gray)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCard)
        )
    }
}

// 部位別頻度グラフ
struct BodyPartFrequencyChartCard: View {
    let items: [BodyPartFrequency]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("部位別の頻度（30日）")
                .font(.headline)
                .foregroundColor(.appTextPrimary)

            Chart {
                ForEach(items) { item in
                    BarMark(
                        x: .value("部位", item.part.displayName),
                        y: .value("日数", item.days)
                    )
                    .foregroundStyle(item.part.color.gradient)
                }
            }
            .frame(height: 180)
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel().foregroundStyle(Color.gray)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine().foregroundStyle(Color.gray.opacity(0.3))
                    AxisValueLabel().foregroundStyle(Color.gray)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCard)
        )
    }
}

// 統計カード（タイトル + 数値 + 単位）
struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        HStack {
            Rectangle()
                .fill(color)
                .frame(width: 4)
                .cornerRadius(2)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.appTextPrimary)
                    Text(unit)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCard)
        )
    }
}
