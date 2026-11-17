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

    /// Which menu is open on top of the game. The game keeps running behind it.
    private(set) var menu: GameMenu = .closed

    /// Timed visibility for the progress card (on run start and when an objective updates).
    private var isTemporarilyVisible = true

    /// True while the player is peeking during an active run.
    private var isPeeking = false

    /// Whether the progress card should be visible: shown on start, on quest updates, and while peeking.
    var showsProgressCard: Bool {
        isPeeking || isTemporarilyVisible
    }

    /// True while the game is getting ready (the study text is being written), before the countdown.
    var isPreparing: Bool {
        state == .preparing
    }

    /// Whether to remind the player that Escape opens the menu. Not while the menu is open
    /// (it says how to close itself), and not once the run is over.
    var showsMenuHint: Bool {
        if case .ended = state { return false }
        return menu == .closed
    }

    /// The clock as the HUD shows it, minutes and seconds ("4:07").
    var timeText: String {
        String(format: "%d:%02d", secondsLeft / 60, secondsLeft % 60)
    }

    /// The objectives the HUD's progress card lists, top to bottom.
    var checklist: [GameObjective] {
        [.minigame, .study]
    }

    /// The number to show while counting down (3, 2, 1), or nil outside the countdown.
    var countdown: Int? {
        guard case .countdown(let number) = state else { return nil }
        return number
    }

    /// How the run ended, or nil while it is still going.
    var result: GameResult? {
        guard case .ended(let ended) = state else { return nil }
        return ended
    }

    /// The fastest win on record, in seconds, as the game over screen shows it: set when the run ends, win or lose.
    /// Nil while the player has never won. A win that just beat the record is already in here.
    private(set) var bestCompletionTime: TimeInterval?

    /// True when the run that just ended was a win that set a new record (the first win counts: there was no record yet).
    private(set) var isNewBest = false

    /// What the game over screen says. Nil while the run is still going, so that is also the screen's on/off switch.
    var gameOverContent: GameOverContent? {
        result.map { GameOverContent(result: $0, bestCompletionTime: bestCompletionTime, isNewBest: isNewBest) }
    }

    // MARK: The parts of the game

    // The next three are shared by the whole app and outlive any single run, so they are handed in instead of created here.

    let settings: GameSettings

    /// What the game remembers between launches. A run counts itself as played when its clock starts (see `startClock`)
    /// and keeps the best completion time up to date when it ends (see `recordBestTime`).
    let store: PlayerStore

    /// The app's camera and head tracking. It is already running when a run starts and keeps running after it.
    let peek: PeekViewModel

    let minigame: MinigameViewModel
    let study: TypingViewModel
    let lecturer: LecturerViewModel

    /// Shows Study and Minigame as tabs and decides which of them gets the keyboard.
    let laptop: LaptopViewModel

    /// Draws the lecturer's top view behind the laptop and moves both with the head tracking.
    let parallaxScene: ParallaxScene

    /// Called when the player chooses to leave the run (from the menu or the game over screen).
    /// Whoever owns the run decides where to go next.
    @ObservationIgnored var onBackToLobby: (() -> Void)?

    @ObservationIgnored private var timerTask: Task<Void, Never>?
    @ObservationIgnored private var progressHideTask: Task<Void, Never>?
    @ObservationIgnored private var startDate: Date?
    @ObservationIgnored private var hasStarted = false

    init(settings: GameSettings, peek: PeekViewModel, store: PlayerStore, minigame: MinigameViewModel, study: TypingViewModel, lecturer: LecturerViewModel) {
        self.settings = settings
        self.store = store
        self.peek = peek
        self.minigame = minigame
        self.study = study
        self.lecturer = lecturer
        self.laptop = LaptopViewModel(minigame: minigame, study: study)
        self.parallaxScene = ParallaxScene(lecturer: lecturer, peek: peek)

        // A part only reports "I'm done" or "something changed". The game decides what that means for the run.
        minigame.onCompleted = { [weak self] in self?.complete(.minigame) }
        study.onCompleted = { [weak self] in self?.complete(.study) }

        // The lecturer starting or stopping a walk and the player switching tabs are the two things
        // that can get the player caught, so both lead to the same check.
        lecturer.onStateChanged = { [weak self] in self?.checkCaught() }
        laptop.onTabChanged = { [weak self] in self?.checkCaught() }

        observePeekMode()
    }

    convenience init(settings: GameSettings, peek: PeekViewModel, store: PlayerStore) {
        self.init(settings: settings, peek: peek, store: store, minigame: MinigameViewModel(), study: TypingViewModel(), lecturer: LecturerViewModel())
    }

    /// For the previews: a store of its own, so a preview never touches the real saved data.
    convenience init(settings: GameSettings, peek: PeekViewModel) {
        self.init(settings: settings, peek: peek, store: PlayerStore(defaults: UserDefaults(suiteName: "NYAC.preview") ?? .standard))
    }

    // MARK: Lifecycle

    /// Gets ready, counts down, then starts the clock. Safe to call more than once.
    func start() async {
        guard !hasStarted else { return }
        hasStarted = true

        // The camera has been on since the app opened, so the run only has to start over from where the player sits now.
        peek.recenter()

        // The countdown waits for the study text, so it only begins once the text is written.
        await study.loadNewText()
        guard !Task.isCancelled else { return }     // the player already left

        await countDown()
        guard !Task.isCancelled else { return }

        startClock()
    }

    /// Stops the clock. Called when the game screen goes away. The camera is not part of the run, so it stays on.
    func stop() {
        timerTask?.cancel()
        timerTask = nil
        progressHideTask?.cancel()
        progressHideTask = nil
    }

    /// Leaves the run. Where that leads is up to whoever owns it (see `onBackToLobby`).
    func backToLobby() {
        onBackToLobby?()
    }

    // MARK: Menu

    /// Escape: opens the menu, goes back from settings, or closes the menu. Does nothing once the run is over.
    func toggleMenu() {
        if case .ended = state { return }

        switch menu {
        case .closed:   menu = .main
        case .main:     menu = .closed
        case .settings: menu = .main
        }
        syncInput()
    }

    func openSettings() {
        guard menu == .main else { return }
        menu = .settings
    }

    func closeSettings() {
        guard menu == .settings else { return }
        menu = .main
    }

    /// The laptop only takes input while the run is going and no menu is in the way.
    /// Nothing else changes when the menu opens: the clock and the lecturer carry on.
    private func syncInput() {
        laptop.isEnabled = state == .running && menu == .closed
    }

    // MARK: Progress Card Visibility

    private func showProgressCardTemporarily(includeFadeInDelay: Bool) {
        progressHideTask?.cancel()
        isTemporarilyVisible = true

        // When hidden, account for the 1s fade-in so the card stays fully visible for 3s before fading out.
        let visibleDuration: Duration = includeFadeInDelay ? .seconds(4) : .seconds(3)

        progressHideTask = Task { [weak self] in
            try? await Task.sleep(for: visibleDuration)
            guard !Task.isCancelled, let self else { return }
            self.isTemporarilyVisible = false
        }
    }

    private func observePeekMode() {
        withObservationTracking {
            _ = peek.mode
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.syncPeekVisibility()
                if case .ended = self.state { return }
                self.observePeekMode()
            }
        }
    }

    private func syncPeekVisibility() {
        isPeeking = state == .running && peek.mode == .peek
    }

    // MARK: Objectives

    func isDone(_ objective: GameObjective) -> Bool {
        completedObjectives.contains(objective)
    }

    /// The win rule: every objective has to be done.
    private func complete(_ objective: GameObjective) {
        guard state == .running else { return }
        let wasInserted = completedObjectives.insert(objective).inserted
        let isGameCompleted = completedObjectives.count == GameObjective.allCases.count

        // Skip fading in the progress card when the final objective finishes, since the win screen
        // already tells the player they succeeded. Swap the two `if` lines below to re-enable it later.
        if wasInserted && !isGameCompleted {
        // if wasInserted {
            showProgressCardTemporarily(includeFadeInDelay: !showsProgressCard)
        }

        if isGameCompleted {
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

    // MARK: Countdown

    private func countDown() async {
        for number in stride(from: GameConfig.countdownSeconds, through: 1, by: -1) {
            state = .countdown(number)
            try? await Task.sleep(for: .seconds(1))
            if Task.isCancelled { return }
        }
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
        // The game counts as played once its clock runs. Leaving while it is still getting ready (or counting down) does not count.
        store.countGamePlayed()
        syncInput()
        syncPeekVisibility()
        showProgressCardTemporarily(includeFadeInDelay: false)
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
        progressHideTask?.cancel()
        progressHideTask = nil
        isPeeking = false
        // Comment out the line below if you re-enable showing the progress card on game completion.
        isTemporarilyVisible = false
        menu = .closed          // the game over screen takes over
        recordBestTime(for: result)         // before the state changes: the game over screen reads it as soon as it shows
        state = .ended(result)
        syncInput()
        lecturer.isActive = false
    }

    /// Keeps the best completion time. Only a win can set it, and only a faster time than the record beats it
    /// (the same time is just a win). The first win has no record to beat, so it sets one and counts as a new best.
    /// The game over screen shows the record after a loss too, so every ending reads it into `bestCompletionTime`.
    private func recordBestTime(for result: GameResult) {
        let record = store.bestCompletionTime

        if case .won(let completionTime) = result, completionTime < (record ?? .infinity) {
            store.saveBestCompletionTime(completionTime)
            bestCompletionTime = completionTime
            isNewBest = true
        } else {
            bestCompletionTime = record
            isNewBest = false
        }
    }
}
