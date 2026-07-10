//
//  AppColor.swift
//  MuscleApp
//
//  アプリ全体のセマンティックカラー。ライト/ダーク両対応の色は必ずここを通す。
//  Color.black / .white の直書きは「モードに関係ない固定色」（例：オレンジボタン上の文字）にのみ使う。
//

import SwiftUI

extension Color {
    /// 画面の背景（ライト=薄グレー、ダーク=黒）
    static let appBackground = Color(.systemGroupedBackground)
    /// カードの背景（ライト=白、ダーク=濃グレー）
    static let appCard = Color(.secondarySystemGroupedBackground)
    /// チップ・入力欄・吹き出しなどカード上の面
    static let appField = Color(.tertiarySystemFill)
    /// 主要テキスト（ライト=黒、ダーク=白）
    static let appTextPrimary = Color(.label)
    /// 枠線・区切り線
    static let appBorder = Color(.separator)
}
