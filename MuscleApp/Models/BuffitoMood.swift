//
//  BuffitoMood.swift
//  MuscleApp
//
//  Buffitoキャラクターの感情状態。
//  トレーニング履歴から算出する0〜100のやる気ポイントでムードが決まる。
//

import SwiftUI

enum BuffitoMood: Int, CaseIterable {
    case darkside = 0    // 💔 闇堕ち（0〜9pt）
    case clingy = 1      // 😭 メンヘラ（10〜24pt）
    case lonely = 2      // 😢 寂しい（25〜39pt）
    case normal = 3      // 😐 普通（40〜69pt）
    case happy = 4       // 😊 ご機嫌（70〜89pt）
    case fired = 5       // 🔥 やる気MAX（90〜100pt）

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
