//
//  StagnationAdvisor.swift
//  MuscleApp
//
//  「停滞レスキュー」相談のローカル判定ロジック。
//  直近30日とそれ以前の推定1RMを比較し、一番伸び悩んでいる種目を1つ提案する。
//  一次回答はローカルで完結。「もっと詳しく」はAIに投げて改善プランを深掘りする。
//

import Foundation

struct StagnationAdvice: Identifiable {
    let id = UUID()
    let exerciseName: String?   // nil = 停滞している種目がない
    let message: String
    let aiQuestion: String
}

enum StagnationAdvisor {
    private static let windowDays = 30
    // これ以上マイナスなら「停滞」とみなす（誤差レベルの微小な後退は無視）
    private static let stagnationThreshold = -0.5

    static func advise(allSets: [WorkoutSet], referenceDate: Date = Date()) -> StagnationAdvice {
        let calendar = Calendar.current
        guard let recentCutoff = calendar.date(byAdding: .day, value: -windowDays, to: referenceDate) else {
            return noDataAdvice()
        }

        let grouped = Dictionary(grouping: allSets) { $0.exercise?.persistentModelID }

        var candidates: [(name: String, recentMax: Double, priorMax: Double, delta: Double, maxWeight: Double)] = []
        for (_, sets) in grouped {
            guard let exercise = sets.first?.exercise else { continue }

            let recent = sets.filter { $0.date >= recentCutoff }
            guard !recent.isEmpty else { continue }

            let prior = sets.filter { $0.date < recentCutoff }
            let priorMax = maxOneRM(of: prior)
            // 比較対象がない（直近30日で始めた種目）は停滞判定の対象外
            guard priorMax > 0 else { continue }

            let recentMax = maxOneRM(of: recent)
            candidates.append((
                name: exercise.name,
                recentMax: recentMax,
                priorMax: priorMax,
                delta: recentMax - priorMax,
                maxWeight: recent.map(\.weight).max() ?? 0
            ))
        }

        guard !candidates.isEmpty else {
            return noDataAdvice()
        }

        // 一番深刻（デルタが最も低い）種目を1つ選ぶ
        guard let worst = candidates.min(by: { $0.delta < $1.delta }) else {
            return noDataAdvice()
        }

        guard worst.delta <= stagnationThreshold else {
            return goodProgressAdvice()
        }

        return StagnationAdvice(
            exerciseName: worst.name,
            message: "\(worst.name)が停滞気味みたい。推定1RMが\(WorkoutFormat.weight(worst.priorMax))kg→\(WorkoutFormat.weight(worst.recentMax))kgで伸びてないよ🐱 デロードか補助種目を試してみる？",
            aiQuestion: "\(worst.name)が停滞しています（直近30日の最大重量\(WorkoutFormat.weight(worst.maxWeight))kg、推定1RM\(WorkoutFormat.weight(worst.recentMax))kg、それ以前は\(WorkoutFormat.weight(worst.priorMax))kg）。原因の候補と、次の2週間の具体的な改善プランを教えてください。"
        )
    }

    // MARK: - 記録なし/停滞なしのメッセージ

    private static func noDataAdvice() -> StagnationAdvice {
        StagnationAdvice(
            exerciseName: nil,
            message: "比較できるほどの記録がまだないみたい。トレーニングを続けて、また今度チェックしよう💪",
            aiQuestion: ""
        )
    }

    private static func goodProgressAdvice() -> StagnationAdvice {
        StagnationAdvice(
            exerciseName: nil,
            message: "今のところ停滞してる種目はなさそう！順調に伸びてるよ、このまま続けよう🔥",
            aiQuestion: ""
        )
    }

    // MARK: - 小道具

    private static func maxOneRM(of sets: [WorkoutSet]) -> Double {
        sets.map { OneRMCalculator.estimate(weight: $0.weight, reps: $0.reps) }.max() ?? 0
    }

}
