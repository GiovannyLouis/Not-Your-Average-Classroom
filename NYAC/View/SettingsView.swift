//
//  SettingsView.swift
//  NYAC
//
//  Created by Vrz on 08/11/26.
//

import SwiftUI

/// The settings card: the camera view and the head-tracking tuning (y threshold and sensitivity). The lobby shows it
/// on its own, and the in-game menu shows it over the game. It changes GameSettings directly, so a new value
/// is used right away, even by a run that is already going.
struct SettingsView: View {
    let settings: GameSettings

    /// The app's camera: where the camera view gets its image and faces.
    let peek: PeekViewModel

    /// Called when the player taps "Back".
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            Text("Settings")
                .font(.system(size: 44))

            // Above the y threshold, so the yellow line can be checked against the face while the slider moves.
            CameraPiPView(peek: peek, settings: settings, size: CGSize(width: 320, height: 240))

            VStack(spacing: 14) {
                row("Y Threshold", value: settings.thresholdY) {
                    Slider(value: Bindable(settings).thresholdY, in: GameSettings.thresholdYRange)
                }
                row("Sensitivity", value: settings.sensitivity) {
                    Slider(value: Bindable(settings).sensitivity, in: GameSettings.sensitivityRange)
                }
            }

            PillButton(title: "Back", action: onBack)
                .padding(.top, 4)
        }
        .cardStyle(width: 560)
    }

    /// A label, a slider and the number it is currently at.
    private func row<Content: View>(_ label: String, value: CGFloat, @ViewBuilder control: () -> Content) -> some View {
        HStack(spacing: 14) {
            Text(label)
                .font(.system(size: 18))
                .frame(width: 120, alignment: .leading)
            control()
            Text(String(format: "%.2f", value))
                .font(.system(size: 18))
                .monospacedDigit()
                .frame(width: 44, alignment: .trailing)
        }
    }
}

#Preview {
    let settings = GameSettings()
    SettingsView(settings: settings, peek: PeekViewModel(settings: settings), onBack: {})
        .padding(40)
        .background(Color.gray)
}
