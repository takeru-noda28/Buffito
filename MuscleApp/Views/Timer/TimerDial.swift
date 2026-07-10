//
//  TimerDial.swift
//  MuscleApp
//

import SwiftUI
import UIKit

// ドラッグ1ラジアンあたりの秒数（一周 ≒ 60秒）
private let secondsPerRadian: Double = 60.0 / (2 * .pi)

// 円形のタイマーダイヤル（円周をなぞる動きで時間を増減）
struct TimerDial: View {
    let remainingSeconds: Int
    let initialSeconds: Int
    let isRunning: Bool
    let centerImage: UIImage?
    let onDragDelta: (Int) -> Void

    // 直前のドラッグ角度（回転量の計算用）
    @State private var previousAngle: Double? = nil
    // 1秒未満の端数を貯めるアキュムレータ
    @State private var accumulator: Double = 0

    // テーマカラー（Proかつ選択ありで反映）
    @AppStorage("timer_theme") private var themeRaw: String = "white"

    private var effectiveTheme: TimerTheme {
        let parsed = TimerTheme(rawValue: themeRaw) ?? .white
        if parsed.isPro && !PremiumManager.shared.isUnlocked(.timerProThemes) {
            return .white
        }
        return parsed
    }

    private let dialSize: CGFloat = 260
    private let innerImageSize: CGFloat = 200
    private let lineWidth: CGFloat = 14

    var body: some View {
        ZStack {
            // ── ガラス調の内側プレート（中央を少し明るく見せる）
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appCard,
                            Color.white.opacity(0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: dialSize - lineWidth, height: dialSize - lineWidth)
                .overlay(
                    Circle()
                        .stroke(Color.appCard, lineWidth: 0.5)
                )

            // ── 背景リング（細めの白で奥行きを表現）
            Circle()
                .stroke(Color.appCard, lineWidth: lineWidth)

            // ── 残り時間を示すアーク + 発光（実行中だけ強めに光る）
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progressGradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: progressColor.opacity(isRunning ? 0.55 : 0.0), radius: 12)
                .animation(.linear(duration: 0.2), value: remainingSeconds)
                .animation(.easeInOut(duration: 0.3), value: progressColor)

            // ── アーク先端のグロードット（進行位置を示す光る点）
            if progress > 0 && progress < 1 {
                progressDot
            }

            // ── 中央の画像（あれば円形クリップ、可読性のため暗いオーバーレイを重ねる）
            if let centerImage = centerImage {
                Image(uiImage: centerImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: innerImageSize, height: innerImageSize)
                    .clipShape(Circle())
                    .overlay(
                        Circle().fill(Color.black.opacity(0.40))
                    )
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
                    .allowsHitTesting(false)
            }

            // ── 中央の時間表示（画像時は影で可読性確保）
            Text(formatTime(remainingSeconds))
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundColor(progressColor)
                .monospacedDigit()
                .kerning(2)
                .shadow(color: progressColor.opacity(isRunning ? 0.45 : 0), radius: 8)
                .shadow(color: centerImage != nil ? .black.opacity(0.6) : .clear, radius: 6)
                .animation(.easeInOut(duration: 0.3), value: progressColor)
        }
        .frame(width: dialSize, height: dialSize)
        .contentShape(Circle())
        .gesture(
            isRunning ? nil : DragGesture(minimumDistance: 0)
                .onChanged { value in
                    handleDragChange(at: value.location)
                }
                .onEnded { _ in
                    previousAngle = nil
                    accumulator = 0
                }
        )
    }

    // アーク先端のグロードット（現在の進行位置に光る点を出す）
    private var progressDot: some View {
        let radius = (dialSize - lineWidth) / 2
        let angle = Angle.degrees(progress * 360 - 90)
        let x = radius * cos(CGFloat(angle.radians))
        let y = radius * sin(CGFloat(angle.radians))
        return Circle()
            .fill(progressColor)
            .frame(width: lineWidth * 0.9, height: lineWidth * 0.9)
            .shadow(color: progressColor.opacity(0.9), radius: 8)
            .offset(x: x, y: y)
            .animation(.linear(duration: 0.2), value: remainingSeconds)
    }

    // アークのグラデーション（残量色をベースに濃淡で奥行きを出す）
    private var progressGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [
                progressColor.opacity(0.7),
                progressColor,
                progressColor.opacity(0.85)
            ]),
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(270)
        )
    }

    // 進行度＝残り秒数 ÷ 初期秒数（プリセット選択直後は1.0で満タン）
    private var progress: Double {
        guard initialSeconds > 0 else { return 0 }
        return Double(remainingSeconds) / Double(initialSeconds)
    }

    // 残量に応じた色（多い=テーマ色、中=オレンジ、少=赤）
    private var progressColor: Color {
        switch progress {
        case 0.33...:
            return effectiveTheme.color
        case 0.10..<0.33:
            return .orange
        default:
            return .red
        }
    }

    // ドラッグ位置から角度を取り、前回との差分を秒数に換算
    private func handleDragChange(at location: CGPoint) {
        let center = CGPoint(x: dialSize / 2, y: dialSize / 2)
        let dx = location.x - center.x
        let dy = location.y - center.y
        let angle = atan2(dy, dx)

        defer { previousAngle = angle }
        guard let prev = previousAngle else { return }

        // -π〜π の境界をまたいだときの補正
        var deltaAngle = angle - prev
        if deltaAngle > .pi { deltaAngle -= 2 * .pi }
        if deltaAngle < -.pi { deltaAngle += 2 * .pi }

        // 角度差分 × (秒/ラジアン) を加算し、1秒以上たまったら反映
        accumulator += deltaAngle * secondsPerRadian
        let secondsToApply = Int(accumulator)
        if secondsToApply != 0 {
            onDragDelta(secondsToApply)
            accumulator -= Double(secondsToApply)
        }
    }

    // 秒数を「mm:ss」形式に変換
    private func formatTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
