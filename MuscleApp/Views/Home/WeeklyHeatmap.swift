//
//  WeeklyHeatmap.swift
//  MuscleApp
//
//  ワークアウト画面に表示する今週のヒートマップ。
//  - 日曜始まり、土曜終わりの7セル
//  - セル色 = 合計負荷量に応じた濃淡（5段階）
//  - 今日のセルはオレンジ枠で強調
//  - 過去日タップで詳細ページへ（記録の確認・追加・編集）
//  - 未来日タップは無効
//

import SwiftUI
import SwiftData

struct WeeklyHeatmap: View {
    @Query private var allSets: [WorkoutSet]

    // 今週の7日（日曜始まり〜土曜終わり）
    private var thisWeekDays: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)  // 1=日, 7=土
        guard let sunday = calendar.date(byAdding: .day, value: -(weekday - 1), to: today) else {
            return []
        }
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: sunday)
        }
    }

    // 日付（startOfDay）→ 合計負荷量
    private var volumesByDay: [Date: Double] {
        let calendar = Calendar.current
        var result: [Date: Double] = [:]
        for set in allSets {
            let day = calendar.startOfDay(for: set.date)
            result[day, default: 0] += set.weight * Double(set.reps)
        }
        return result
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                ForEach(thisWeekDays, id: \.self) { date in
                    cell(for: date)
                }
            }
            legend
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appField)
        )
    }

    // ヒートマップ1セル
    private func cell(for date: Date) -> some View {
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(date)
        let isFuture = calendar.startOfDay(for: date) > calendar.startOfDay(for: Date())
        let volume = volumesByDay[calendar.startOfDay(for: date)] ?? 0
        let tier = VolumeTier.from(volume: volume)
        let day = calendar.component(.day, from: date)

        let label = VStack(spacing: 3) {
            Text(weekdayLabel(date))
                .font(.caption2)
                .foregroundColor(.gray)
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(tier.color)
                    .frame(height: 36)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(
                                isToday ? Color.orange : Color.clear,
                                lineWidth: 2
                            )
                    )
                Text("\(day)")
                    .font(.subheadline.bold())
                    .foregroundColor(tier.textColor)
            }
            .opacity(isFuture ? 0.4 : 1.0)
        }
        .frame(maxWidth: .infinity)

        // 今日 or 未来日は遷移しない（今日は下にDaySummary、未来は記録不可）
        if isToday || isFuture {
            return AnyView(label)
        } else {
            return AnyView(
                NavigationLink(value: HomeRoute.dayDetail(date)) { label }
                    .buttonStyle(.plain)
            )
        }
    }

    // 凡例（コンパクト：左→右で軽→重）
    private var legend: some View {
        HStack(spacing: 4) {
            Text("軽")
                .font(.caption2)
                .foregroundColor(.gray.opacity(0.7))
            ForEach(VolumeTier.allCases, id: \.rawValue) { tier in
                RoundedRectangle(cornerRadius: 2)
                    .fill(tier.color)
                    .frame(width: 12, height: 8)
            }
            Text("重")
                .font(.caption2)
                .foregroundColor(.gray.opacity(0.7))
            Spacer()
        }
    }

    // 日/月/火/...のラベル
    private func weekdayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}
