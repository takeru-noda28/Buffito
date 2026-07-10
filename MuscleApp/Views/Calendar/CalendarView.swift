//
//  CalendarView.swift
//  MuscleApp
//

import SwiftUI
import SwiftData

// カレンダー画面（日付タップで1日のサマリ表示 + 部位フィルター）
struct CalendarView: View {
    @State private var selectedDate: Date = Date()
    @State private var filteredPart: BodyPart? = nil  // nilなら全部位表示
    @Query private var allSets: [WorkoutSet]

    // 日付（startOfDay）→ その日に鍛えた部位の集合（フィルター適用）
    private var workoutsByDay: [Date: Set<BodyPart>] {
        var result: [Date: Set<BodyPart>] = [:]
        for set in allSets {
            guard let part = set.exercise?.bodyPart else { continue }
            // フィルターが選択されていて一致しない場合はスキップ
            if let filter = filteredPart, filter != part { continue }
            let day = Calendar.current.startOfDay(for: set.date)
            result[day, default: []].insert(part)
        }
        return result
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        CustomCalendar(
                            selectedDate: $selectedDate,
                            workoutsByDay: workoutsByDay
                        )
                        .padding(.horizontal, 32)
                        .padding(.top, 8)

                        BodyPartFilter(selected: $filteredPart)
                            .padding(.horizontal)

                        DaySummaryView(date: selectedDate, backLabel: "カレンダー", filteredPart: filteredPart)
                            .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("カレンダー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.appBackground, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
        }
    }
}

// 凡例＆フィルター（部位タップで絞り込み、もう一度タップで解除）
struct BodyPartFilter: View {
    @Binding var selected: BodyPart?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "全て", color: .white, isActive: selected == nil) {
                    selected = nil
                }
                ForEach(BodyPart.orderedAll) { part in
                    FilterChip(
                        label: part.displayName,
                        color: part.color,
                        isActive: selected == part
                    ) {
                        // 同じ部位を再タップで解除
                        selected = (selected == part) ? nil : part
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }
}

// フィルター用のチップ（小さなボタン）
struct FilterChip: View {
    let label: String
    let color: Color
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                Text(label)
                    .font(.caption2.bold())
                    .foregroundColor(.appTextPrimary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(isActive ? Color.gray.opacity(0.45) : Color.appField)
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        isActive ? Color.gray : Color.clear,
                        lineWidth: 1
                    )
            )
        }
    }
}

// 自作カレンダー（コンパクト版・部位色ドット対応）
struct CustomCalendar: View {
    @Binding var selectedDate: Date
    let workoutsByDay: [Date: Set<BodyPart>]

    @State private var displayedMonth: Date = Date()

    private let weekdayLabels = ["日", "月", "火", "水", "木", "金", "土"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)

    // カレンダー全体の背景色（ページ背景の黒よりやや明るいグレー）
    private let calendarBackground = Color.appField

    var body: some View {
        VStack(spacing: 8) {
            // 月切替ヘッダー（タイトルタップで年月の直接選択）
            HStack {
                Button { shiftMonth(by: -1) } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.appTextPrimary)
                        .frame(width: 28, height: 28)
                }
                Spacer()
                Menu {
                    Menu("年を変更") {
                        ForEach(yearRange.reversed(), id: \.self) { year in
                            Button("\(year)年") { setYear(year) }
                        }
                    }
                    Menu("月を変更") {
                        ForEach(1...12, id: \.self) { month in
                            Button("\(month)月") { setMonth(month) }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(monthYearText)
                            .font(.subheadline.bold())
                            .foregroundColor(.appTextPrimary)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
                Button { shiftMonth(by: 1) } label: {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.appTextPrimary)
                        .frame(width: 28, height: 28)
                }
            }

            // 曜日ヘッダー
            HStack(spacing: 2) {
                ForEach(Array(weekdayLabels.enumerated()), id: \.offset) { idx, day in
                    Text(day)
                        .font(.caption2)
                        .foregroundColor(weekdayColor(idx))
                        .frame(maxWidth: .infinity)
                }
            }

            // 日付グリッド
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(monthDates, id: \.self) { date in
                    DayCell(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                        isToday: Calendar.current.isDateInToday(date),
                        bodyParts: bodyParts(for: date),
                        isCurrentMonth: Calendar.current.isDate(date, equalTo: displayedMonth, toGranularity: .month)
                    )
                    .onTapGesture { selectedDate = date }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(calendarBackground)
        )
        // 左右スワイプで月を切替（短いタップとの誤動作を避けるため minimumDistance を確保）
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    let dx = value.translation.width
                    let dy = value.translation.height
                    // 横方向の移動が縦方向より大きい時のみ反応
                    guard abs(dx) > abs(dy) else { return }
                    if dx > 50 {
                        shiftMonth(by: -1)
                    } else if dx < -50 {
                        shiftMonth(by: 1)
                    }
                }
        )
    }

    // 指定日に鍛えた部位（ユーザー指定の順序で並べる）
    private func bodyParts(for date: Date) -> [BodyPart] {
        let day = Calendar.current.startOfDay(for: date)
        guard let parts = workoutsByDay[day] else { return [] }
        return BodyPart.orderedAll.filter { parts.contains($0) }
    }

    // 表示中の月の日付（前後の月を含めた42マス）
    private var monthDates: [Date] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth) else { return [] }
        let weekday = calendar.component(.weekday, from: monthInterval.start)
        let daysBeforeMonth = weekday - 1
        guard let gridStart = calendar.date(byAdding: .day, value: -daysBeforeMonth, to: monthInterval.start) else { return [] }
        return (0..<42).compactMap { calendar.date(byAdding: .day, value: $0, to: gridStart) }
    }

    private var monthYearText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: displayedMonth)
    }

    private func shiftMonth(by value: Int) {
        if let new = Calendar.current.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = new
        }
    }

    // 直接年を変更
    private func setYear(_ year: Int) {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: displayedMonth)
        components.year = year
        if let new = Calendar.current.date(from: components) {
            displayedMonth = new
        }
    }

    // 直接月を変更
    private func setMonth(_ month: Int) {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: displayedMonth)
        components.month = month
        if let new = Calendar.current.date(from: components) {
            displayedMonth = new
        }
    }

    // 選択可能な年の範囲（現在年の前後10年）
    private var yearRange: ClosedRange<Int> {
        let currentYear = Calendar.current.component(.year, from: Date())
        return (currentYear - 10)...(currentYear + 10)
    }

    // 日曜=赤、土曜=青、他=灰色
    private func weekdayColor(_ index: Int) -> Color {
        switch index {
        case 0: return .red.opacity(0.7)
        case 6: return .blue.opacity(0.7)
        default: return .gray
        }
    }
}

// カレンダーの1マス（部位ごとに色付きドット）
struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let bodyParts: [BodyPart]
    let isCurrentMonth: Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 1) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.caption)
                .foregroundColor(textColor)
                .frame(width: 26, height: 26)
                .background(
                    Circle().fill(backgroundColor)
                )
                .overlay(
                    // 選択中：濃いオレンジの枠 / 今日：薄いオレンジの細枠
                    Circle()
                        .strokeBorder(overlayBorderColor, lineWidth: overlayBorderWidth)
                )

            // 部位ドット（最大5個並ぶ）
            HStack(spacing: 2) {
                ForEach(bodyParts) { part in
                    Circle()
                        .fill(part.color)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(height: 6)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }

    private var textColor: Color {
        if colorScheme == .light {
            return isCurrentMonth ? .black : .black.opacity(0.42)
        }
        if !isCurrentMonth { return .gray.opacity(0.3) }
        return .appTextPrimary
    }

    private var backgroundColor: Color {
        // 選択中：薄いオレンジで塗りつぶし
        if isSelected { return Color.orange.opacity(0.25) }
        return .clear
    }

    private var overlayBorderColor: Color {
        if isSelected { return .orange }
        if isToday { return .orange.opacity(0.5) }
        return .clear
    }

    private var overlayBorderWidth: CGFloat {
        if isSelected { return 1.5 }
        if isToday { return 1.0 }
        return 0
    }
}
