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
                Slider(value: Bindable(viewModel).thresholdY, in: 0.2...0.8)
                    .frame(width: 140)
                Text(String(format: "%.2f", viewModel.thresholdY))
                    .monospacedDigit()
            }

            HStack {
                Text("Sensitivity")
                Slider(value: Bindable(viewModel).sensitivity, in: 0.5...3)
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
