//
//  PaywallSheet.swift
//  MuscleApp
//
//  Pro機能の勧誘画面。比較表でどの機能が無料/Proか明確に表示する。
//

import SwiftUI

struct PaywallSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // ヘッダー：アイコン + タイトル
                        VStack(spacing: 12) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 56))
                                .foregroundStyle(LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))

                            Text("Buffito Pro")
                                .font(.largeTitle.bold())
                                .foregroundColor(.appTextPrimary)

                            Text("もっと深く、もっと続けやすく")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 16)

                        // 比較表
                        ProComparisonView()

                        // 価格表示（後でStoreKit実装）
                        VStack(spacing: 4) {
                            Text("¥0 / 月")
                                .font(.title2.bold())
                                .foregroundColor(.appTextPrimary)
                            Text("テスト版のため無料")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 8)

                        // 加入ボタン
                        Button {
                            PremiumManager.shared.isPremium = true
                            dismiss()
                        } label: {
                            Text("Proに加入する")
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                        }

                        Text("※ 現在はテストモードです。実際の課金は今後実装予定。")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                        .foregroundColor(.appTextPrimary)
                }
            }
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}
