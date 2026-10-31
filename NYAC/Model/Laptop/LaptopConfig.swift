//
//  LaptopConfig.swift
//  NYAC
//
//  Created by Vrz on 30/10/26.
//


import Foundation

enum LaptopConfig {
    /// One clock for the whole laptop: Study and Minigame both have to be done inside it.
    static let timeLimit: TimeInterval = 300

    /// The tab that is on screen when the game starts.
    static let startingTab: LaptopTab = .study
}
