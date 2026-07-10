//
//  RestSession.swift
//  MuscleApp
//

import Foundation
import SwiftData
import Observation

// 進行中のレストタイマーを管理（ExerciseDetailViewとTimerViewで共有）
@Observable
final class RestSession {
    static let shared = RestSession()

    var startDate: Date? = nil
    var endDate: Date? = nil
    var exerciseName: String? = nil
    var bodyPart: BodyPart? = nil
    var setNumber: Int? = nil
    var setID: PersistentIdentifier? = nil

    var isActive: Bool { endDate != nil }

    private init() {}

    func start(exercise: Exercise, setNumber: Int, setID: PersistentIdentifier, durationSeconds: Int) {
        startDate = Date()
        endDate = Date().addingTimeInterval(TimeInterval(durationSeconds))
        exerciseName = exercise.name
        bodyPart = exercise.bodyPart
        self.setNumber = setNumber
        self.setID = setID
    }

    func clear() {
        startDate = nil
        endDate = nil
        exerciseName = nil
        bodyPart = nil
        setNumber = nil
        setID = nil
    }

    // 現在時刻時点での残り秒数
    func remainingSeconds(now: Date) -> Int? {
        guard let endDate = endDate else { return nil }
        return max(0, Int(ceil(endDate.timeIntervalSince(now))))
    }

    // 経過秒数（タイマー開始からの実時間）
    var elapsedSeconds: Int? {
        guard let startDate = startDate else { return nil }
        return Int(Date().timeIntervalSince(startDate))
    }
}
