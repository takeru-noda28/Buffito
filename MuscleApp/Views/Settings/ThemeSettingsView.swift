//
//  ThemeSettingsView.swift
//  MuscleApp
//
//  テーマ設定ページ。
//  - 外観モード（システム/ダーク/ライト）：将来の拡張用枠
//  - タイマーテーマカラー：Pro機能。タイマーアークの色を6色から選べる
//

import SwiftUI

struct ThemeSettingsView: View {
    @AppStorage(AppearanceMode.storageKey) private var themeMode: String = AppearanceMode.defaultValue.rawValue
    @AppStorage("timer_theme") private var timerThemeRaw: String = "white"

    @State private var showPaywall: Bool = false

    private let colorColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    appearanceSection
                    timerColorSection
                }
                .padding()
            }
        }
        .navigationTitle("テーマ")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .preferredColorScheme(selectedAppearanceMode.colorScheme)
        .sheet(isPresented: $showPaywall) {
            PaywallSheet()
        }
    }

    // MARK: - 外観モード

    private var appearanceSection: some View {
        VStack(spacing: 8) {
            SettingCard(title: "外観モード") {
                VStack(spacing: 0) {
                    let modes = AppearanceMode.allCases
                    ForEach(Array(modes.enumerated()), id: \.element.id) { idx, mode in
                        appearanceRow(mode)
                        if idx < modes.count - 1 {
                            Divider().background(Color.gray.opacity(0.2))
                        }
                    }
                }
            }
            Text("選んだ外観はすぐに反映されます。")
                .font(.caption2)
                .foregroundColor(.gray)
                .padding(.horizontal)
                .multilineTextAlignment(.center)
        }
    }

    private func appearanceRow(_ mode: AppearanceMode) -> some View {
        Button {
            themeMode = mode.rawValue
        } label: {
            HStack {
                Image(systemName: mode.iconName)
                    .foregroundColor(.gray)
                    .frame(width: 24)
                Text(mode.label)
                    .foregroundColor(.appTextPrimary)
                Spacer()
                if themeMode == mode.rawValue {
                    Image(systemName: "checkmark")
                        .foregroundColor(.orange)
                }
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
    }

    // MARK: - タイマーテーマカラー（Pro）

    private var timerColorSection: some View {
        SettingCard(title: "タイマーテーマカラー") {
            VStack(alignment: .leading, spacing: 12) {
                if !PremiumManager.shared.isUnlocked(.timerProThemes) {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text("Pro機能：デフォルト以外の色を選ぶには加入が必要")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }

                LazyVGrid(columns: colorColumns, spacing: 14) {
                    ForEach(TimerTheme.allCases) { theme in
                        colorSwatch(theme)
                    }
                }
            }
        }
    }

    // 1色分のスウォッチ
    private func colorSwatch(_ theme: TimerTheme) -> some View {
        Button {
            if theme.isPro && !PremiumManager.shared.isUnlocked(.timerProThemes) {
                showPaywall = true
            } else {
                timerThemeRaw = theme.rawValue
            }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(theme.color)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle().strokeBorder(
                                isSelected(theme) ? Color.orange : Color.appBorder,
                                lineWidth: isSelected(theme) ? 3 : 1
                            )
                        )

                    // 未解放のPro限定色なら鍵バッジ
                    if theme.isPro && !PremiumManager.shared.isUnlocked(.timerProThemes) {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.appTextPrimary)
                            .padding(5)
                            .background(Circle().fill(Color.black.opacity(0.65)))
                    }
                }

                Text(theme.displayName)
                    .font(.caption2)
                    .foregroundColor(.appTextPrimary)
            }
        }
    }

    private func isSelected(_ theme: TimerTheme) -> Bool {
        timerThemeRaw == theme.rawValue
    }

    private var selectedAppearanceMode: AppearanceMode {
        AppearanceMode(rawValue: themeMode) ?? .system
    }
}
