//
//  ProgressCardView.swift
//  NYAC
//
//  Created by Vrz on 15/11/26.
//

import SwiftUI

/// The progress tracker: a dark card titled PROGRESS, with one row per objective and a checkbox at the end of the row.
/// A row is white while its objective is in progress. Once the objective is done, its text and its checkbox turn green.
///
/// Pure display: the game decides what is done and when the card should be visible, this view draws and fades it.
struct ProgressCardView: View {

    /// One row of the card.
    struct Item: Identifiable {
        let title: String
        let isDone: Bool

        var id: String { title }
    }

    let items: [Item]
    var isVisible: Bool = true

    // MARK: - Look

    /// The SF Symbols of the checkbox. For a filled green square with a white tick, use "checkmark.app.fill" instead.
    private static let emptyBox = "app"
    private static let checkedBox = "checkmark.app"

    /// The green of a finished row.
    private static let doneColor = Color(red: 0.46, green: 0.98, blue: 0.45)

    private static let width: CGFloat = 230

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PROGRESS")
                .font(.system(size: 20))
                .foregroundStyle(.white)

            // The line under the title.
            Rectangle()
                .fill(.white.opacity(0.5))
                .frame(height: 1)
                .padding(.bottom, 2)

            ForEach(items) { item in
                row(for: item)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(width: Self.width)
        .background(Color.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .opacity(isVisible ? 1 : 0)
        .animation(.easeInOut(duration: 0.3), value: isVisible)
    }

    private func row(for item: Item) -> some View {
        HStack(spacing: 12) {
            Text(item.title)

            Spacer(minLength: 0)

            Image(systemName: item.isDone ? Self.checkedBox : Self.emptyBox)
                .imageScale(.large)
        }
        .font(.system(size: 18))
        .foregroundStyle(item.isDone ? Self.doneColor : Color.white)
        .animation(.easeOut(duration: 0.1), value: item.isDone)
    }
}

#Preview {
    ProgressCardView(items: [
        .init(title: "Finish the game", isDone: false),
        .init(title: "Take the notes", isDone: true)
    ])
    .padding(24)
    .background(Color(white: 0.85))
}
