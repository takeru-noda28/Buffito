//
//  BuffitoHeroCard.swift
//  MuscleApp
//
//  相棒ホーム（Buffitoタブ）用のヒーロー型ステータスカード。
//  キャラを大きく中央に置き、ムード色のグローとストリークで「相棒感」を出す。
//  吹き出しタップでセリフをシャッフル、それ以外の場所タップで詳細画面へ。
//  ホーム画面のコンパクト版は BuffitoSpeechCard（別物）。
//

import SwiftUI

struct BuffitoHeroCard: View {
    let allSets: [WorkoutSet]
    // カード（吹き出し以外）タップで詳細画面へ（遷移は呼び出し元のNavigationPathが持つ）
    let onOpenDetail: () -> Void

    @State private var speech: String?

    private static let imageSize: CGFloat = 140
    private static let glowSize: CGFloat = 190

    private var streakInfo: StreakInfo {
        StreakTracker.calculate(sets: allSets)
    }

    private var mood: BuffitoMood {
        BuffitoMoodMeter.currentMood(allSets: allSets)
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(RadialGradient(
                        colors: [mood.tintColor.opacity(0.45), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: Self.glowSize / 2
                    ))
                    .frame(width: Self.glowSize, height: Self.glowSize)

                buffitoImage
            }

            speechBubbleButton
                .padding(.horizontal, 24)
                .padding(.top, 6)

            Text(mood.statusText)
                .font(.headline)
                .foregroundColor(.appTextPrimary)
                .padding(.top, 8)

            Text(streakInfo.cardLabel)
                .font(.subheadline)
                .foregroundColor(.orange)

            HStack(spacing: 3) {
                Text("詳細を見る")
                Image(systemName: "chevron.right")
                    .font(.caption2)
            }
            .font(.caption)
            .foregroundColor(.gray)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
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
            BuffitoSpeechBubble(text: speech ?? mood.statusText, tailEdge: .top)
        }
        .buttonStyle(.plain)
    }

    // Buffito画像。Assets.xcassetsに登録があれば本画像、なければ絵文字
    @ViewBuilder
    private var buffitoImage: some View {
        if UIImage(named: mood.assetName) != nil {
            Image(mood.assetName)
                .resizable()
                .scaledToFit()
                .frame(width: Self.imageSize, height: Self.imageSize)
        } else {
            Text(mood.emoji)
                .font(.system(size: 90))
        }
    }
}
