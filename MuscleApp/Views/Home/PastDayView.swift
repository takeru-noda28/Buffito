//
//  PastDayView.swift
//  MuscleApp
//
//  ワークアウト画面の週次ヒートマップから過去日付をタップした時に開くページ。
//  カレンダー機能と同じ動線で過去日付の確認・編集を可能にする。
//

import SwiftUI

struct PastDayView: View {
    let date: Date

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                DaySummaryView(date: date, backLabel: "ワークアウト")
                    .padding()
            }
        }
        .navigationTitle(formattedDate)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.appTextPrimary)
                }
            }
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日(E)"
        return formatter.string(from: date)
    }
}
