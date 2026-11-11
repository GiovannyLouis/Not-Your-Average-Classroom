//
//  PeekViewModel.swift
//  NYAC
//
//  Created by Vrz on 01/11/26.
//

import SwiftUI
import Observation

/// ViewModel: the one camera of the whole app. It opens the camera, picks which face to follow and turns its
/// position into a mode (focus / peek) and a calibrated head offset (-1...1 on each axis).
///
/// The app makes one when it opens and keeps the camera on for as long as it is open, so every screen (the lobby,
/// the settings and every run) reads the same head tracking. It doesn't draw anything: scenes and views read from it.
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

    // MARK: - State for the views and scenes

    private(set) var mode: HeadMode = .focus
    private(set) var headOffset: CGPoint = .zero
    private(set) var faceDetected = false
    private(set) var cameraDenied = false

    // For the picture-in-picture view
    private(set) var cameraImage: CGImage?
    private(set) var faceBox: CGRect?               // the face we're locked onto
    private(set) var otherFaceBoxes: [CGRect] = []  // everyone else in frame (ignored)

    // MARK: - Private

    /// The tuning set by default or by the player (y threshold, sensitivity). This view model only reads it.
    private let settings: GameSettings

    @ObservationIgnored private let service = HeadTrackingService()
    @ObservationIgnored private var neutralX: CGFloat?
    @ObservationIgnored private var lastFaceX: CGFloat?

    // Face lock
    @ObservationIgnored private var lockedBox: CGRect?
    @ObservationIgnored private var missedFrames = 0

    init(settings: GameSettings) {
        self.settings = settings

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

    /// Start over from where the player is right now: forget the locked face and the sideways calibration, so the next
    /// frame locks onto the biggest face and treats where it sits as the center. The camera stays on between runs,
    /// so every run calls this first, otherwise it would inherit the calibration (and the pose) from earlier.
    func recenter() {
        relockFace()
        neutralX = nil
        mode = .focus
        headOffset = .zero
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

        // Switch focus and peek with minimum jitter, but extra effort.
        // Switch to the commented below and comment this one if prefer an absolute change instead
        let hysteresis: CGFloat = 0.005
        switch mode {
        case .focus where face.y > settings.thresholdY + hysteresis: mode = .peek
        case .peek where face.y < settings.thresholdY - hysteresis: mode = .focus
            default: break
        }
//        // Plain threshold: the moment the center dot is above the line it's peek, otherwise focus.
//        mode = face.y > settings.thresholdY ? .peek : .focus

        var dx = face.x - (neutralX ?? face.x)
        if mirrorX { dx = -dx }                    // camera sees you mirrored: your right = smaller x
        let dy = face.y - settings.thresholdY      // Vision's y points up; the threshold is the vertical center

        let range = headRange / max(settings.sensitivity, 0.01)
        headOffset = CGPoint(x: clamp(dx / range), y: clamp(dy / range))
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

