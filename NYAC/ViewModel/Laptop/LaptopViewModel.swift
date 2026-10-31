//
//  LaptopViewModel.swift
//  NYAC
//
//  Created by Vrz on 30/10/26.
//

import Foundation
import Observation

/// Owns everything the two tabs share: the clock, which tab is on screen, which tabs are done
/// and the final win/lose result.
///
/// Study and Minigame keep their own state and are never paused or reset when the tab changes.
/// This view model only decides which of them gets the keyboard.
@MainActor
@Observable
final class LaptopViewModel {
 
    // MARK: Output for the view
 
    private(set) var state: LaptopState = .preparing
    private(set) var activeTab: LaptopTab = LaptopConfig.startingTab
    private(set) var completedTabs: Set<LaptopTab> = []
 
    /// Whole seconds left on the shared clock. Only changes once per second.
    private(set) var secondsLeft = Int(LaptopConfig.timeLimit)
 
    // MARK: The two features
    // They live as long as the laptop does, so switching tabs never resets them.
 
    let minigame: MinigameViewModel
    let study: TypingViewModel
 
    @ObservationIgnored private var timerTask: Task<Void, Never>?
    @ObservationIgnored private var endDate: Date?
    @ObservationIgnored private var hasStarted = false
 
    init(minigame: MinigameViewModel, study: TypingViewModel) {
        self.minigame = minigame
        self.study = study
 
        // A feature only reports "I'm done". The laptop decides what that means for the run.
        minigame.onCompleted = { [weak self] in self?.markDone(.minigame) }
        study.onCompleted = { [weak self] in self?.markDone(.study) }
    }
 
    convenience init() {
        self.init(minigame: MinigameViewModel(), study: TypingViewModel())
    }
 
    // MARK: Lifecycle
 
    /// Generates the study text, then starts the shared clock. Safe to call more than once.
    func start() async {
        guard !hasStarted else { return }
        hasStarted = true
 
        // The clock waits for the text, so a slow generation doesn't eat the player's time.
        await study.loadNewText()
        startClock()
    }
 
    // MARK: Tabs
 
    func switchTab() {
        guard state == .running else { return }
        activeTab = activeTab.next
    }
 
    func isDone(_ tab: LaptopTab) -> Bool {
        completedTabs.contains(tab)
    }
 
    // MARK: Input from the view
    // Each call only reaches its own tab, and only while that tab is on screen.
 
    func move(_ direction: Move) {
        guard acceptsInput(for: .minigame) else { return }
        minigame.move(direction)
    }
 
    func type(_ character: Character) {
        guard acceptsInput(for: .study) else { return }
        study.type(character)
    }
 
    func deleteLast() {
        guard acceptsInput(for: .study) else { return }
        study.deleteLast()
    }
 
    private func acceptsInput(for tab: LaptopTab) -> Bool {
        state == .running && activeTab == tab
    }
 
    // MARK: Progress
 
    private func markDone(_ tab: LaptopTab) {
        guard state == .running else { return }
        completedTabs.insert(tab)
 
        if completedTabs.count == LaptopTab.allCases.count { finish(.won) }
    }
 
    // MARK: Shared clock
 
    private func startClock() {
        endDate = Date().addingTimeInterval(LaptopConfig.timeLimit)
        state = .running
 
        timerTask = Task { [weak self] in
            while true {
                try? await Task.sleep(for: .milliseconds(100))
                guard !Task.isCancelled, let self else { return }
                self.tick()
            }
        }
    }
 
    private func tick() {
        guard state == .running, let endDate else { return }
 
        let remaining = endDate.timeIntervalSinceNow
        let seconds = max(0, Int(remaining.rounded(.up)))
        if seconds != secondsLeft { secondsLeft = seconds }
 
        if remaining <= 0 { finish(.lost) }
    }
 
    private func finish(_ result: LaptopState) {
        timerTask?.cancel()
        timerTask = nil
        state = result
    }
}
