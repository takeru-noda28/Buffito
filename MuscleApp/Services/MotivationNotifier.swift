//
//  MotivationNotifier.swift
//  MuscleApp
//

import Foundation
import UserNotifications

// モチベーション通知を管理（◯日ジムに行ってないと通知）
final class MotivationNotifier {
    static let shared = MotivationNotifier()
    private init() {}

    private let identifier = "muscleapp_motivation"

    // 直近のトレーニング日から N日後の指定時刻に通知をスケジュール
    func scheduleIfNeeded(lastWorkoutDate: Date?, daysThreshold: Int, hour: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        guard let lastDate = lastWorkoutDate else { return }
        guard let triggerDay = Calendar.current.date(byAdding: .day, value: daysThreshold, to: lastDate) else { return }

        var components = Calendar.current.dateComponents([.year, .month, .day], from: triggerDay)
        components.hour = hour
        components.minute = 0

        // 過去の日時にはスケジュールできない
        guard let triggerDate = Calendar.current.date(from: components), triggerDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "💪 トレーニングしよう"
        content.body = "前回のトレーニングから\(daysThreshold)日経ちました！今日こそ頑張りましょう"
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }

    func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
