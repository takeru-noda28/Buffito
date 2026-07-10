//
//  SetInputBar.swift
//  MuscleApp
//

import SwiftUI
import UIKit

// キーボードフォーカス対象
private enum InputField: Hashable {
    case weight, reps
}

// 画面下の入力バー（重量・回数 + セット追加ボタン）
struct InputBar: View {
    @Binding var weight: Double
    @Binding var reps: Int
    let isPremium: Bool
    let onAddSet: () -> Void
    let onRestAction: () -> Void

    @FocusState private var focusedField: InputField?

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // 重量入力
                VStack(alignment: .leading, spacing: 4) {
                    Text("重量")
                        .font(.caption)
                        .foregroundColor(.gray)
                    HStack(spacing: 4) {
                        StepperButton(systemName: "minus") {
                            weight = max(0, weight - 2.5)
                        }
                        TextField("", value: $weight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.appTextPrimary)
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity)
                            .focused($focusedField, equals: .weight)
                        Text("kg")
                            .foregroundColor(.gray)
                            .font(.caption)
                        StepperButton(systemName: "plus") {
                            weight += 2.5
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.appField)
                    )
                }

                // 回数入力
                VStack(alignment: .leading, spacing: 4) {
                    Text("回数")
                        .font(.caption)
                        .foregroundColor(.gray)
                    HStack(spacing: 4) {
                        StepperButton(systemName: "minus") {
                            reps = max(0, reps - 1)
                        }
                        TextField("", value: $reps, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.appTextPrimary)
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity)
                            .focused($focusedField, equals: .reps)
                        Text("回")
                            .foregroundColor(.gray)
                            .font(.caption)
                        StepperButton(systemName: "plus") {
                            reps += 1
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.appField)
                    )
                }
            }

            HStack(spacing: 8) {
                Button {
                    dismissKeyboard()
                    onAddSet()
                } label: {
                    Text("セット追加")
                        .font(.subheadline.bold())
                        .foregroundColor(Color(.systemBackground))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.appTextPrimary)
                        .cornerRadius(12)
                }

                Button {
                    dismissKeyboard()
                    onRestAction()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isPremium ? "pencil.and.list.clipboard" : "crown.fill")
                        Text(isPremium ? "レスト編集" : "レスト記録")
                            .font(.subheadline.bold())
                        if !isPremium {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                        }
                    }
                    .foregroundColor(isPremium ? .white : .yellow)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        isPremium
                            ? AnyShapeStyle(LinearGradient(colors: [.green, .teal], startPoint: .leading, endPoint: .trailing))
                            : AnyShapeStyle(Color.appField)
                    )
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color.appBackground)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完了") { dismissKeyboard() }
            }
        }
    }

    // フォーカス解除＋念のためUIKit側でも明示的に閉じる
    private func dismissKeyboard() {
        focusedField = nil
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }
}

// +/- の小さなボタン
struct StepperButton: View {
    let systemName: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: systemName)
                .font(.subheadline.bold())
                .foregroundColor(.appTextPrimary)
                .frame(width: 32, height: 32)
                .background(Color.appField)
                .clipShape(Circle())
        }
    }
}
