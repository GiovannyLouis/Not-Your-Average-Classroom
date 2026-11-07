//
//  TestCharacter.swift
//  NYAC
//
//  Created by Vrz on 29/10/26.
//


/// One character of the target text together with how it should be displayed.
struct TestCharacter: Identifiable {
    let id: Int              // position in the text
    let character: Character
    let state: CharacterState
}