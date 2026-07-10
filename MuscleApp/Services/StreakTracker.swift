//
//  StreakTracker.swift
//  MuscleApp
//
//  セット履歴から連続トレーニング日数を計算する。
//  今日 or 昨日にトレーニングがあれば「継続中」、それ以前ならストリークは0。
//

import Foundation

struct StreakInfo {
    let current: Int       // 現在の連続日数
    let longest: Int       // 過去最長の連続日数
    let lastWorkoutDate: Date?  // 最後にトレーニングした日（startOfDay）

    // ステータスカード（ホーム/相棒ホーム）で共有する表示文
    var cardLabel: String {
        if current >= 1 {
            return "🔥 \(current)日連続中"
        }
        if lastWorkoutDate == nil {
            return "最初の1セットを記録しよう"
        }
        return "今日から再スタート！"
    }
}

enum StreakTracker {
    // セット全件から連続日数情報を算出
    static func calculate(sets: [WorkoutSet], referenceDate: Date = Date()) -> StreakInfo {
        let calendar = Calendar.current
        let trainingDays = uniqueDays(sets: sets, calendar: calendar)

        guard let mostRecent = trainingDays.first else {
            return StreakInfo(current: 0, longest: 0, lastWorkoutDate: nil)
        }

        let current = currentStreak(
            trainingDays: trainingDays,
            referenceDate: referenceDate,
            calendar: calendar
        )
        let longest = longestStreak(days: trainingDays.reversed(), calendar: calendar)

        return StreakInfo(current: current, longest: longest, lastWorkoutDate: mostRecent)
    }

    // 不在日数（最後のトレ日から今日まで何日経ったか）
    static func daysSinceLastWorkout(sets: [WorkoutSet], referenceDate: Date = Date()) -> Int {
        let calendar = Calendar.current
        let days = uniqueDays(sets: sets, calendar: calendar)
        guard let last = days.first else { return Int.max }
        let today = calendar.startOfDay(for: referenceDate)
        return calendar.dateComponents([.day], from: last, to: today).day ?? 0
    }

    // MARK: - Helpers

    // セットを日単位（startOfDay）でユニーク化、新しい順にソート
    private static func uniqueDays(sets: [WorkoutSet], calendar: Calendar) -> [Date] {
        Set(sets.map { calendar.startOfDay(for: $0.date) }).sorted(by: >)
    }

    // 現在の連続日数：今日 or 昨日から始まる必要あり
    private static func currentStreak(
        trainingDays: [Date],
        referenceDate: Date,
        calendar: Calendar
    ) -> Int {
        guard let mostRecent = trainingDays.first else { return 0 }
        let today = calendar.startOfDay(for: referenceDate)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }

        // 直近のトレが今日でも昨日でもなければ「継続中」とは見なさない
        guard mostRecent == today || mostRecent == yesterday else { return 0 }

        var streak = 1
        var prev = mostRecent
        for day in trainingDays.dropFirst() {
            guard let expected = calendar.date(byAdding: .day, value: -1, to: prev),
                  day == expected else {
                break
            }
            streak += 1
            prev = day
        }
        return streak
    }

    // 全期間で最も長い連続日数
    private static func longestStreak(days: [Date], calendar: Calendar) -> Int {
        guard !days.isEmpty else { return 0 }
        var longest = 1
        var currentRun = 1
        for i in 1..<days.count {
            guard let expected = calendar.date(byAdding: .day, value: 1, to: days[i - 1]),
                  days[i] == expected else {
                currentRun = 1
                continue
            }
            currentRun += 1
            longest = max(longest, currentRun)
        }
        return longest
    }
}
