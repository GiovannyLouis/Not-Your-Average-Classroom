//
//  TestWord.swift
//  NYAC
//
//  Created by Vrz on 29/10/26.
//


/// A word of the target text. It keeps its trailing space so lines wrap naturally.
struct TestWord: Identifiable {
    let id: Int              // position of the word's first character
    let characters: [TestCharacter]
}