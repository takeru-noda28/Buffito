//
//  AppLog.swift
//  MuscleApp
//
//  アプリ共通のロガー。
//  規約：エラーを握りつぶさず、最低限ここのロガーで記録する。
//  Console.app や Xcode コンソールで subsystem "com.buffito.MuscleApp" を
//  フィルタすると確認できる。
//

import os

enum AppLog {
    private static let subsystem = "com.buffito.MuscleApp"

    /// SwiftData（保存・フェッチ）関連
    static let swiftData = Logger(subsystem: subsystem, category: "SwiftData")
    /// 画像の保存・読み込み関連
    static let media = Logger(subsystem: subsystem, category: "Media")
    /// アラーム音・オーディオセッション関連
    static let audio = Logger(subsystem: subsystem, category: "Audio")
    /// ネットワーク・外部API関連
    static let network = Logger(subsystem: subsystem, category: "Network")
    /// ホーム画面ウィジェット関連
    static let widget = Logger(subsystem: subsystem, category: "Widget")
}
