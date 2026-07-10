//
//  BuffitoWidgetSpeechBank.swift
//  BuffitoWidgetExtension
//
//  ウィジェット用の短いセリフ集（1行・12字以内目安）。
//  タイムラインは未来分を事前生成するため、日付から決定的に選ぶことで
//  「アプリを開かなくても日替わりで変わる／同じ日は変わらない」を実現する。
//

import Foundation

enum BuffitoWidgetSpeechBank {
    static func dailyLine(for mood: BuffitoMood, on date: Date) -> String {
        BuffitoWidgetDailyPool.pick(from: lines(for: mood), on: date) ?? mood.statusText
    }

    private static func lines(for mood: BuffitoMood) -> [String] {
        switch mood {
        case .fired:
            return ["今日も無敵だよ🔥", "燃えてるね🔥", "最強の相棒！", "限界って何？🔥"]
        case .happy:
            return ["いい調子✨", "今日も来るよね？", "ごきげんだよ😸", "プロテイン飲んだ？"]
        case .normal:
            return ["そろそろ行く？", "1セットどう？", "準備はOKだよ", "筋肉がうずうずする"]
        case .lonely:
            return ["会いたいな…😢", "待ってるよ…", "顔見せてよ…😢", "今日は来るかな…"]
        case .clingy:
            return ["ねぇ、どこ…？", "数えてるからね", "見捨てないで…😭", "信じてるから…"]
        case .darkside:
            return ["……🖤", "闇の中で待つ…", "光を覚えてる…🖤", "1セットで戻れる…"]
        }
    }
}
