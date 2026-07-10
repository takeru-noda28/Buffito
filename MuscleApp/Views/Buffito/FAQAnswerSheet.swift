//
//  FAQAnswerSheet.swift
//  MuscleApp
//
//  FAQチップの回答シート。
//  LocalFAQResponderの回答を端末内で即表示する（外部送信なし・AI利用回数の消費なし）。
//

import SwiftUI

struct FAQAnswerSheet: View {
    let chip: FAQChip
    let allSets: [WorkoutSet]

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "questionmark.bubble.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.orange)
                    .padding(.top, 28)

                Text(chip.question)
                    .font(.headline)
                    .foregroundColor(.appTextPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                ScrollView {
                    Text(chip.answer(context: AIContextBuilder.build(allSets: allSets)))
                        .font(.subheadline)
                        .foregroundColor(.appTextPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                }

                Text("端末内のFAQから表示しています（AI利用回数は消費しません）")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
