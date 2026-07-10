//
//  TodayWorkoutConsultSheet.swift
//  MuscleApp
//
//  「今日なにやる?」相談の結果シート。
//  提案部位の表示と、「記録する」「AIに詳しく聞く」への導線を持つ。
//

import SwiftUI

struct TodayWorkoutConsultSheet: View {
    let advice: TodayWorkoutAdvice
    let onRecord: (BodyPart) -> Void
    let onAskAI: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: advice.part?.iconName ?? "figure.mixed.cardio")
                    .font(.system(size: 44))
                    .foregroundColor(.orange)
                    .padding(.top, 28)

                Text("今日なにやる？")
                    .font(.headline)
                    .foregroundColor(.appTextPrimary)

                Text(advice.message)
                    .font(.subheadline)
                    .foregroundColor(.appTextPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()

                VStack(spacing: 10) {
                    if let part = advice.part {
                        Button {
                            onRecord(part)
                        } label: {
                            Text("\(part.displayName)を記録する")
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14).fill(Color.orange)
                                )
                        }
                    }

                    Button {
                        onAskAI(advice.aiQuestion)
                    } label: {
                        Text("Buffitoに詳しく聞く")
                            .font(.subheadline.bold())
                            .foregroundColor(.appTextPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.appField)
                            )
                    }

                    Text("質問文を入れた状態でAIチャットが開きます（送信で利用回数を1回使います）")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
