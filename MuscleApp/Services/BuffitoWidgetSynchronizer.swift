//
//  BuffitoWidgetSynchronizer.swift
//  MuscleApp
//
//  SwiftDataの変更後に、ウィジェット用スナップショットを同期するアプリ側サービス。
//  ウィジェットターゲットをSwiftDataへ依存させないため、Bridgeとは分離する。
//

import SwiftData

enum BuffitoWidgetSynchronizer {
    /// SwiftDataから全セットを取得し、ウィジェットを同期する。
    /// - Returns: 全セットを取得できた場合は現在のストリーク
    @discardableResult
    static func synchronize(using modelContext: ModelContext, operation: String) -> Int? {
        let descriptor = FetchDescriptor<WorkoutSet>()
        guard let allSets = modelContext.fetchOrLog(
            descriptor,
            operation: "\(operation)の全セット取得"
        ) else {
            return nil
        }

        return synchronize(allSets: allSets)
    }

    /// 取得済みセットからストリークを計算して同期する。
    @discardableResult
    static func synchronize(allSets: [WorkoutSet]) -> Int {
        let currentStreak = StreakTracker.calculate(sets: allSets).current
        synchronize(allSets: allSets, currentStreak: currentStreak)
        return currentStreak
    }

    /// 呼び出し元で計算済みのストリークを再利用して同期する。
    static func synchronize(allSets: [WorkoutSet], currentStreak: Int) {
        BuffitoWidgetBridge.update(
            trainingDays: BuffitoMoodMeter.trainingDays(from: allSets),
            lastWorkoutDate: allSets.map(\.date).max(),
            currentStreak: currentStreak
        )
    }
}
