//
//  Obstacle.swift
//  NYAC
//
//  Created by Vrz on 28/10/26.
//

import Foundation

/// A car (on a road) or a log (on a river). `x` is its center. What the car looks like is up to its row (Row.car).
struct Obstacle: Identifiable {
    let id = UUID()
    var x: CGFloat
    let width: CGFloat
}
