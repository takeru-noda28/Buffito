//
//  BuffitoWidgetBridge.swift
//  MuscleApp
//
//  アプリ→ウィジェットのデータ受け渡し。
//  SwiftDataストア本体は共有せず、ムード計算に必要な最小情報（直近のトレ日と
//  ストリーク）だけをApp Group共有UserDefaultsにスナップショットとして書く。
//  ムードは決定的に再計算できるため、ウィジェット側で未来日の予測もできる。
//  このファイルはアプリ・ウィジェット両ターゲットに含める。
//

import Foundation
import WidgetKit

struct BuffitoWidgetSnapshot: Codable {
    // startOfDay正規化済みのトレ日（直近のムード計算窓+余裕分）
    let trainingDays: [Date]
    let currentStreak: Int
    let updatedAt: Date
}

enum BuffitoWidgetBridge {
    static let appGroupID = "group.com.n.musclapp.MuscleApp"
    private static let snapshotKey = "buffito_widget_snapshot"
    // ムード計算窓30日+タイムライン先読み分をカバーする保存範囲
    private static let keepDays = 45

    // アプリ側から呼ぶ：スナップショット保存 + ウィジェット再描画依頼
    static func update(trainingDays: Set<Date>, currentStreak: Int) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            AppLog.widget.error("App Group UserDefaultsを開けませんでした: \(appGroupID, privacy: .public)")
            return
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let cutoff = calendar.date(byAdding: .day, value: -keepDays, to: today) ?? today
        let recentDays = trainingDays.filter { $0 >= cutoff }.sorted()

        let snapshot = BuffitoWidgetSnapshot(
            trainingDays: recentDays,
            currentStreak: currentStreak,
            updatedAt: Date()
        )

        do {
            let data = try JSONEncoder().encode(snapshot)
            defaults.set(data, forKey: snapshotKey)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            AppLog.widget.error("ウィジェットスナップショットの保存失敗: \(error.localizedDescription, privacy: .public)")
        }
    }

    // ウィジェット側から呼ぶ：スナップショット読み込み（未設定ならnil）
    static func load() -> BuffitoWidgetSnapshot? {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: snapshotKey) else {
            return nil
        }
        do {
            return try JSONDecoder().decode(BuffitoWidgetSnapshot.self, from: data)
        } catch {
            AppLog.widget.error("ウィジェットスナップショットの読み込み失敗: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
}
