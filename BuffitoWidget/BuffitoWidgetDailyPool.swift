//
//  BuffitoWidgetDailyPool.swift
//  BuffitoWidgetExtension
//
//  「プールから日替わりで1つ選ぶ」共通ヘルパ。
//  ウィジェットのタイムラインは未来分を事前生成するため、真の乱数ではなく
//  日付から決定的に選ぶ（＝リロードのたびに変わらず、日が変わると入れ替わる）。
//  セリフ・画像など複数のプールで使う。saltを変えるとプール間で回り方がずれる。
//

import Foundation

enum BuffitoWidgetDailyPool {
    private static let randomMultiplier: UInt64 = 6_364_136_223_846_793_005
    private static let randomIncrement: UInt64 = 1_442_695_040_888_963_407
    private static let seedMixer: UInt64 = 11_400_714_819_323_198_485

    static func pick<T>(from pool: [T], on date: Date, salt: Int = 0) -> T? {
        guard !pool.isEmpty else { return nil }
        let dayIndex = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        return pool[(dayIndex &+ salt &* 17) % pool.count]
    }

    // 同日は固定しつつ、候補を日替わりでシャッフルして連日同じ項目が続かないようにする
    static func pickDailyWithoutRepeating<T>(
        from pool: [T],
        on date: Date,
        salt: Int = 0
    ) -> T? {
        guard pool.count >= 2 else { return pool.first }
        let dayIndex = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0

        // 2候補は交互表示が唯一の重複しない並びになる
        if pool.count == 2 {
            return pool[positiveModulo(dayIndex &+ salt, divisor: pool.count)]
        }

        let position = positiveModulo(dayIndex, divisor: pool.count)
        let cycleIndex = dayIndex / pool.count
        var order = shuffledIndices(
            count: pool.count,
            cycleIndex: cycleIndex,
            salt: salt
        )

        // シャッフル周期の境界でも前日と同じ候補にならないよう、周期全体の並びを補正する
        let previousOrder = shuffledIndices(
            count: pool.count,
            cycleIndex: cycleIndex - 1,
            salt: salt
        )
        if order.first == previousOrder.last {
            order.swapAt(0, 1)
        }
        return pool[order[position]]
    }

    private static func shuffledIndices(
        count: Int,
        cycleIndex: Int,
        salt: Int
    ) -> [Int] {
        var indices = Array(0..<count)
        var randomState = UInt64(bitPattern: Int64(cycleIndex))
        randomState ^= UInt64(bitPattern: Int64(salt)) &* seedMixer

        for upperBound in stride(from: count - 1, through: 1, by: -1) {
            randomState = randomState &* randomMultiplier &+ randomIncrement
            let swapIndex = Int(randomState % UInt64(upperBound + 1))
            indices.swapAt(upperBound, swapIndex)
        }
        return indices
    }

    private static func positiveModulo(_ value: Int, divisor: Int) -> Int {
        let remainder = value % divisor
        return remainder >= 0 ? remainder : remainder + divisor
    }
}
