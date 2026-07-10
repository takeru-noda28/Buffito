//
//  BodyPart.swift
//  MuscleApp
//

import SwiftUI

// 鍛える部位（rawValueは保存用の安定キー、表示名は別途）
enum BodyPart: String, CaseIterable, Identifiable {
    case chest, back, shoulder, leg, arm, other

    var id: String { rawValue }

    // ユーザーに見せる名前（日本語）
    var displayName: String {
        switch self {
        case .chest: return "胸"
        case .back: return "背中"
        case .shoulder: return "肩"
        case .leg: return "脚"
        case .arm: return "腕"
        case .other: return "その他"
        }
    }

    // 並び替え可能な部位順を取得（@AppStorageから読む）
    static var orderedAll: [BodyPart] {
        let stored = UserDefaults.standard.string(forKey: "body_part_order") ?? defaultOrderString
        let parts = stored.split(separator: ",").compactMap { BodyPart(rawValue: String($0)) }
        let missing = BodyPart.allCases.filter { !parts.contains($0) }
        return parts + missing
    }

    static let defaultOrderString = "chest,back,shoulder,leg,arm,other"

    // 部位ごとの色（カレンダーや凡例で使用）
    var color: Color {
        switch self {
        case .chest: return .red
        case .back: return .blue
        case .shoulder: return .yellow
        case .leg: return .green
        case .arm: return .purple
        case .other: return .cyan
        }
    }

    // 部位アイコン（暫定：SF Symbols）。後でBuffito版に差し替え予定。
    var iconName: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.pilates"
        case .shoulder: return "figure.boxing"
        case .leg: return "figure.run"
        case .arm: return "dumbbell.fill"
        case .other: return "figure.core.training"
        }
    }
}

// 初期種目データ（部位ごとに用意）
let defaultExercisesByPart: [BodyPart: [String]] = [
    .chest: ["ベンチプレス", "インクラインダンベルプレス", "インクラインプレススミス"],
    .back: ["ラットプルダウン", "ローイング", "チンニング(懸垂)"],
    .shoulder: ["ダンベルショルダープレス", "スミスショルダープレス", "サイドレイズ"],
    .leg: ["スクワット", "レッグプレス", "レッグカール"],
    .arm: ["スカルクラッシャー", "EZバーカール", "トライセプスエクステンション"],
    .other: ["アブローラー", "プランク", "クランチ"]
]

// 種目追加シートで提案する主要な種目（部位ごと）
let popularExercisesByPart: [BodyPart: [String]] = [
    .chest: [
        "ベンチプレス", "インクラインダンベルプレス", "インクラインプレススミス",
        "ダンベルプレス", "インクラインベンチプレス", "デクラインベンチプレス",
        "ダンベルフライ", "ケーブルクロスオーバー", "プッシュアップ", "ペックフライ"
    ],
    .back: [
        "ラットプルダウン", "ローイング", "チンニング(懸垂)",
        "ベントオーバーロウ", "ダンベルロウ", "デッドリフト",
        "シーテッドロウ", "Tバーロウ", "プルアップ"
    ],
    .shoulder: [
        "ダンベルショルダープレス", "スミスショルダープレス", "サイドレイズ",
        "フロントレイズ", "リアレイズ", "アーノルドプレス",
        "バーベルショルダープレス", "ケーブルサイドレイズ", "シュラッグ"
    ],
    .leg: [
        "スクワット", "レッグプレス", "レッグカール",
        "レッグエクステンション", "ルーマニアンデッドリフト", "ブルガリアンスクワット",
        "ヒップスラスト", "カーフレイズ", "ハックスクワット"
    ],
    .arm: [
        "スカルクラッシャー", "EZバーカール", "トライセプスエクステンション",
        "バーベルカール", "ダンベルカール", "ハンマーカール",
        "プリーチャーカール", "ケーブルプッシュダウン", "ディップス"
    ],
    .other: [
        "アブローラー", "プランク", "クランチ",
        "レッグレイズ", "ロシアンツイスト", "ヒップアブダクション",
        "シットアップ", "ケーブルクランチ"
    ]
]
