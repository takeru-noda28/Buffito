//
//  WorkoutSet.swift
//  MuscleApp
//

import SwiftData
import Foundation

// 1セットの記録（重量・回数）
@Model
final class WorkoutSet {
    var weight: Double = 0
    var reps: Int = 0
    var date: Date = Date()
    var restSeconds: Int? = nil
    var exercise: Exercise?

    init(weight: Double, reps: Int, date: Date = Date(), restSeconds: Int? = nil) {
        self.weight = weight
        self.reps = reps
        self.date = date
        self.restSeconds = restSeconds
    }
}
