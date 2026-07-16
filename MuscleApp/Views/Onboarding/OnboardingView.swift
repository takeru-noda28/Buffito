//
//  OnboardingView.swift
//  MuscleApp
//

import SwiftUI

// 初回起動時に基本操作を案内する全画面スライド
struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss

    let onComplete: () -> Void

    @State private var selectedPage: Int = 0

    private let pages = OnboardingPage.pages

    init(onComplete: @escaping () -> Void = {}) {
        self.onComplete = onComplete
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                TabView(selection: $selectedPage) {
                    ForEach(pages) { page in
                        OnboardingPageView(page: page)
                            .tag(page.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                footer
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack {
            Button {
                moveToPreviousPage()
            } label: {
                Label("戻る", systemImage: "chevron.left")
                    .labelStyle(.iconOnly)
                    .foregroundColor(.appTextPrimary)
                    .frame(width: 44, height: 44)
            }
            .opacity(selectedPage == 0 ? 0 : 1)
            .disabled(selectedPage == 0)

            Spacer()

            Text("\(selectedPage + 1) / \(pages.count)")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Button("スキップ") {
                finishOnboarding()
            }
            .font(.subheadline)
            .foregroundColor(.orange)
            .frame(minWidth: 44, minHeight: 44)
        }
        .padding(.horizontal, 12)
    }

    private var footer: some View {
        VStack(spacing: 14) {
            HStack(spacing: 7) {
                ForEach(pages) { page in
                    Capsule()
                        .fill(page.id == selectedPage ? Color.orange : Color.appField)
                        .frame(width: page.id == selectedPage ? 24 : 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: selectedPage)
                }
            }
            .accessibilityHidden(true)

            Button {
                moveToNextPageOrFinish()
            } label: {
                Text(isLastPage ? "Buffitoを始める" : "次へ")
                    .font(.headline)
                    .foregroundColor(Color(.systemBackground))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.appTextPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    private var isLastPage: Bool {
        selectedPage == pages.count - 1
    }

    private func moveToPreviousPage() {
        guard selectedPage > 0 else { return }
        withAnimation {
            selectedPage -= 1
        }
    }

    private func moveToNextPageOrFinish() {
        guard !isLastPage else {
            finishOnboarding()
            return
        }
        withAnimation {
            selectedPage += 1
        }
    }

    private func finishOnboarding() {
        onComplete()
        dismiss()
    }
}
