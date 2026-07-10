//
//  BuffitoWidgetImageBank.swift
//  BuffitoWidgetExtension
//
//  ウィジェットに表示するBuffito画像のプール。
//  ★ウィジェット専用画像を増やしたら、該当ムードの配列にアセット名を
//    追記するだけで日替わり表示の候補に入る（コードの他の箇所は変更不要）。
//  Assets.xcassetsに未登録の名前は自動で候補から外れるので、先に名前だけ
//  書いておいても安全。
//

import Foundation
import UIKit

enum BuffitoWidgetImageBank {
    private static func assetNames(for mood: BuffitoMood) -> [String] {
        switch mood {
        case .fired:
            return ["buffito_fired"]
        case .happy:
            return ["buffito_happy"]
        case .normal:
            return ["buffito_normal"]
        case .lonely:
            return ["buffito_lonely"]
        case .clingy:
            return ["buffito_clingy"]
        case .darkside:
            return ["buffito_darkside"]
        }
    }

    // 日替わりで1枚選ぶ。全滅（未登録のみ）ならnil＝呼び出し側が絵文字にフォールバック
    static func dailyAssetName(for mood: BuffitoMood, on date: Date) -> String? {
        let available = assetNames(for: mood).filter { UIImage(named: $0) != nil }
        return BuffitoWidgetDailyPool.pick(from: available, on: date, salt: 1)
    }
}
