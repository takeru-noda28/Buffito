//
//  PRCelebrationBanner.swift
//  MuscleApp
//

import SwiftUI

// PRバナーの表示データ
struct PRBannerData: Equatable {
    let title: String
    let subtitle: String
}

// 自己ベスト更新時のお祝いバナー（画面下からポップアップ）
struct PRCelebrationBanner: View {
    let data: PRBannerData

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "trophy.fill")
                .font(.title)
                .foregroundColor(.yellow)
            VStack(alignment: .leading, spacing: 4) {
                Text(data.title)
                    .font(.headline)
                    .foregroundColor(.appTextPrimary)
                Text(data.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.appTextPrimary)
            }
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(
                    colors: [.orange, .red],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .shadow(color: .black.opacity(0.4), radius: 10, y: 4)
        )
        .padding(.horizontal, 16)
    }
}
