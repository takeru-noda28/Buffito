//
//  BuffitoSpeechCard.swift
//  MuscleApp
//
//  ホーム画面用の吹き出し型ステータスカード。
//  吹き出しタップでセリフをシャッフル、それ以外の場所タップで詳細画面へ。
//  （相棒ホームの大型版は BuffitoHeroCard）
//

import SwiftUI
import SwiftData

struct BuffitoSpeechCard: View {
    // カード（吹き出し以外）タップで詳細画面へ（遷移は呼び出し元のNavigationPathが持つ）
    let onOpenDetail: () -> Void

    @Query private var allSets: [WorkoutSet]
    @State private var speech: String?

    private static let imageSize: CGFloat = 64

    private var streakInfo: StreakInfo {
        StreakTracker.calculate(sets: allSets)
    }

    private var mood: BuffitoMood {
        BuffitoMoodMeter.currentMood(allSets: allSets)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                buffitoIcon
                speechBubbleButton
                Spacer(minLength: 0)
            }

            HStack(spacing: 6) {
                chip(mood.statusText, background: mood.tintColor.opacity(0.35))
                chip(streakInfo.cardLabel, background: Color.appCard)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.appCard)
        )
        .contentShape(Rectangle())
        .onTapGesture { onOpenDetail() }
        .onAppear {
            // ムードが変わった直後は遷移セリフを優先して1回だけ見せる
            if let transition = BuffitoMoodTransition.consumeLine(for: mood) {
                speech = transition
            } else if speech == nil {
                speech = BuffitoSpeechBank.randomLine(for: mood)
            }
        }
    }

    // 吹き出しはタップでセリフをシャッフル（カードの遷移タップより優先される）
    private var speechBubbleButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                speech = BuffitoSpeechBank.randomLine(for: mood, excluding: speech)
            }
        } label: {
            BuffitoSpeechBubble(text: speech ?? mood.statusText, tailEdge: .leading)
        }
        .buttonStyle(.plain)
    }

    // Buffito画像。Assets.xcassetsに登録があれば本画像、なければ絵文字
    @ViewBuilder
    private var buffitoIcon: some View {
        if UIImage(named: mood.assetName) != nil {
            Image(mood.assetName)
                .resizable()
                .scaledToFit()
                .frame(width: Self.imageSize, height: Self.imageSize)
        } else {
            Text(mood.emoji)
                .font(.system(size: 48))
                .frame(width: Self.imageSize, height: Self.imageSize)
        }
    }

    private func chip(_ text: String, background: Color) -> some View {
        Text(text)
            .font(.caption2)
            .foregroundColor(.appTextPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(background))
    }
}
