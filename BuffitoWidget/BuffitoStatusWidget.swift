//
//  BuffitoStatusWidget.swift
//  BuffitoWidgetExtension
//
//  Buffitoの状態を表示するホーム画面ウィジェット。
//  アプリが書いたスナップショット（トレ日・ストリーク）からムードを再計算する。
//  ムードは決定的なので、未来7日分のタイムラインを事前生成しておけば
//  アプリを開かなくても「サボるとBuffitoが寂しくなっていく」が再現できる。
//

import SwiftUI
import WidgetKit

private struct SmallWidgetImageMetrics {
    let size: CGFloat
    let bottomOffset: CGFloat
}

private struct SmallWidgetPalette {
    let backgroundStart: Color
    let backgroundEnd: Color
    let scoreText: Color
    let speechText: Color
}

// Aは明るく、Bは従来の紫を維持する
private enum SmallWidgetTheme {
    private static let yellowPalette = SmallWidgetPalette(
        backgroundStart: Color(red: 1.00, green: 0.87, blue: 0.29),
        backgroundEnd: Color(red: 0.98, green: 0.55, blue: 0.13),
        scoreText: Color(red: 0.25, green: 0.16, blue: 0.03),
        speechText: Color(red: 0.32, green: 0.20, blue: 0.04)
    )
    private static let greenPalette = SmallWidgetPalette(
        backgroundStart: Color(red: 0.68, green: 0.93, blue: 0.35),
        backgroundEnd: Color(red: 0.14, green: 0.68, blue: 0.38),
        scoreText: Color(red: 0.04, green: 0.20, blue: 0.10),
        speechText: Color(red: 0.05, green: 0.25, blue: 0.13)
    )
    private static let orangePalette = SmallWidgetPalette(
        backgroundStart: Color(red: 1.00, green: 0.69, blue: 0.27),
        backgroundEnd: Color(red: 0.95, green: 0.35, blue: 0.18),
        scoreText: Color(red: 0.27, green: 0.11, blue: 0.03),
        speechText: Color(red: 0.34, green: 0.14, blue: 0.04)
    )
    private static let recentWorkoutPalettes = [
        yellowPalette,
        greenPalette,
        orangePalette
    ]
    private static let workoutOverduePalette = SmallWidgetPalette(
        backgroundStart: Color(red: 0.40, green: 0.29, blue: 0.75),
        backgroundEnd: Color(red: 0.15, green: 0.11, blue: 0.34),
        scoreText: Color(red: 0.79, green: 0.73, blue: 0.95),
        speechText: Color(red: 0.82, green: 0.78, blue: 0.93)
    )

    static func palette(
        for group: BuffitoWidgetImageGroup,
        on date: Date
    ) -> SmallWidgetPalette {
        switch group {
        case .recentWorkout:
            return BuffitoWidgetDailyPool.pick(
                from: recentWorkoutPalettes,
                on: date,
                salt: 43
            ) ?? yellowPalette
        case .workoutOverdue:
            return workoutOverduePalette
        }
    }
}

// smallウィジェットのレイアウト値。モックアップの上下構成を保つため一元管理する
private enum SmallWidgetLayout {
    static let horizontalPadding: CGFloat = 10
    static let topPadding: CGFloat = 16
    static let textSpacing: CGFloat = 3
    private static let defaultImageMetrics = SmallWidgetImageMetrics(
        size: 132,
        bottomOffset: 28
    )
    static let emojiBottomOffset = defaultImageMetrics.bottomOffset

    // 追加2枚は透明な上余白が大きいため、個別に表示領域を補正する
    static func imageMetrics(for assetName: String) -> SmallWidgetImageMetrics {
        switch assetName {
        case "buffito_widget_happy_sleep_bowl_cutout":
            return SmallWidgetImageMetrics(size: 140, bottomOffset: 10)
        case "buffito_widget_darkside_loading_cutout":
            return SmallWidgetImageMetrics(size: 156, bottomOffset: 0)
        default:
            return defaultImageMetrics
        }
    }
}

private enum WidgetTimelineConstants {
    static let recentWorkoutDuration: TimeInterval = 14 * 60 * 60
    static let futureDayCount = 7
}

// MARK: - タイムライン

struct BuffitoStatusEntry: TimelineEntry {
    let date: Date
    let score: Int
    let streak: Int
    // 一言と画像はタイムライン生成時に選び、表示中に変化しないよう保持する
    let speech: String
    let smallImageGroup: BuffitoWidgetImageGroup
    let smallAssetName: String?
    let compactAssetName: String?

    var mood: BuffitoMood { BuffitoMoodMeter.mood(for: score) }
}

struct BuffitoStatusProvider: TimelineProvider {
    // ウィジェットギャラリーのプレビュー用
    func placeholder(in context: Context) -> BuffitoStatusEntry {
        makeEntry(
            date: Date(),
            score: 100,
            streak: 7,
            imageGroup: .recentWorkout
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (BuffitoStatusEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BuffitoStatusEntry>) -> Void) {
        // 今日+未来7日分（毎日0時切替）。トレーニングが記録されたら
        // アプリ側がタイムラインを再読み込みするので、未来分は「サボり続けた場合」の予測でよい
        let calendar = Calendar.current
        let now = Date()
        let snapshot = BuffitoWidgetBridge.load()
        var entryDates: Set<Date> = [now]

        // 14時間の境界をEntryとして追加し、次の0時を待たずB群へ切り替える
        if let lastWorkoutDate = snapshot?.lastWorkoutDate {
            let transitionDate = lastWorkoutDate.addingTimeInterval(
                WidgetTimelineConstants.recentWorkoutDuration
            )
            if transitionDate > now {
                entryDates.insert(transitionDate)
            }
        }

        for offset in 1...WidgetTimelineConstants.futureDayCount {
            guard let day = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now)) else { continue }
            entryDates.insert(day)
        }

        let entries = entryDates.sorted().map {
            currentEntry(referenceDate: $0, snapshot: snapshot)
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func currentEntry(referenceDate: Date = Date()) -> BuffitoStatusEntry {
        currentEntry(referenceDate: referenceDate, snapshot: BuffitoWidgetBridge.load())
    }

    private func currentEntry(
        referenceDate: Date,
        snapshot: BuffitoWidgetSnapshot?
    ) -> BuffitoStatusEntry {
        guard let snapshot else {
            // アプリ未起動（スナップショット無し）は初期状態の「普通」を見せる
            return makeEntry(
                date: referenceDate,
                score: 50,
                streak: 0,
                imageGroup: .workoutOverdue
            )
        }

        let calendar = Calendar.current
        let trainingDays = Set(snapshot.trainingDays.map { calendar.startOfDay(for: $0) })
        let score = BuffitoMoodMeter.score(trainingDays: trainingDays, referenceDate: referenceDate)

        // ストリークは「最後のトレが今日か昨日」なら継続、それ以降は0
        let day = calendar.startOfDay(for: referenceDate)
        let gapDays = trainingDays.max().flatMap {
            calendar.dateComponents([.day], from: $0, to: day).day
        }
        let streak = (gapDays ?? Int.max) <= 1 ? snapshot.currentStreak : 0

        return makeEntry(
            date: referenceDate,
            score: score,
            streak: streak,
            imageGroup: imageGroup(
                lastWorkoutDate: snapshot.lastWorkoutDate,
                referenceDate: referenceDate
            )
        )
    }

    private func imageGroup(
        lastWorkoutDate: Date?,
        referenceDate: Date
    ) -> BuffitoWidgetImageGroup {
        guard let lastWorkoutDate else { return .workoutOverdue }
        let elapsed = referenceDate.timeIntervalSince(lastWorkoutDate)
        guard elapsed >= 0,
              elapsed < WidgetTimelineConstants.recentWorkoutDuration else {
            return .workoutOverdue
        }
        return .recentWorkout
    }

    private func makeEntry(
        date: Date,
        score: Int,
        streak: Int,
        imageGroup: BuffitoWidgetImageGroup
    ) -> BuffitoStatusEntry {
        let mood = BuffitoMoodMeter.mood(for: score)
        let smallAssetName = BuffitoWidgetImageBank.dailySmallAssetName(
            for: imageGroup,
            on: date
        )
        return BuffitoStatusEntry(
            date: date,
            score: score,
            streak: streak,
            speech: BuffitoWidgetSpeechBank.dailyLine(
                for: imageGroup,
                mood: mood,
                on: date
            ),
            smallImageGroup: imageGroup,
            smallAssetName: smallAssetName,
            compactAssetName: BuffitoWidgetImageBank.compactAssetName(for: mood)
        )
    }
}

// MARK: - ウィジェット定義

struct BuffitoStatusWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: BuffitoWidgetBridge.widgetKind, provider: BuffitoStatusProvider()) { entry in
            BuffitoStatusWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [entry.mood.tintColor.opacity(0.45), Color.black],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("Buffitoの状態")
        .description("記録に応じて変わるBuffitoの気分とストリークを表示します。")
        .supportedFamilies([.systemSmall, .systemMedium])
        // smallの全面背景と下端のBuffitoを枠いっぱいに表示するため標準余白を無効化する
        .contentMarginsDisabled()
    }
}

// MARK: - View

struct BuffitoStatusWidgetView: View {
    let entry: BuffitoStatusEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemMedium: mediumLayout
        default: smallLayout
        }
    }

    // small：上部にやる気%、中央に一言、下部にBuffitoを置くシンプル構成
    private var smallLayout: some View {
        ZStack(alignment: .bottom) {
            smallBackground
            smallBuffitoImage

            VStack(spacing: SmallWidgetLayout.textSpacing) {
                smallScoreText
                smallSpeechText
                Spacer()
            }
            .padding(.top, SmallWidgetLayout.topPadding)
            .padding(.horizontal, SmallWidgetLayout.horizontalPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    private var smallPalette: SmallWidgetPalette {
        SmallWidgetTheme.palette(
            for: entry.smallImageGroup,
            on: entry.date
        )
    }

    private var smallBackground: some View {
        LinearGradient(
            colors: [
                smallPalette.backgroundStart,
                smallPalette.backgroundEnd
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var smallScoreText: some View {
        Text("やる気 \(entry.score)%")
            .font(.system(size: 23, weight: .bold, design: .rounded))
            .foregroundColor(smallPalette.scoreText)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
    }

    // 日付とムードに応じた一言を中央に表示する
    private var smallSpeechText: some View {
        Text(entry.speech)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundColor(smallPalette.speechText)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
    }

    // 背景のないムード画像を下端から覗かせる。画像ごとの透明余白も同じ枠内で吸収する
    @ViewBuilder
    private var smallBuffitoImage: some View {
        if let assetName = entry.smallAssetName {
            let metrics = SmallWidgetLayout.imageMetrics(for: assetName)
            Image(assetName)
                .resizable()
                .scaledToFit()
                .frame(
                    width: metrics.size,
                    height: metrics.size
                )
                .offset(y: metrics.bottomOffset)
        } else {
            Text(entry.mood.emoji)
                .font(.system(size: 80))
                .offset(y: SmallWidgetLayout.emojiBottomOffset)
        }
    }

    // medium：キャラ + ステータス文 + やる気ゲージ + ストリーク
    // contentMarginsDisabledで標準余白が消えるため自前でパディングする
    private var mediumLayout: some View {
        HStack(spacing: 14) {
            buffitoImage(size: 84)
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.mood.statusText)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                gauge
                HStack {
                    streakLabel
                    Spacer()
                    Text("\(entry.score) / 100pt")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var streakLabel: some View {
        Text(entry.streak >= 1 ? "🔥 \(entry.streak)日連続中" : "今日から再スタート！")
            .font(.caption2)
            .foregroundColor(.orange)
    }

    private var gauge: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.2))
                Capsule()
                    .fill(entry.mood.tintColor)
                    .frame(width: geometry.size.width * CGFloat(entry.score) / 100)
            }
        }
        .frame(height: 8)
    }

    // Buffito画像（medium用）。透過アセットがあれば本画像、なければ絵文字
    @ViewBuilder
    private func buffitoImage(size: CGFloat) -> some View {
        if let assetName = entry.compactAssetName {
            Image(assetName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            Text(entry.mood.emoji)
                .font(.system(size: size * 0.7))
                .frame(width: size, height: size)
        }
    }
}
