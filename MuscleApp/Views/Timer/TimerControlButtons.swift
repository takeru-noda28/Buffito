//
//  TimerControlButtons.swift
//  MuscleApp
//

import SwiftUI

// スタート/停止/リセット ボタン（アラーム中は停止ボタン優先）
struct ControlButtons: View {
    let isRunning: Bool
    let isAlerting: Bool
    let onToggle: () -> Void
    let onReset: () -> Void
    let onStopAlarm: () -> Void

    var body: some View {
        if isAlerting {
            StopAlarmButton(onTap: onStopAlarm)
        } else {
            HStack(spacing: 20) {
                // リセット：ガラス調の控えめなボタン
                Button(action: onReset) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.appTextPrimary)
                        .frame(width: 64, height: 64)
                        .background(
                            ZStack {
                                Circle().fill(.ultraThinMaterial)
                                Circle().fill(Color.appField)
                            }
                        )
                        .overlay(
                            Circle().stroke(Color.appBorder, lineWidth: 0.8)
                        )
                        .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
                }

                // 再生/一時停止：白いガラスボタン（主役）
                Button(action: onToggle) {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 84, height: 84)
                        .background(
                            ZStack {
                                Circle().fill(Color.white)
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.white.opacity(0.0), .black.opacity(0.08)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            }
                        )
                        .overlay(
                            Circle().stroke(Color.white.opacity(0.6), lineWidth: 1)
                        )
                        .shadow(color: .white.opacity(0.25), radius: 12, y: 0)
                        .shadow(color: .black.opacity(0.5), radius: 10, y: 6)
                }
            }
        }
    }
}

// レスト時間として記録するボタン（紐付けがある時のみ表示）
struct RecordRestButton: View {
    let isPremium: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                Text("レスト時間を記録")
                    .font(.subheadline.bold())
                if !isPremium {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                }
            }
            .foregroundColor(isPremium ? .white : .gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                isPremium
                    ? AnyShapeStyle(LinearGradient(colors: [.green, .teal], startPoint: .leading, endPoint: .trailing))
                    : AnyShapeStyle(Color.appField)
            )
            .cornerRadius(12)
        }
        .padding(.horizontal, 32)
    }
}

// アラーム停止ボタン（赤くて大きい）
struct StopAlarmButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "stop.fill")
                Text("停止")
                    .font(.title3.bold())
            }
            .foregroundColor(.appTextPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.red)
            .cornerRadius(16)
        }
        .padding(.horizontal, 32)
    }
}
