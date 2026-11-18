//
//  SoundService.swift
//  NYAC
//
//  Created by Vrz on 18/11/26.
//


import AVFoundation
import AppKit

/// Plays the game's sounds. One for the whole app (`SoundService.shared`), handed to the view models that make sounds.
///
/// There are two kinds of sound:
///  - a one-shot (`play`): a click, a hop, a win. The same sound may overlap itself (see SoundConfig.maxOverlap).
///  - a loop (`startLoop` / `stopLoop`): the menu music, and the lecturer's footsteps. It plays until it is stopped.
///
/// A sound is found by its name (see `Sound`): any audio file with that name in the project, wherever it sits
/// (bgm.mp3, click.wav, ...), or a data asset with that name in Assets.xcassets. While the project does not have the file
/// yet, that sound is simply silent, so a missing asset never breaks anything, and it starts playing as soon as the file is added.
/// In a debug build, the names that were not found are printed once when the app opens.
@MainActor
final class SoundService {

    static let shared = SoundService()

    // MARK: - Finding the files

    /// File types AVAudioPlayer can open. (.ogg is not one of them: convert it to .wav, .mp3 or .m4a.)
    private static let fileExtensions: Set<String> = ["wav", "mp3", "m4a", "aif", "aiff", "aifc", "caf", "aac"]

    private enum Source {
        case file(URL)
        case data(Data)
    }

    /// Where each sound was found. A sound that was not found is in `missing` instead.
    private var sources: [Sound: Source] = [:]
    private var missing: Set<Sound> = []

    /// Every audio file in the app, by lowercased name without extension. Built the first time it is needed.
    /// The whole bundle is searched, so it does not matter which folder of the project a file was dropped in.
    private lazy var fileIndex: [String: URL] = SoundService.makeFileIndex()

    // MARK: - Players

    /// The one-shots: a few players per sound, so a sound can play over itself.
    private var pools: [Sound: [AVAudioPlayer]] = [:]

    /// The loops that are playing now.
    private var loops: [Sound: AVAudioPlayer] = [:]

    init() {
        for sound in Sound.allCases {
            _ = source(for: sound)
        }

        #if DEBUG
        // A typo in a file name shows up here: the sound stays silent and the name it was looking for is printed.
        let notFound = Sound.allCases.filter { missing.contains($0) }.map(\.assetName)
        if !notFound.isEmpty {
            print("SoundService: no audio file found for \(notFound.joined(separator: ", ")), so those sounds stay silent")
        }
        #endif

        // One player per one-shot is made ahead, so the first click or hop does not wait for the file to be read.
        for sound in Sound.allCases where sound != .bgm {
            if let player = makePlayer(for: sound) {
                pools[sound] = [player]
            }
        }
    }

    // MARK: - One-shots

    /// Plays the sound once, from the start.
    func play(_ sound: Sound) {
        guard !SoundConfig.isMuted, let player = availablePlayer(for: sound) else { return }
        player.volume = SoundConfig.volume(of: sound)
        player.currentTime = 0
        player.play()
    }

    /// A player that is not busy, or a new one while the sound has fewer than `maxOverlap`,
    /// or else the busy one that is furthest along (it is cut short and used again).
    private func availablePlayer(for sound: Sound) -> AVAudioPlayer? {
        let pool = pools[sound] ?? []

        if let idle = pool.first(where: { !$0.isPlaying }) {
            return idle
        }
        if pool.count < SoundConfig.maxOverlap, let extra = makePlayer(for: sound) {
            pools[sound] = pool + [extra]
            return extra
        }
        return pool.max(by: { $0.currentTime < $1.currentTime })
    }

    // MARK: - Loops

    /// Starts the sound looping, fading in over `fadeIn` seconds. Does nothing if it is already looping.
    func startLoop(_ sound: Sound, fadeIn: TimeInterval = 0) {
        guard !SoundConfig.isMuted, loops[sound] == nil, let player = makePlayer(for: sound) else { return }

        let volume = SoundConfig.volume(of: sound)
        player.numberOfLoops = -1
        player.volume = fadeIn > 0 ? 0 : volume
        player.play()
        if fadeIn > 0 {
            player.setVolume(volume, fadeDuration: fadeIn)
        }
        loops[sound] = player
    }

    /// Stops the loop, fading out over `fadeOut` seconds. Does nothing if it is not looping.
    func stopLoop(_ sound: Sound, fadeOut: TimeInterval = 0) {
        // The loop is let go of right away, so starting it again during the fade begins a new one.
        guard let player = loops.removeValue(forKey: sound) else { return }

        guard fadeOut > 0 else {
            player.stop()
            return
        }

        player.setVolume(0, fadeDuration: fadeOut)
        Task { [player] in
            try? await Task.sleep(for: .seconds(fadeOut))
            player.stop()
        }
    }

    // MARK: - Making players

    /// A new player for the sound, or nil when the sound has no file (or the file cannot be opened).
    private func makePlayer(for sound: Sound) -> AVAudioPlayer? {
        guard let source = source(for: sound) else { return nil }

        do {
            let player: AVAudioPlayer
            switch source {
            case .file(let url): player = try AVAudioPlayer(contentsOf: url)
            case .data(let data): player = try AVAudioPlayer(data: data)
            }
            player.prepareToPlay()
            return player
        } catch {
            // Found, but not playable (a format AVAudioPlayer does not know). Silent from now on, and said once.
            sources[sound] = nil
            missing.insert(sound)
            #if DEBUG
            print("SoundService: \(sound.assetName) was found but could not be opened (\(error.localizedDescription)), so it stays silent")
            #endif
            return nil
        }
    }

    /// Where the sound's file is, looked up once.
    private func source(for sound: Sound) -> Source? {
        if let known = sources[sound] { return known }
        guard !missing.contains(sound) else { return nil }

        let name = sound.assetName
        if let url = fileIndex[name.lowercased()] {
            sources[sound] = .file(url)
        } else if let asset = NSDataAsset(name: name) {
            sources[sound] = .data(asset.data)
        } else {
            missing.insert(sound)
        }
        return sources[sound]
    }

    private static func makeFileIndex() -> [String: URL] {
        guard let root = Bundle.main.resourceURL,
              let walker = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        else { return [:] }

        var index: [String: URL] = [:]
        for case let url as URL in walker {
            guard fileExtensions.contains(url.pathExtension.lowercased()) else { continue }
            let name = url.deletingPathExtension().lastPathComponent.lowercased()
            if index[name] == nil { index[name] = url }
        }
        return index
    }
}
