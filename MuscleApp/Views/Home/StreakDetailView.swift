//
//  StreakDetailView.swift
//  MuscleApp
//
//  ホームのBuffitoカードをタップした時に開く詳細画面。
//  - Buffitoの大画像 + ムード表示
//  - ストリーク統計（現在 / 最長 / 総トレ日数 / 最後のトレから）
//  - ムードガイド（どの状態でBuffitoがどうなるか）
//

import SwiftUI
import SwiftData

struct StreakDetailView: View {
    @Query private var allSets: [WorkoutSet]
    @Environment(\.dismiss) private var dismiss

    private var streakInfo: StreakInfo {
        StreakTracker.calculate(sets: allSets)
    }

    private var daysSinceLastWorkout: Int {
        StreakTracker.daysSinceLastWorkout(sets: allSets)
    }

    private var moodScore: Int {
        BuffitoMoodMeter.score(allSets: allSets)
    }

    private var mood: BuffitoMood {
        BuffitoMoodMeter.mood(for: moodScore)
    }

    // 総トレーニング日数（重複日を除いた数）
    private var totalTrainingDays: Int {
        Set(allSets.map { Calendar.current.startOfDay(for: $0.date) }).count
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    heroSection
                    moodGaugeSection
                    statsSection
                    moodGuideSection
                }
                .padding()
            }
        }
        .navigationTitle("Buffitoの状態")
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
    }

    // MARK: - セクション

    // 大きなBuffito画像 + ムード文
    private var heroSection: some View {
        VStack(spacing: 14) {
            heroIcon
            Text(mood.statusText)
                .font(.title3.bold())
                .foregroundColor(.appTextPrimary)
            Text(mood.displayName)
                .font(.caption)
                .foregroundColor(.appTextPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(
                    colors: [mood.tintColor, mood.tintColor.opacity(0.4)],
                    startPoint: .top,
                    endPoint: .bottom
                ))
        )
    }

    @ViewBuilder
    private var heroIcon: some View {
        if UIImage(named: mood.assetName) != nil {
            Image(mood.assetName)
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
        } else {
            Text(mood.emoji)
                .font(.system(size: 110))
                .frame(width: 160, height: 160)
                .background(Color.appField)
                .clipShape(RoundedRectangle(cornerRadius: 24))
        }
    }

    // やる気ポイントのゲージ（0〜100 + 次のムードまでの残りpt）
    private var moodGaugeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("やる気ポイント")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer()
                Text("\(moodScore)")
                    .font(.title3.bold())
                    .foregroundColor(mood.tintColor)
                Text("/ 100pt")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            gaugeBar

            Text(nextMoodHint)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCard)
        )
    }

    private static let gaugeHeight: CGFloat = 12
    private static let maxScore = 100

    // ゲージ本体。しきい値の位置に目盛り線を置き、ムード帯の境界を可視化する
    private var gaugeBar: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.appField)

                Capsule()
                    .fill(LinearGradient(
                        colors: [mood.tintColor.opacity(0.6), mood.tintColor],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: width * CGFloat(moodScore) / CGFloat(Self.maxScore))

                ForEach(BuffitoMoodMeter.moodThresholds, id: \.threshold) { band in
                    Rectangle()
                        .fill(Color.appBackground.opacity(0.8))
                        .frame(width: 2, height: Self.gaugeHeight)
                        .offset(x: width * CGFloat(band.threshold) / CGFloat(Self.maxScore))
                }
            }
        }
        .frame(height: Self.gaugeHeight)
        .animation(.easeInOut(duration: 0.3), value: moodScore)
    }

    // 次のムードに上がるまでの残りpt。最上位なら称賛だけ
    private var nextMoodHint: String {
        guard let next = BuffitoMoodMeter.moodThresholds.first(where: { $0.threshold > moodScore }) else {
            return "やる気MAX！最高の状態だよ🔥"
        }
        let remaining = next.threshold - moodScore
        return "「\(next.mood.displayName)」まであと\(remaining)pt（トレ1回で+\(BuffitoMoodMeter.trainGain)pt）"
    }

    // 4つの統計カード
    private var statsSection: some View {
        VStack(spacing: 12) {
            statRow(
                icon: "flame.fill", color: .orange,
                label: "現在の連続日数",
                value: "\(streakInfo.current)", unit: "日"
            )
            statRow(
                icon: "trophy.fill", color: .yellow,
                label: "最長連続記録",
                value: "\(streakInfo.longest)", unit: "日"
            )
            statRow(
                icon: "calendar", color: .blue,
                label: "総トレーニング日数",
                value: "\(totalTrainingDays)", unit: "日"
            )
            statRow(
                icon: "moon.zzz.fill", color: .purple,
                label: "最後のトレから",
                value: lastWorkoutValueText, unit: ""
            )
        }
    }

    private var lastWorkoutValueText: String {
        guard streakInfo.lastWorkoutDate != nil else { return "まだなし" }
        if daysSinceLastWorkout == 0 { return "今日" }
        return "\(daysSinceLastWorkout)日前"
    }

    private func statRow(icon: String, color: Color, label: String, value: String, unit: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 28)
            Text(label)
                .foregroundColor(.gray)
                .font(.subheadline)
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.title3.bold())
                    .foregroundColor(.appTextPrimary)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCard)
        )
    }

    // ムードガイド（全6段階を一覧表示、現在のムードに「現在」バッジ）
    private var moodGuideSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ムードガイド")
                .font(.subheadline)
                .foregroundColor(.gray)

            VStack(spacing: 0) {
                let moods = BuffitoMood.allCases.reversed()
                ForEach(Array(moods.enumerated()), id: \.element.rawValue) { idx, m in
                    moodGuideRow(m, isCurrent: m == mood)
                    if idx < BuffitoMood.allCases.count - 1 {
                        Divider().background(Color.gray.opacity(0.2))
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appCard)
            )
        }
    }

    private func moodGuideRow(_ m: BuffitoMood, isCurrent: Bool) -> some View {
        HStack(spacing: 12) {
            Text(m.emoji)
                .font(.title3)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(m.displayName)
                    .font(.subheadline.bold())
                    .foregroundColor(.appTextPrimary)
                Text(moodCondition(m))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            Spacer()
            if isCurrent {
                Text("現在")
                    .font(.caption.bold())
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(Color.orange.opacity(0.2))
                    )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // ムードに到達する条件の説明（やる気ポイント制。トレで上がり、休みが続くと下がる）
    private func moodCondition(_ m: BuffitoMood) -> String {
        switch m {
        case .fired: return "やる気90pt以上（連続トレで到達）"
        case .happy: return "やる気70〜89pt（週3ペース目安）"
        case .normal: return "やる気40〜69pt（トレした日は必ずここ以上）"
        case .lonely: return "やる気25〜39pt（3日ほど空くと）"
        case .clingy: return "やる気10〜24pt（さらにサボると）"
        case .darkside: return "やる気9pt以下（1週間サボると）"
        }
    }
}
