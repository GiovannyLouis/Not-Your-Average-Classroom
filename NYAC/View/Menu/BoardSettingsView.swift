//
//  BoardSettingsView.swift
//  NYAC
//
//  Created by Vrz on 17/11/26.
//

import SwiftUI

/// The settings page of the main screen, drawn on the board: the camera view with its camera picker, and the two
/// head-tracking sliders.
/// It is laid out to fit inside `MenuLayout.contentFrame`, and the room behind it keeps moving with the head,
/// so the player can feel what a sensitivity does while they change it. The in-game menu has its own card (SettingsView).
///
/// It changes GameSettings directly, so a new value is used right away, by this screen and by the next run.
struct BoardSettingsView: View {
    let settings: GameSettings

    /// The app's camera: where the camera view gets its image and faces.
    let peek: PeekViewModel

    /// Called when the player taps "Back".
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            BoardTitleText(text: "Settings", size: 84)

            HStack(spacing: 80) {
                // Next to the sliders, so the yellow line can be checked against the face while the threshold moves.
                // The camera picker is under it: pick another camera and this view shows it at once.
                VStack(spacing: 16) {
                    CameraPiPView(peek: peek, settings: settings, size: CGSize(width: 380, height: 285))
                    BoardCameraPicker(peek: peek)
                }
                .frame(width: 380)

                VStack(alignment: .leading, spacing: 40) {
                    row("Y Threshold", value: Bindable(settings).thresholdY, range: GameSettings.thresholdYRange)
                    row("Sensitivity", value: Bindable(settings).sensitivity, range: GameSettings.sensitivityRange)

                    Text("Move your head from side to side and watch the desks.")
                        .font(.system(size: 28))
                        .foregroundStyle(.black.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(width: 600)
            }

            BoardButton(title: "Back",
                        size: CGSize(width: 260, height: 84),
                        fontSize: 32,
                        action: onBack)
        }
        .foregroundStyle(.black)
        .padding(.bottom, 48)
    }

    /// A label with the number it is at, and the slider under it.
    private func row(_ label: String, value: Binding<CGFloat>, range: ClosedRange<CGFloat>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(label)
                Spacer()
                Text(String(format: "%.2f", value.wrappedValue))
                    .monospacedDigit()
            }
            .font(.system(size: 38))

            BoardSlider(value: value, range: range)
        }
    }
}

#Preview {
    let settings = GameSettings()
    BoardSettingsView(settings: settings, peek: PeekViewModel(settings: settings), onBack: {})
        .frame(width: MenuLayout.contentFrame.width, height: MenuLayout.contentFrame.height)
        .background(Color.white)
}
