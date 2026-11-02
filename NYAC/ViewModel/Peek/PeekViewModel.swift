//
//  PeekViewModel.swift
//  NYAC
//
//  Created by Vrz on 01/11/26.
//

import SwiftUI
import Observation
import SpriteKit

/// ViewModel: picks which face to follow and turns its position into a mode (focus / peek) and a calibrated
/// head offset (-1...1 on each axis). It hands everything to the scene.
@MainActor
@Observable
final class PeekViewModel {

    // MARK: - Tunables

    /// Flip this if moving your head right makes the scene react the wrong way on your camera.
    private let mirrorX = true

    /// How far the face center has to travel in the camera image (0...1 units)
    /// to reach offset 1.0 at sensitivity 1. Smaller = more sensitive.
    private let headRange: CGFloat = 0.15

    /// How far (camera 0...1 units) the locked face may move between two frames and still count as the same person.
    private let maxFaceJump: CGFloat = 0.15

    /// How many frames the locked face may go missing before the lock is released (about 1 second at 30 fps).
    private let releaseAfterMissedFrames = 30

    // MARK: - State for the view

    let scene: ParallaxScene

    /// Camera-image y where the modes switch (0 = bottom of the frame, 1 = top; 0.5 = halfway).
    /// Face center above this line = peek, otherwise focus.
    var thresholdY: CGFloat = 0.5

    var sensitivity: CGFloat = 1.0

    /// Overlay switches. They only hide the overlay; tracking keeps running underneath.
    var showsDebugPanel = true
    var showsCameraPiP = true

    private(set) var mode: HeadMode = .focus
    private(set) var headOffset: CGPoint = .zero
    private(set) var faceDetected = false
    private(set) var cameraDenied = false

    // For the picture-in-picture view
    private(set) var cameraImage: CGImage?
    private(set) var faceBox: CGRect?               // the face we're locked onto
    private(set) var otherFaceBoxes: [CGRect] = []  // everyone else in frame (ignored)

    // MARK: - Private

    @ObservationIgnored private let service = HeadTrackingService()
    @ObservationIgnored private var neutralX: CGFloat?
    @ObservationIgnored private var lastFaceX: CGFloat?

    // Face lock
    @ObservationIgnored private var lockedBox: CGRect?
    @ObservationIgnored private var missedFrames = 0

    init() {
        scene = ParallaxScene(size: CGSize(width: 900, height: 600))
        scene.scaleMode = .resizeFill

        service.onFrame = { [weak self] frame in
            Task { @MainActor in self?.handle(frame) }
        }
    }

    // MARK: - Intents

    func start() async {
        cameraDenied = !(await service.start())
    }

    func stop() {
        service.stop()
    }

    /// Treat your current sideways position as "centered". (Vertically, the threshold line is the center.)
    func calibrate() {
        neutralX = lastFaceX
    }

    /// Forget the locked face. The next frame locks onto the biggest (closest) face in view.
    func relockFace() {
        lockedBox = nil
        missedFrames = 0
    }

    // MARK: - Frame handling

    private func handle(_ frame: TrackingFrame) {
        cameraImage = frame.image

        let locked = lockedFace(in: frame.faceBoxes)
        faceBox = locked
        otherFaceBoxes = frame.faceBoxes.filter { $0 != locked }

        guard let box = locked else {
            faceDetected = false
            return
        }
        faceDetected = true

        let face = CGPoint(x: box.midX, y: box.midY)
        lastFaceX = face.x
        if neutralX == nil { neutralX = face.x }   // first detection auto-calibrates sideways

        // Plain threshold: the moment the center dot is above the line it's peek, otherwise focus.
        mode = face.y > thresholdY ? .peek : .focus
        scene.mode = mode

        var dx = face.x - (neutralX ?? face.x)
        if mirrorX { dx = -dx }                    // camera sees you mirrored: your right = smaller x
        let dy = face.y - thresholdY               // Vision's y points up; the threshold is the vertical center

        let range = headRange / max(sensitivity, 0.01)
        headOffset = CGPoint(x: clamp(dx / range), y: clamp(dy / range))
        scene.headOffset = headOffset
    }

    /// Returns the box that belongs to the person we're locked onto (nil if they're not visible this frame).
    /// Vision doesn't say who is who, so we follow position: the face nearest to where ours was last seen.
    private func lockedFace(in boxes: [CGRect]) -> CGRect? {
        // 1. Already locked: stick with the face closest to where it was last seen.
        if let last = lockedBox {
            if let match = boxes.min(by: { distance($0, last) < distance($1, last) }),
               distance(match, last) < maxFaceJump {
                lockedBox = match
                missedFrames = 0
                return match
            }

            // Our face isn't visible this frame. Hold the lock for a moment (they may have just turned away),
            // then give up so a new face can be picked.
            missedFrames += 1
            if missedFrames <= releaseAfterMissedFrames { return nil }
            lockedBox = nil
        }

        // 2. No lock: lock onto the biggest (closest) face in view.
        guard let first = boxes.max(by: { $0.width < $1.width }) else { return nil }
        lockedBox = first
        missedFrames = 0
        return first
    }

    private func distance(_ a: CGRect, _ b: CGRect) -> CGFloat {
        hypot(a.midX - b.midX, a.midY - b.midY)
    }

    private func clamp(_ value: CGFloat) -> CGFloat {
        min(max(value, -1), 1)
    }
}
