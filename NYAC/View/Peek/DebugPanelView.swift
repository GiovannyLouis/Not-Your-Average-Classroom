//
//  DebugPanelView.swift
//  NYAC
//
//  Created by Vrz on 01/11/26.
//


import SwiftUI

/// Tuning panel for the head tracking. Its own view so the fast-changing readouts
/// only refresh this panel, not the whole game screen.
struct DebugPanelView: View {
    let viewModel: PeekViewModel
    let settings: GameSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mode: \(viewModel.mode.rawValue)")
                .font(.headline)
                .foregroundStyle(viewModel.mode == .peek ? .orange : .cyan)

            Text(viewModel.faceDetected ? "Face locked" : "No face detected")
                .foregroundStyle(viewModel.faceDetected ? .green : .orange)

            Text(String(format: "head x: %+.2f   y: %+.2f", viewModel.headOffset.x, viewModel.headOffset.y))
                .monospacedDigit()

            HStack {
                Text("Threshold Y")
                Slider(value: Bindable(settings).thresholdY, in: GameSettings.thresholdYRange)
                    .frame(width: 140)
                Text(String(format: "%.2f", settings.thresholdY))
                    .monospacedDigit()
            }

            HStack {
                Text("Sensitivity")
                Slider(value: Bindable(settings).sensitivity, in: GameSettings.sensitivityRange)
                    .frame(width: 140)
            }

            HStack {
                Button("Calibrate X") {
                    viewModel.calibrate()
                }
                Button("Re-lock face") {
                    viewModel.relockFace()
                }
            }
        }
        .font(.callout)
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}
