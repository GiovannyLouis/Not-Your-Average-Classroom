//
//  MinigameState.swift
//  NYAC
//
//  Created by Vrz on 28/10/26.
//

enum MinigameState: Equatable {
    case ready                 // level built, waiting for the first move
    case playing               // clock is running
    case ended(Outcome)        // over: the chicken cannot move, but the world goes on.
                               // After a death a fresh run starts by itself, a win stays as it is
}
