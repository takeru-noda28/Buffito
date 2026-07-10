//
//  RestOrGoConsultSheet.swift
//  MuscleApp
//
//  「休む？行く？」相談のシート。
//  疲労感を1タップで選ぶと、記録データと合わせて3段階（休む/軽め/行く）で判定。
//  根拠チップで「記録を見て判定した」ことを示し、行く系なら部位提案へつなぐ。
//

import SwiftUI

struct RestOrGoConsultSheet: View {
    let allSets: [WorkoutSet]
    // 「空いてる部位を提案してもらう」→ 今日なにやる？の提案シートへ切り替える
    let onSuggestWorkout: () -> Void

    @State private var advice: RestOrGoAdvice?

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: headerIconName)
                    .font(.system(size: 44))
                    .foregroundColor(.orange)
                    .padding(.top, 28)

                Text("休む？行く？")
                    .font(.headline)
                    .foregroundColor(.appTextPrimary)

                if let advice {
                    resultView(advice)
                } else {
                    fatigueQuestionView
                }

                Spacer()

                if let advice, advice.verdict != .rest {
                    suggestWorkoutButton
                } else {
                    Color.clear.frame(height: 24)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private var headerIconName: String {
        guard let advice else { return "questionmark.circle.fill" }
        switch advice.verdict {
        case .rest: return "bed.double.fill"
        case .light: return "figure.walk"
        case .go: return "figure.run"
        }
    }

    // MARK: - 疲労感の入力（1タップ）

    private var fatigueQuestionView: some View {
        VStack(spacing: 14) {
            Text("今日の疲れ具合は？")
                .font(.subheadline)
                .foregroundColor(.appTextPrimary)

            HStack(spacing: 10) {
                ForEach(FatigueLevel.allCases) { level in
                    fatigueButton(level)
                }
            }
            .padding(.horizontal)
        }
    }

    private func fatigueButton(_ level: FatigueLevel) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                advice = RestOrGoAdvisor.advise(fatigue: level, allSets: allSets)
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: level.iconName)
                    .font(.title2)
                    .foregroundColor(.orange)
                Text(level.label)
                    .font(.subheadline.bold())
                    .foregroundColor(.appTextPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.appCard)
            )
        }
    }

    // MARK: - 判定結果

    private func resultView(_ advice: RestOrGoAdvice) -> some View {
        VStack(spacing: 14) {
            Text(verdictTitle(advice.verdict))
                .font(.title3.bold())
                .foregroundColor(.orange)

            Text(advice.message)
                .font(.subheadline)
                .foregroundColor(.appTextPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if !advice.evidence.isEmpty {
                evidenceChips(advice.evidence)
            }
        }
    }

    private func verdictTitle(_ verdict: RestOrGoVerdict) -> String {
        switch verdict {
        case .rest: return "今日は休もう"
        case .light: return "今日は軽めがおすすめ"
        case .go: return "今日は行こう！"
        }
    }

    // 判定根拠（記録を見て判定したことを見せる）
    private func evidenceChips(_ items: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.appField))
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - 部位提案への導線（行く/軽めの時だけ）

    private var suggestWorkoutButton: some View {
        Button {
            onSuggestWorkout()
        } label: {
            Text("空いてる部位を提案してもらう")
                .font(.headline)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14).fill(Color.orange)
                )
        }
        .padding(.horizontal)
        .padding(.bottom, 24)
    }
}
