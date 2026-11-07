//
//  LaptopTab.swift
//  NYAC
//
//  Created by Vrz on 30/10/26.
//


/// The screens inside the laptop. Every tab stays alive in the background;
/// only the one on screen receives keyboard input.
enum LaptopTab: CaseIterable, Hashable {
    case study
    case minigame

    /// The game objective this tab is about. The tab shows a check mark once it is done.
    var objective: GameObjective {
        switch self {
        case .study:    return .study
        case .minigame: return .minigame
        }
    }

    /// The tab the Tab key switches to (wraps around).
    var next: LaptopTab {
        let all = Self.allCases
        let index = all.firstIndex(of: self) ?? 0
        return all[(index + 1) % all.count]
    }
}
