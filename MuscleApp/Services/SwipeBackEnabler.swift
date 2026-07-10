//
//  SwipeBackEnabler.swift
//  MuscleApp
//
//  カスタム戻るボタンを使っているNavigationStackでも、
//  左端からの右スワイプで前画面に戻れるようにする
//

import UIKit

extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // ルート画面ではスワイプを無効化（戻る先がないため）
        return viewControllers.count > 1
    }
}
