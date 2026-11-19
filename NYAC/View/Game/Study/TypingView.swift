//
//  TypingView.swift
//  NYAC
//
//  Created by Vrz on 29/10/26.
//

import SwiftUI

/// Pure display: the game owns the clock and loading the text, the laptop owns the keyboard.
/// The one thing it does by itself is the shake: the text shakes for a moment when a wrong character is typed.
struct TypingView: View {
    let viewModel: TypingViewModel

    /// Goes up by 1 (animated) with every wrong character, and ShakeEffect turns that into one shake.
    @State private var shakePhase: CGFloat = 0

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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        // The shake comes before the white background, so only the text moves. The paper stays put, and so does the laptop
        // picture around it (it is not part of this view at all, it is drawn over the LaptopView).
        .modifier(ShakeEffect(travel: TypingLayout.shakeTravel, cycles: TypingLayout.shakeCycles, phase: shakePhase))
        .background(Color.white)
        .preferredColorScheme(.light)   // keeps "black = correct" readable
        // The count goes up in the same update that turns the character red, so the shake starts with it. Only the
        // shake's own phase is animated: the red itself is not inside this animation, so it still pops at once.
        .onChange(of: viewModel.wrongKeyCount) { _, _ in
            withAnimation(.linear(duration: TypingLayout.shakeDuration)) {
                shakePhase += 1
            }
        }
    }

    // MARK: Header (loading / result)

    @ViewBuilder
    private var header: some View {
        Group {
            switch viewModel.status {
            case .loading:
                Text("generating text...")
            case .finished:
                Text("Done")
            case .idle, .running:
                Text("")
            }
        }
        .font(.system(size: 32, weight: .semibold, design: .monospaced))
        .foregroundStyle(Color.orange)
        .frame(height: 40, alignment: .leading)
    }
}

#Preview {
    TypingView(viewModel: TypingViewModel())
}
