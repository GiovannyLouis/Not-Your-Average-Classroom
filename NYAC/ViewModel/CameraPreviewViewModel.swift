//
//  CameraPreviewViewModel.swift
//  NYAC
//
//  Created by Vrz on 08/11/26.
//

import CoreGraphics
import Observation

/// Only the camera and the faces in it, for the settings screen in the lobby, where there is no run (and so no
/// PeekViewModel) yet. It opens the camera when asked and follows the biggest face, the same one a run locks onto first.
@MainActor
@Observable
final class CameraPreviewViewModel: CameraPreviewSource {

    private(set) var cameraImage: CGImage?
    private(set) var faceBox: CGRect?
    private(set) var otherFaceBoxes: [CGRect] = []

    @ObservationIgnored private let service = HeadTrackingService()

    init() {
        service.onFrame = { [weak self] frame in
            Task { @MainActor in self?.handle(frame) }
        }
    }

    // MARK: - Intents

    func start() async {
        _ = await service.start()
    }

    func stop() {
        service.stop()
    }

    // MARK: - Frame handling

    private func handle(_ frame: TrackingFrame) {
        cameraImage = frame.image

        let player = frame.faceBoxes.max(by: { $0.width < $1.width })
        faceBox = player
        otherFaceBoxes = frame.faceBoxes.filter { $0 != player }
    }
}
