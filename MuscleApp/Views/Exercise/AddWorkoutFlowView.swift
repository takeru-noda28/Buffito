//
//  AddWorkoutFlowView.swift
//  MuscleApp
//
//  カレンダーから過去の日付にトレーニングを記録するためのシート。
//  内側にNavigationStackを持ち、部位選択 → 種目選択 → 入力 の流れを完結させる。
//

import SwiftUI

struct AddWorkoutFlowView: View {
    let targetDate: Date

    @Environment(\.dismiss) private var dismiss
    @AppStorage("body_part_order") private var bodyPartOrder: String = BodyPart.defaultOrderString

    // ホームと同じ順序で部位を並べる
    private var orderedParts: [BodyPart] {
        let parts = bodyPartOrder.split(separator: ",").compactMap { BodyPart(rawValue: String($0)) }
        let missing = BodyPart.allCases.filter { !parts.contains($0) }
        return parts + missing
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 12) {
                        targetDateBanner

                        ForEach(orderedParts) { part in
                            NavigationLink(value: part) {
                                bodyPartRow(part)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("部位を選ぶ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                        .foregroundColor(.appTextPrimary)
                }
            }
            .navigationDestination(for: BodyPart.self) { part in
                ExerciseListView(bodyPart: part, targetDate: targetDate)
            }
        }
    }

    // 記録対象の日付を上部に表示するバナー
    private var targetDateBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "calendar")
                .foregroundColor(.orange)
            Text("\(formattedTargetDate) に記録")
                .font(.subheadline.bold())
                .foregroundColor(.appTextPrimary)
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.15))
        )
    }

    // 部位1行
    private func bodyPartRow(_ part: BodyPart) -> some View {
        HStack {
            Image(systemName: part.iconName)
                .font(.title2)
                .foregroundColor(.appTextPrimary)
                .frame(width: 32)
            Text(part.displayName)
                .font(.title3.bold())
                .foregroundColor(.appTextPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.appField)
        .cornerRadius(12)
    }

    private var formattedTargetDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日(E)"
        return formatter.string(from: targetDate)
    }
}
