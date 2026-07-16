//
//  Version12UpdateView.swift
//  MuscleApp
//

import SwiftUI

// v1.2で追加した機能の詳細
struct Version12UpdateView: View {
    private let features: [(icon: String, color: Color, title: String, body: String)] = [
        (
            "note.text",
            .orange,
            "種目ごとのメモ",
            "フォームの向きや回数のコツなどを種目詳細に自由に残せます。入力した内容は自動で保存されます。"
        ),
        (
            "photo.on.rectangle.angled",
            .blue,
            "日替わりウィジェット",
            "トレーニング記録後は明るいBuffitoが、間が空くと寂しがるBuffitoが日替わりで登場します。"
        ),
        (
            "rectangle.stack.fill",
            .green,
            "はじめての基本操作ガイド",
            "部位から種目を選び、セットを記録する流れを4枚のスライドで案内します。設定からいつでも見直せます。"
        ),
        (
            "moon.stars.fill",
            .purple,
            "ダークモードからスタート",
            "新しくインストールしたときはダークモードで始まります。外観は設定からいつでも変更できます。"
        )
    ]

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    header

                    ForEach(Array(features.enumerated()), id: \.offset) { _, feature in
                        featureCard(feature)
                    }

                    Text("これからも、筋トレを続ける相棒としてBuffitoを育てていきます。")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                        .padding(.top, 4)
                }
                .padding()
            }
        }
        .navigationTitle("v1.2の新機能")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image("buffito_happy")
                .resizable()
                .scaledToFit()
                .frame(height: 150)
                .accessibilityLabel("ご機嫌なBuffito")

            Text("Buffito v1.2")
                .font(.title2.bold())
                .foregroundColor(.appTextPrimary)

            Text("記録とBuffitoを、もっと身近に。")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 4)
    }

    private func featureCard(
        _ feature: (icon: String, color: Color, title: String, body: String)
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: feature.icon)
                .font(.title2)
                .foregroundColor(feature.color)
                .frame(width: 46, height: 46)
                .background(feature.color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(feature.title)
                    .font(.headline)
                    .foregroundColor(.appTextPrimary)

                Text(feature.body)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
