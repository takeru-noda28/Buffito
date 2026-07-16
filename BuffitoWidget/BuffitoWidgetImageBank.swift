//
//  BuffitoWidgetImageBank.swift
//  BuffitoWidgetExtension
//
//  ウィジェットに表示するBuffito画像のプール。
//  smallは最終記録から14時間未満のA群と、それ以降のB群から日替わりで選ぶ。
//  mediumはムード別の共有透過キャラ画像を使う。
//  smallの候補を増やす場合は、該当するA/B配列へアセット名を追記する。
//  アセットカタログに未登録の名前は自動で候補から外れる。
//

import Foundation
import UIKit

enum BuffitoWidgetImageGroup {
    case recentWorkout
    case workoutOverdue
}

enum BuffitoWidgetImageBank {
    // WidgetKitのアーカイブ上限を超えないよう、smallへ直接表示する画像は768px四方以下にする
    private static let recentWorkoutAssetNames = [
        "buffito_fired",
        "buffito_happy",
        "buffito_widget_happy_sleep_bowl_cutout"
    ]

    private static let workoutOverdueAssetNames = [
        "buffito_lonely",
        "buffito_clingy",
        "buffito_darkside",
        "buffito_widget_darkside_loading_cutout"
    ]

    // small用。再読み込みで画像がぶれないよう、日付ベースの疑似ランダムで選ぶ
    static func dailySmallAssetName(
        for group: BuffitoWidgetImageGroup,
        on date: Date
    ) -> String? {
        switch group {
        case .recentWorkout:
            let available = existingAssetNames(in: recentWorkoutAssetNames)
            return BuffitoWidgetDailyPool.pick(
                from: available,
                on: date,
                salt: 11
            )
        case .workoutOverdue:
            let available = existingAssetNames(in: workoutOverdueAssetNames)
            return BuffitoWidgetDailyPool.pickDailyWithoutRepeating(
                from: available,
                on: date,
                salt: 29
            )
        }
    }

    // mediumでは背景が四角く出ないよう、従来の透過キャラ画像だけを使う
    static func compactAssetName(for mood: BuffitoMood) -> String? {
        existingAssetName(mood.assetName)
    }

    static func existingAssetName(_ assetName: String) -> String? {
        existingAssetNames(in: [assetName]).first
    }

    private static func existingAssetNames(in assetNames: [String]) -> [String] {
        assetNames.filter { UIImage(named: $0) != nil }
    }
}
