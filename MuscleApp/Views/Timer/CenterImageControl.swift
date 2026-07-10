//
//  CenterImageControl.swift
//  MuscleApp
//

import SwiftUI

// 中央画像の追加/変更ボタン（Pro機能）
struct CenterImageControl: View {
    let hasImage: Bool
    let isPremium: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.caption)
                Text(label)
                    .font(.caption.bold())
                if !isPremium {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                }
            }
            .foregroundColor(isPremium ? .white : .yellow)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    Capsule().fill(.ultraThinMaterial)
                    Capsule().fill(Color.appField)
                }
            )
            .overlay(
                Capsule().stroke(Color.appBorder, lineWidth: 0.6)
            )
        }
    }

    private var iconName: String {
        if !isPremium { return "crown.fill" }
        return hasImage ? "photo.fill" : "photo.badge.plus"
    }

    private var label: String {
        if !isPremium { return "Proで中央に画像を入れる" }
        return hasImage ? "中央画像を変更" : "中央に画像を追加"
    }
}
