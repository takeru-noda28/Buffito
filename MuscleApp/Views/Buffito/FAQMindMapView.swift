//
//  FAQMindMapView.swift
//  MuscleApp
//
//  よくある質問のマインドマップ表示。
//  中央のBuffitoアバターから放射状にFAQノードを配置し、タップで回答シートを開く。
//

import SwiftUI

struct FAQMindMapView: View {
    let chips: [FAQChip]
    let onSelect: (FAQChip) -> Void

    private static let mapHeight: CGFloat = 300
    private static let avatarSize: CGFloat = 60
    // ノードが端で見切れないよう、半径から差し引く余白
    private static let nodeMargin: CGFloat = 48

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2 - Self.nodeMargin

            ZStack {
                branchLines(center: center, radius: radius)
                    .stroke(Color.appBorder, lineWidth: 1)

                buffitoAvatar
                    .position(center)

                ForEach(Array(chips.enumerated()), id: \.element.id) { index, chip in
                    nodeButton(chip)
                        .position(nodePosition(at: index, center: center, radius: radius))
                }
            }
        }
        .frame(height: Self.mapHeight)
    }

    // MARK: - 配置計算（真上から時計回りに等間隔）

    private func nodeAngle(at index: Int) -> CGFloat {
        (2 * .pi / CGFloat(chips.count)) * CGFloat(index) - .pi / 2
    }

    private func nodePosition(at index: Int, center: CGPoint, radius: CGFloat) -> CGPoint {
        let angle = nodeAngle(at: index)
        return CGPoint(
            x: center.x + radius * cos(angle),
            y: center.y + radius * sin(angle)
        )
    }

    private func branchLines(center: CGPoint, radius: CGFloat) -> Path {
        Path { path in
            for index in chips.indices {
                path.move(to: center)
                path.addLine(to: nodePosition(at: index, center: center, radius: radius))
            }
        }
    }

    // MARK: - 部品

    private var buffitoAvatar: some View {
        Image("BuffitoAvatar")
            .resizable()
            .scaledToFill()
            .frame(width: Self.avatarSize, height: Self.avatarSize)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.orange.opacity(0.6), lineWidth: 1.5))
    }

    private func nodeButton(_ chip: FAQChip) -> some View {
        Button {
            onSelect(chip)
        } label: {
            Text(chip.label)
                .font(.caption)
                .foregroundColor(.appTextPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.appField))
                .overlay(Capsule().stroke(Color.appBorder, lineWidth: 0.5))
        }
    }
}
