//
//  BuffitoMood.swift
//  MuscleApp
//
//  Buffitoキャラクターの感情状態。
//  連続日数と不在日数から自動的にムードが決まる。
//

import SwiftUI

enum BuffitoMood: Int, CaseIterable {
    case darkside = 0    // 💔 闇堕ち（7日以上不在）
    case clingy = 1      // 😭 メンヘラ（5-6日不在）
    case lonely = 2      // 😢 寂しい（2-4日不在）
    case normal = 3      // 😐 普通（0-1日不在）
    case happy = 4       // 😊 ご機嫌（連続1-2日）
    case fired = 5       // 🔥 やる気MAX（連続3日以上）

    var emoji: String {
        switch self {
        case .darkside: return "💔"
        case .clingy: return "😭"
        case .lonely: return "😢"
        case .normal: return "😐"
        case .happy: return "😊"
        case .fired: return "🔥"
        }
    }

    var displayName: String {
        switch self {
        case .darkside: return "闇堕ち中"
        case .clingy: return "メンヘラ気味"
        case .lonely: return "寂しい"
        case .normal: return "普通"
        case .happy: return "ご機嫌"
        case .fired: return "やる気MAX"
        }
    }

    // カード表示用のテキスト
    var statusText: String {
        switch self {
        case .fired: return "Buffitoはやる気MAX"
        case .happy: return "Buffitoはご機嫌"
        case .normal: return "Buffitoは普通"
        case .lonely: return "Buffitoが寂しがってる"
        case .clingy: return "Buffitoがメンヘラ気味..."
        case .darkside: return "Buffito完全に闇堕ち🖤"
        }
    }

    // カード背景のテーマ色
    var tintColor: Color {
        switch self {
        case .fired: return .orange
        case .happy: return Color(red: 0.95, green: 0.65, blue: 0.0)  // 黄寄りオレンジ
        case .normal: return Color.gray
        case .lonely: return .blue
        case .clingy: return .pink
        case .darkside: return .purple
        }
    }

    // Assets.xcassets で使う画像名（同名の画像があれば自動表示、なければ絵文字フォールバック）
    var assetName: String {
        switch self {
        case .darkside: return "buffito_darkside"
        case .clingy: return "buffito_clingy"
        case .lonely: return "buffito_lonely"
        case .normal: return "buffito_normal"
        case .happy: return "buffito_happy"
        case .fired: return "buffito_fired"
        }
    }
}
