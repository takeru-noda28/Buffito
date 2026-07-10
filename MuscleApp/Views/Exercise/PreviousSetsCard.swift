//
//  PreviousSetsCard.swift
//  MuscleApp
//

import SwiftUI
import SwiftData

// 前回のセット一覧カード
struct PreviousSetsCard: View {
    let sets: [WorkoutSet]
    var showsChevron: Bool = false  // タップで履歴ページに遷移できることを示す矢印

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("前回")
                    .font(.headline)
                    .foregroundColor(.appTextPrimary)
                if let date = sets.first?.date {
                    Text(date.formatted(.dateTime.month().day()))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                if showsChevron {
                    Text("履歴")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundColor(.gray)
                }
            }

            ForEach(Array(sets.enumerated()), id: \.element.persistentModelID) { index, set in
                HStack {
                    Text("\(index + 1).")
                        .foregroundColor(.gray)
                        .frame(width: 28, alignment: .leading)
                    Text(formatSet(set))
                        .foregroundColor(.appTextPrimary)
                    Spacer()
                }
                .font(.body)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCard)
        )
    }

    private func formatSet(_ set: WorkoutSet) -> String {
        let weight = set.weight.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(set.weight))
            : String(format: "%.1f", set.weight)
        return "\(weight)kg × \(set.reps)回"
    }
}

// 前回の記録がない種目用：履歴ページへの導線
struct EmptyHistoryLink: View {
    var body: some View {
        HStack {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundColor(.gray)
            Text("過去の履歴を見る")
                .font(.subheadline)
                .foregroundColor(.appTextPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCard)
        )
    }
}
