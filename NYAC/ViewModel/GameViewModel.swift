//
//  GameViewModel.swift
//  NYAC
//
//  Created by Vrz on 05/11/26.
//


import Foundation
import Observation

/// The whole game in one place. It builds every part of the game, wires them together and owns what no single
/// part can own: the clock, which objectives are done, and how the run ends.
///
/// The parts only report what happened ("the minigame is finished", "the lecturer started walking").
/// This view model decides what that means for the run.
///
/// One run is one GameViewModel. Playing again means making a new one, so nothing ever needs resetting.
@MainActor
@Observable
final class GameViewModel {

    // MARK: Output for the views

    private(set) var state: GameState = .preparing
    private(set) var completedObjectives: Set<GameObjective> = []

    /// Whole seconds left on the clock. Only changes once per second.
    private(set) var secondsLeft = Int(GameConfig.timeLimit)

    /// How the run ended, or nil while it is still going.
    var result: GameResult? {
        guard case .ended(let ended) = state else { return nil }
        return ended
    }

    /// What the game over screen says. Nil while the run is still going, so that is also the screen's on/off switch.
    var gameOverContent: GameOverContent? {
        result.map { GameOverContent(result: $0) }
    }

    // MARK: The parts of the game

    /// Shared by the whole app and outlives any single run, so it is handed in instead of created here.
    let settings: GameSettings

    let minigame: MinigameViewModel
    let study: TypingViewModel
    let lecturer: LecturerViewModel

    /// Shows Study and Minigame as tabs and decides which of them gets the keyboard.
    let laptop: LaptopViewModel

    /// Head tracking and the parallax scene that draws the lecturer's top view.
    let peek: PeekViewModel

    @ObservationIgnored private var timerTask: Task<Void, Never>?
    @ObservationIgnored private var startDate: Date?
    @ObservationIgnored private var hasStarted = false

    init(settings: GameSettings, minigame: MinigameViewModel, study: TypingViewModel, lecturer: LecturerViewModel) {
        self.settings = settings
        self.minigame = minigame
        self.study = study
        self.lecturer = lecturer
        self.laptop = LaptopViewModel(minigame: minigame, study: study)
        self.peek = PeekViewModel(lecturer: lecturer, settings: settings)

        // A part only reports "I'm done" or "something changed". The game decides what that means for the run.
        minigame.onCompleted = { [weak self] in self?.complete(.minigame) }
        study.onCompleted = { [weak self] in self?.complete(.study) }

        // The lecturer starting or stopping a walk and the player switching tabs are the two things
        // that can get the player caught, so both lead to the same check.
        lecturer.onStateChanged = { [weak self] in self?.checkCaught() }
        laptop.onTabChanged = { [weak self] in self?.checkCaught() }
    }

    convenience init(settings: GameSettings) {
        self.init(settings: settings, minigame: MinigameViewModel(), study: TypingViewModel(), lecturer: LecturerViewModel())
    }

    // MARK: Lifecycle

    /// Gets ready, then starts the clock. Safe to call more than once.
    func start() async {
        guard !hasStarted else { return }
        hasStarted = true

        // The clock waits for both, so a slow text generation or the camera permission prompt doesn't eat the player's time.
        async let camera: Void = peek.start()
        async let text: Void = study.loadNewText()
        await camera
        await text

        startClock()
    }

    /// Stops the clock and the camera. Called when the game screen goes away.
    func stop() {
        timerTask?.cancel()
        timerTask = nil
        peek.stop()
    }

    // MARK: Objectives

    func isDone(_ objective: GameObjective) -> Bool {
        completedObjectives.contains(objective)
    }

    /// The win rule: every objective has to be done.
    private func complete(_ objective: GameObjective) {
        guard state == .running else { return }
        completedObjectives.insert(objective)

        if completedObjectives.count == GameObjective.allCases.count {
            end(.won(completionTime: elapsed))
        }
    }

    // MARK: Lecturer

    /// The caught rule: gaming while the lecturer can see the screen ends the run. It is checked whenever either side
    /// changes: the lecturer starts or stops walking, or the player switches tabs. Being on the minigame tab is what
    /// counts, whether or not a key is being pressed.
    private func checkCaught() {
        guard state == .running, laptop.activeTab == .minigame, lecturer.state.canCatchPlayer else { return }
        end(.caught(survivedFor: elapsed))
    }

    // MARK: Clock

    /// Seconds since the clock started.
    private var elapsed: TimeInterval {
        guard let startDate else { return 0 }
        return Date().timeIntervalSince(startDate)
    }

    private func startClock() {
        startDate = Date()
        state = .running
        laptop.isEnabled = true
        lecturer.isActive = true

        timerTask = Task { [weak self] in
            while true {
                try? await Task.sleep(for: .milliseconds(100))
                guard !Task.isCancelled, let self else { return }
                self.tick()
            }
        }
    }

    private func tick() {
        guard state == .running else { return }

        let remaining = GameConfig.timeLimit - elapsed
        let seconds = max(0, Int(remaining.rounded(.up)))
        if seconds != secondsLeft { secondsLeft = seconds }

        if remaining <= 0 { end(.timeUp) }
    }

    // MARK: Ending

    private func end(_ result: GameResult) {
        timerTask?.cancel()
        timerTask = nil
        state = .ended(result)
        laptop.isEnabled = false
        lecturer.isActive = false
    }
}
