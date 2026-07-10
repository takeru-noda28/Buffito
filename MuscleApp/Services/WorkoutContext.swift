//
//  WorkoutContext.swift
//  MuscleApp
//

import Foundation
import SwiftData
import Observation

// 直近に追加されたセットを記憶（タイマーの自動紐付け用）
@Observable
final class WorkoutContext {
    static let shared = WorkoutContext()

    var lastSetID: PersistentIdentifier? = nil
    var lastExerciseName: String? = nil
    var lastBodyPart: BodyPart? = nil
    var lastSetNumber: Int? = nil
    var lastAddedAt: Date? = nil
    // ユーザーが「違う」と却下した場合のフラグ
    var isDismissed: Bool = false

    // 「最近」の閾値（5分以内）
    static let recentThreshold: TimeInterval = 300

    private init() {}

    func updateAfterAddingSet(exercise: Exercise, setID: PersistentIdentifier, setNumber: Int) {
        lastSetID = setID
        lastExerciseName = exercise.name
        lastBodyPart = exercise.bodyPart
        lastSetNumber = setNumber
        lastAddedAt = Date()
        isDismissed = false
    }

    func dismiss() {
        isDismissed = true
    }

    func clear() {
        lastSetID = nil
        lastExerciseName = nil
        lastBodyPart = nil
        lastSetNumber = nil
        lastAddedAt = nil
        isDismissed = false
    }

    // 「最近活動した」と判定
    var isRecent: Bool {
        guard let addedAt = lastAddedAt, !isDismissed else { return false }
        return Date().timeIntervalSince(addedAt) < Self.recentThreshold
    }
}
