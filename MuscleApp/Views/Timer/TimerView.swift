//
//  TimerView.swift
//  MuscleApp
//

import SwiftUI
import SwiftData
import UserNotifications
import UIKit
import PhotosUI

// ローカル通知の識別子（キャンセル時に使う）
private let timerNotificationId: String = "muscleapp_timer_complete"

// タイマーの最大秒数（10分まで設定可能）
private let timerMaxSeconds: Int = 600

// レストタイマー画面
struct TimerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allSets: [WorkoutSet]

    // 初期設定の秒数（リセット時に戻す値）
    @State private var initialSeconds: Int = 60
    // 一時停止中の残り秒数（動作中はendDateから計算するため不要）
    @State private var pausedRemaining: Int = 60
    // 動作中の終了予定時刻（nilなら停止中）
    @State private var endDate: Date? = nil
    // 現在時刻（tickで更新→計算プロパティが再評価される）
    @State private var now: Date = Date()

    // ユーザーがカスタマイズ可能なプリセット（端末に保存）
    @AppStorage("timer_presets") private var presetsData: String = "30,60,120,180"

    // 編集中のプリセット位置（nilなら未編集）。新規追加時は presets.count を指定。
    @State private var editingIndex: Int? = nil

    // 通知（音・バイブ）を鳴らしているかどうか
    @State private var isAlerting: Bool = false

    // アラーム再生用の管理オブジェクト
    @State private var alarmPlayer = AlarmPlayer()

    // ペイウォール表示用
    @State private var showPaywall: Bool = false

    // タイマー中央画像（Pro機能）
    @State private var centerImage: UIImage? = nil
    @State private var pickerItem: PhotosPickerItem? = nil
    @State private var showImagePicker: Bool = false
    @State private var showImageMenu: Bool = false

    // アプリのライフサイクル監視
    @Environment(\.scenePhase) private var scenePhase

    // 0.25秒ごとに発火する表示更新タイマー
    private let tick = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()

    // タイマーが動作中か
    private var isRunning: Bool { endDate != nil }

    // 残り秒数（動作中はendDateから計算、停止中はpausedRemaining）
    private var remainingSeconds: Int {
        if let endDate = endDate {
            return max(0, Int(ceil(endDate.timeIntervalSince(now))))
        }
        return pausedRemaining
    }

    var body: some View {
        ZStack {
            // Glassmorphism 用：中央が少し明るいラジアルグラデで奥行きを出す
            backgroundGradient.ignoresSafeArea()

            VStack(spacing: 16) {
                // バナー領域：常に同じ高さを確保（表示有無で下が動かないように）
                ZStack {
                    if RestSession.shared.isActive {
                        RestContextBanner()
                    } else if hasTimerActivity && WorkoutContext.shared.isRecent {
                        RestPredictionBanner(onDismiss: {
                            WorkoutContext.shared.dismiss()
                        })
                    }
                }
                .frame(height: 70)

                ActivityRingsTimerDial(
                    remainingSeconds: remainingSeconds,
                    initialSeconds: initialSeconds,
                    isRunning: isRunning,
                    centerImage: centerImage,
                    onDragDelta: handleDialDragDelta
                )

                CenterImageControl(
                    hasImage: centerImage != nil,
                    isPremium: PremiumManager.shared.isUnlocked(.timerCenterImage),
                    onTap: handleImageButtonTap
                )

                PresetButtons(
                    presets: presets,
                    selected: initialSeconds,
                    isRunning: isRunning,
                    onSelect: selectPreset,
                    onEdit: { editingIndex = $0 },
                    onMoveLeft: moveLeft,
                    onMoveRight: moveRight,
                    onDelete: deletePreset,
                    onAddNew: { editingIndex = presets.count }
                )

                ControlButtons(
                    isRunning: isRunning,
                    isAlerting: isAlerting,
                    onToggle: toggleRunning,
                    onReset: reset,
                    onStopAlarm: stopAlarm
                )

                // レスト時間として記録するボタン（紐付けがある時だけ表示）
                if canRecordRest {
                    RecordRestButton(
                        isPremium: PremiumManager.shared.isUnlocked(.restTracking),
                        onTap: recordRestTime
                    )
                }

                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallSheet()
        }
        .onAppear {
            requestNotificationPermission()
            centerImage = TimerImageStore.shared.load()
        }
        .photosPicker(isPresented: $showImagePicker, selection: $pickerItem, matching: .images)
        .onChange(of: pickerItem) { _, newItem in
            Task { await loadSelectedImage(from: newItem) }
        }
        .confirmationDialog("タイマー中央の画像", isPresented: $showImageMenu, titleVisibility: .visible) {
            Button("画像を変更") { showImagePicker = true }
            Button("画像を削除", role: .destructive) { deleteCenterImage() }
            Button("キャンセル", role: .cancel) {}
        }
        .onReceive(tick) { date in
            now = date
            checkCompletion()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                now = Date()
                checkCompletion()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
            cancelScheduledNotification()
        }
        .sheet(item: Binding(
            get: { editingIndex.map { EditingTarget(index: $0) } },
            set: { editingIndex = $0?.index }
        )) { target in
            TimePickerSheet(
                initialSeconds: presets.indices.contains(target.index) ? presets[target.index] : 60,
                onSave: { newSeconds in
                    savePreset(at: target.index, seconds: newSeconds)
                    editingIndex = nil
                },
                onCancel: { editingIndex = nil }
            )
        }
    }

    // Glassmorphism 用のラジアルグラデ背景
    // 中央：濃いグレー（やや明るめ）→ 縁：純黒 で奥行きを演出
    private var backgroundGradient: RadialGradient {
        RadialGradient(
            colors: [
                Color.appCard,
                Color.appBackground,
                Color.appBackground
            ],
            center: .center,
            startRadius: 5,
            endRadius: 500
        )
    }

    // プリセット配列（文字列から数値配列へ）
    private var presets: [Int] {
        presetsData.split(separator: ",").compactMap { Int($0) }
    }

    // プリセット配列を保存形式に変換して書き戻す
    private func writePresets(_ array: [Int]) {
        presetsData = array.map(String.init).joined(separator: ",")
    }

    // 指定位置にプリセットを保存（範囲外なら末尾に追加、上限あり）
    private func savePreset(at index: Int, seconds: Int) {
        var array = presets
        if array.indices.contains(index) {
            array[index] = seconds
        } else if array.count < PresetButtons.maxCount {
            array.append(seconds)
        }
        writePresets(array)
    }

    // 左に移動（先頭ならなにもしない）
    private func moveLeft(at index: Int) {
        var array = presets
        guard index > 0, array.indices.contains(index) else { return }
        array.swapAt(index, index - 1)
        writePresets(array)
    }

    // 右に移動（末尾ならなにもしない）
    private func moveRight(at index: Int) {
        var array = presets
        guard index < array.count - 1, array.indices.contains(index) else { return }
        array.swapAt(index, index + 1)
        writePresets(array)
    }

    // 削除（最低1個は残す）
    private func deletePreset(at index: Int) {
        var array = presets
        guard array.count > 1, array.indices.contains(index) else { return }
        array.remove(at: index)
        writePresets(array)
    }

    // ダイヤルがドラッグされたとき：現在値からの差分を加算（動作中は無効）
    private func handleDialDragDelta(_ delta: Int) {
        guard !isRunning else { return }
        let newValue = min(max(pausedRemaining + delta, 0), timerMaxSeconds)
        initialSeconds = newValue
        pausedRemaining = newValue
        isAlerting = false
    }

    // プリセットを選んだとき
    // 動作中はリセットを避けるため何もしない（ボタンも視覚的にdisable）
    private func selectPreset(_ seconds: Int) {
        guard !isRunning else { return }
        cancelScheduledNotification()
        initialSeconds = seconds
        pausedRemaining = seconds
        endDate = nil
        isAlerting = false
        alarmPlayer.stop()
    }

    // スタート / 一時停止 を切り替え
    private func toggleRunning() {
        if isAlerting {
            stopAlarm()
            return
        }
        if isRunning {
            // 一時停止：終了時刻から残り秒数を保存
            pausedRemaining = remainingSeconds
            endDate = nil
            cancelScheduledNotification()
        } else {
            // スタート：0秒なら初期値に戻して開始
            let toRun = pausedRemaining > 0 ? pausedRemaining : initialSeconds
            pausedRemaining = toRun
            endDate = Date().addingTimeInterval(TimeInterval(toRun))
            now = Date()
            scheduleCompletionNotification(after: TimeInterval(toRun))
        }
    }

    // リセット（記録はしない）
    private func reset() {
        cancelScheduledNotification()
        pausedRemaining = initialSeconds
        endDate = nil
        isAlerting = false
        alarmPlayer.stop()
    }

    // 0秒到達チェック（tick内・フォアグラウンド復帰時に呼ばれる）
    private func checkCompletion() {
        guard isRunning, remainingSeconds <= 0 else { return }
        endDate = nil
        pausedRemaining = 0
        isAlerting = true
        alarmPlayer.start()
        // 注：自動保存はしない。記録ボタンで明示的に保存する設計
    }

    // 現在の経過秒数（実行中・一時停止中・アラーム中それぞれ対応）
    private var elapsedSeconds: Int {
        if isAlerting { return initialSeconds }  // 完了済み
        if isRunning { return initialSeconds - remainingSeconds }  // 動作中
        return initialSeconds - pausedRemaining  // 一時停止中
    }

    // タイマーに何か活動があるか（実行中・一時停止中・アラーム中）
    private var hasTimerActivity: Bool {
        isRunning || isAlerting || pausedRemaining < initialSeconds
    }

    // レスト記録ボタンを表示すべきか
    private var canRecordRest: Bool {
        WorkoutContext.shared.isRecent && hasTimerActivity
    }

    // レスト時間として明示的に保存
    private func recordRestTime() {
        guard PremiumManager.shared.isUnlocked(.restTracking) else {
            showPaywall = true
            return
        }
        guard WorkoutContext.shared.isRecent,
              let setID = WorkoutContext.shared.lastSetID else { return }

        // 該当セットを取得（@Queryキャッシュ→modelContext経由の順）
        let targetSet: WorkoutSet?
        if let cached = allSets.first(where: { $0.persistentModelID == setID }) {
            targetSet = cached
        } else {
            targetSet = modelContext.model(for: setID) as? WorkoutSet
        }

        guard let set = targetSet else { return }
        set.restSeconds = elapsedSeconds
        modelContext.saveOrLog("休憩秒数の記録")
        WorkoutContext.shared.clear()

        // 記録したらタイマーを止めてリセット
        alarmPlayer.stop()
        cancelScheduledNotification()
        endDate = nil
        pausedRemaining = initialSeconds
        isAlerting = false
    }

    // 通知を止めて初期状態に戻す
    private func stopAlarm() {
        alarmPlayer.stop()
        isAlerting = false
        pausedRemaining = initialSeconds
        endDate = nil
    }

    // 通知許可をリクエスト（初回のみダイアログ表示）
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    // バックグラウンドでも鳴るローカル通知をスケジュール
    private func scheduleCompletionNotification(after seconds: TimeInterval) {
        cancelScheduledNotification()
        let content = UNMutableNotificationContent()
        content.title = "レスト終了"
        content.body = "次のセットを始めましょう"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        let request = UNNotificationRequest(identifier: timerNotificationId, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // 予約中の通知をキャンセル
    private func cancelScheduledNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [timerNotificationId])
    }

    // 中央画像ボタンのタップ処理
    // 未解放ならPaywall、解放済みは画像がある時メニュー、ない時はピッカーを開く
    private func handleImageButtonTap() {
        guard PremiumManager.shared.isUnlocked(.timerCenterImage) else {
            showPaywall = true
            return
        }
        if centerImage != nil {
            showImageMenu = true
        } else {
            showImagePicker = true
        }
    }

    // PhotosPickerで選んだ画像をUIImageに変換 → 保存
    private func loadSelectedImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        let data: Data?
        do {
            data = try await item.loadTransferable(type: Data.self)
        } catch {
            AppLog.media.error("選択画像の読み込み失敗: \(error.localizedDescription, privacy: .public)")
            return
        }
        guard let data, let image = UIImage(data: data) else { return }
        TimerImageStore.shared.save(image: image)
        await MainActor.run {
            centerImage = image
            pickerItem = nil
        }
    }

    // 中央画像を削除
    private func deleteCenterImage() {
        TimerImageStore.shared.delete()
        centerImage = nil
    }
}
