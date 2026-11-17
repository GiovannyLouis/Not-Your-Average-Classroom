//
//  CameraDevice.swift
//  NYAC
//
//  Created by Vrz on 17/11/26.
//

import Foundation

/// A camera the player can choose from: the Mac's own, one that is plugged in, an iPhone, or a virtual one (OBS, say).
/// `nonisolated` because the camera service builds it on a background queue.
nonisolated struct CameraDevice: Identifiable, Hashable, Sendable {
    /// The system's own id for the camera. It stays the same between launches, so it is what gets saved.
    let id: String

    /// What the player sees in the list, for example "FaceTime HD Camera".
    let name: String
}
