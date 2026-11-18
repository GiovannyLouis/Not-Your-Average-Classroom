//
//  SoundConfig.swift
//  NYAC
//
//  Created by Vrz on 18/11/26.
//


import Foundation

/// Everything about the sound you may want to tweak, in one place.
enum SoundConfig {

    /// Flip this to silence the whole game while you work on it.
    static let isMuted = false

    // MARK: - Volume

    /// How loud each sound is, 0...1 (the Mac's own volume comes on top of it).
    /// If a file is recorded too loud or too quiet, fix it here instead of re-exporting it.
    static func volume(of sound: Sound) -> Float {
        switch sound {
        case .bgm:        return 0.45
        case .click:      return 0.7
        case .win:        return 0.9
        case .lose:       return 0.9
        case .peekUp:     return 0.6
        case .peekDown:   return 0.6
        case .typing:     return 0.5
        case .backspace:  return 0.5
        case .hop:        return 0.6
        case .hit:        return 0.8
        case .drown:      return 0.8
        case .footsteps:  return 0.6
        }
    }

    // MARK: - Music

    /// Seconds the menu music takes to fade in when the main screen comes up, and to fade out when a run starts.
    static let musicFadeIn: TimeInterval = 1.0
    static let musicFadeOut: TimeInterval = 0.6

    // MARK: - Overlapping

    /// How many copies of the same sound may play at once. Fast typing, or a few hops in a row, play over each other
    /// instead of cutting each other off. When all of them are busy, the one that is furthest along is restarted.
    static let maxOverlap = 4

    // MARK: - Footsteps

    /// How the footsteps file is played while the lecturer walks.
    enum FootstepsPlayback {
        /// The file is looped for as long as the walk lasts and stops when he arrives. Use this when footsteps.* is
        /// a recording of several steps in a row. (Its own tempo is the file's: it does not follow stepsPerSecond.)
        case loop

        /// The file is played once for every step, at the tempo of LecturerConfig.stepsPerSecond, at the moment
        /// each step touches the ground (the lowest point of his bounce). Use this when footsteps.* is ONE step.
        case perStep
    }

    static let footsteps: FootstepsPlayback = .perStep

    /// Seconds the looped footsteps take to fade out when he arrives (so the loop is not cut dead). Only for `.loop`.
    static let footstepsFadeOut: TimeInterval = 0.2
}
