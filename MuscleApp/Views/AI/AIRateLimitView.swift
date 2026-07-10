//
//  AIRateLimitView.swift
//  MuscleApp
//

import SwiftUI

struct AIRateLimitView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "hourglass")
                    .font(.system(size: 56))
                    .foregroundColor(.orange)

                Text("今日の利用回数を超えました")
                    .font(.title3.bold())
                    .foregroundColor(.appTextPrimary)
                    .multilineTextAlignment(.center)

                Text("明日また話そう。\nProならアプリ内の回数制限なしで相談できます。")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)

                Button { showPaywall = true } label: {
                    HStack {
                        Image(systemName: "crown.fill")
                        Text("Proで無制限に相談")
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(12)
                }
                .padding(.top, 12)

                Button("閉じる") { dismiss() }
                    .foregroundColor(.gray)
            }
            .padding()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallSheet()
        }
    }
}
