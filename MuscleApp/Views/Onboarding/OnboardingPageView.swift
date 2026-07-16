//
//  OnboardingPageView.swift
//  MuscleApp
//

import SwiftUI

// オンボーディングの説明ページ
struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                visual

                VStack(spacing: 10) {
                    Text(page.title)
                        .font(.title2.bold())
                        .foregroundColor(.appTextPrimary)
                        .multilineTextAlignment(.center)

                    Text(page.body)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private var visual: some View {
        switch page.visual {
        case .welcome:
            welcomeVisual
        case .workoutFlow:
            workoutFlowVisual
        case .setRecording:
            setRecordingVisual
        case .supportingFeatures:
            supportingFeaturesVisual
        }
    }

    private var welcomeVisual: some View {
        Image("buffito_happy")
            .resizable()
            .scaledToFit()
            .frame(height: 220)
            .accessibilityLabel("ご機嫌なBuffito")
    }

    private var workoutFlowVisual: some View {
        HStack(spacing: 8) {
            flowStep(icon: "figure.strengthtraining.traditional", title: "部位")
            flowArrow
            flowStep(icon: "dumbbell.fill", title: "種目")
            flowArrow
            flowStep(icon: "list.number", title: "セット")
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.appCard)
        }
    }

    private var setRecordingVisual: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("ベンチプレス")
                    .font(.headline)
                    .foregroundColor(.appTextPrimary)
                Spacer()
                Text("胸")
                    .font(.caption.bold())
                    .foregroundColor(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.orange.opacity(0.15)))
            }

            HStack(spacing: 10) {
                inputPreview(title: "重量", value: "60", unit: "kg")
                inputPreview(title: "回数", value: "10", unit: "回")
            }

            Text("セット追加")
                .font(.headline)
                .foregroundColor(Color(.systemBackground))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color.appTextPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.appCard)
        }
    }

    private var supportingFeaturesVisual: some View {
        HStack(spacing: 10) {
            featureTile(icon: "timer", title: "タイマー", color: .red)
            featureTile(icon: "chart.bar.fill", title: "分析", color: .green)
            featureTile(icon: "calendar", title: "カレンダー", color: .orange)
        }
        .frame(maxWidth: .infinity)
    }

    private func flowStep(icon: String, title: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.orange)
            Text(title)
                .font(.caption.bold())
                .foregroundColor(.appTextPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.appField)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var flowArrow: some View {
        Image(systemName: "chevron.right")
            .font(.caption.bold())
            .foregroundColor(.secondary)
    }

    private func inputPreview(title: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title2.bold())
                    .foregroundColor(.appTextPrimary)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appField)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func featureTile(icon: String, title: String, color: Color) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            Text(title)
                .font(.caption.bold())
                .foregroundColor(.appTextPrimary)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
