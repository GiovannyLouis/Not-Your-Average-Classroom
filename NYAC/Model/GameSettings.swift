//
//  GameSettings.swift
//  NYAC
//
//  Created by Vrz on 05/11/26.
//

import SwiftUI
import Observation

/// Everything the player (or the developer) can tune. The app creates one and hands it to every run,
/// so the values survive from one run to the next. Features only read it; settings screens write it.
///
/// The values below are the defaults.
@MainActor
@Observable
final class GameSettings {

    // MARK: Head tracking

    /// Camera-image y where the modes switch (0 = bottom of the frame, 1 = top; 0.5 = halfway).
    /// Face center above this line = peek, otherwise focus.
    var thresholdY: CGFloat = 0.5
    static let thresholdYRange: ClosedRange<CGFloat> = 0.2...0.8

    /// How far the head has to move to reach the full parallax. Bigger = more sensitive.
    var sensitivity: CGFloat = 1.0
    static let sensitivityRange: ClosedRange<CGFloat> = 0.5...3

    // MARK: Debug overlays
    // They only hide the overlay; tracking keeps running underneath.

    var showsDebugPanel = true
    var showsCameraPiP = true
}
