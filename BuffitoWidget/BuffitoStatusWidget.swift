//
//  BuffitoStatusWidget.swift
//  BuffitoWidgetExtension
//
//  ホーム画面ウィジェット（Apple Fitness風）。
//  アプリが書いたスナップショット（トレ日・ストリーク）からムードを再計算する。
//  ムードは決定的なので、未来7日分のタイムラインを事前生成しておけば
//  アプリを開かなくても「サボるとBuffitoが寂しくなっていく」が再現できる。
//

import SwiftUI
import WidgetKit

// MARK: - タイムライン

struct BuffitoStatusEntry: TimelineEntry {
    let date: Date
    let score: Int
    let streak: Int
    // 日替わりの一言と画像（タイムライン生成時に日付から決定的に選ぶ）
    let speech: String
    let assetName: String?

    var mood: BuffitoMood { BuffitoMoodMeter.mood(for: score) }
}

struct BuffitoStatusProvider: TimelineProvider {
    // ウィジェットギャラリーのプレビュー用
    func placeholder(in context: Context) -> BuffitoStatusEntry {
        BuffitoStatusEntry(
            date: Date(),
            score: 100,
            streak: 7,
            speech: "今日も無敵だよ🔥",
            assetName: BuffitoWidgetImageBank.dailyAssetName(for: .fired, on: Date())
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (BuffitoStatusEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BuffitoStatusEntry>) -> Void) {
        // 今日+未来7日分（毎日0時切替）。トレーニングが記録されたら
        // アプリ側がreloadAllTimelines()を呼ぶので、未来分は「サボり続けた場合」の予測でよい
        let calendar = Calendar.current
        let now = Date()
        var entries = [currentEntry(referenceDate: now)]

        for offset in 1...7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now)) else { continue }
            entries.append(currentEntry(referenceDate: day))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func currentEntry(referenceDate: Date = Date()) -> BuffitoStatusEntry {
        guard let snapshot = BuffitoWidgetBridge.load() else {
            // アプリ未起動（スナップショット無し）は初期状態の「普通」を見せる
            return makeEntry(date: referenceDate, score: 50, streak: 0)
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

        return makeEntry(date: referenceDate, score: score, streak: streak)
    }

    private func makeEntry(date: Date, score: Int, streak: Int) -> BuffitoStatusEntry {
        let mood = BuffitoMoodMeter.mood(for: score)
        return BuffitoStatusEntry(
            date: date,
            score: score,
            streak: streak,
            speech: BuffitoWidgetSpeechBank.dailyLine(for: mood, on: date),
            assetName: BuffitoWidgetImageBank.dailyAssetName(for: mood, on: date)
        )
    }
}

// MARK: - ウィジェット定義

struct BuffitoStatusWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "BuffitoStatusWidget", provider: BuffitoStatusProvider()) { entry in
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
        // smallはキャラを枠いっぱいに見せるため標準の余白を無効化する（A案）
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

    // small（A案+一言）：キャラ全画面 + 上部中央にやる気% + 下部に日替わりの一言
    private var smallLayout: some View {
        ZStack {
            fullBleedBuffito
            VStack {
                scorePill
                Spacer()
                speechText
            }
            .padding(.vertical, 9)
            .padding(.horizontal, 6)
        }
    }

    // 日替わりの一言（帯なし・影でどのムード色でも読めるようにする）
    private var speechText: some View {
        Text(entry.speech)
            .font(.caption.bold())
            .foregroundColor(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .shadow(color: .black.opacity(0.85), radius: 3, x: 0, y: 1)
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

    // キャラの全画面表示。透過PNG前提でムード色の背景に重ねる
    // 画像はタイムライン生成時にBuffitoWidgetImageBankから日替わりで選択済み
    @ViewBuilder
    private var fullBleedBuffito: some View {
        if let assetName = entry.assetName {
            Image(assetName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        } else {
            Text(entry.mood.emoji)
                .font(.system(size: 80))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // やる気%のピル（黒半透明は視認性確保のための固定色）
    private var scorePill: some View {
        Text("\(entry.score)%")
            .font(.subheadline.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 11)
            .padding(.vertical, 3)
            .background(Capsule().fill(Color.black.opacity(0.45)))
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

    // Buffito画像（medium用）。日替わり選択済みのアセットがあれば本画像、なければ絵文字
    @ViewBuilder
    private func buffitoImage(size: CGFloat) -> some View {
        if let assetName = entry.assetName {
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
