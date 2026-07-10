//
//  ExerciseDetailView.swift
//  MuscleApp
//

import SwiftUI
import SwiftData
import UIKit

// 種目の記録画面（重量・回数を入力してセットを保存）
struct ExerciseDetailView: View {
    let exercise: Exercise
    var backLabel: String = "戻る"
    var targetDate: Date? = nil  // nil = 今日として記録 / それ以外 = 指定日に記録

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // この種目のすべてのセット（新しい順）
    @Query private var allSets: [WorkoutSet]

    // 入力中の重量・回数
    @State private var weightInput: Double = 0.0
    @State private var repsInput: Int = 0

    // PR達成時のポップアップ表示（B-3：通知の代わりにアプリ内アニメーション）
    @State private var prBanner: PRBannerData? = nil

    // レスト中のアラーム再生器・アラート表示中フラグ
    @State private var restAlarmPlayer = AlarmPlayer()
    @State private var isRestAlerting: Bool = false
    @State private var now: Date = Date()

    // デフォルトのレスト秒数（後でユーザー設定化）
    @AppStorage("default_rest_seconds") private var defaultRestSeconds: Int = 90

    // ペイウォール表示用
    @State private var showPaywall: Bool = false

    // レスト編集シート表示用
    @State private var showRestEditSheet: Bool = false

    // レスト記録・編集が解放されているか
    private var isRestUnlocked: Bool { PremiumManager.shared.isUnlocked(.restTracking) }
    // 共有レストセッション
    private var restSession: RestSession { RestSession.shared }

    // 0.5秒ごとに発火する表示更新タイマー
    private let tick = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    // レスト残り秒数（このViewが管理中のもののみ）
    private var restRemainingSeconds: Int? {
        // 別の種目でレスト中の場合は表示しない（その種目のExerciseDetailViewで表示される）
        guard restSession.isActive,
              let restingExerciseName = restSession.exerciseName,
              restingExerciseName == exercise.name else { return nil }
        return restSession.remainingSeconds(now: now)
    }

    init(exercise: Exercise, backLabel: String = "戻る", targetDate: Date? = nil) {
        self.exercise = exercise
        self.backLabel = backLabel
        self.targetDate = targetDate
        let exerciseId = exercise.persistentModelID
        _allSets = Query(
            filter: #Predicate<WorkoutSet> { $0.exercise?.persistentModelID == exerciseId },
            sort: [SortDescriptor(\.date, order: .reverse)]
        )
    }

    // 表示・記録対象の日（指定がなければ今日）
    private var referenceDate: Date { targetDate ?? Date() }

    // 対象日のセット（古い順）
    private var todaySets: [WorkoutSet] {
        allSets.filter { Calendar.current.isDate($0.date, inSameDayAs: referenceDate) }
            .sorted { $0.date < $1.date }
    }

    // 直近の過去ワークアウト（対象日より前で最新の日）
    private var previousSets: [WorkoutSet] {
        let startOfReference = Calendar.current.startOfDay(for: referenceDate)
        let past = allSets.filter { $0.date < startOfReference }
        guard let mostRecent = past.first else { return [] }
        let mostRecentDay = Calendar.current.startOfDay(for: mostRecent.date)
        return past.filter { Calendar.current.startOfDay(for: $0.date) == mostRecentDay }
            .sorted { $0.date < $1.date }
    }

    // 新規セットに使う日時：対象日の現在時刻（過去日の場合）/ 現在（今日の場合）
    private var newRecordDate: Date {
        guard let targetDate = targetDate,
              !Calendar.current.isDateInToday(targetDate) else { return Date() }
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: targetDate)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: now)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        components.second = timeComponents.second
        return calendar.date(from: components) ?? targetDate
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            mainContent
            // PR達成時の祝福バナー（数秒後に自動消滅）
            if let banner = prBanner {
                PRCelebrationBanner(data: banner)
                    .padding(.bottom, 96)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1)
            }
        }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            // レスト中バナー（タイマー作動中のみ表示）
            if let remaining = restRemainingSeconds {
                RestBanner(
                    remainingSeconds: remaining,
                    isAlerting: isRestAlerting,
                    onStop: stopRest
                )
            }

            ScrollView {
                VStack(spacing: 24) {
                    GrowthSummaryCard(exercise: exercise)

                    NavigationLink {
                        ExerciseHistoryView(exercise: exercise)
                    } label: {
                        if !previousSets.isEmpty {
                            PreviousSetsCard(sets: previousSets, showsChevron: true)
                        } else {
                            EmptyHistoryLink()
                        }
                    }
                    .buttonStyle(.plain)

                    TodaySetsList(sets: todaySets, onDelete: deleteSet)
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)

            InputBar(
                weight: $weightInput,
                reps: $repsInput,
                isPremium: isRestUnlocked,
                onAddSet: addSet,
                onRestAction: onRestActionTap
            )
        }
        .background(Color.appBackground.ignoresSafeArea())
        .onReceive(tick) { date in
            now = date
            checkRestCompletion()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallSheet()
        }
        .sheet(isPresented: $showRestEditSheet) {
            RestEditSheet(exercise: exercise, sets: todaySets)
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.appTextPrimary)
                }
            }
        }
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            loadInputValues()
            registerWorkoutContextIfPossible()
        }
        .onChange(of: weightInput) { _, newValue in
            UserDefaults.standard.set(newValue, forKey: weightStorageKey)
        }
        .onChange(of: repsInput) { _, newValue in
            UserDefaults.standard.set(newValue, forKey: repsStorageKey)
        }
    }

    // 種目ごとの最後の入力値を永続化するキー
    private var weightStorageKey: String { "last_weight_input_\(exercise.name)" }
    private var repsStorageKey: String { "last_reps_input_\(exercise.name)" }

    // 入力値の初期化：
    // 1. 永続化された値があればそれを優先（前回ユーザーが入力した値）
    // 2. 過去のセット履歴があれば最後のセットの値
    // 3. なければ0
    private func loadInputValues() {
        if let savedWeight = UserDefaults.standard.object(forKey: weightStorageKey) as? Double {
            weightInput = savedWeight
        } else if let last = previousSets.last {
            weightInput = last.weight
        }
        if let savedReps = UserDefaults.standard.object(forKey: repsStorageKey) as? Int {
            repsInput = savedReps
        } else if let last = previousSets.last {
            repsInput = last.reps
        }
    }

    // 今日のセットが既にあれば WorkoutContext を更新（タイマー自動判定用）
    private func registerWorkoutContextIfPossible() {
        guard let lastTodaySet = todaySets.last else { return }
        WorkoutContext.shared.updateAfterAddingSet(
            exercise: exercise,
            setID: lastTodaySet.persistentModelID,
            setNumber: todaySets.count
        )
    }

    // 新しいセットを保存（WorkoutContext更新 + モチベ通知 + Buffito通知）
    private func addSet() {
        let setNumber = todaySets.count + 1
        let newSet = WorkoutSet(weight: weightInput, reps: repsInput, date: newRecordDate)
        newSet.exercise = exercise
        modelContext.insert(newSet)
        modelContext.saveOrLog("セット追加")  // persistentModelIDを確定させる

        WorkoutContext.shared.updateAfterAddingSet(
            exercise: exercise,
            setID: newSet.persistentModelID,
            setNumber: setNumber
        )

        triggerBuffitoNotifications(newSet: newSet)
    }

    // Buffitoの感情通知を発火（PRはアプリ内バナーに切替・ストリーク / 不在通知 / PRチャレンジ）
    private func triggerBuffitoNotifications(newSet: WorkoutSet) {
        // PR判定（1RM or 最大重量を更新したらアプリ内バナーで祝福）
        let pr = PRDetector.detect(newSet: newSet, history: allSets)
        if pr.isAny {
            showPRBanner(pr: pr, newSet: newSet)
        }

        // 全種目の全セットを1回だけフェッチして使い回す
        let descriptor = FetchDescriptor<WorkoutSet>()
        if let everySet = modelContext.fetchOrLog(descriptor, operation: "通知判定用の全セット取得") {
            // ストリーク達成判定
            let streak = StreakTracker.calculate(sets: everySet)
            BuffitoNotifier.shared.celebrateStreakIfMilestone(currentStreak: streak.current)
            // 部位ごとのPRチャレンジ通知をスケジュール
            BuffitoNotifier.shared.schedulePartChallenges(allSets: everySet)
            // 毎日リマインダーを最新ストリークで再スケジュール
            rescheduleDailyReminderIfEnabled(currentStreak: streak.current)

            let latestWorkoutDate = everySet.map(\.date).max() ?? newSet.date
            scheduleMotivationNotification(lastWorkoutDate: latestWorkoutDate)
            BuffitoNotifier.shared.rescheduleAfterWorkout(lastWorkoutDate: latestWorkoutDate, allSets: everySet)
            // ホーム画面ウィジェットを最新のムード・ストリークに更新
            BuffitoWidgetBridge.update(
                trainingDays: BuffitoMoodMeter.trainingDays(from: everySet),
                currentStreak: streak.current
            )
        } else {
            scheduleMotivationNotification(lastWorkoutDate: newSet.date)
            BuffitoNotifier.shared.rescheduleAfterWorkout(lastWorkoutDate: newSet.date, allSets: [newSet])
        }
    }

    // 「ジムに行ってない通知」の再スケジュール
    // 設定UIは廃止し、許可があれば常に動く方針
    private func scheduleMotivationNotification(lastWorkoutDate: Date) {
        let days = UserDefaults.standard.integer(forKey: "motivation_days")
        let hour = UserDefaults.standard.integer(forKey: "motivation_hour")
        MotivationNotifier.shared.scheduleIfNeeded(
            lastWorkoutDate: lastWorkoutDate,
            daysThreshold: days > 0 ? days : 3,
            hour: hour > 0 ? hour : 18
        )
    }

    // 毎日リマインダーが有効なら、最新のストリークで再スケジュール
    private func rescheduleDailyReminderIfEnabled(currentStreak: Int) {
        guard UserDefaults.standard.bool(forKey: "daily_reminder_enabled") else { return }
        let stored = UserDefaults.standard.integer(forKey: "daily_reminder_hour")
        let hour = stored > 0 ? stored : 19
        DailyReminder.shared.schedule(hour: hour, currentStreak: currentStreak)
    }

    // レスト編集ボタン（未解放→ペイウォール / 解放済み→編集シート）
    private func onRestActionTap() {
        if isRestUnlocked {
            showRestEditSheet = true
        } else {
            showPaywall = true
        }
    }

    // tickごとにレスト完了をチェック
    private func checkRestCompletion() {
        guard !isRestAlerting,
              restSession.isActive,
              let endDate = restSession.endDate,
              now >= endDate else { return }

        // 経過秒数をセットに保存
        saveRestSecondsToSet(elapsed: Int(endDate.timeIntervalSince(restSession.startDate ?? endDate)))

        isRestAlerting = true
        restAlarmPlayer.start()
    }

    // レストタイマー停止（手動 or アラーム停止）
    private func stopRest() {
        // まだ完了前で手動停止した場合も、経過秒数を保存
        if !isRestAlerting, let elapsed = restSession.elapsedSeconds {
            saveRestSecondsToSet(elapsed: elapsed)
        }
        restAlarmPlayer.stop()
        restSession.clear()
        isRestAlerting = false
    }

    // 経過秒数をRestSessionが指すセットに保存
    private func saveRestSecondsToSet(elapsed: Int) {
        guard let setID = restSession.setID,
              let set = allSets.first(where: { $0.persistentModelID == setID }) else { return }
        set.restSeconds = elapsed
        modelContext.saveOrLog("休憩秒数の記録")
    }

    // セットを削除
    // PR達成バナーを表示し、3秒後に自動で消す
    private func showPRBanner(pr: PRResult, newSet: WorkoutSet) {
        let data = PRBannerData(
            title: pr.isMaxWeightPR ? "最大重量更新！🏋️" : "推定1RM更新！🏆",
            subtitle: prSubtitle(pr: pr, newSet: newSet)
        )
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            prBanner = data
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeOut(duration: 0.4)) {
                prBanner = nil
            }
        }
    }

    private func prSubtitle(pr: PRResult, newSet: WorkoutSet) -> String {
        let weight = formatNumber(newSet.weight)
        if pr.isMaxWeightPR && pr.isOneRMPR {
            return "\(weight)kg × \(newSet.reps)回 (推定1RM \(formatNumber(pr.newOneRM))kg)"
        }
        if pr.isMaxWeightPR {
            return "\(weight)kg × \(newSet.reps)回"
        }
        return "推定1RM \(formatNumber(pr.newOneRM))kg"
    }

    private func formatNumber(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }

    private func deleteSet(_ set: WorkoutSet) {
        withAnimation(.easeInOut(duration: 0.25)) {
            modelContext.delete(set)
        }
        modelContext.saveOrLog("セット削除")
    }
}
