//
//  BuffitoMoodMeter+WorkoutSet.swift
//  MuscleApp
//
//  WorkoutSet（SwiftData）からムードを計算するアプリ側の入口。
//  ウィジェットターゲットはSwiftDataを持たないため、このファイルはアプリのみに含める。
//

import Foundation

extension BuffitoMoodMeter {
    static func currentMood(allSets: [WorkoutSet], referenceDate: Date = Date()) -> BuffitoMood {
        currentMood(trainingDays: trainingDays(from: allSets), referenceDate: referenceDate)
    }

    static func score(allSets: [WorkoutSet], referenceDate: Date = Date()) -> Int {
        score(trainingDays: trainingDays(from: allSets), referenceDate: referenceDate)
    }

    static func trainingDays(from allSets: [WorkoutSet]) -> Set<Date> {
        let calendar = Calendar.current
        return Set(allSets.map { calendar.startOfDay(for: $0.date) })
    }
}
