//
//  AppearanceMode.swift
//  MuscleApp
//
//  外観モード設定（@AppStorage "theme_mode" の値と1対1）。
//  ルート（MuscleAppApp）がこの値を preferredColorScheme に反映する。
//

import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case dark
    case light

    static let storageKey = "theme_mode"
    static let defaultValue = AppearanceMode.dark

    var id: String { rawValue }

    // nil = システム準拠
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .dark: return .dark
        case .light: return .light
        }
    }

    var label: String {
        switch self {
        case .system: return "システム設定に合わせる"
        case .dark: return "ダークモード"
        case .light: return "ライトモード"
        }
    }

    var iconName: String {
        switch self {
        case .system: return "iphone"
        case .dark: return "moon.fill"
        case .light: return "sun.max.fill"
        }
    }
}
