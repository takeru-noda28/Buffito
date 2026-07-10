//
//  ActivityRingsTimerDial.swift
//  MuscleApp
//
//  Apple Watch の Activity Rings 風のタイマーダイヤル。
//  3重の同心リング：
//    - 外側（オレンジ）：レストタイマー進行
//    - 中央（緑）：今日のセット消化率（目標10セット）
//    - 内側（青）：ストリーク（目標7日）
//
//  仮実装。元の TimerDial と同じインターフェースで差し替え可能。
//

import SwiftUI
import SwiftData

struct ActivityRingsTimerDial: View {
    let remainingSeconds: Int
    let initialSeconds: Int
    let isRunning: Bool
    let centerImage: UIImage?
    let onDragDelta: (Int) -> Void

    // SwiftDataから全セットを取得（中央リング・内側リングの計算用）
    @Query private var allSets: [WorkoutSet]

    // ドラッグ操作の累積角度
    @State private var previousAngle: Double? = nil
    @State private var accumulator: Double = 0

    // テーマカラー（Proかつ選択ありで反映）
    @AppStorage("timer_theme") private var themeRaw: String = "white"

    // MARK: - サイズ定数

    private let dialSize: CGFloat = 280
    private let outerLineWidth: CGFloat = 22
    private let middleLineWidth: CGFloat = 22
    private let innerLineWidth: CGFloat = 22
    private let ringGap: CGFloat = 4  // リング間の隙間
    private let ringTrackOpacity: Double = 0.26
    private let ringHighlightOpacity: Double = 0.92

    // 目標値（Activity Rings の「ゴール」相当）
    private let dailySetGoal: Int = 10
    private let streakGoal: Int = 7

    // MARK: - Body

    var body: some View {
        ZStack {
            // 内側の薄いガラスプレート
            Circle()
                .fill(.ultraThinMaterial)
                .opacity(0.35)
                .frame(width: innerCircleSize, height: innerCircleSize)

            // 3重リング（外→中→内）
            outerRing
            middleRing
            innerRing

            // 中央コンテンツ（画像 / 時間 / 統計）
            centerContent
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

    // MARK: - 各リング

    // 外側：タイマー進行
    private var outerRing: some View {
        ringView(
            progress: timerProgress,
            color: timerColor,
            lineWidth: outerLineWidth,
            ringSize: dialSize,
            isGlowing: isRunning
        )
    }

    // 中央：今日のセット消化率
    private var middleRing: some View {
        ringView(
            progress: setProgress,
            color: .green,
            lineWidth: middleLineWidth,
            ringSize: dialSize - (outerLineWidth + ringGap) * 2,
            isGlowing: false
        )
    }

    // 内側：ストリーク
    private var innerRing: some View {
        ringView(
            progress: streakProgress,
            color: .cyan,
            lineWidth: innerLineWidth,
            ringSize: dialSize - (outerLineWidth + middleLineWidth + ringGap * 2) * 2,
            isGlowing: false
        )
    }

    // 共通：1本のリングを描画
    private func ringView(
        progress: Double,
        color: Color,
        lineWidth: CGFloat,
        ringSize: CGFloat,
        isGlowing: Bool
    ) -> some View {
        ZStack {
            // 背景トラック。画像の上でも第2象限が沈まないよう少し濃くする
            Circle()
                .stroke(color.opacity(ringTrackOpacity), lineWidth: lineWidth)

            // 進行アーク
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    ringGradient(for: color),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(isGlowing ? 0.6 : 0.0), radius: 10)
                .animation(.easeInOut(duration: 0.4), value: progress)
        }
        .frame(width: ringSize, height: ringSize)
    }

    private func ringGradient(for color: Color) -> AngularGradient {
        AngularGradient(
            colors: [
                color,
                color.opacity(ringHighlightOpacity),
                color,
                color.opacity(0.96)
            ],
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(270)
        )
    }

    // MARK: - 中央コンテンツ

    private var innerCircleSize: CGFloat {
        dialSize - (outerLineWidth + middleLineWidth + innerLineWidth + ringGap * 4) * 2
    }

    @ViewBuilder
    private var centerContent: some View {
        ZStack {
            // 中央画像（あれば円形クリップで表示）
            if let centerImage = centerImage {
                Image(uiImage: centerImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: innerCircleSize - 8, height: innerCircleSize - 8)
                    .clipShape(Circle())
                    .overlay(
                        Circle().fill(Color.black.opacity(0.40))
                    )
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
                    .allowsHitTesting(false)
            }

            // 時間表示
            VStack(spacing: 2) {
                Text(formatTime(remainingSeconds))
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.appTextPrimary)
                    .monospacedDigit()
                    .kerning(1.5)
                    .shadow(color: timerColor.opacity(isRunning ? 0.5 : 0.0), radius: 6)

                // セット数・ストリーク表示（小さく）
                HStack(spacing: 12) {
                    miniStat(label: "今日", value: "\(todaySetCount)", color: .green)
                    Capsule().fill(Color.appField).frame(width: 1, height: 12)
                    miniStat(label: "🔥", value: "\(streakDays)", color: .cyan)
                }
                .padding(.top, 2)
            }
        }
    }

    private func miniStat(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 1) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
    }

    // MARK: - 進行度計算

    // テーマカラー（タイマー進行リング用）
    private var effectiveTheme: TimerTheme {
        let parsed = TimerTheme(rawValue: themeRaw) ?? .white
        if parsed.isPro && !PremiumManager.shared.isUnlocked(.timerProThemes) {
            return .white
        }
        return parsed
    }

    // タイマーの進行度（残り÷初期）
    private var timerProgress: Double {
        guard initialSeconds > 0 else { return 0 }
        return Double(remainingSeconds) / Double(initialSeconds)
    }

    // タイマーリングの色（残量で警告色に変化）
    private var timerColor: Color {
        switch timerProgress {
        case 0.33...:
            // テーマ色が white なら見やすくオレンジ寄りにする
            return effectiveTheme == .white ? .orange : effectiveTheme.color
        case 0.10..<0.33:
            return .orange
        default:
            return .red
        }
    }

    // 今日のセット数
    private var todaySetCount: Int {
        allSets.filter { Calendar.current.isDateInToday($0.date) }.count
    }

    // 今日のセット消化率（目標は dailySetGoal）
    private var setProgress: Double {
        min(Double(todaySetCount) / Double(dailySetGoal), 1.0)
    }

    // ストリーク日数
    private var streakDays: Int {
        StreakTracker.calculate(sets: allSets).current
    }

    // ストリーク進行度（目標は streakGoal）
    private var streakProgress: Double {
        min(Double(streakDays) / Double(streakGoal), 1.0)
    }

    // MARK: - ドラッグ操作（時間調整）

    private func handleDragChange(at location: CGPoint) {
        let center = CGPoint(x: dialSize / 2, y: dialSize / 2)
        let dx = location.x - center.x
        let dy = location.y - center.y
        let angle = atan2(dy, dx)

        defer { previousAngle = angle }
        guard let prev = previousAngle else { return }

        var deltaAngle = angle - prev
        if deltaAngle > .pi { deltaAngle -= 2 * .pi }
        if deltaAngle < -.pi { deltaAngle += 2 * .pi }

        accumulator += deltaAngle * (60.0 / (2 * .pi))
        let secondsToApply = Int(accumulator)
        if secondsToApply != 0 {
            onDragDelta(secondsToApply)
            accumulator -= Double(secondsToApply)
        }
    }

    private func formatTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
