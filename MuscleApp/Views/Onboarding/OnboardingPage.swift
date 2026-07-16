//
//  OnboardingPage.swift
//  MuscleApp
//

import Foundation

// オンボーディング1ページ分の表示内容
struct OnboardingPage: Identifiable {
    enum Visual {
        case welcome
        case workoutFlow
        case setRecording
        case supportingFeatures
    }

    let id: Int
    let title: String
    let body: String
    let visual: Visual

    static let pages: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            title: "Buffitoへようこそ",
            body: "トレーニングを記録して、相棒Buffitoと一緒に続けよう。",
            visual: .welcome
        ),
        OnboardingPage(
            id: 1,
            title: "記録は3ステップ",
            body: "部位、種目の順に選ぶだけ。迷わずセット記録へ進めます。",
            visual: .workoutFlow
        ),
        OnboardingPage(
            id: 2,
            title: "重量と回数を入力",
            body: "重量と回数を入力して「セット追加」。前回の値も自動で引き継ぎます。",
            visual: .setRecording
        ),
        OnboardingPage(
            id: 3,
            title: "成長を振り返ろう",
            body: "タイマー、分析、カレンダーで継続と成長を確認できます。",
            visual: .supportingFeatures
        )
    ]
}
