//
//  PremiumManager.swift
//  MuscleApp
//
//  Pro機能の解放判定を一元管理する。
//  機能側は isPremium を直接見ず、必ず isUnlocked(_:) を通すこと。
//

import Observation

@Observable
final class PremiumManager {
    static let shared = PremiumManager()

    // Pro販売スイッチ。StoreKit導入まで false ＝ Pro導線（Paywall・比較表・王冠バッジ）を
    // 出さず全機能を開放する。課金開始時に true へ切り替えるだけで、
    // 各画面のロックと導線が一斉に有効になる。
    static let isSalesEnabled = false

    // 購入状態（StoreKit導入までは設定のテスト用トグルでのみ変わる）
    var isPremium: Bool = false

    // 機能の解放判定。将来は機能ごとの無料開放やトライアルもここで制御する
    func isUnlocked(_ feature: ProFeature) -> Bool {
        // 販売開始前は全機能開放（購入手段がないのにロックしない）
        guard Self.isSalesEnabled else { return true }
        return isPremium
    }

    private init() {}
}
