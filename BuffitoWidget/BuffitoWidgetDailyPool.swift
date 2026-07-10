//
//  BuffitoWidgetDailyPool.swift
//  BuffitoWidgetExtension
//
//  「プールから日替わりで1つ選ぶ」共通ヘルパ。
//  ウィジェットのタイムラインは未来分を事前生成するため、真の乱数ではなく
//  日付から決定的に選ぶ（＝リロードのたびに変わらず、日が変わると入れ替わる）。
//  セリフ・画像など複数のプールで使う。saltを変えるとプール間で回り方がずれる。
//

import Foundation

enum BuffitoWidgetDailyPool {
    static func pick<T>(from pool: [T], on date: Date, salt: Int = 0) -> T? {
        guard !pool.isEmpty else { return nil }
        let dayIndex = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        return pool[(dayIndex &+ salt &* 17) % pool.count]
    }
}
