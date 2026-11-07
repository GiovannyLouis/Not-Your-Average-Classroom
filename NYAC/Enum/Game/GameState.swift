//
//  GameState.swift
//  NYAC
//
//  Created by Vrz on 05/11/26.
//


/// Where one run of the game is at.
enum GameState: Equatable {
    /// Getting ready: the study text is being written and the camera is starting. The clock has not started yet.
    case preparing

    /// Everything is ready and the game is counting down to the start: 3, 2, 1. The clock has not started yet.
    case countdown(Int)

    /// The clock is running and the player is in the game.
    case running

    /// The run is over. The result says how it ended.
    case ended(GameResult)
}
