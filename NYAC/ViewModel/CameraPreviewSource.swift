//
//  CameraPreviewSource.swift
//  NYAC
//
//  Created by Vrz on 08/11/26.
//


import CoreGraphics

/// Anything that can supply the camera image and the faces found in it. CameraPiPView draws from this,
/// so the same preview works both in game (the run's head tracking) and in the lobby (CameraPreviewViewModel).
@MainActor
protocol CameraPreviewSource: AnyObject {
    var cameraImage: CGImage? { get }

    /// The face the game follows (the biggest one in view).
    var faceBox: CGRect? { get }

    /// Everyone else in frame. They are shown but ignored.
    var otherFaceBoxes: [CGRect] { get }
}

extension PeekViewModel: CameraPreviewSource {}
