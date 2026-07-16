//
//  AlarmPlayer.swift
//  MuscleApp
//

import AVFoundation
import UIKit

// 完了通知の繰り返し回数・間隔
private let alarmRepeatCount: Int = 10
private let alarmIntervalSeconds: Double = 1.5

// タイマー完了時の音とバイブを管理する
// 音は .ambient セッションで再生するので、マナーモード時は無音になる
final class AlarmPlayer {
    private var player: AVAudioPlayer?
    private var repeatTask: Task<Void, Never>?

    // 通知開始：音 + バイブを繰り返す
    func start() {
        configureSessionForAmbient()
        repeatTask?.cancel()
        repeatTask = Task { @MainActor [weak self] in
            for _ in 0..<alarmRepeatCount {
                if Task.isCancelled { return }
                self?.playBeep()
                self?.vibrate()
                do {
                    try await Task.sleep(
                        nanoseconds: UInt64(alarmIntervalSeconds * 1_000_000_000)
                    )
                } catch {
                    if !Task.isCancelled {
                        AppLog.audio.error(
                            "アラーム待機失敗: \(error.localizedDescription, privacy: .public)"
                        )
                    }
                    return
                }
            }
        }
    }

    // 通知停止
    func stop() {
        repeatTask?.cancel()
        repeatTask = nil
        player?.stop()
        player = nil
    }

    // マナーモードを尊重するため .ambient で構成
    private func configureSessionForAmbient() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            // 失敗しても音が鳴らないだけなので継続する（バイブは動く）
            AppLog.audio.error("オーディオセッション構成失敗: \(error.localizedDescription, privacy: .public)")
        }
    }

    // iOSに標準で入っているシステムサウンドを使う
    private func playBeep() {
        let url = URL(fileURLWithPath: "/System/Library/Audio/UISounds/Modern/sms_alert_aurora.caf")
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            self.player = player
            player.play()
        } catch {
            // 音が出せなくてもバイブで気付けるので継続する
            AppLog.audio.error("アラーム音の再生失敗: \(error.localizedDescription, privacy: .public)")
        }
    }

    // 触覚フィードバックでバイブ（マナーモードでも動く）
    @MainActor
    private func vibrate() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
