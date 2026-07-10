//
//  DailyReminderMessageBank.swift
//  MuscleApp
//
//  毎日のリマインダー通知のメッセージプール。
//  ストリーク（連続日数）に応じて、ランダムにメッセージを選ぶ。
//

import Foundation

struct DailyReminderMessage {
    let title: String
    let body: String
}

enum DailyReminderMessageBank {
    // 現在のストリークに応じて、ランダムにメッセージを選ぶ
    static func randomMessage(currentStreak: Int) -> DailyReminderMessage {
        if currentStreak >= 1 {
            return streakMessages(currentStreak: currentStreak).randomElement() ?? fallback
        }
        return generalMessages.randomElement() ?? fallback
    }

    // ストリークが0のとき（連続記録なし）の汎用メッセージ
    private static let generalMessages: [DailyReminderMessage] = [
        DailyReminderMessage(title: "💪 ジムの時間だよ",
                             body: "Buffitoがそわそわ待ってる！"),
        DailyReminderMessage(title: "🔥 燃えてる？",
                             body: "今日も筋肉に火をつけよう！"),
        DailyReminderMessage(title: "🎯 今日のミッション",
                             body: "ジムへ行く、それだけ！シンプル一択！"),
        DailyReminderMessage(title: "🏆 昨日の自分を超えろ",
                             body: "1セットでもいい、始めれば勝ち！"),
        DailyReminderMessage(title: "⚡ パワーチャージ",
                             body: "ジムで全部出し切ろう！Buffitoが応援してる"),
        DailyReminderMessage(title: "💯 やるかやらないか",
                             body: "30分でもいい、ジムに行こう！"),
        DailyReminderMessage(title: "🦾 マッチョ予備軍",
                             body: "今日のひと踏ん張りが未来のマッチョを作る！"),
        DailyReminderMessage(title: "🌟 君ならできる",
                             body: "Buffitoは信じてる！今日も一緒に頑張ろう"),
        DailyReminderMessage(title: "🔥 一日一筋トレ",
                             body: "習慣にしちゃえばこっちのもん！今日も行くよ"),
        DailyReminderMessage(title: "💪 今日くらいは...",
                             body: "って思った日こそチャンス。Buffitoと立ち向かおう"),
    ]

    // ストリーク継続中のメッセージ（次の日に達成する数値を含めて煽る）
    private static func streakMessages(currentStreak: Int) -> [DailyReminderMessage] {
        let next = currentStreak + 1
        // 7日連続以上は休息も推奨
        var messages: [DailyReminderMessage] = [
            DailyReminderMessage(
                title: "🔥 \(currentStreak)日連続中！",
                body: "今日行けば\(next)日連続！Buffitoと一緒に頑張ろう！"
            ),
            DailyReminderMessage(
                title: "💪 \(currentStreak)日継続中",
                body: "今日も止まるな！\(next)日目を一緒に作ろう！"
            ),
            DailyReminderMessage(
                title: "🌟 \(currentStreak)日連続",
                body: "君の継続力すごい！今日もBuffitoが待ってる"
            ),
            DailyReminderMessage(
                title: "🚀 ノンストップ\(currentStreak)日",
                body: "今日でちょうど\(next)日目！この勢いを止めるな！"
            ),
        ]
        // 7日連続以上は「休息も大事」を混ぜる
        if currentStreak >= 7 {
            messages.append(
                DailyReminderMessage(
                    title: "🔥 \(currentStreak)日連続！",
                    body: "ちなみに...しんどい時は休んでもいいんだよ。Buffitoは君の健康も大事"
                )
            )
        }
        return messages
    }

    // フォールバック（randomElementが空配列の場合）
    private static let fallback = DailyReminderMessage(
        title: "🏋️ Buffito",
        body: "今日のトレーニングを記録しよう！"
    )
}
