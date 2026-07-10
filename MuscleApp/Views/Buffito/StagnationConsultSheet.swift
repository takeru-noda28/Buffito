//
//  StagnationConsultSheet.swift
//  MuscleApp
//
//  「停滞レスキュー」相談の結果シート。
//  停滞種目があれば「Buffitoに詳しく聞く」でAIに改善プランを深掘りできる。
//

import SwiftUI

struct StagnationConsultSheet: View {
    let advice: StagnationAdvice
    let onAskAI: (String) -> Void

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: advice.exerciseName != nil ? "arrow.turn.right.up" : "checkmark.seal.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.orange)
                    .padding(.top, 28)

                Text("停滞レスキュー")
                    .font(.headline)
                    .foregroundColor(.appTextPrimary)

                Text(advice.message)
                    .font(.subheadline)
                    .foregroundColor(.appTextPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()

                if advice.exerciseName != nil {
                    VStack(spacing: 10) {
                        Button {
                            onAskAI(advice.aiQuestion)
                        } label: {
                            Text("Buffitoに改善プランを聞く")
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14).fill(Color.orange)
                                )
                        }

                        Text("質問文を入れた状態でAIチャットが開きます（送信で利用回数を1回使います）")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                } else {
                    Color.clear.frame(height: 24)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
