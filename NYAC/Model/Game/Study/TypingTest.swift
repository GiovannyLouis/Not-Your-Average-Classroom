//
//  TypingTest.swift
//  NYAC
//
//  Created by Vrz on 29/10/26.
//


/// Pure typing logic: the target text and what the player has typed so far.
struct TypingTest {
    // MARK: - Stored Properties
    
    let text: [Character]
    private(set) var typed: [Character] = []
    
    // MARK: - Initialization
    
    init(text: String) {
        // Collapse newlines and repeated spaces so every character can actually be typed.
        let normalized = text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        self.text = Array(normalized)
    }
    
    // MARK: - Computed Properties

    /// True once every character has been typed and all of them are correct.
    var isCompleted: Bool {
        !text.isEmpty && typed == text
    }

    var correctCount: Int {
        zip(typed, text).filter { $0 == $1 }.count
    }

    /// Target text with the state of every character.
    var characters: [TestCharacter] {
        text.enumerated().map { index, character in
            let state: CharacterState
            if index >= typed.count {
                state = .unwritten
            } else {
                state = typed[index] == character ? .correct : .incorrect
            }
            return TestCharacter(id: index, character: character, state: state)
        }
    }

    /// Target text grouped into words.
    var words: [TestWord] {
        var result: [TestWord] = []
        var current: [TestCharacter] = []

        for item in characters {
            current.append(item)
            if item.character == " " {
                result.append(TestWord(id: current[0].id, characters: current))
                current = []
            }
        }
        if !current.isEmpty {
            result.append(TestWord(id: current[0].id, characters: current))
        }
        return result
    }
}

// MARK: - Typing Actions

extension TypingTest {
    mutating func type(_ character: Character) {
        guard typed.count < text.count else { return }
        typed.append(character)
    }

    mutating func deleteLast() {
        _ = typed.popLast()
    }
}
