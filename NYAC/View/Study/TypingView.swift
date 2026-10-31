//
//  TypingView.swift
//  NYAC
//
//  Created by Vrz on 29/10/26.
//

import SwiftUI

/// Pure display: the laptop owns the clock, the keyboard and loading the text.
struct TypingView: View {
    let viewModel: TypingViewModel

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
        .background(Color.white)
        .preferredColorScheme(.light)   // keeps "black = correct" readable
    }

    // MARK: Header (loading / result)

    @ViewBuilder
    private var header: some View {
        Group {
            switch viewModel.status {
            case .loading:
                Text("generating text...")
            case .finished:
                Text("\(viewModel.wpm) wpm   ·   done")
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
