//
//  SettingsView.swift
//  MuscleApp
//

import SwiftUI
import SwiftData

// 設定画面（Pro / 通知 / テーマ / サポート / その他）
struct SettingsView: View {
    let onClose: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var aiMessages: [AIMessage]

    @State private var premiumState: Bool = PremiumManager.shared.isPremium
    @State private var showPaywall: Bool = false
    @State private var showDeleteChatConfirm: Bool = false
    @AppStorage("ai_consent_given") private var aiConsentGiven: Bool = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Pro導線は販売開始（StoreKit導入）までまとめて非表示
                        if PremiumManager.isSalesEnabled {
                            proSection
                        }
                        aiSection
                        notificationSection
                        themeSection
                        supportSection
                        otherSection
                        if PremiumManager.isSalesEnabled {
                            testSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        onClose()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.appTextPrimary)
                    }
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallSheet()
        }
    }

    // MARK: - 各セクション

    // Pro機能：タップでPaywallSheetを開くボタン1つだけのシンプル構成
    private var proSection: some View {
        SettingCard(title: "Pro機能") {
            Button {
                showPaywall = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(premiumState ? "Pro加入中" : "Buffito Pro")
                            .font(.subheadline.bold())
                            .foregroundColor(.appTextPrimary)
                        Text(premiumState ? "全機能が利用可能" : "サブスクリプションを管理")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .contentShape(Rectangle())
            }
        }
    }

    private var notificationSection: some View {
        SettingCard(title: "通知") {
            NavigationLink {
                NotificationSettingsView()
            } label: {
                settingsLinkRow(icon: "bell.badge.fill", iconColor: .orange, title: "通知設定")
            }
        }
    }

    private var aiSection: some View {
        SettingCard(title: "AI機能") {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AI利用の同意")
                            .foregroundColor(.appTextPrimary)
                        Text(aiConsentGiven ? "同意済み" : "未同意")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    if aiConsentGiven {
                        Button("取り消す") {
                            aiConsentGiven = false
                        }
                        .font(.subheadline)
                        .foregroundColor(.orange)
                    }
                }
                .padding(.vertical, 12)

                Divider().background(Color.gray.opacity(0.2))

                deleteChatHistoryRow
            }
        }
    }

    // AIチャット履歴の削除（履歴が空のときは無効化して件数で状態を示す）
    private var deleteChatHistoryRow: some View {
        Button {
            showDeleteChatConfirm = true
        } label: {
            HStack {
                Image(systemName: "trash.fill")
                    .foregroundColor(aiMessages.isEmpty ? .gray : .red)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text("チャット履歴を削除")
                        .foregroundColor(aiMessages.isEmpty ? .gray : .appTextPrimary)
                    Text(aiMessages.isEmpty ? "履歴はありません" : "\(aiMessages.count)件のメッセージ")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            .padding(.vertical, 12)
        }
        .disabled(aiMessages.isEmpty)
        .confirmationDialog(
            "チャット履歴を削除しますか？",
            isPresented: $showDeleteChatConfirm,
            titleVisibility: .visible
        ) {
            Button("\(aiMessages.count)件のメッセージを削除", role: .destructive) {
                modelContext.deleteAllOrLog(AIMessage.self, operation: "AIチャット履歴の削除")
            }
        } message: {
            Text("この操作は取り消せません。履歴は端末内にのみ保存されています。")
        }
    }

    private var themeSection: some View {
        SettingCard(title: "外観") {
            NavigationLink {
                ThemeSettingsView()
            } label: {
                settingsLinkRow(icon: "paintbrush.fill", iconColor: .purple, title: "テーマ")
            }
        }
    }

    private var supportSection: some View {
        SettingCard(title: "サポート") {
            VStack(spacing: 0) {
                NavigationLink {
                    AnnouncementsView()
                } label: {
                    settingsLinkRow(icon: "megaphone.fill", iconColor: .blue, title: "お知らせ")
                }
                Divider().background(Color.gray.opacity(0.2))
                NavigationLink {
                    HowToUseView()
                } label: {
                    settingsLinkRow(icon: "questionmark.circle.fill", iconColor: .green, title: "使い方")
                }
                Divider().background(Color.gray.opacity(0.2))
                NavigationLink {
                    ContactFormView()
                } label: {
                    settingsLinkRow(icon: "envelope.fill", iconColor: .cyan, title: "お問い合わせ")
                }
            }
        }
    }

    private var otherSection: some View {
        SettingCard(title: "その他") {
            VStack(spacing: 0) {
                NavigationLink {
                    TermsOfUseView()
                } label: {
                    settingsLinkRow(icon: "doc.text.fill", iconColor: .gray, title: "利用規約")
                }
                Divider().background(Color.gray.opacity(0.2))
                NavigationLink {
                    PrivacyPolicyView()
                } label: {
                    settingsLinkRow(icon: "lock.shield.fill", iconColor: .gray, title: "プライバシーポリシー")
                }
                Divider().background(Color.gray.opacity(0.2))
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.gray)
                        .frame(width: 24)
                    Text("バージョン")
                        .foregroundColor(.appTextPrimary)
                    Spacer()
                    Text(appVersion)
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }
                .padding(.vertical, 12)
            }
        }
    }

    // テスト用：Pro加入状態の切替（本番では削除）
    private var testSection: some View {
        SettingCard(title: "テスト用設定") {
            Toggle(isOn: $premiumState) {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                    Text("Pro会員（テスト切替）")
                        .foregroundColor(.appTextPrimary)
                }
            }
            .onChange(of: premiumState) { _, new in
                PremiumManager.shared.isPremium = new
            }
        }
    }

    // 共通：遷移リンク1行
    private func settingsLinkRow(icon: String, iconColor: Color = .gray, title: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)
            Text(title)
                .foregroundColor(.appTextPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

// 設定の1セクション（タイトル + 中身）
struct SettingCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            content
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.appCard)
                )
        }
    }
}
