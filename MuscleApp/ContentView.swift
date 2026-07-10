//
//  ContentView.swift
//  MuscleApp
//
//  Created by 野田武流 on 2026/05/18.
//

import SwiftUI
import SwiftData

// アプリのルートView。タブバーを管理する
struct ContentView: View {
    // タブの並び順（Buffito＝AIチャットを中央に配置）
    private enum Tab {
        case home, analytics, buffito, timer, calendar
    }

    @State private var selectedTab: Tab = .home
    @State private var homeId = UUID()
    @State private var analyticsId = UUID()
    @State private var buffitoId = UUID()
    @State private var calendarId = UUID()

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext

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
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                refreshOnForeground()
            }
        }
    }

    // アプリ起動/前面復帰時の同期処理。
    // リマインダー文面とホーム画面ウィジェットが古いストリーク/ムードのままにならないようにする
    private func refreshOnForeground() {
        let descriptor = FetchDescriptor<WorkoutSet>()
        guard let allSets = modelContext.fetchOrLog(descriptor, operation: "前面復帰時の全セット取得") else { return }
        let currentStreak = StreakTracker.calculate(sets: allSets).current

        BuffitoWidgetBridge.update(
            trainingDays: BuffitoMoodMeter.trainingDays(from: allSets),
            currentStreak: currentStreak
        )
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
    ContentView()
        .modelContainer(for: [Exercise.self, WorkoutSet.self, AIMessage.self], inMemory: true)
}
