//
//  Sound.swift
//  NYAC
//
//  Created by Vrz on 18/11/26.
//

import Foundation

/// Every sound the game plays. The raw value is the name of the audio file in the project, without its extension
/// ("bgm" is bgm.mp3, bgm.wav, ...). A sound whose file is not in the project yet is just silent (see SoundService).
enum Sound: String, CaseIterable {
    /// The music of the main screen and its settings. It loops.
    case bgm

    /// Any UI button (PillButton and BoardButton).
    case click

    /// The run ended: the player won, or lost (caught, or time is up).
    case win, lose

    /// The head went above the threshold (peek), or came back under it (focus).
    case peekUp = "peekup"
    case peekDown = "peekdown"

    /// A key typed in Study (right or wrong), and a key deleted.
    case typing = "type"
    case backspace

    /// The chicken hops, gets hit by a car, falls in the river.
    case hop, hit, drown

    /// The lecturer walks from one spot to another (see SoundConfig.footsteps for how it is played).
    case footsteps

    /// The file name to look for.
    var assetName: String { rawValue }
}
