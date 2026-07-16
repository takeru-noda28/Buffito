//
//  WhatsNewSheet.swift
//  MuscleApp
//

import SwiftUI

// v1.2への更新後に一度だけ表示する新機能案内
struct WhatsNewSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let highlights: [(icon: String, color: Color, title: String, body: String)] = [
        ("note.text", .orange, "種目メモ", "フォームや回数のコツを種目ごとに記録"),
        ("photo.on.rectangle.angled", .blue, "日替わりウィジェット", "Buffitoの表情が日によって変化"),
        ("rectangle.stack.fill", .green, "基本操作ガイド", "記録の流れを4枚のスライドで案内")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        hero
                        highlightCard
                        detailsLink
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("アップデート")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.appTextPrimary)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("閉じる")
                }
            }
        }
    }

    private var hero: some View {
        VStack(spacing: 12) {
            Image("buffito_happy")
                .resizable()
                .scaledToFit()
                .frame(height: 150)
                .accessibilityLabel("ご機嫌なBuffito")

            Text("BUFFITO v1.2")
                .font(.caption.bold())
                .foregroundColor(.orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.orange.opacity(0.15)))

            Text("トレーニングを、\nもっと自分らしく。")
                .font(.title.bold())
                .foregroundColor(.appTextPrimary)
                .multilineTextAlignment(.center)

            Text("記録を続けやすくする新機能を追加しました。")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var highlightCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(highlights.enumerated()), id: \.offset) { index, item in
                HStack(spacing: 14) {
                    Image(systemName: item.icon)
                        .font(.title3)
                        .foregroundColor(item.color)
                        .frame(width: 40, height: 40)
                        .background(item.color.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.title)
                            .font(.headline)
                            .foregroundColor(.appTextPrimary)
                        Text(item.body)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.vertical, 14)

                if index < highlights.count - 1 {
                    Divider()
                        .background(Color.appBorder)
                }
            }
        }
        .padding(.horizontal, 16)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var detailsLink: some View {
        NavigationLink {
            AnnouncementsView()
        } label: {
            HStack {
                Text("新機能を見る")
                    .font(.headline)
                Spacer()
                Image(systemName: "arrow.right")
                    .accessibilityHidden(true)
            }
            .foregroundColor(Color(.systemBackground))
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 18)
            .padding(.vertical, 15)
            .background(Color.appTextPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}
