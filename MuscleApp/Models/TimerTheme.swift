//
//  TimerTheme.swift
//  MuscleApp
//
//  タイマーアークの色テーマ。
//  デフォルト（白）は無料で使え、それ以外はPro限定。
//  残量が少ない時はテーマに関わらず警告色（橙・赤）に切り替わる。
//

import SwiftUI

enum TimerTheme: String, CaseIterable, Identifiable {
    case white   // デフォルト（無料）
    case orange
    case pink
    case blue
    case green
    case purple

    var id: String { rawValue }

    var color: Color {
        switch self {
        // デフォルトはモード適応（ダーク=白 / ライト=黒）。背景に沈まないようにする
        case .white: return .appTextPrimary
        case .orange: return .orange
        case .pink: return .pink
        case .blue: return .blue
        case .green: return .green
        case .purple: return .purple
        }
    }

    var displayName: String {
        switch self {
        case .white: return "デフォルト"
        case .orange: return "オレンジ"
        case .pink: return "ピンク"
        case .blue: return "ブルー"
        case .green: return "グリーン"
        case .purple: return "パープル"
        }
    }

    // Pro限定テーマかどうか（white以外はPro）
    var isPro: Bool {
        self != .white
    }

    // UserDefaultsから現在のテーマを取得。Proテーマが未解放なら強制的にwhite
    static var effective: TimerTheme {
        let raw = UserDefaults.standard.string(forKey: "timer_theme") ?? "white"
        let parsed = TimerTheme(rawValue: raw) ?? .white
        if parsed.isPro && !PremiumManager.shared.isUnlocked(.timerProThemes) {
            return .white
        }
        return parsed
    }
}
