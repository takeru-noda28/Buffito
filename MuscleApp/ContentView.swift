//
//  ContentView.swift
//  MuscleApp
//
//  Created by 野田武流 on 2026/05/18.
//

import SwiftUI
import SwiftData

private enum LaunchExperienceStorage {
    static let onboardingCompletedKey = "has_completed_onboarding"
    static let lastSeenUpdateVersionKey = "last_seen_whats_new_version"
    static let currentUpdateVersion = "1.2"
}

// アプリのルートView。タブバーを管理する
struct ContentView: View {
    let presentsLaunchExperience: Bool

    // タブの並び順（Buffito＝AIチャットを中央に配置）
    private enum Tab {
        case home, analytics, buffito, timer, calendar
    }

    @State private var selectedTab: Tab = .home
    @State private var homeId = UUID()
    @State private var analyticsId = UUID()
    @State private var buffitoId = UUID()
    @State private var calendarId = UUID()
    @State private var showOnboarding: Bool = false
    @State private var showWhatsNew: Bool = false
    @State private var hasEvaluatedLaunchExperience: Bool = false

    @AppStorage(LaunchExperienceStorage.onboardingCompletedKey)
    private var hasCompletedOnboarding: Bool = false
    @AppStorage(LaunchExperienceStorage.lastSeenUpdateVersionKey)
    private var lastSeenUpdateVersion: String = ""

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext

    init(presentsLaunchExperience: Bool = true) {
        self.presentsLaunchExperience = presentsLaunchExperience
    }

    // 同じタブを再タップしたら .id を変えてルートに戻す
    private var tabBinding: Binding<Tab> {
        Binding(
            get: { selectedTab },
            set: { newValue in
                if newValue == selectedTab {
                    switch newValue {
                    case .home: homeId = UUID()
                    case .analytics: analyticsId = UUID()
                    case .buffito: buffitoId = UUID()
                    case .calendar: calendarId = UUID()
                    default: break
                    }
                }
                selectedTab = newValue
            }
        )
    }

    var body: some View {
        TabView(selection: tabBinding) {
            HomeView()
                .id(homeId)
                .tabItem {
                    Label("ホーム", systemImage: "house.fill")
                }
                .tag(Tab.home)

            AnalyticsView()
                .id(analyticsId)
                .tabItem {
                    Label("分析", systemImage: "chart.bar.fill")
                }
                .tag(Tab.analytics)

            BuffitoHomeView(onOpenAnalytics: { selectedTab = .analytics })
                .id(buffitoId)
                .tabItem {
                    Label("Buffito", systemImage: "cat.fill")
                }
                .tag(Tab.buffito)

            TimerView()
                .tabItem {
                    Label("タイマー", systemImage: "timer")
                }
                .tag(Tab.timer)

            CalendarView()
                .id(calendarId)
                .tabItem {
                    Label("カレンダー", systemImage: "calendar")
                }
                .tag(Tab.calendar)
        }
        .tint(selectedTabColor)
        .onAppear {
            refreshOnForeground()
            presentOnboardingIfNeeded()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                refreshOnForeground()
            }
        }
        .fullScreenCover(isPresented: $showOnboarding, onDismiss: {
            presentWhatsNewIfNeeded()
        }) {
            OnboardingView {
                completeOnboarding()
            }
        }
        .sheet(isPresented: $showWhatsNew) {
            WhatsNewSheet()
        }
    }

    private func presentOnboardingIfNeeded() {
        guard presentsLaunchExperience,
              !hasEvaluatedLaunchExperience else { return }

        if hasCompletedOnboarding {
            hasEvaluatedLaunchExperience = true
            presentWhatsNewIfNeeded()
            return
        }

        guard let hasExistingRecord = hasExistingWorkoutRecord() else { return }
        hasEvaluatedLaunchExperience = true

        if hasExistingRecord {
            hasCompletedOnboarding = true
            presentWhatsNewIfNeeded()
        } else {
            showOnboarding = true
        }
    }

    private func presentWhatsNewIfNeeded() {
        guard presentsLaunchExperience,
              lastSeenUpdateVersion != LaunchExperienceStorage.currentUpdateVersion else { return }
        // 表示中にアプリを終了しても次回起動で重複表示しないよう、表示開始時に既読化する
        lastSeenUpdateVersion = LaunchExperienceStorage.currentUpdateVersion
        showWhatsNew = true
    }

    // 新規ユーザーはオンボーディング完了時点で同バージョンの更新案内も既読にする
    private func completeOnboarding() {
        hasCompletedOnboarding = true
        lastSeenUpdateVersion = LaunchExperienceStorage.currentUpdateVersion
    }

    // 新設したオンボーディングキーを持たなくても、記録があれば既存ユーザーと判定する
    private func hasExistingWorkoutRecord() -> Bool? {
        var descriptor = FetchDescriptor<WorkoutSet>()
        descriptor.fetchLimit = 1
        guard let existingSets = modelContext.fetchOrLog(
            descriptor,
            operation: "起動体験の既存記録確認"
        ) else {
            return nil
        }
        return !existingSets.isEmpty
    }

    // アプリ起動/前面復帰時の同期処理。
    // リマインダー文面とホーム画面ウィジェットが古いストリーク/ムードのままにならないようにする
    private func refreshOnForeground() {
        guard let currentStreak = BuffitoWidgetSynchronizer.synchronize(
            using: modelContext,
            operation: "前面復帰時"
        ) else { return }
        rescheduleDailyReminderIfEnabled(currentStreak: currentStreak)
    }

    // 毎日リマインダーが有効なら、最新ストリークで再スケジュール
    private func rescheduleDailyReminderIfEnabled(currentStreak: Int) {
        guard UserDefaults.standard.bool(forKey: "daily_reminder_enabled") else { return }
        let stored = UserDefaults.standard.integer(forKey: "daily_reminder_hour")
        let hour = stored > 0 ? stored : DailyReminder.defaultHour

        DailyReminder.shared.schedule(hour: hour, currentStreak: currentStreak)
    }

    // 選択中のタブに応じてアイコンの色を変える
    private var selectedTabColor: Color {
        switch selectedTab {
        case .home: return .blue
        case .analytics: return .green
        case .buffito: return .orange
        case .timer: return .red
        case .calendar: return .orange
        }
    }
}

#Preview {
    ContentView(presentsLaunchExperience: false)
        .modelContainer(for: [Exercise.self, WorkoutSet.self, AIMessage.self], inMemory: true)
}
