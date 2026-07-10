//
//  HowToUseView.swift
//  MuscleApp
//
//  アプリの使い方ガイド。各機能の使い方を簡潔に説明する。
//

import SwiftUI

// 使い方1セクション分のデータ
private struct HowToStep: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let body: String
}

struct HowToUseView: View {
    private let steps: [HowToStep] = [
        HowToStep(
            icon: "figure.strengthtraining.traditional",
            title: "1. トレーニングを記録する",
            body: "ホームから部位を選び、種目をタップ。重量と回数を入力して「セット追加」で記録完了。前回の値が自動でセットされるので、入力は最小限でOK。"
        ),
        HowToStep(
            icon: "timer",
            title: "2. レストタイマーを使う",
            body: "タイマータブで秒数をプリセット選択 or ダイヤルをドラッグして調整。バックグラウンドでも動作し、完了時に音とバイブで知らせます。"
        ),
        HowToStep(
            icon: "calendar",
            title: "3. カレンダーで履歴を見る",
            body: "カレンダータブで日付をタップすると、その日のトレーニング内容が表示されます。部位フィルターで絞り込み可能。左右スワイプで月を切り替え。"
        ),
        HowToStep(
            icon: "chart.bar.fill",
            title: "4. 分析で統計を確認",
            body: "分析タブで総トレーニング日数・総負荷量・グラフが見れます。直近30日のトレーニング量推移と部位別の頻度を可視化。"
        ),
        HowToStep(
            icon: "bell.fill",
            title: "5. 通知を活用",
            body: "設定 → 通知設定 から、毎日のリマインダー、ジムに行ってない時の通知を設定できます。続けるための背中押しに。"
        ),
        HowToStep(
            icon: "sparkles",
            title: "6. 便利機能を活用",
            body: "セットを追加してタイマーを使うと「何セット目のレスト？」を自動判定。レスト時間の自動記録 / 編集も可能になります。"
        )
    ]

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 12) {
                    Text("Buffito の主な使い方を紹介します。")
                        .font(.subheadline)
                        .foregroundColor(.appTextPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 4)

                    ForEach(steps) { step in
                        stepCard(step)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("使い方")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private func stepCard(_ step: HowToStep) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: step.icon)
                .font(.title2)
                .foregroundColor(.orange)
                .frame(width: 36, height: 36)
                .background(
                    Circle().fill(Color.orange.opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(step.title)
                    .font(.headline)
                    .foregroundColor(.appTextPrimary)
                Text(step.body)
                    .font(.subheadline)
                    .foregroundColor(.appTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCard)
        )
    }
}
