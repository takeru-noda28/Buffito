//
//  AnnouncementsView.swift
//  MuscleApp
//
//  アプリからのお知らせ一覧。今は静的な内容、将来サーバ取得に拡張可能。
//

import SwiftUI

// お知らせ1件分のデータ
private struct Announcement: Identifiable {
    let id = UUID()
    let date: String
    let title: String
    let body: String
}

struct AnnouncementsView: View {
    // 静的お知らせ（新しいものから順）
    private let announcements: [Announcement] = [
        Announcement(
            date: "2026年5月21日",
            title: "Buffito v1.0 リリース準備中",
            body: "TestFlightで友達への配布準備を進めています。フィードバックお待ちしています！"
        )
    ]

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                if announcements.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 12) {
                        ForEach(announcements) { item in
                            announcementCard(item)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("お知らせ")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            Text("現在お知らせはありません")
                .foregroundColor(.gray)
        }
        .padding(.top, 100)
    }

    private func announcementCard(_ item: Announcement) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.date)
                .font(.caption)
                .foregroundColor(.gray)
            Text(item.title)
                .font(.headline)
                .foregroundColor(.appTextPrimary)
            Text(item.body)
                .font(.subheadline)
                .foregroundColor(.appTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCard)
        )
    }
}
