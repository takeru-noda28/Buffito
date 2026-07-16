//
//  AnnouncementsView.swift
//  MuscleApp
//
//  アプリからのお知らせ一覧。今は静的な内容、将来サーバ取得に拡張可能。
//

import SwiftUI

// お知らせから開く詳細画面
private enum AnnouncementDestination {
    case version12
}

// お知らせ1件分のデータ
private struct Announcement: Identifiable {
    let id: String
    let date: String
    let title: String
    let body: String
    let destination: AnnouncementDestination?
}

struct AnnouncementsView: View {
    // 静的お知らせ（新しいものから順）
    private let announcements: [Announcement] = [
        Announcement(
            id: "version-1.2",
            date: "2026年7月",
            title: "Buffito v1.2の新機能",
            body: "種目メモ、記録状況で表情が変わる日替わりウィジェット、初回操作ガイドなどを追加しました。",
            destination: .version12
        ),
        Announcement(
            id: "app-store-release",
            date: "2026年7月10日",
            title: "Buffitoを正式リリースしました",
            body: "2026年7月10日、BuffitoをApp Storeで正式リリースしました。使ってくださる皆さま、応援してくださる皆さまに心から感謝します。これからも、筋トレを続ける相棒として育てていきます。",
            destination: nil
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
                            announcementRow(item)
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

    @ViewBuilder
    private func announcementRow(_ item: Announcement) -> some View {
        switch item.destination {
        case .version12:
            NavigationLink {
                Version12UpdateView()
            } label: {
                announcementCard(item, showsDisclosureIndicator: true)
            }
            .buttonStyle(.plain)
        case nil:
            announcementCard(item, showsDisclosureIndicator: false)
        }
    }

    private func announcementCard(
        _ item: Announcement,
        showsDisclosureIndicator: Bool
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(item.title)
                    .font(.headline)
                    .foregroundColor(.appTextPrimary)
                Text(item.body)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            if showsDisclosureIndicator {
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
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
