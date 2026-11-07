//
//  GameObjective.swift
//  NYAC
//
//  Created by Vrz on 05/11/26.
//


/// What the player has to finish to win. Every objective has to be done before the clock runs out.
enum GameObjective: CaseIterable, Hashable {
    case study
    case minigame
}
