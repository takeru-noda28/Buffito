//
//  DaySummaryView.swift
//  MuscleApp
//

import SwiftUI
import SwiftData

// 指定日の1日サマリ（部位ごと→種目ごと→セット一覧）
struct DaySummaryView: View {
    let date: Date
    var backLabel: String = "戻る"
    var filteredPart: BodyPart? = nil
    var showsAddButton: Bool = true  // 「+ この日に記録を追加」ボタンを表示するか

    @Query private var allDaySets: [WorkoutSet]
    @State private var showAddSheet: Bool = false

    init(date: Date, backLabel: String = "戻る", filteredPart: BodyPart? = nil, showsAddButton: Bool = true) {
        self.date = date
        self.backLabel = backLabel
        self.filteredPart = filteredPart
        self.showsAddButton = showsAddButton
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else {
            _allDaySets = Query(filter: nil, sort: [SortDescriptor(\.date)])
            return
        }
        _allDaySets = Query(
            filter: #Predicate<WorkoutSet> { $0.date >= start && $0.date < end },
            sort: [SortDescriptor(\.date)]
        )
    }

    // 未来の日付には記録できない
    private var canAddRecord: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        let target = Calendar.current.startOfDay(for: date)
        return target <= today
    }

    // 表示中の日付が今日かどうか（過去日付かを判別するために使う）
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    // 部位フィルター適用後のセット
    private var sets: [WorkoutSet] {
        guard let part = filteredPart else { return allDaySets }
        return allDaySets.filter { $0.exercise?.bodyPart == part }
    }

    // 種目ごとにグループ化（実施順に並べる：最初のセット時刻順）
    private var exerciseGroups: [(exercise: Exercise, sets: [WorkoutSet])] {
        var groups: [PersistentIdentifier: (Exercise, [WorkoutSet])] = [:]
        for set in sets {
            guard let ex = set.exercise else { continue }
            let id = ex.persistentModelID
            if var existing = groups[id] {
                existing.1.append(set)
                groups[id] = existing
            } else {
                groups[id] = (ex, [set])
            }
        }
        return groups.values
            .map { ($0.0, $0.1.sorted { $0.date < $1.date }) }
            .sorted {
                ($0.1.first?.date ?? .distantPast) < ($1.1.first?.date ?? .distantPast)
            }
            .map { (exercise: $0.0, sets: $0.1) }
    }

    // この日の合計値
    private var totalExercises: Int {
        Set(sets.compactMap { $0.exercise?.persistentModelID }).count
    }
    private var totalSets: Int { sets.count }
    private var totalReps: Int { sets.reduce(0) { $0 + $1.reps } }
    private var totalVolumeKg: Double {
        sets.reduce(0) { $0 + $1.weight * Double($1.reps) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(formatDate(date))
                .font(.title2.bold())
                .foregroundColor(.appTextPrimary)

            if sets.isEmpty {
                Text("この日の記録はありません")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 32)
            } else {
                DayTotalsCard(
                    exercises: totalExercises,
                    sets: totalSets,
                    reps: totalReps,
                    volumeKg: totalVolumeKg
                )
                ForEach(exerciseGroups, id: \.exercise.persistentModelID) { item in
                    ExerciseSessionCard(
                        exercise: item.exercise,
                        sets: item.sets,
                        backLabel: backLabel,
                        targetDate: isToday ? nil : date
                    )
                }
            }

            if canAddRecord && showsAddButton {
                addRecordButton
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddWorkoutFlowView(targetDate: date)
        }
    }

    // 「この日に記録を追加」ボタン
    private var addRecordButton: some View {
        Button {
            showAddSheet = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("この日に記録を追加")
                    .font(.subheadline.bold())
            }
            .foregroundColor(.appTextPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
            )
        }
    }

    // 「5月19日(月)」形式に変換
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日(E)"
        return formatter.string(from: date)
    }
}

// 日別合計サマリカード（種目数・セット数・レップ数・負荷量）
struct DayTotalsCard: View {
    let exercises: Int
    let sets: Int
    let reps: Int
    let volumeKg: Double

    var body: some View {
        HStack(spacing: 0) {
            TotalItem(label: "種目", value: "\(exercises)", unit: "")
            Divider().background(Color.gray.opacity(0.3)).padding(.vertical, 8)
            TotalItem(label: "セット", value: "\(sets)", unit: "")
            Divider().background(Color.gray.opacity(0.3)).padding(.vertical, 8)
            TotalItem(label: "レップ", value: "\(reps)", unit: "")
            Divider().background(Color.gray.opacity(0.3)).padding(.vertical, 8)
            TotalItem(label: "負荷量", value: WorkoutFormat.volume(volumeKg), unit: "kg")
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCard)
        )
    }

}

// 合計サマリの1項目
struct TotalItem: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(value)
                    .font(.title3.bold())
                    .foregroundColor(.appTextPrimary)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// 1種目分のカード（部位色＋種目名 + セット + ドラッグで実施順並び替え）
struct ExerciseSessionCard: View {
    let exercise: Exercise
    let sets: [WorkoutSet]
    var backLabel: String = "戻る"
    var targetDate: Date? = nil  // 過去日付からの遷移時に使用

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationLink {
            ExerciseDetailView(
                exercise: exercise,
                backLabel: backLabel,
                targetDate: targetDate
            )
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(exercise.bodyPart.color)
                        .frame(width: 10, height: 10)
                    Text(exercise.bodyPart.displayName)
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("/")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(exercise.name)
                        .font(.subheadline.bold())
                        .foregroundColor(.appTextPrimary)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Spacer()
                }

                ForEach(Array(sets.enumerated()), id: \.element.persistentModelID) { idx, set in
                    HStack {
                        Text("\(idx + 1).")
                            .foregroundColor(.gray)
                            .frame(width: 24, alignment: .leading)
                        Text(formatSet(set))
                            .foregroundColor(.appTextPrimary)
                        Spacer()
                    }
                    .font(.subheadline)
                    if let rest = set.restSeconds {
                        RestIndicator(seconds: rest)
                    }
                }

                // 種目メモ（2行まで。全文はカードタップ→種目詳細で読む）
                if let memo = trimmedMemo {
                    HStack(alignment: .top, spacing: 4) {
                        Image(systemName: "note.text")
                        Text(memo)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 2)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appCard)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // 長押し → ドラッグで実施順を入れ替え
        .draggable(dragPayload) {
            HStack(spacing: 6) {
                Circle().fill(exercise.bodyPart.color).frame(width: 8, height: 8)
                Text(exercise.name).foregroundColor(.appTextPrimary)
            }
            .padding(10)
            .background(Color.appField)
            .cornerRadius(8)
        }
        .dropDestination(for: String.self) { items, _ in
            guard let payload = items.first,
                  let draggedFirstSetTime = Double(payload),
                  draggedFirstSetTime != firstSetTime else { return false }
            swapFirstSetDate(draggedFirstSetTime: draggedFirstSetTime)
            return true
        }
    }

    // 空白・改行だけのメモは「なし」扱いにする
    private var trimmedMemo: String? {
        let memo = exercise.memo.trimmingCharacters(in: .whitespacesAndNewlines)
        return memo.isEmpty ? nil : memo
    }

    private var firstSetTime: Double {
        sets.first?.date.timeIntervalSinceReferenceDate ?? 0
    }

    private var dragPayload: String {
        String(firstSetTime)
    }

    // 別の種目とこの種目の「表示中の日付の最初のセット時刻」を入れ替える
    private func swapFirstSetDate(draggedFirstSetTime: Double) {
        let calendar = Calendar.current
        let summaryDate = targetDate ?? Date()
        let startOfDay = calendar.startOfDay(for: summaryDate)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay),
              let targetFirstSetID = sets.first?.persistentModelID else { return }

        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { $0.date >= startOfDay && $0.date < endOfDay }
        )
        guard let daySets = modelContext.fetchOrLog(descriptor, operation: "並べ替え対象の当日セット取得") else { return }

        guard let draggedFirstSet = daySets.first(where: {
                abs($0.date.timeIntervalSinceReferenceDate - draggedFirstSetTime) < 0.001
              }),
              let targetFirstSet = daySets.first(where: {
                $0.persistentModelID == targetFirstSetID
              }) else { return }

        let temp = draggedFirstSet.date
        draggedFirstSet.date = targetFirstSet.date
        targetFirstSet.date = temp
        modelContext.saveOrLog("種目の並べ替え")
    }

    private func formatSet(_ set: WorkoutSet) -> String {
        let weight = set.weight.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(set.weight))
            : String(format: "%.1f", set.weight)
        return "\(weight)kg × \(set.reps)回"
    }
}

// 部位カード（種目とセットを表示）※互換のため残置
struct PartSummaryCard: View {
    let part: BodyPart
    let exercises: [(exercise: Exercise, sets: [WorkoutSet])]

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: part.iconName)
                    .foregroundColor(.appTextPrimary)
                Text(part.displayName)
                    .font(.headline)
                    .foregroundColor(.appTextPrimary)
                Spacer()
                if exercises.count > 1 {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text("長押しでドラッグ")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }

            ForEach(Array(exercises.enumerated()), id: \.element.exercise.persistentModelID) { idx, item in
                if idx > 0 {
                    Divider()
                        .background(Color.appBorder)
                }
                exerciseBlock(item: item)
                    .draggable(item.exercise.name) {
                        Text(item.exercise.name)
                            .padding(8)
                            .background(Color.appField)
                            .cornerRadius(8)
                            .foregroundColor(.appTextPrimary)
                    }
                    .dropDestination(for: String.self) { items, _ in
                        guard let draggedName = items.first,
                              draggedName != item.exercise.name else { return false }
                        swapSortOrder(draggedName: draggedName, target: item.exercise)
                        return true
                    }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCard)
        )
    }

    @ViewBuilder
    private func exerciseBlock(item: (exercise: Exercise, sets: [WorkoutSet])) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            NavigationLink {
                ExerciseDetailView(exercise: item.exercise)
            } label: {
                HStack(spacing: 4) {
                    Text(item.exercise.name)
                        .font(.subheadline.bold())
                        .foregroundColor(.appTextPrimary)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            ForEach(Array(item.sets.enumerated()), id: \.element.persistentModelID) { index, set in
                HStack {
                    Text("\(index + 1).")
                        .foregroundColor(.gray)
                        .frame(width: 24, alignment: .leading)
                    Text(formatSet(set))
                        .foregroundColor(.appTextPrimary)
                    Spacer()
                }
                .font(.subheadline)
                if let rest = set.restSeconds {
                    RestIndicator(seconds: rest)
                }
            }
        }
        .padding(.leading, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    // ドラッグ&ドロップで sortOrder を入れ替える
    private func swapSortOrder(draggedName: String, target: Exercise) {
        guard let draggedItem = exercises.first(where: { $0.exercise.name == draggedName }) else { return }
        let temp = draggedItem.exercise.sortOrder
        draggedItem.exercise.sortOrder = target.sortOrder
        target.sortOrder = temp
        modelContext.saveOrLog("表示順の入れ替え")
    }

    private func formatSet(_ set: WorkoutSet) -> String {
        let weight = set.weight.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(set.weight))
            : String(format: "%.1f", set.weight)
        return "\(weight)kg × \(set.reps)回"
    }
}
