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

    /// How the progress card in the HUD words this objective.
    var title: String {
        switch self {
        case .study:    return "Take the notes"
        case .minigame: return "Finish the game"
        }
    }
}
