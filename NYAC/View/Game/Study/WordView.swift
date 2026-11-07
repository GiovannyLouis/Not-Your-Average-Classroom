//
//  WordView.swift
//  NYAC
//
//  Created by Vrz on 29/10/26.
//

import SwiftUI

struct WordView: View {
    let word: TestWord
    let cursorIndex: Int?

    var body: some View {
        Text(attributedWord)
            .font(.system(size: 28, design: .monospaced))
            .fixedSize()
    }

    private var attributedWord: AttributedString {
        var result = AttributedString()

        for item in word.characters {
            var piece = AttributedString(String(item.character))

            switch item.state {
            case .unwritten:
                piece.foregroundColor = Color.gray
            case .correct:
                piece.foregroundColor = Color.black
            case .incorrect:
                piece.foregroundColor = Color.red
                // A wrong space would be invisible, so tint its background.
                if item.character == " " {
                    piece.backgroundColor = Color.red.opacity(0.3)
                }
            }

            if item.id == cursorIndex {
                piece.backgroundColor = Color.orange.opacity(0.35)
            }

            result.append(piece)
        }

        return result
    }
}
