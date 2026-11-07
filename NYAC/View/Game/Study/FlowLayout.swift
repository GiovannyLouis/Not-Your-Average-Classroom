//
//  FlowLayout.swift
//  NYAC
//
//  Created by Vrz on 29/10/26.
//

import SwiftUI

/// Places its children left to right and wraps them onto a new row when they run out of width,
/// the same way text wraps. Used so each word can be its own view (and scroll target).
struct FlowLayout: Layout {
    var rowSpacing: CGFloat = 14

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let proposedWidth = proposal.width.flatMap { $0.isFinite ? $0 : nil }
        let result = arrange(subviews, maxWidth: proposedWidth ?? .infinity)
        return CGSize(width: proposedWidth ?? result.size.width, height: result.size.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(subviews, maxWidth: bounds.width)
        for (subview, point) in zip(subviews, result.points) {
            subview.place(
                at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(_ subviews: Subviews, maxWidth: CGFloat) -> (points: [CGPoint], size: CGSize) {
        var points: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var usedWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + rowSpacing
                rowHeight = 0
            }

            points.append(CGPoint(x: x, y: y))
            x += size.width
            usedWidth = max(usedWidth, x)
            rowHeight = max(rowHeight, size.height)
        }

        return (points, CGSize(width: usedWidth, height: y + rowHeight))
    }
}
