//
//  BuffitoMoodMeter.swift
//  MuscleApp
//
//  やる気ポイント制のムード判定（0〜100）。
//  記録から毎回決定的に再計算するので、状態の保存は不要。
//  設計意図：
//  - トレした日は最低40（普通）を保証 → 闇堕ち/メンヘラでも1回で立ち直る
//  - 減点は連続休養日数で増える（1日目は軽傷、3日目にガクッと落ちる）
//    → やる気MAX(100)でも3日連続で休むとちょうど39（寂しい）になる
//  - 「今日」はまだ終わっていないので減点しない（トレ済みなら加点のみ反映）
//    → 毎日通っている人が翌朝に一時的にムードダウンして見えるのを防ぐ
//
//  このファイルはウィジェットターゲットとも共有するため、SwiftData（WorkoutSet）に
//  依存しない「トレ日の集合」ベースで実装する。WorkoutSetからの変換は
//  BuffitoMoodMeter+WorkoutSet.swift（アプリ側のみ）にある。
//

import Foundation

enum BuffitoMoodMeter {
    // トレした日に保証される「普通」ライン
    static let neutralScore = 40

    // トレ1回の加点（ゲージ画面の説明文でも使う）
    static let trainGain = 15

    private static let startScore = 50
    private static let windowDays = 30
    // 連続休養n日目の減点（4日目以降は ongoingRestPenalty）
    private static let restPenalties = [6, 20, 35]
    private static let ongoingRestPenalty = 8

    static func currentMood(trainingDays: Set<Date>, referenceDate: Date = Date()) -> BuffitoMood {
        mood(for: score(trainingDays: trainingDays, referenceDate: referenceDate))
    }

    // 直近30日を古い順に走査してポイントを算出。
    // trainingDays は startOfDay に正規化済みの日付集合を渡す
    static func score(trainingDays: Set<Date>, referenceDate: Date = Date()) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: referenceDate)

        guard !trainingDays.isEmpty,
              let windowStart = calendar.date(byAdding: .day, value: -(windowDays - 1), to: today) else {
            return startScore
        }

        var score = startScore
        var restRun = 0
        var day = windowStart
        while day <= today {
            if trainingDays.contains(day) {
                restRun = 0
                score = max(score + trainGain, neutralScore)
            } else if day < today {
                // 今日の未トレはまだ「休み」と確定していないので減点しない
                restRun += 1
                let penalty = restRun <= restPenalties.count
                    ? restPenalties[restRun - 1]
                    : ongoingRestPenalty
                score -= penalty
            }
            score = min(max(score, 0), 100)
            day = calendar.date(byAdding: .day, value: 1, to: day) ?? day.addingTimeInterval(86400)
        }
        return score
    }

    // 各ムードの下限しきい値（昇順）。ムード判定とゲージ表示の両方で使う
    static let moodThresholds: [(threshold: Int, mood: BuffitoMood)] = [
        (10, .clingy), (25, .lonely), (40, .normal), (70, .happy), (90, .fired)
    ]

    static func mood(for score: Int) -> BuffitoMood {
        var result: BuffitoMood = .darkside
        for band in moodThresholds where score >= band.threshold {
            result = band.mood
        }
        return result
    }
}
