//
//  Obstacle.swift
//  NYAC
//
//  Created by Vrz on 28/10/26.
//

import Foundation

/// A car (on a road) or a log (on a river). `x` is its center.
struct Obstacle: Identifiable {
    let id = UUID()
    var x: CGFloat
    let width: CGFloat
    let variant = Int.random(in: 0..<3)        // picks the car color, ignored for logs
}
