//
//  OneRMCalculator.swift
//  MuscleApp
//
//  推定1RM（1回挙上最大重量）を計算するユーティリティ。
//  1RM = weight × (1 + reps / 40)（reps > 1 が前提の式）
//  - 1回挙上はそれ自体が実測1RMなので、式を通さず重量をそのまま返す
//  - 10レップ以上は誤差が大きくなるので注意（参考値として扱う）
//

import Foundation

enum OneRMCalculator {
    // 推定式の分母（大きいほど控えめな推定になる）
    private static let repsDivisor = 40.0

    // 推定1RMを計算（kg）
    static func estimate(weight: Double, reps: Int) -> Double {
        guard weight > 0, reps > 0 else { return 0 }
        // 推定式は reps > 1 が前提。1回挙上は実測値そのもの
        if reps == 1 { return weight }
        return weight * (1.0 + Double(reps) / repsDivisor)
    }
}
