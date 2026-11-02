//
//  TrackingFrame.swift
//  NYAC
//
//  Created by Vrz on 01/11/26.
//

import CoreGraphics

/// One camera frame plus where Vision found faces in it.
/// `nonisolated` because the camera service builds it on a background queue.
nonisolated struct TrackingFrame: @unchecked Sendable {
    let image: CGImage
    /// Every face found, in Vision coordinates: 0...1, origin at the bottom-left of the *unmirrored* camera image.
    /// Empty = no face. Deciding which one is "you" is the view model's job.
    let faceBoxes: [CGRect]
}
