//
//  AIConsentSheet.swift
//  MuscleApp
//

import SwiftUI

struct AIConsentSheet: View {
    let onAgree: () -> Void
    let onCancel: () -> Void

    private let googlePrivacyPolicyURL = URL(string: "https://policies.google.com/privacy")

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 28)

                    Text("AI機能の利用に同意")
                        .font(.title2.bold())
                        .foregroundColor(.appTextPrimary)

                    Text("Buffitoに質問するには、以下の内容を確認してください。")
                        .font(.subheadline)
                        .foregroundColor(.appTextPrimary)

                    VStack(alignment: .leading, spacing: 14) {
                        consentRow(icon: "paperplane.fill", text: "質問内容と過去30日のトレーニング記録が Google Gemini API に送信されます")
                        consentRow(icon: "person.crop.circle.badge.xmark", text: "氏名・メールアドレスなどの個人情報は送信されません")
                        consentRow(icon: "chart.bar.doc.horizontal", text: "送信データはAIによる回答生成のために使われます")
                        consentRow(icon: "arrow.uturn.backward.circle", text: "同意は設定画面からいつでも取り消せます")
                    }

                    if let googlePrivacyPolicyURL {
                        Link("Google プライバシーポリシー", destination: googlePrivacyPolicyURL)
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }

                    VStack(spacing: 12) {
                        Button(action: onAgree) {
                            Text("同意して利用する")
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .cornerRadius(12)
                        }

                        Button(action: onCancel) {
                            Text("キャンセル")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
        }
        .interactiveDismissDisabled()
    }

    private func consentRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .frame(width: 22)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.appTextPrimary)
        }
    }
}
