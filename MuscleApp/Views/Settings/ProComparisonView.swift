//
//  ProComparisonView.swift
//  MuscleApp
//
//  無料 vs Pro の機能比較表。PaywallSheetと設定画面の両方で再利用する。
//

import SwiftUI

// 比較表の1行分のデータ
private struct ComparisonItem {
    let icon: String
    let name: String
    let freeAvailable: Bool
    let proAvailable: Bool
}

struct ProComparisonView: View {
    // 比較項目（無料 / Pro 両方で使える機能）
    private let basicItems: [ComparisonItem] = [
        .init(icon: "dumbbell.fill", name: "種目記録", freeAvailable: true, proAvailable: true),
        .init(icon: "timer", name: "レストタイマー", freeAvailable: true, proAvailable: true),
        .init(icon: "calendar", name: "カレンダー", freeAvailable: true, proAvailable: true),
        .init(icon: "chart.bar.fill", name: "分析グラフ", freeAvailable: true, proAvailable: true),
        .init(icon: "bell.fill", name: "モチベ通知", freeAvailable: true, proAvailable: true),
        .init(icon: "bubble.left.and.bubble.right.fill", name: "AIチャット（1日10回）", freeAvailable: true, proAvailable: true)
    ]

    // Pro限定機能
    private let proItems: [ComparisonItem] = [
        .init(icon: "sparkles", name: "レスト自動判定", freeAvailable: false, proAvailable: true),
        .init(icon: "checkmark.circle.fill", name: "レスト時間の自動記録", freeAvailable: false, proAvailable: true),
        .init(icon: "pencil.and.list.clipboard", name: "レスト時間の編集", freeAvailable: false, proAvailable: true),
        .init(icon: "photo.fill", name: "タイマー中央に画像", freeAvailable: false, proAvailable: true),
        .init(icon: "paintbrush.fill", name: "タイマーテーマカラー", freeAvailable: false, proAvailable: true),
        .init(icon: "sparkles", name: "AIチャット上限なし", freeAvailable: false, proAvailable: true)
    ]

    var body: some View {
        VStack(spacing: 0) {
            headerRow

            sectionHeader("無料でも使える機能")
            ForEach(basicItems.indices, id: \.self) { i in
                comparisonRow(basicItems[i])
                if i < basicItems.count - 1 { divider }
            }

            sectionHeader("Pro限定機能", highlight: true)
            ForEach(proItems.indices, id: \.self) { i in
                comparisonRow(proItems[i])
                if i < proItems.count - 1 { divider }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCard)
        )
    }

    // ヘッダー行（"機能" / "無料" / "Pro"）
    private var headerRow: some View {
        HStack(spacing: 0) {
            Text("機能")
                .font(.caption.bold())
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("無料")
                .font(.caption.bold())
                .foregroundColor(.gray)
                .frame(width: 50)
            Text("Pro")
                .font(.caption.bold())
                .foregroundColor(.yellow)
                .frame(width: 50)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.appField)
    }

    private func sectionHeader(_ title: String, highlight: Bool = false) -> some View {
        HStack(spacing: 4) {
            if highlight {
                Image(systemName: "crown.fill").font(.caption2).foregroundColor(.yellow)
            }
            Text(title)
                .font(.caption2)
                .foregroundColor(highlight ? .yellow : .gray)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    private func comparisonRow(_ item: ComparisonItem) -> some View {
        HStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: item.icon)
                    .foregroundColor(.gray)
                    .frame(width: 20)
                Text(item.name)
                    .font(.subheadline)
                    .foregroundColor(.appTextPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            availabilityMark(item.freeAvailable, color: .white)
                .frame(width: 50)
            availabilityMark(item.proAvailable, color: .yellow)
                .frame(width: 50)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // ✓ / − の表示
    private func availabilityMark(_ available: Bool, color: Color) -> some View {
        Group {
            if available {
                Image(systemName: "checkmark")
                    .foregroundColor(color)
                    .font(.subheadline.bold())
            } else {
                Text("−")
                    .foregroundColor(.gray.opacity(0.5))
                    .font(.subheadline)
            }
        }
    }

    private var divider: some View {
        Divider()
            .background(Color.gray.opacity(0.2))
            .padding(.leading, 14)
    }
}
