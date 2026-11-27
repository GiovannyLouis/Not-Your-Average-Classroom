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

    // For the camera pickers in the settings
    /// The cameras the Mac has right now. It updates by itself when one is plugged in or unplugged.
    private(set) var cameras: [CameraDevice] = []
    private var defaultCameraID: String?

    /// The camera in use: the one the player chose, if it is still there, otherwise the system's default.
    var activeCameraID: String? {
        if let chosen = settings.cameraID, cameras.contains(where: { $0.id == chosen }) { return chosen }
        return defaultCameraID
    }

    // MARK: - Private

    /// The tuning set by default or by the player (y threshold, sensitivity, camera). The player's camera choice is
    /// the one thing this view model writes into it (see `selectCamera`).
    private let settings: GameSettings

    @ObservationIgnored private let service = HeadTrackingService()
    @ObservationIgnored private var neutralX: CGFloat?
    @ObservationIgnored private var lastFaceX: CGFloat?

    // Face lock
    @ObservationIgnored private var lockedBox: CGRect?
    @ObservationIgnored private var missedFrames = 0

    /// While true the pose stays at focus and the head offset at zero, whatever the head does (see `freeze`).
    /// Only `handle` reads it, so nothing observes it.
    @ObservationIgnored private var isFrozen = false

    init(settings: GameSettings) {
        self.settings = settings

        service.onFrame = { [weak self] frame in
            Task { @MainActor in self?.handle(frame) }
        }
        service.onCamerasChanged = { [weak self] in
            Task { @MainActor in self?.refreshCameras() }
        }
        refreshCameras()
    }

    // MARK: - Intents

    func start() async {
        service.selectCamera(id: settings.cameraID)     // the camera the player chose last time, before it opens
        cameraDenied = !(await service.start())
    }

    /// Switches to another camera, and remembers it for the next launch. The picture and the face of the old camera are
    /// dropped (the preview goes black until the new camera's first frame), and the head tracking starts over from where
    /// the player sits now, like at the start of a run.
    func selectCamera(_ id: String) {
        guard id != activeCameraID else { return }
        settings.cameraID = id
        useActiveCamera()
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

    /// Holds the pose at focus and the head offset at zero, so nothing that follows the head moves, and peeking does nothing.
    /// The camera, the face lock and the sideways calibration carry on underneath, so the first frame after `unfreeze`
    /// already has the right pose and offset. A run uses this while it is still getting ready (the study text is being
    /// written and the player must not be able to look at the lecturer yet).
    func freeze() {
        isFrozen = true
        mode = .focus
        headOffset = .zero
    }

    /// Lets the head move the scene again. The next frame from the camera brings the real pose and offset back.
    func unfreeze() {
        isFrozen = false
    }

    // MARK: - Cameras

    /// Reads the list of cameras again. If the camera in use is a different one now (the chosen one was unplugged, or came back,
    /// or the system's default changed), the camera is switched to it.
    private func refreshCameras() {
        let before = activeCameraID
        cameras = HeadTrackingService.availableCameras()
        defaultCameraID = HeadTrackingService.defaultCameraID
        if activeCameraID != before {
            useActiveCamera()
        }
    }

    private func useActiveCamera() {
        cameraImage = nil
        faceBox = nil
        otherFaceBoxes = []
        faceDetected = false
        recenter()
        service.selectCamera(id: settings.cameraID)     // nil (never chose) = the system's default, wherever it points now
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

        // Frozen: the face is still followed and calibrated above, but the pose and the offset stay where `freeze` put them.
        guard !isFrozen else { return }

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

