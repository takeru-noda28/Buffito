//
//  MuscleAppApp.swift
//  MuscleApp
//
//  Created by 野田武流 on 2026/05/18.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct MuscleAppApp: App {
    @AppStorage(AppearanceMode.storageKey)
    private var themeMode: String = AppearanceMode.defaultValue.rawValue

    init() {
        // フォアグラウンドでも通知を表示するデリゲートを設定
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    private var appearanceMode: AppearanceMode {
        AppearanceMode(rawValue: themeMode) ?? .system
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(appearanceMode.colorScheme)
        }
        .modelContainer(for: [Exercise.self, WorkoutSet.self, AIMessage.self])
    }
}
