//
//  TypingView.swift
//  NYAC
//
//  Created by Vrz on 29/10/26.
//

import SwiftUI

struct TypingView: View {
    @State private var viewModel = TypingViewModel()
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 8) {
                header

                if let notice = viewModel.notice {
                    Text(notice)
                        .font(.callout)
                        .foregroundStyle(Color.gray)
                }
            }

            ScrollViewReader { proxy in
                ScrollView {
                    FlowLayout(rowSpacing: 14) {
                        ForEach(viewModel.words) { word in
                            WordView(word: word, cursorIndex: viewModel.cursorIndex)
                                .id(word.id)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                // Keep the line you are typing on in the middle of the visible area.
                .onChange(of: viewModel.currentWordID) { _, id in
                    guard let id else { return }
                    withAnimation(.easeOut(duration: 0.15)) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
        .padding(60)
        .frame(
            minWidth: 800, idealWidth: 1000, maxWidth: .infinity,
            minHeight: 400, idealHeight: 600, maxHeight: .infinity,
            alignment: .topLeading
        )
        .background(Color.white)
        .preferredColorScheme(.light)   // keeps "black = correct" readable
        .focusable()
        .focused($isFocused)
        .focusEffectDisabled()
        .onAppear { isFocused = true }
        .task { await viewModel.loadNewText() }
        .onKeyPress { press in handle(press) }
    }

    // MARK: Header (timer / result)

    @ViewBuilder
    private var header: some View {
        Group {
            switch viewModel.status {
            case .loading:
                Text("generating text...")
            case .finished:
                Text("\(viewModel.wpm) wpm   ·   esc for new text")
            case .idle, .running:
                Text("\(viewModel.timeRemaining)")
            }
        }
        .font(.system(size: 32, weight: .semibold, design: .monospaced))
        .foregroundStyle(Color.orange)
    }

    // MARK: Keyboard

    private func handle(_ press: KeyPress) -> KeyPress.Result {
        if press.key == .escape {
            viewModel.reset()
            return .handled
        }

        if isBackspace(press) {
            viewModel.deleteLast()
            return .handled
        }

        guard press.modifiers.isDisjoint(with: [.command, .control]),
              press.characters.count == 1,
              let character = press.characters.first,
              character == " " || character.isLetter || character.isNumber
                || character.isPunctuation || character.isSymbol
        else { return .ignored }

        viewModel.type(character)
        return .handled
    }

    /// The Mac Backspace key sends U+007F, which SwiftUI reports as `.deleteForward`
    /// rather than `.delete`, so accept both (plus the raw characters) to be safe.
    private func isBackspace(_ press: KeyPress) -> Bool {
        press.key == .delete
            || press.key == .deleteForward
            || press.characters == "\u{7F}"
            || press.characters == "\u{8}"
    }
}

#Preview {
    TypingView()
}
