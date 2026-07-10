//
//  BuffitoMoodTransition.swift
//  MuscleApp
//
//  前回表示時からのムード変化を検知して、状態推移セリフを1回だけ返す。
//  例：闇堕ちから普通に戻った →「今度は捨てないでね❤️‍🩹」
//

import Foundation

enum BuffitoMoodTransition {
    private static let storageKey = "last_seen_buffito_mood"

    // ムードが前回表示時から変わっていたら遷移セリフを返し、記録を更新する。
    // ホームとBuffitoタブのうち、先に表示された側が1回だけ表示する
    static func consumeLine(for mood: BuffitoMood) -> String? {
        let defaults = UserDefaults.standard
        defer { defaults.set(mood.rawValue, forKey: storageKey) }

        // 初回表示（記録なし）は遷移ではないので何も出さない
        guard let raw = defaults.object(forKey: storageKey) as? Int,
              let previous = BuffitoMood(rawValue: raw) else {
            return nil
        }
        return BuffitoSpeechBank.transitionLine(from: previous, to: mood)
    }
}
