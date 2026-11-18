//
//  ShakeEffect.swift
//  NYAC
//
//  Created by Vrz on 18/11/26.
//

import SwiftUI

/// Shakes a view from side to side. It only moves the view's picture: its place in the layout stays where it is.
///
/// `phase` is the whole of the control: every time it goes up by 1 (animated), the view makes one shake that dies down
/// and ends exactly where it started. So a shake is started by animating `phase` from n to n + 1, and another one
/// started in the middle of a shake just carries on from where the first one is.
///
///     view.modifier(ShakeEffect(travel: 8, cycles: 3, phase: shakes))
///     withAnimation(.linear(duration: 0.3)) { shakes += 1 }
nonisolated struct ShakeEffect: GeometryEffect {
    /// How far the view swings to each side at the start of a shake, in points.
    var travel: CGFloat

    /// How many swings (there and back) one shake has. A whole number.
    var cycles: CGFloat

    var phase: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        // The whole part of the phase says which shake it is, the rest says how far through that shake we are (0...1).
        let progress = phase - phase.rounded(.down)
        let dying = 1 - progress
        let x = travel * dying * sin(2 * CGFloat.pi * cycles * progress)
        return ProjectionTransform(CGAffineTransform(translationX: x, y: 0))
    }
}
