//
//  TimerRestBanners.swift
//  MuscleApp
//

import SwiftUI

// タイマー画面に表示する、自動予測されたレスト対象（×で却下可能）
struct RestPredictionBanner: View {
    let onDismiss: () -> Void

    private var context: WorkoutContext { WorkoutContext.shared }

    var body: some View {
        HStack(spacing: 12) {
            if let part = context.lastBodyPart {
                Circle()
                    .fill(part.color)
                    .frame(width: 10, height: 10)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text("自動判定")
                        .font(.caption)
                        .foregroundColor(.gray)
                    if !PremiumManager.shared.isUnlocked(.restTracking) {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                HStack(spacing: 6) {
                    if let part = context.lastBodyPart {
                        Text(part.displayName)
                            .font(.subheadline.bold())
                            .foregroundColor(.appTextPrimary)
                        Text("/")
                            .foregroundColor(.gray)
                    }
                    if let name = context.lastExerciseName {
                        Text(name)
                            .font(.subheadline.bold())
                            .foregroundColor(.appTextPrimary)
                    }
                    if let num = context.lastSetNumber {
                        Text("\(num)セット目")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appField)
        )
    }
}

// タイマー画面に表示する、現在のレスト対象情報
struct RestContextBanner: View {
    private var session: RestSession { RestSession.shared }

    var body: some View {
        HStack(spacing: 12) {
            if let part = session.bodyPart {
                Circle()
                    .fill(part.color)
                    .frame(width: 10, height: 10)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("レスト中")
                    .font(.caption)
                    .foregroundColor(.gray)
                HStack(spacing: 6) {
                    if let part = session.bodyPart {
                        Text(part.displayName)
                            .font(.subheadline.bold())
                            .foregroundColor(.appTextPrimary)
                        Text("/")
                            .foregroundColor(.gray)
                    }
                    if let name = session.exerciseName {
                        Text(name)
                            .font(.subheadline.bold())
                            .foregroundColor(.appTextPrimary)
                    }
                    if let num = session.setNumber {
                        Text("\(num)セット目")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appField)
        )
    }
}
