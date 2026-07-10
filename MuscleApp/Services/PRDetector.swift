//
//  PRDetector.swift
//  MuscleApp
//
//  追加したセットがその種目の自己ベスト（PR）を更新したかを判定。
//  以下の2つの基準のどちらかを更新すればPR：
//  - 推定1RM
//  - 最大挙上重量（1回でも持ち上げた最大の重量）
//

import Foundation

// PR判定の結果
struct PRResult {
    let isOneRMPR: Bool       // 1RMを更新したか
    let isMaxWeightPR: Bool   // 最大重量を更新したか
    let newOneRM: Double      // 新セットの推定1RM
    let newWeight: Double     // 新セットの重量

    var isAny: Bool { isOneRMPR || isMaxWeightPR }
}

enum PRDetector {
    // 新セットが該当種目の自己ベスト（1RM or 最大重量）を更新したかを判定
    // history は同じ種目の過去全セット（newSetを含んでも除外しても可）
    static func detect(newSet: WorkoutSet, history: [WorkoutSet]) -> PRResult {
        let newOneRM = OneRMCalculator.estimate(weight: newSet.weight, reps: newSet.reps)
        let newWeight = newSet.weight

        // newSet自体を除外した過去のセット
        let prior = history.filter { $0.persistentModelID != newSet.persistentModelID }

        // 過去の最高値（履歴がなければ初回扱い→PRにしない）
        guard !prior.isEmpty else {
            return PRResult(isOneRMPR: false, isMaxWeightPR: false,
                            newOneRM: newOneRM, newWeight: newWeight)
        }

        let priorMaxOneRM = prior.map { OneRMCalculator.estimate(weight: $0.weight, reps: $0.reps) }.max() ?? 0
        let priorMaxWeight = prior.map { $0.weight }.max() ?? 0

        return PRResult(
            isOneRMPR: newOneRM > priorMaxOneRM,
            isMaxWeightPR: newWeight > priorMaxWeight,
            newOneRM: newOneRM,
            newWeight: newWeight
        )
    }
}
