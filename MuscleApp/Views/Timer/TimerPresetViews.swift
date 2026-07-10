//
//  TimerPresetViews.swift
//  MuscleApp
//

import SwiftUI
import UIKit

// シート表示用のラッパー（Int を Identifiable にするため）
struct EditingTarget: Identifiable {
    let index: Int
    var id: Int { index }
}

// プリセット秒数のボタン列＋末尾の「＋」ボタン
struct PresetButtons: View {
    // プリセットの最大個数（＋ボタン含めて8個まで）
    static let maxCount = 7

    let presets: [Int]
    let selected: Int
    let isRunning: Bool
    let onSelect: (Int) -> Void
    let onEdit: (Int) -> Void
    let onMoveLeft: (Int) -> Void
    let onMoveRight: (Int) -> Void
    let onDelete: (Int) -> Void
    let onAddNew: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(presets.enumerated()), id: \.offset) { index, seconds in
                PresetButton(
                    label: formatLabel(seconds),
                    isSelected: seconds == selected,
                    isDisabled: isRunning,
                    onTap: { onSelect(seconds) }
                )
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.3).onEnded { _ in
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                )
                .contextMenu {
                    Button {
                        onEdit(index)
                    } label: {
                        Label("時間を変更", systemImage: "pencil")
                    }
                    if index > 0 {
                        Button {
                            onMoveLeft(index)
                        } label: {
                            Label("前へ移動", systemImage: "arrow.left")
                        }
                    }
                    if index < presets.count - 1 {
                        Button {
                            onMoveRight(index)
                        } label: {
                            Label("後ろへ移動", systemImage: "arrow.right")
                        }
                    }
                    if presets.count > 1 {
                        Button(role: .destructive) {
                            onDelete(index)
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
                }
            }

            // 「＋」ボタン（上限に達したら非表示）
            if presets.count < PresetButtons.maxCount {
                AddPresetButton(onTap: onAddNew)
            }
        }
    }

    // ボタンに表示するラベル（60秒以上は「1:30」のようにmm:ss）
    private func formatLabel(_ totalSeconds: Int) -> String {
        if totalSeconds < 60 {
            return "\(totalSeconds)s"
        }
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return seconds == 0 ? "\(minutes)m" : String(format: "%d:%02d", minutes, seconds)
    }
}

// プリセット1つ分のボタン（ガラス調・選択時は内側ハイライト）
struct PresetButton: View {
    let label: String
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void

    private let cornerRadius: CGFloat = 12

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.subheadline.bold())
                .foregroundColor(isDisabled ? .white.opacity(0.35) : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(buttonBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(borderColor, lineWidth: isSelected ? 1.2 : 0.6)
                )
                .shadow(color: isSelected ? .white.opacity(0.15) : .clear, radius: 6)
        }
        .disabled(isDisabled)
        .animation(.easeInOut(duration: 0.18), value: isSelected)
    }

    @ViewBuilder
    private var buttonBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(isSelected ? Color.gray.opacity(0.45) : Color.appField)
        }
    }

    private var borderColor: Color {
        isSelected ? Color.gray : Color.appBorder
    }
}

// 新規追加ボタン（＋マーク・ガラス調）
struct AddPresetButton: View {
    let onTap: () -> Void

    private let cornerRadius: CGFloat = 12

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "plus")
                .font(.subheadline.bold())
                .foregroundColor(.appTextPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            Color.appBorder,
                            style: StrokeStyle(lineWidth: 1, dash: [4])
                        )
                )
        }
    }
}

// 時間設定シート（分・秒のホイールピッカー）
struct TimePickerSheet: View {
    let initialSeconds: Int
    let onSave: (Int) -> Void
    let onCancel: () -> Void

    @State private var minutes: Int
    @State private var seconds: Int

    init(initialSeconds: Int, onSave: @escaping (Int) -> Void, onCancel: @escaping () -> Void) {
        self.initialSeconds = initialSeconds
        self.onSave = onSave
        self.onCancel = onCancel
        _minutes = State(initialValue: initialSeconds / 60)
        _seconds = State(initialValue: initialSeconds % 60)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                HStack(spacing: 0) {
                    Picker("分", selection: $minutes) {
                        ForEach(0..<11) { value in
                            Text("\(value) 分").tag(value).foregroundColor(.appTextPrimary)
                        }
                    }
                    .pickerStyle(.wheel)

                    Picker("秒", selection: $seconds) {
                        ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { value in
                            Text("\(value) 秒").tag(value).foregroundColor(.appTextPrimary)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                .padding()
            }
            .navigationTitle("時間を設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let total = max(5, minutes * 60 + seconds)
                        onSave(total)
                    }
                }
            }
        }
    }
}
