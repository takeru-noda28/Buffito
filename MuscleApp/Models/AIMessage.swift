//
//  AIMessage.swift
//  MuscleApp
//

import Foundation
import SwiftData

// AIチャットのメッセージ履歴を端末内に保存する
@Model
final class AIMessage {
    var roleRaw: String
    var content: String
    var timestamp: Date

    init(role: AIMessageRole, content: String, timestamp: Date = Date()) {
        self.roleRaw = role.rawValue
        self.content = content
        self.timestamp = timestamp
    }

    var role: AIMessageRole {
        AIMessageRole(rawValue: roleRaw) ?? .user
    }
}

enum AIMessageRole: String, Codable {
    case user
    case assistant
}
