//
//  TodayWorkoutAdvisor.swift
//  MuscleApp
//
//  「今日なにやる?」相談のローカル判定ロジック。
//  部位ごとの「最後にやってからの日数」を計算し、一番空いている部位を提案する。
//  AIは使わない（深掘りしたい時だけ aiQuestion をチャットに渡す）。
//

import Foundation

// 相談結果。カード表示用の本文と、AIチャットへ引き継ぐ質問文を持つ
struct TodayWorkoutAdvice: Identifiable {
    let id = UUID()
    let part: BodyPart?     // nil = 記録がなく部位を絞れない
    let message: String
    let aiQuestion: String
}

enum TodayWorkoutAdvisor {
    // この日数以上空いていたら「久しぶり」と表現を変える
    private static let restedThresholdDays = 3

    static func advise(allSets: [WorkoutSet], referenceDate: Date = Date()) -> TodayWorkoutAdvice {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: referenceDate)

        // 部位ごとの最終トレーニング日
        var lastDates: [BodyPart: Date] = [:]
        for set in allSets {
            guard let part = set.exercise?.bodyPart else { continue }
            let day = calendar.startOfDay(for: set.date)
            if day > (lastDates[part] ?? .distantPast) {
                lastDates[part] = day
            }
        }

        guard !lastDates.isEmpty else {
            return TodayWorkoutAdvice(
                part: nil,
                message: "まだ記録がないから、まずは好きな部位から始めよう！迷ったら胸か脚がおすすめ💪",
                aiQuestion: "筋トレ初心者です。最初の1週間のおすすめメニューを教えてください。"
            )
        }

        // 一番間隔が空いている部位（同日数なら部位の並び順が先のもの）
        let order = BodyPart.orderedAll
        let ranked = lastDates
            .map { (part: $0.key, days: daysBetween($0.value, today, calendar: calendar)) }
            .sorted { a, b in
                if a.days != b.days { return a.days > b.days }
                return orderIndex(a.part, in: order) < orderIndex(b.part, in: order)
            }

        // lastDatesが空でないことは上で保証済み
        guard let top = ranked.first else {
            return TodayWorkoutAdvice(part: nil, message: "記録の読み取りに失敗しました。", aiQuestion: "")
        }

        return TodayWorkoutAdvice(
            part: top.part,
            message: buildMessage(part: top.part, days: top.days, allSets: allSets, calendar: calendar),
            aiQuestion: "今日は\(top.part.displayName)を鍛えようと思います。直近の記録を踏まえて、おすすめの種目構成とセット・重量の組み方を教えてください。"
        )
    }

    // MARK: - メッセージ組み立て

    private static func buildMessage(
        part: BodyPart,
        days: Int,
        allSets: [WorkoutSet],
        calendar: Calendar
    ) -> String {
        let name = part.displayName
        let lastLine = lastSetLine(part: part, allSets: allSets)

        // 一番空いている部位ですら今日やっている＝全部位を今日こなしている
        if days == 0 {
            return "今日は全部位を記録済み！すごい💪 やりすぎには気をつけて、休息も大事にしよう。"
        }
        if days >= restedThresholdDays {
            return "\(name)が\(days)日空いてるよ。今日は\(name)の日にしよう！\(lastLine)"
        }
        return "どの部位もいいペースで回せてる！順番的には次は\(name)がおすすめ。\(lastLine)"
    }

    // 「前回は◯◯ 50kg×10回だった」の1文を作る（記録が薄い場合は空文字）
    private static func lastSetLine(part: BodyPart, allSets: [WorkoutSet]) -> String {
        let partSets = allSets
            .filter { $0.exercise?.bodyPart == part }
            .sorted { $0.date > $1.date }

        guard let latest = partSets.first, let exercise = latest.exercise else { return "" }

        // 最新日の同一種目の中で一番重かったセットを「前回」として見せる
        let calendar = Calendar.current
        let bestOfDay = partSets
            .filter {
                $0.exercise === exercise &&
                calendar.isDate($0.date, inSameDayAs: latest.date)
            }
            .max { $0.weight < $1.weight } ?? latest

        return "前回は\(exercise.name) \(WorkoutFormat.weight(bestOfDay.weight))kg×\(bestOfDay.reps)回だった。"
    }

    // MARK: - 小道具

    private static func daysBetween(_ from: Date, _ to: Date, calendar: Calendar) -> Int {
        calendar.dateComponents([.day], from: from, to: to).day ?? 0
    }

    private static func orderIndex(_ part: BodyPart, in order: [BodyPart]) -> Int {
        order.firstIndex(of: part) ?? order.count
    }

}
