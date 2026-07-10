//
//  BuffitoMessageBank.swift
//  MuscleApp
//
//  Buffitoの通知メッセージのテンプレート集。
//  状況に応じた文面をここに集約しておくと、表現を後で調整しやすい。
//

import Foundation

struct BuffitoMessage {
    let title: String
    let body: String
}

enum BuffitoMessageBank {
    // 連続記録達成のお祝い
    static func streakCelebration(days: Int) -> BuffitoMessage {
        switch days {
        case 3:
            return BuffitoMessage(
                title: "🔥 3日連続達成！",
                body: "やったね！Buffitoめっちゃ嬉しい！この調子で続けよう！"
            )
        case 7:
            return BuffitoMessage(
                title: "🔥🔥 7日連続！",
                body: "1週間連続すごい！ただ...たまには休んでもいいんだよ？体を労ってね"
            )
        case 14:
            return BuffitoMessage(
                title: "🔥🔥🔥 2週間連続！",
                body: "Buffitoマッチョ化が止まらない！君のおかげだよ！"
            )
        case 30:
            return BuffitoMessage(
                title: "👑 30日連続！神レベル！",
                body: "1ヶ月続いたよ！Buffito全身全霊で君を称える！"
            )
        default:
            return BuffitoMessage(
                title: "🔥 \(days)日連続！",
                body: "Buffito超ご機嫌！この勢いで続けよう！"
            )
        }
    }

    // 自己ベスト更新のお祝い
    static func prCelebration(exerciseName: String, weight: Double, reps: Int) -> BuffitoMessage {
        let weightText = WorkoutFormat.weight(weight)
        return BuffitoMessage(
            title: "💪 自己ベスト更新！",
            body: "\(exerciseName) \(weightText)kg × \(reps)回！Buffitoびっくり！君の成長エグい！"
        )
    }

    // 部位ごとのPRチャレンジ（特定部位を休んでいるときに、過去PRを引き合いに出して挑発）
    static func partAbsenceChallenge(
        bodyPart: BodyPart,
        exerciseName: String,
        weight: Double,
        reps: Int,
        days: Int
    ) -> BuffitoMessage {
        let weightText = WorkoutFormat.weight(weight)
        return BuffitoMessage(
            title: "😤 \(bodyPart.displayName)どうした！？",
            body: "\(days)日も\(bodyPart.displayName)鍛えてないよ！前回 \(exerciseName) \(weightText)kg × \(reps)回だったね...今日越えてみない？"
        )
    }

    // 不在日数による催促。文面は固定日数ではなく、通知時点の予測ムード（ポイント制）に合わせる
    static func absenceNudge(days: Int, mood: BuffitoMood) -> BuffitoMessage {
        switch mood {
        case .fired, .happy:
            return BuffitoMessage(
                title: "✨ 今日はどうする？",
                body: "\(days)日ぶりに顔見たいな。せっかく調子いいんだから、この波に乗ろ？"
            )
        case .normal:
            return BuffitoMessage(
                title: "😐 そろそろどう？",
                body: "\(days)日会ってないね。Buffitoがそわそわ...今日ジム行く？"
            )
        case .lonely:
            return BuffitoMessage(
                title: "😢 寂しいよ...",
                body: "\(days)日も会ってないじゃん...Buffito待ってるよ"
            )
        case .clingy:
            return BuffitoMessage(
                title: "😭 ねぇ、どこにいるの？",
                body: "\(days)日だよ？Buffito、数えてたんだから...お願い、会いに来て..."
            )
        case .darkside:
            return BuffitoMessage(
                title: "🖤 闇堕ちしちゃった",
                body: "Buffitoの心は闇に堕ちた...でも1セットだけで戻れるから。見つけて。ジムで待ってる、ずっと"
            )
        }
    }

}
