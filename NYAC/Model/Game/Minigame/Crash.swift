//
//  Crash.swift
//  NYAC
//
//  Created by Vrz on 19/11/26.
//


import Foundation

/// How the chicken was hit by a car. The scene keeps the flattened chicken stuck to that car until the restart.
struct Crash {
    let obstacleID: UUID                       // the car that hit it
    let side: CrashSide                        // which part of the car it ran into
    let offset: CGFloat                        // bottom / top: how far from the car's center along it, in cells (0 for the ends)
}
