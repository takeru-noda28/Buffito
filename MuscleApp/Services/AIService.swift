//
//  AIService.swift
//  MuscleApp
//

import Foundation
import UIKit

enum AIServiceError: LocalizedError {
    case networkError
    case rateLimitExceeded(limit: Int, resetAt: Date)
    case invalidEndpoint
    case invalidResponse
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .networkError:
            return "ネットワークに接続できません"
        case .rateLimitExceeded(let limit, _):
            return "今日の利用回数（\(limit)回）を超えました"
        case .invalidEndpoint:
            return "AIサーバーのURL設定が正しくありません"
        case .invalidResponse:
            return "サーバーからの応答が不正です"
        case .serverError(let message):
            return message
        }
    }
}

struct AIResponse {
    let reply: String
    let remaining: Int
    let limit: Int
}

final class AIService {
    static let shared = AIService()

    private let session: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let fallbackDeviceIdKey = "ai_fallback_device_id"

    private init(session: URLSession = .shared) {
        self.session = session
    }

    private var endpoint: String {
        Bundle.main.object(forInfoDictionaryKey: "AIBackendURL") as? String
            ?? "https://buffito-ai-proxy.buffito.workers.dev/api/chat"
    }

    private var deviceId: String {
        if let idfv = UIDevice.current.identifierForVendor?.uuidString {
            return idfv
        }
        if let storedId = UserDefaults.standard.string(forKey: fallbackDeviceIdKey) {
            return storedId
        }

        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: fallbackDeviceIdKey)
        return newId
    }

    func sendMessage(_ message: String, context: AIWorkoutContext, isPro: Bool) async throws -> AIResponse {
        guard let url = URL(string: endpoint) else {
            throw AIServiceError.invalidEndpoint
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(
            RequestBody(deviceId: deviceId, message: message, context: context, isPro: isPro)
        )

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            AppLog.network.error("AI通信失敗: \(error.localizedDescription, privacy: .public)")
            throw AIServiceError.networkError
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        if httpResponse.statusCode == 429 {
            // エラーボディの解析は精一杯の努力でよい（失敗してもフォールバック値で通知できる）
            let errorBody = decodeErrorBody(
                RateLimitErrorBody.self,
                from: data,
                operation: "利用上限エラー応答の解析"
            )
            let resetAt = errorBody?.resetAt.flatMap { ISO8601DateFormatter().date(from: $0) } ?? Date()
            throw AIServiceError.rateLimitExceeded(limit: errorBody?.limit ?? 0, resetAt: resetAt)
        }

        guard httpResponse.statusCode == 200 else {
            // エラーボディの解析は精一杯の努力でよい（失敗時は汎用メッセージを使う）
            let errorBody = decodeErrorBody(
                ErrorBody.self,
                from: data,
                operation: "サーバーエラー応答の解析"
            )
            throw AIServiceError.serverError(errorBody?.message ?? "エラーが発生しました")
        }

        let decoded: SuccessBody
        do {
            decoded = try decoder.decode(SuccessBody.self, from: data)
        } catch {
            AppLog.network.error("AI応答解析失敗: \(error.localizedDescription, privacy: .public)")
            throw AIServiceError.invalidResponse
        }

        return AIResponse(reply: decoded.reply, remaining: decoded.remaining, limit: decoded.limit)
    }

    private func decodeErrorBody<Body: Decodable>(
        _ type: Body.Type,
        from data: Data,
        operation: String
    ) -> Body? {
        do {
            return try decoder.decode(type, from: data)
        } catch {
            AppLog.network.error(
                "\(operation, privacy: .public)失敗: \(error.localizedDescription, privacy: .public)"
            )
            return nil
        }
    }
}

private struct RequestBody: Encodable {
    let deviceId: String
    let message: String
    let context: AIWorkoutContext
    let isPro: Bool
}

private struct SuccessBody: Decodable {
    let reply: String
    let remaining: Int
    let limit: Int
}

private struct ErrorBody: Decodable {
    let error: String?
    let message: String?
}

private struct RateLimitErrorBody: Decodable {
    let error: String?
    let message: String?
    let limit: Int?
    let resetAt: String?
}
