//
//  BuffitoSpeechBubble.swift
//  MuscleApp
//
//  Buffitoのセリフ吹き出し。
//  しっぽの向きを切り替えて、ホーム（キャラが左）とヒーローカード（キャラが上）で共用する。
//

import SwiftUI

struct BuffitoSpeechBubble: View {
    enum TailEdge {
        case leading  // キャラが左にいる（ホームのコンパクトカード）
        case top      // キャラが上にいる（ヒーローカード）
    }

    let text: String
    let tailEdge: TailEdge

    private static let bubbleColor = Color.appField

    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundColor(.appTextPrimary)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Self.bubbleColor)
            )
            .overlay(alignment: tailAlignment) {
                TailTriangle(edge: tailEdge)
                    .fill(Self.bubbleColor)
                    .frame(width: tailSize.width, height: tailSize.height)
                    .offset(tailOffset)
            }
    }

    private var tailAlignment: Alignment {
        switch tailEdge {
        case .leading: return .leading
        case .top: return .top
        }
    }

    private var tailSize: CGSize {
        switch tailEdge {
        case .leading: return CGSize(width: 9, height: 14)
        case .top: return CGSize(width: 14, height: 9)
        }
    }

    private var tailOffset: CGSize {
        switch tailEdge {
        case .leading: return CGSize(width: -8, height: 0)
        case .top: return CGSize(width: 0, height: -8)
        }
    }

    // 吹き出しのしっぽ（キャラ側に尖る三角形）
    private struct TailTriangle: Shape {
        let edge: TailEdge

        func path(in rect: CGRect) -> Path {
            var path = Path()
            switch edge {
            case .leading:
                path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            case .top:
                path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
            }
            path.closeSubpath()
            return path
        }
    }
}
