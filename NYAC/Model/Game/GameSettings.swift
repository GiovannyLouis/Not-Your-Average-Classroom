//
//  GameSettings.swift
//  NYAC
//
//  Created by Vrz on 05/11/26.
//

import SwiftUI
import Observation

/// Everything the player can tune. AppViewModel creates one and hands it to every run,
/// so the values survive from one run to the next. Features only read it; settings screens write it.
///
/// The values below are the defaults. AppViewModel restores what the player saved over them when the app opens,
/// and saves them again every time one changes (see PlayerStore).
@MainActor
@Observable
final class GameSettings {

    // MARK: Head tracking

    /// Camera-image y where the modes switch (0 = bottom of the frame, 1 = top; 0.5 = halfway).
    /// Face center above this line = peek, otherwise focus.
    var thresholdY: CGFloat = 0.33
    static let thresholdYRange: ClosedRange<CGFloat> = 0.2...0.8

    /// How far the head has to move to reach the full parallax. Bigger = more sensitive.
    var sensitivity: CGFloat = 1.0
    static let sensitivityRange: ClosedRange<CGFloat> = 0.5...3

    // MARK: Camera

    /// The camera the player chose (see CameraDevice.id). Nil = they never chose, so the system's default camera is used.
    /// The settings screens do not write this directly: they go through PeekViewModel.selectCamera, which also switches the camera.
    var cameraID: String?
}

