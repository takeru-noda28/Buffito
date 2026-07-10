//
//  NotificationSettingsView.swift
//  MuscleApp
//
//  通知に関する設定をまとめた詳細ページ。
//  - iOS全体の通知許可状態の表示
//  - 毎日のリマインダー
//  - ジムに行ってない通知（モチベ通知）
//

import SwiftUI
import SwiftData
import UserNotifications
import UIKit

struct NotificationSettingsView: View {
    // 毎日のリマインダー設定
    @AppStorage("daily_reminder_enabled") private var dailyReminderEnabled: Bool = false
    @AppStorage("daily_reminder_hour") private var dailyReminderHour: Int = DailyReminder.defaultHour

    // Buffito通知設定（defaultをtrueにするため初期値は明示しない＋onAppearで補完）
    @AppStorage("buffito_emotion_enabled") private var buffitoEmotionEnabled: Bool = true
    @AppStorage("buffito_streak_enabled") private var buffitoStreakEnabled: Bool = true
    @AppStorage("buffito_part_challenge_enabled") private var buffitoPartChallengeEnabled: Bool = true
    @AppStorage("buffito_emotion_hour") private var buffitoEmotionHour: Int = BuffitoNotifier.defaultEmotionHour

    // iOSの通知許可状態
    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined

    // ストリーク計算用にModelContext
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    permissionSection
                    buffitoSection
                    dailyReminderSection
                }
                .padding()
            }
        }
        .navigationTitle("通知設定")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            refreshAuthorizationStatus()
        }
    }

    // MARK: - セクション

    // iOSの通知許可状態を表示するセクション
    private var permissionSection: some View {
        SettingCard(title: "アプリの通知") {
            HStack {
                Image(systemName: permissionIcon)
                    .foregroundColor(permissionColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(permissionTitle)
                        .foregroundColor(.appTextPrimary)
                        .font(.subheadline)
                    Text(permissionSubtitle)
                        .foregroundColor(.gray)
                        .font(.caption)
                }
                Spacer()
                if authorizationStatus != .authorized {
                    Button("設定") {
                        openSystemSettings()
                    }
                    .foregroundColor(.blue)
                    .font(.subheadline.bold())
                }
            }
        }
    }

    // Buffitoの感情通知
    private var buffitoSection: some View {
        SettingCard(title: "Buffitoとの会話 🔥") {
            VStack(spacing: 12) {
                Toggle(isOn: $buffitoStreakEnabled) {
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("連続記録の祝福")
                            .foregroundColor(.appTextPrimary)
                    }
                }

                Divider().background(Color.gray.opacity(0.3))

                Toggle(isOn: $buffitoPartChallengeEnabled) {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.heart.fill")
                            .foregroundColor(.red)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("PRチャレンジ通知")
                                .foregroundColor(.appTextPrimary)
                            Text("部位を休んでいる時に過去PRで挑発")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }

                Divider().background(Color.gray.opacity(0.3))

                Toggle(isOn: $buffitoEmotionEnabled) {
                    HStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.pink)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("寂しがるBuffito")
                                .foregroundColor(.appTextPrimary)
                            Text("ジムから遠ざかると段階的に通知")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .onChange(of: buffitoEmotionEnabled) { _, enabled in
                    if enabled {
                        requestPermissionIfNeeded()
                    } else {
                        BuffitoNotifier.shared.cancelAbsenceNotifications()
                    }
                }

                if buffitoEmotionEnabled {
                    Divider().background(Color.gray.opacity(0.3))
                    Stepper(value: $buffitoEmotionHour, in: 0...23) {
                        HStack {
                            Text("通知時刻")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                            Spacer()
                            Text(String(format: "%02d:00", buffitoEmotionHour))
                                .foregroundColor(.appTextPrimary)
                        }
                    }
                }
            }
        }
    }

    // 毎日のリマインダー
    private var dailyReminderSection: some View {
        SettingCard(title: "毎日のリマインダー") {
            VStack(spacing: 12) {
                Toggle(isOn: $dailyReminderEnabled) {
                    HStack(spacing: 8) {
                        Image(systemName: "alarm.fill")
                            .foregroundColor(.yellow)
                        Text("毎日通知する")
                            .foregroundColor(.appTextPrimary)
                    }
                }
                .onChange(of: dailyReminderEnabled) { _, enabled in
                    if enabled {
                        requestPermissionIfNeeded()
                        rescheduleDailyReminder()
                    } else {
                        DailyReminder.shared.cancel()
                    }
                }

                if dailyReminderEnabled {
                    Divider().background(Color.gray.opacity(0.3))
                    Stepper(value: $dailyReminderHour, in: 0...23) {
                        HStack {
                            Text("通知時刻")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                            Spacer()
                            Text(String(format: "%02d:00", dailyReminderHour))
                                .foregroundColor(.appTextPrimary)
                        }
                    }
                    .onChange(of: dailyReminderHour) { _, _ in
                        // 時刻を変更したら即時に再スケジュール（ストリーク反映）
                        rescheduleDailyReminder()
                    }
                }
            }
        }
    }

    // 毎日リマインダーを最新のストリークで再スケジュール
    private func rescheduleDailyReminder() {
        let streak = currentStreak()
        DailyReminder.shared.schedule(hour: dailyReminderHour, currentStreak: streak)
    }

    // SwiftDataから全セットを取得して、現在の連続日数を計算
    private func currentStreak() -> Int {
        let descriptor = FetchDescriptor<WorkoutSet>()
        guard let sets = modelContext.fetchOrLog(descriptor, operation: "ストリーク計算用の全セット取得") else { return 0 }
        return StreakTracker.calculate(sets: sets).current
    }

    // MARK: - 通知許可状態の表示用ヘルパー

    private var permissionIcon: String {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral: return "checkmark.circle.fill"
        case .denied: return "xmark.octagon.fill"
        default: return "questionmark.circle.fill"
        }
    }

    private var permissionColor: Color {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral: return .green
        case .denied: return .red
        default: return .gray
        }
    }

    private var permissionTitle: String {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral: return "通知は許可されています"
        case .denied: return "通知が許可されていません"
        default: return "まだ通知を許可していません"
        }
    }

    private var permissionSubtitle: String {
        switch authorizationStatus {
        case .denied: return "iOSの設定アプリで許可してください"
        case .notDetermined: return "通知を有効にすると初回ダイアログが出ます"
        default: return "全ての通知機能が利用可能です"
        }
    }

    // MARK: - 処理

    private func refreshAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                authorizationStatus = settings.authorizationStatus
            }
        }
    }

    private func requestPermissionIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                // 通知許可がOnになったら「ジムに行ってない通知」も自動的に有効化（UIには出さない）
                if granted {
                    UserDefaults.standard.set(true, forKey: "motivation_enabled")
                }
                refreshAuthorizationStatus()
            }
        }
    }

    // iOSの設定アプリを開く（通知許可の変更用）
    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
