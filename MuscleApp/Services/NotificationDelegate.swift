//
//  NotificationDelegate.swift
//  MuscleApp
//
//  アプリ起動中（フォアグラウンド）でも通知バナーを表示するためのデリゲート。
//  テスト時にアプリを閉じなくても通知が確認できる。
//

import Foundation
import UserNotifications

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    private override init() {}

    // フォアグラウンドでも通知バナーと音を表示
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge, .list])
    }
}
