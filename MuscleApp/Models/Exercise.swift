//
//  Exercise.swift
//  MuscleApp
//

import SwiftData
import Foundation

// 種目（ベンチプレスなど）。SwiftDataで端末に保存される
@Model
final class Exercise {
    var name: String = ""
    var bodyPartRaw: String = ""
    var isDefault: Bool = false
    var sortOrder: Int = 0
    var createdAt: Date = Date()
    var memo: String = ""

    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.exercise)
    var sets: [WorkoutSet] = []

    init(name: String, bodyPart: BodyPart, isDefault: Bool = false, sortOrder: Int = 0) {
        self.name = name
        self.bodyPartRaw = bodyPart.rawValue
        self.isDefault = isDefault
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }

    var bodyPart: BodyPart {
        BodyPart(rawValue: bodyPartRaw) ?? .chest
    }
}
