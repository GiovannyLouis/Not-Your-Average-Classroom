//
//  MinigameState.swift
//  NYAC
//
//  Created by Vrz on 28/10/26.
//

enum MinigameState: Equatable {
    case ready                 // level built, waiting for the first move
    case playing               // clock is running
    case ended(Outcome)        // short result pause, then a fresh run starts by itself
}
