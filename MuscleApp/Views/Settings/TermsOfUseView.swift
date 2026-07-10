//
//  TermsOfUseView.swift
//  MuscleApp
//

import SwiftUI

struct TermsOfUseView: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("最終更新日：2026年7月7日")
                        .font(.caption)
                        .foregroundColor(.gray)

                    section(
                        title: "1. 同意",
                        body: "本アプリ「Buffito」をインストール・使用することにより、本利用規約に同意したものとみなされます。"
                    )

                    section(
                        title: "2. 利用許諾",
                        body: "本アプリの使用許諾は、個人的かつ非商用目的での使用に限定されます。"
                    )

                    section(
                        title: "3. 免責事項",
                        body: """
・本アプリはトレーニング記録の補助を目的としています
・トレーニング内容や強度に関する医学的助言は提供しません
・健康上の問題や怪我のリスクがある場合は、必ず医師または専門家に相談してください
・本アプリの使用に関連して生じた怪我、健康被害、その他の損害について、開発者は責任を負いません
"""
                    )

                    section(
                        title: "4. データのバックアップ",
                        body: "ユーザーは自己責任でデータを管理してください。アプリのアンインストール、端末の故障等によるデータ消失について、開発者は責任を負いません。"
                    )

                    section(
                        title: "5. 有料機能",
                        body: "現在、本アプリは有料機能やアプリ内課金を提供していません。将来、有料機能を提供する場合は、課金は Apple ID 経由で処理され、返金については Apple のポリシーに従います。"
                    )

                    section(
                        title: "6. 禁止事項",
                        body: """
以下の行為を禁止します：
・本アプリのリバースエンジニアリング
・本アプリの不正な改変・配布
・本アプリを使用した違法行為
"""
                    )

                    section(
                        title: "7. 規約の変更",
                        body: "本規約は予告なく変更されることがあります。変更後の利用は変更後の規約への同意とみなされます。"
                    )

                    section(
                        title: "8. 準拠法",
                        body: "本規約は日本法に準拠します。"
                    )

                    section(
                        title: "9. お問い合わせ",
                        body: "アプリ内 設定画面の「お問い合わせ」フォームよりお送りください。"
                    )
                }
                .padding()
            }
        }
        .navigationTitle("利用規約")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    // タイトル + 本文の1セクション
    private func section(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .foregroundColor(.appTextPrimary)
            Text(body)
                .font(.subheadline)
                .foregroundColor(.appTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
    }
}
