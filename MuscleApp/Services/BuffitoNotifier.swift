//
//  BuffitoNotifier.swift
//  MuscleApp
//
//  Buffitoの感情通知を一括管理する。
//  - 連続記録達成 → 即時のお祝い通知
//  - 自己ベスト更新 → 即時のお祝い通知
//  - 不在日数に応じた段階的な催促 → スケジュール通知
//

import Foundation
import UserNotifications

final class BuffitoNotifier {
    static let shared = BuffitoNotifier()
    private init() {}

    // 通知識別子のプレフィックス
    private let absencePrefix = "buffito_absence_"
    private let celebrationPrefix = "buffito_celebrate_"
    private let partChallengePrefix = "buffito_partchallenge_"

    // 不在通知を出す日数（最後のトレ日から N日後）
    private let absenceDayOffsets = [2, 3, 5, 7, 10, 14]

    // 連続記録のマイルストーン
    private let streakMilestones = [3, 7, 14, 30]

    // 部位ごとの「サボってない？」チャレンジ通知を出す日数（最後にその部位を鍛えてから N日後）
    private let partChallengeDays = 3

    // ユーザー設定キー（UserDefaults）
    private enum Keys {
        static let emotionEnabled = "buffito_emotion_enabled"
        static let streakEnabled = "buffito_streak_enabled"
        static let prEnabled = "buffito_pr_enabled"
        static let partChallengeEnabled = "buffito_part_challenge_enabled"
        static let emotionHour = "buffito_emotion_hour"
        static let lastStreakMilestone = "buffito_last_streak_milestone"
    }

    // MARK: - 公開API

    // セット追加時のフック：不在通知のリセット + 新規スケジュール
    // ムードは記録から決定的に計算できるため、「このまま休み続けたらN日後にどのムードか」を
    // 予測して文面を選ぶ（トレされたら全キャンセル→再スケジュールなので予測は必ず当たる）
    func rescheduleAfterWorkout(lastWorkoutDate: Date, allSets: [WorkoutSet]) {
        cancelAbsenceNotifications()
        guard isEmotionEnabled else { return }

        let hour = emotionHour
        let calendar = Calendar.current
        for offset in absenceDayOffsets {
            guard let triggerDay = calendar.date(byAdding: .day, value: offset, to: lastWorkoutDate) else { continue }
            let projectedMood = BuffitoMoodMeter.currentMood(allSets: allSets, referenceDate: triggerDay)
            let message = BuffitoMessageBank.absenceNudge(days: offset, mood: projectedMood)
            scheduleCalendarNotification(
                identifier: "\(absencePrefix)\(offset)",
                from: lastWorkoutDate,
                daysOffset: offset,
                hour: hour,
                message: message
            )
        }
    }

    // 連続記録のマイルストーン達成を祝う
    func celebrateStreakIfMilestone(currentStreak: Int) {
        guard isStreakEnabled else { return }

        let lastNotified = UserDefaults.standard.integer(forKey: Keys.lastStreakMilestone)

        // 連続が途切れて再開した場合は記録をリセット
        if currentStreak < lastNotified {
            UserDefaults.standard.set(0, forKey: Keys.lastStreakMilestone)
        }

        // 達成済みの最大マイルストーン
        guard let achieved = streakMilestones.filter({ $0 <= currentStreak }).max(),
              achieved > UserDefaults.standard.integer(forKey: Keys.lastStreakMilestone) else {
            return
        }

        let message = BuffitoMessageBank.streakCelebration(days: achieved)
        scheduleImmediateNotification(
            identifier: "\(celebrationPrefix)streak_\(achieved)",
            message: message
        )
        UserDefaults.standard.set(achieved, forKey: Keys.lastStreakMilestone)
    }

    // 自己ベスト更新を祝う
    func celebratePR(exerciseName: String, weight: Double, reps: Int) {
        guard isPREnabled else { return }
        let message = BuffitoMessageBank.prCelebration(
            exerciseName: exerciseName, weight: weight, reps: reps
        )
        scheduleImmediateNotification(
            identifier: "\(celebrationPrefix)pr_\(UUID().uuidString)",
            message: message
        )
    }

    func cancelAbsenceNotifications() {
        let ids = absenceDayOffsets.map { "\(absencePrefix)\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    // 部位ごとのPRチャレンジ通知をスケジュール
    // 各部位について「最後のトレから N日後」に、その部位のPRを引き合いに出して挑発
    func schedulePartChallenges(allSets: [WorkoutSet]) {
        cancelPartChallenges()
        guard isPartChallengeEnabled else { return }

        let calendar = Calendar.current
        // 部位ごとにグループ化
        let groupedByPart: [BodyPart: [WorkoutSet]] = Dictionary(grouping: allSets) {
            $0.exercise?.bodyPart ?? .other
        }

        for (part, sets) in groupedByPart {
            // 最後にこの部位を鍛えた日
            guard let lastDate = sets.map(\.date).max() else { continue }

            // この部位のPR（重量×回数が最大のセット）
            guard let prSet = sets.max(by: { score($0) < score($1) }),
                  let prExercise = prSet.exercise,
                  prSet.weight > 0, prSet.reps > 0 else { continue }

            let message = BuffitoMessageBank.partAbsenceChallenge(
                bodyPart: part,
                exerciseName: prExercise.name,
                weight: prSet.weight,
                reps: prSet.reps,
                days: partChallengeDays
            )

            scheduleCalendarNotification(
                identifier: "\(partChallengePrefix)\(part.rawValue)",
                from: calendar.startOfDay(for: lastDate),
                daysOffset: partChallengeDays,
                hour: emotionHour,
                message: message
            )
        }
    }

    func cancelPartChallenges() {
        let ids = BodyPart.allCases.map { "\(partChallengePrefix)\($0.rawValue)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    // セットのスコア（重量 × 回数）
    private func score(_ set: WorkoutSet) -> Double {
        set.weight * Double(set.reps)
    }

    // MARK: - 設定アクセサ（デフォルトを与えるためのラッパー）

    var isEmotionEnabled: Bool {
        UserDefaults.standard.object(forKey: Keys.emotionEnabled) as? Bool ?? true
    }
    var isStreakEnabled: Bool {
        UserDefaults.standard.object(forKey: Keys.streakEnabled) as? Bool ?? true
    }
    var isPREnabled: Bool {
        UserDefaults.standard.object(forKey: Keys.prEnabled) as? Bool ?? true
    }
    var isPartChallengeEnabled: Bool {
        UserDefaults.standard.object(forKey: Keys.partChallengeEnabled) as? Bool ?? true
    }
    /// 感情通知のデフォルト時刻（19時）
    static let defaultEmotionHour = 19

    var emotionHour: Int {
        let stored = UserDefaults.standard.integer(forKey: Keys.emotionHour)
        return stored > 0 ? stored : Self.defaultEmotionHour
    }

    // MARK: - 内部処理

    // 指定日数後の特定時刻にカレンダー型通知をスケジュール
    private func scheduleCalendarNotification(
        identifier: String,
        from baseDate: Date,
        daysOffset: Int,
        hour: Int,
        message: BuffitoMessage
    ) {
        let calendar = Calendar.current
        guard let triggerDay = calendar.date(byAdding: .day, value: daysOffset, to: baseDate) else { return }

        var components = calendar.dateComponents([.year, .month, .day], from: triggerDay)
        components.hour = hour
        components.minute = 0

        guard let date = calendar.date(from: components), date > Date() else { return }

        let request = makeRequest(identifier: identifier, message: message,
                                  trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false))
        UNUserNotificationCenter.current().add(request)
    }

    // 即時通知（1秒後に発火）
    private func scheduleImmediateNotification(identifier: String, message: BuffitoMessage) {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = makeRequest(identifier: identifier, message: message, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // 通知リクエストを組み立てる共通処理
    private func makeRequest(identifier: String, message: BuffitoMessage, trigger: UNNotificationTrigger) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = message.title
        content.body = message.body
        content.sound = .default
        return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }
}
