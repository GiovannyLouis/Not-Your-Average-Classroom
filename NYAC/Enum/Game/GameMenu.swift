//
//  GameMenu.swift
//  NYAC
//
//  Created by Vrz on 07/11/26.
//


/// The menu the player opens in game with Escape. It is not a pause: the game keeps running behind it.
enum GameMenu {
    case closed

    /// The two buttons: Settings and Back to Lobby.
    case main

    case settings
}
