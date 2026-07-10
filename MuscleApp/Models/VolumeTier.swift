//
//  VolumeTier.swift
//  MuscleApp
//
//  ヒートマップの色濃度の段階。
//  1日の合計負荷量（重量 × 回数）をkg単位で判定する。
//

import SwiftUI

enum VolumeTier: Int, CaseIterable {
    case none = 0     // 0kg（休み）
    case light = 1    // ～2,000kg
    case medium = 2   // 2,000～5,000kg
    case heavy = 3    // 5,000～10,000kg
    case extreme = 4  // 10,000kg以上

    // ヒートマップセルの背景色（緑のグラデーション）
    var color: Color {
        switch self {
        case .none: return Color.appCard
        case .light: return Color.green.opacity(0.28)
        case .medium: return Color.green.opacity(0.5)
        case .heavy: return Color.green.opacity(0.75)
        case .extreme: return .green
        }
    }

    // セル内文字色
    var textColor: Color {
        switch self {
        case .none, .light: return .white.opacity(0.85)
        default: return .white
        }
    }

    // ボリューム値からTierを判定（kg単位）
    static func from(volume: Double) -> VolumeTier {
        switch volume {
        case ..<1: return .none
        case ..<2000: return .light
        case ..<5000: return .medium
        case ..<10000: return .heavy
        default: return .extreme
        }
    }
}
