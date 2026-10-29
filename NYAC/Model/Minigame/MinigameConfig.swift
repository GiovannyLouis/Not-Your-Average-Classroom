//
//  MinigameConfig.swift
//  NYAC
//
//  Created by Vrz on 28/10/26.
//

import Foundation

enum MinigameConfig {
    static let columns = 14
    static let generatedRowCount = 20          // plus a safe row at each end = 22 rows
    static let timeLimit: TimeInterval = 300
    static let restartDelay: TimeInterval = 1.2
    static let playerRadius: CGFloat = 0.3     // chicken size used for car collisions
}
