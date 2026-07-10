//
//  DailyReminder.swift
//  MuscleApp
//
//  毎日決まった時刻に届くリマインダー通知。
//  ストリーク（連続日数）を文面に反映するため、14日分の個別通知を
//  ランダムなメッセージでスケジュールする方式を採用している。
//  （iOSのUNCalendarNotificationTriggerは内容を毎日変えられないため）
//

import Foundation
import UserNotifications

final class DailyReminder {
    static let shared = DailyReminder()
    private init() {}

    /// リマインダーのデフォルト時刻（19時）
    static let defaultHour = 19

    private let identifierPrefix = "muscleapp_daily_reminder_"
    // 先読みでスケジュールしておく日数（アプリ起動時などに再スケジュールする想定）
    private let lookaheadDays = 14

    // ストリーク情報を反映した文面で、今後14日分のリマインダーをスケジュール
    func schedule(hour: Int, minute: Int = 0, currentStreak: Int = 0) {
        cancel()

        let calendar = Calendar.current
        for dayOffset in 0..<lookaheadDays {
            guard let baseDate = calendar.date(byAdding: .day, value: dayOffset, to: Date()) else { continue }

            var components = calendar.dateComponents([.year, .month, .day], from: baseDate)
            components.hour = hour
            components.minute = minute

            guard let triggerDate = calendar.date(from: components), triggerDate > Date() else { continue }

            // 日ごとにランダムにメッセージを選択。
            // 2日以上先はストリークが途切れている前提で汎用文面にする
            // （トレーニングされるたびに全体が再スケジュールされるので、この予測は必ず当たる）
            let projectedStreak = dayOffset <= 1 ? currentStreak : 0
            let message = DailyReminderMessageBank.randomMessage(currentStreak: projectedStreak)

            let content = UNMutableNotificationContent()
            content.title = message.title
            content.body = message.body
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: "\(identifierPrefix)\(dayOffset)",
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request)
        }
    }

    // 予約中のリマインダーを全部キャンセル
    func cancel() {
        let ids = (0..<lookaheadDays).map { "\(identifierPrefix)\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }
}
