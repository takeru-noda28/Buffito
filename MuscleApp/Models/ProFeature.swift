//
//  ProFeature.swift
//  MuscleApp
//
//  Pro限定にできる機能のカタログ。
//  新しいPro機能を追加する／既存機能をProに変える時は、ここにcaseを足して
//  該当箇所を PremiumManager.shared.isUnlocked(...) でゲートする。
//

import Foundation

enum ProFeature: CaseIterable {
    case timerCenterImage   // タイマー中央画像
    case timerProThemes     // タイマーテーマカラー（デフォルト以外の色）
    case restTracking       // レスト自動判定・記録・編集
    case aiUnlimitedChat    // AIチャット無制限（サーバー側のレシート検証とセットで有効化する）
}
