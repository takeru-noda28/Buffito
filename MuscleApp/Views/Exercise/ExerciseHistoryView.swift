//
//  ExerciseHistoryView.swift
//  MuscleApp
//
//  種目の過去記録ページ（案A：チャート + セッションリスト）。
//  @Queryではなく onAppear での明示フェッチを使用（多重Queryによるフリーズ回避）。
//

import SwiftUI
import SwiftData
import Charts

struct ExerciseHistoryView: View {
    let exercise: Exercise

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var allSets: [WorkoutSet] = []
    @State private var filter: HistoryFilter = .days30
    @State private var didLoad: Bool = false

    enum HistoryFilter: String, CaseIterable, Identifiable {
        case days30 = "30日"
        case days90 = "90日"
        case all = "全件"
        var id: String { rawValue }
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                LazyVStack(spacing: 16) {
                    summaryCard
                    chartCard
                    filterChips
                    sessionsList
                }
                .padding()
            }
        }
        .navigationTitle("\(exercise.name) の履歴")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left").foregroundColor(.appTextPrimary)
                }
            }
        }
        .task {
            guard !didLoad else { return }
            await loadHistory()
            didLoad = true
        }
    }

    // バックグラウンドで履歴フェッチ（メインスレッドのフリーズ防止）
    private func loadHistory() async {
        let exerciseId = exercise.persistentModelID
        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate<WorkoutSet> { $0.exercise?.persistentModelID == exerciseId },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        if let fetched = modelContext.fetchOrLog(descriptor, operation: "種目履歴の取得") {
            allSets = fetched
        }
    }

    // MARK: - データ計算

    private var filteredSets: [WorkoutSet] {
        switch filter {
        case .all:
            return allSets
        case .days30, .days90:
            let days = filter == .days30 ? 30 : 90
            guard let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) else {
                return allSets
            }
            return allSets.filter { $0.date >= cutoff }
        }
    }

    private var sessionGroups: [SessionGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredSets) { calendar.startOfDay(for: $0.date) }
        return grouped.map { day, sets in
            SessionGroup(date: day, sets: sets.sorted { $0.date < $1.date })
        }.sorted { $0.date > $1.date }
    }

    private var dailyMaxes: [DailyMax] {
        sessionGroups.map { group in
            let maxWeight = group.sets.map { $0.weight }.max() ?? 0
            return DailyMax(date: group.date, maxWeight: maxWeight)
        }.sorted { $0.date < $1.date }
    }

    private var maxOneRM: Double {
        allSets.map { OneRMCalculator.estimate(weight: $0.weight, reps: $0.reps) }.max() ?? 0
    }

    private var maxWeightSet: WorkoutSet? {
        allSets.max(by: { $0.weight < $1.weight })
    }

    private var sessionCountAll: Int {
        let calendar = Calendar.current
        return Set(allSets.map { calendar.startOfDay(for: $0.date) }).count
    }

    // MARK: - サマリーカード

    private var summaryCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                summaryItem(
                    icon: "trophy.fill", color: .yellow,
                    label: "推定1RM",
                    value: WorkoutFormat.weight(maxOneRM), unit: "kg"
                )
                summaryItem(
                    icon: "scalemass.fill", color: .orange,
                    label: "最大重量",
                    value: maxWeightSet.map { WorkoutFormat.weight($0.weight) } ?? "—",
                    unit: maxWeightSet != nil ? "kg" : ""
                )
            }
            HStack(spacing: 12) {
                summaryItem(
                    icon: "calendar", color: .blue,
                    label: "総セッション",
                    value: "\(sessionCountAll)", unit: "回"
                )
                summaryItem(
                    icon: "list.number", color: .green,
                    label: "総セット",
                    value: "\(allSets.count)", unit: "回"
                )
            }
        }
    }

    private func summaryItem(icon: String, color: Color, label: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3.bold())
                    .foregroundColor(.appTextPrimary)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCard)
        )
    }

    // MARK: - チャート

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("最大重量の推移")
                .font(.subheadline)
                .foregroundColor(.gray)

            if dailyMaxes.isEmpty {
                Text("データなし")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                Chart(dailyMaxes) { item in
                    LineMark(
                        x: .value("日付", item.date),
                        y: .value("重量", item.maxWeight)
                    )
                    .foregroundStyle(Color.orange)

                    PointMark(
                        x: .value("日付", item.date),
                        y: .value("重量", item.maxWeight)
                    )
                    .foregroundStyle(Color.orange)
                }
                .frame(height: 160)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine().foregroundStyle(Color.gray.opacity(0.2))
                        AxisValueLabel(format: .dateTime.month().day())
                            .foregroundStyle(Color.gray)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine().foregroundStyle(Color.gray.opacity(0.2))
                        AxisValueLabel().foregroundStyle(Color.gray)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCard)
        )
    }

    // MARK: - フィルター

    private var filterChips: some View {
        HStack(spacing: 8) {
            ForEach(HistoryFilter.allCases) { f in
                Button {
                    filter = f
                } label: {
                    Text(f.rawValue)
                        .font(.caption.bold())
                        .foregroundColor(filter == f ? Color(.systemBackground) : Color.appTextPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(filter == f ? Color.appTextPrimary : Color.appField)
                        )
                }
            }
            Spacer()
        }
    }

    // MARK: - セッション一覧

    private var sessionsList: some View {
        VStack(spacing: 10) {
            if sessionGroups.isEmpty {
                Text("この期間に記録はありません")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.vertical, 24)
            } else {
                ForEach(sessionGroups) { group in
                    sessionCard(group)
                }
            }
        }
    }

    private func sessionCard(_ group: SessionGroup) -> some View {
        let groupMaxOneRM = group.sets
            .map { OneRMCalculator.estimate(weight: $0.weight, reps: $0.reps) }
            .max() ?? 0
        let isPRSession = groupMaxOneRM > 0 && groupMaxOneRM >= maxOneRM - 0.001

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(formatDate(group.date))
                    .font(.subheadline.bold())
                    .foregroundColor(.appTextPrimary)
                if isPRSession {
                    Text("🏆 PR")
                        .font(.caption.bold())
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(Color.yellow.opacity(0.2))
                        )
                }
                Spacer()
            }
            ForEach(Array(group.sets.enumerated()), id: \.element.persistentModelID) { idx, set in
                HStack {
                    Text("\(idx + 1).")
                        .foregroundColor(.gray)
                        .frame(width: 24, alignment: .leading)
                    Text(formatSet(set))
                        .foregroundColor(.appTextPrimary)
                    Spacer()
                }
                .font(.subheadline)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCard)
        )
    }

    // MARK: - フォーマッタ

    private func formatSet(_ set: WorkoutSet) -> String {
        "\(WorkoutFormat.weight(set.weight))kg × \(set.reps)回"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日(E)"
        return formatter.string(from: date)
    }
}

// セッションのグループデータ
private struct SessionGroup: Identifiable {
    let date: Date
    let sets: [WorkoutSet]
    var id: Date { date }
}

// チャート用の日次データ
private struct DailyMax: Identifiable {
    let date: Date
    let maxWeight: Double
    var id: Date { date }
}
