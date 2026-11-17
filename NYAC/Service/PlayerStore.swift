//
//  PlayerStore.swift
//  NYAC
//
//  Created by Vrz on 17/11/26.
//

import Foundation

/// Everything the game remembers between launches: the player's settings, how many games they have played and their
/// best completion time. It only reads and writes (in UserDefaults), what the numbers mean is up to the view models.
///
/// Only the best completion time ever reaches the player (on the game over screen). The games played count is for the
/// code, for example to start a tutorial while `gamesPlayed` is still 0.
///
/// While testing, `resetProgress()` forgets the games played and the best time, so a first win (or a "new best") can be tried again.
@MainActor
final class PlayerStore {

    private let defaults: UserDefaults

    /// `defaults` is where it keeps things. Another one (a UserDefaults(suiteName:)) keeps previews and tests apart from the real data.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private enum Key {
        static let thresholdY = "settings.thresholdY"
        static let sensitivity = "settings.sensitivity"
        static let cameraID = "settings.cameraID"
        static let gamesPlayed = "progress.gamesPlayed"
        static let bestCompletionTime = "progress.bestCompletionTime"
    }

    // MARK: - Settings

    /// Puts the saved settings into `settings`. A value that was never saved keeps its default,
    /// and a saved one is kept inside its range (so a range that shrinks later cannot leave a value outside it).
    func load(into settings: GameSettings) {
        if let saved = number(for: Key.thresholdY) {
            settings.thresholdY = Self.clamped(CGFloat(saved), to: GameSettings.thresholdYRange)
        }
        if let saved = number(for: Key.sensitivity) {
            settings.sensitivity = Self.clamped(CGFloat(saved), to: GameSettings.sensitivityRange)
        }
        // The camera is kept even when it is not plugged in right now: it is used again as soon as it is back.
        settings.cameraID = defaults.string(forKey: Key.cameraID)
    }

    /// Saves the settings as they are now.
    func save(_ settings: GameSettings) {
        defaults.set(Double(settings.thresholdY), forKey: Key.thresholdY)
        defaults.set(Double(settings.sensitivity), forKey: Key.sensitivity)
        if let cameraID = settings.cameraID {
            defaults.set(cameraID, forKey: Key.cameraID)
        } else {
            defaults.removeObject(forKey: Key.cameraID)
        }
    }

    // MARK: - Games played

    /// How many games have been played. 0 until the first one starts.
    var gamesPlayed: Int {
        max(0, defaults.integer(forKey: Key.gamesPlayed))
    }

    /// Counts one more game played.
    func countGamePlayed() {
        defaults.set(gamesPlayed + 1, forKey: Key.gamesPlayed)
    }

    // MARK: - Best completion time

    /// The fastest win so far, in seconds. Nil until the player has won once.
    var bestCompletionTime: TimeInterval? {
        guard let seconds = number(for: Key.bestCompletionTime), seconds > 0 else { return nil }
        return seconds
    }

    func saveBestCompletionTime(_ seconds: TimeInterval) {
        defaults.set(seconds, forKey: Key.bestCompletionTime)
    }

    // MARK: - Testing

    /// Forgets the games played and the best completion time (not the settings). Nothing in the game calls this.
    /// To start from a clean slate while testing, call it once, for example at the end of `AppViewModel.init(store:)`, then remove it.
    func resetProgress() {
        defaults.removeObject(forKey: Key.gamesPlayed)
        defaults.removeObject(forKey: Key.bestCompletionTime)
    }

    // MARK: - Helpers

    /// A saved number, or nil if there is none (or it is not a usable number).
    private func number(for key: String) -> Double? {
        guard let value = defaults.object(forKey: key) as? Double, value.isFinite else { return nil }
        return value
    }

    private static func clamped(_ value: CGFloat, to range: ClosedRange<CGFloat>) -> CGFloat {
        min(max(value, range.lowerBound), range.upperBound)
    }
}
