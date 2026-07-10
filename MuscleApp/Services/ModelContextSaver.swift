//
//  ModelContextSaver.swift
//  MuscleApp
//
//  SwiftDataの保存・フェッチのエラーを握りつぶさないための共通ヘルパー。
//  規約：`try?` でエラーを捨てず、最低限ログを出す。
//

import SwiftData

extension ModelContext {
    /// 保存を試み、失敗したらログに出す。呼び出し元を特定できるよう操作名を渡す
    /// - Parameter operation: 何の保存か（例：「セット追加」「休憩秒数の記録」）
    /// - Returns: 保存に成功したら true
    @discardableResult
    func saveOrLog(_ operation: String) -> Bool {
        do {
            try save()
            return true
        } catch {
            AppLog.swiftData.error("保存失敗（\(operation, privacy: .public)）: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    /// フェッチを試み、失敗したらログに出して nil を返す。
    /// 呼び出し側は従来の `try?` と同じ感覚で optional として扱える
    /// - Parameter operation: 何のフェッチか（例：「今日のセット取得」）
    func fetchOrLog<T: PersistentModel>(_ descriptor: FetchDescriptor<T>, operation: String) -> [T]? {
        do {
            return try fetch(descriptor)
        } catch {
            AppLog.swiftData.error("フェッチ失敗（\(operation, privacy: .public)）: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
}
