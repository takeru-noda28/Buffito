//
//  PrivacyPolicyView.swift
//  MuscleApp
//

import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("最終更新日：2026年7月7日")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text("「Buffito」（以下「本アプリ」）は、ユーザーのプライバシーを尊重します。本ポリシーでは、本アプリでの情報の取り扱いについて説明します。")
                        .foregroundColor(.appTextPrimary)

                    section(
                        title: "1. 収集する情報",
                        body: """
本アプリは以下の情報をユーザーの端末内にのみ保存します：
・トレーニング記録（種目、重量、回数、日時、レスト時間）
・設定情報（通知設定、プリセット時間、外観設定など）
・ユーザーが任意で選択した写真（タイマー画面に表示するため）
・AIチャットの履歴（AI機能「Buffitoに聞く」を利用した場合）

これらの情報は外部サーバーには送信されません（AI機能を利用する場合を除く・第8条を参照）。すべてユーザーの端末内に保存されます。写真は本アプリのDocumentsディレクトリ内に保存され、アンインストール時に削除されます。
"""
                    )

                    section(
                        title: "2. 情報の利用目的",
                        body: """
収集した情報は以下の目的のみに使用されます：
・トレーニング記録の表示・分析
・ローカル通知の送信（「◯日ジムに行っていない」など）
・統計情報の表示
・AI機能利用時の回答生成（第8条を参照）
"""
                    )

                    section(
                        title: "3. 第三者への提供",
                        body: "本アプリは取得した情報を第三者に提供しません。ただし、ユーザーが任意でAI機能を利用する場合に限り、Google LLC が提供する Gemini API へ一部データが送信されます（第8条を参照）。"
                    )

                    section(
                        title: "4. 通知",
                        body: "本アプリはローカル通知機能を使用します。通知の許可はiOSの設定からいつでも変更できます。"
                    )

                    section(
                        title: "5. 課金情報",
                        body: "現在、本アプリはアプリ内課金を提供していません。将来、有料機能を提供する場合は Apple の StoreKit を使用し、決済情報は Apple によって処理されます。本アプリは決済情報を収集しません。"
                    )

                    section(
                        title: "6. データの削除",
                        body: "本アプリをアンインストールすると、端末内に保存されたすべてのデータが削除されます。"
                    )

                    section(
                        title: "7. 児童のプライバシー",
                        body: "本アプリは13歳未満の児童を対象としていません。"
                    )

                    section(
                        title: "8. AI機能利用時のデータ送信",
                        body: """
本アプリの「Buffitoに聞く」（AI機能）を利用する場合、以下のデータが Google LLC が提供する Gemini API に送信されます：

・ユーザーがAIに送信した質問内容
・過去30日のトレーニング記録（種目名、重量、回数、日付）
・連続記録（ストリーク）情報
・推定1RM・自己ベスト情報
・匿名のデバイス識別子（IDFV、利用回数制限のためのみ使用）

送信されるデータには、氏名・メールアドレス・電話番号などの個人を特定できる情報は一切含まれません。データは AI による回答生成のためにのみ使用され、本アプリ運営者は送信内容にアクセスできません。

AI機能を利用しない場合、上記データの外部送信は一切発生しません。AI機能の利用には初回起動時に明示的な同意が必要であり、同意は設定画面からいつでも取り消すことができます。

【関連リンク】
・Google プライバシーポリシー：https://policies.google.com/privacy
・Gemini API データ使用ポリシー：https://ai.google.dev/gemini-api/terms
"""
                    )

                    section(
                        title: "9. ポリシーの変更",
                        body: "本ポリシーは予告なく変更されることがあります。変更後の利用は変更後のポリシーへの同意とみなされます。"
                    )

                    section(
                        title: "10. お問い合わせ",
                        body: "ご質問やご意見は、アプリ内 設定画面の「お問い合わせ」フォームよりお送りください。"
                    )
                }
                .padding()
            }
        }
        .navigationTitle("プライバシーポリシー")
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
