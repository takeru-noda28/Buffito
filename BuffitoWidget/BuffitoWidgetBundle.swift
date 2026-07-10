//
//  BuffitoWidgetBundle.swift
//  BuffitoWidgetExtension
//
//  ウィジェットのエントリポイント。
//

import SwiftUI
import WidgetKit

@main
struct BuffitoWidgetBundle: WidgetBundle {
    var body: some Widget {
        BuffitoStatusWidget()
    }
}
