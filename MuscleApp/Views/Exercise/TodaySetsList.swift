//
//  TodaySetsList.swift
//  MuscleApp
//

import SwiftUI
import SwiftData

// 今日のセット一覧（セット間にレスト時間を表示）
struct TodaySetsList: View {
    let sets: [WorkoutSet]
    let onDelete: (WorkoutSet) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if sets.isEmpty {
                Text("まだ記録がありません")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                ForEach(Array(sets.enumerated()), id: \.element.persistentModelID) { index, set in
                    TodaySetRow(index: index + 1, set: set, onDelete: { onDelete(set) })
                    // セットの下にレスト時間を表示（記録があれば最後のセットでも表示）
                    if let rest = set.restSeconds {
                        RestIndicator(seconds: rest)
                    }
                }
            }
        }
    }
}

// セット間に表示するレスト時間の小さい行
struct RestIndicator: View {
    let seconds: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "timer")
                .font(.caption2)
            Text(formatRest(seconds))
                .font(.caption2)
        }
        .foregroundColor(.gray)
        .padding(.leading, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formatRest(_ totalSeconds: Int) -> String {
        if totalSeconds < 60 {
            return "レスト \(totalSeconds)秒"
        }
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        if secs == 0 {
            return "レスト \(minutes)分"
        }
        return String(format: "レスト %d分%02d秒", minutes, secs)
    }
}

// 今日のセット1行
struct TodaySetRow: View {
    let index: Int
    let set: WorkoutSet
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Text("\(index)セット目")
                .font(.subheadline)
                .foregroundColor(.gray)
                .frame(width: 80, alignment: .leading)

            Text(formatSet(set))
                .font(.title3.bold())
                .foregroundColor(.appTextPrimary)

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appField)
        )
    }

    private func formatSet(_ set: WorkoutSet) -> String {
        let weight = set.weight.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(set.weight))
            : String(format: "%.1f", set.weight)
        return "\(weight)kg × \(set.reps)回"
    }
}
