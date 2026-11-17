//
//  HeadTrackingService.swift
//  NYAC
//
//  Created by Vrz on 01/11/26.
//

import AVFoundation
import CoreImage
import Vision

/// Model/service layer: opens the webcam, runs Vision face detection on every frame,
/// and reports the frame and all the faces. It knows nothing about SpriteKit or SwiftUI.
nonisolated final class HeadTrackingService: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {

    /// Called on a background queue for every frame.
    var onFrame: (@Sendable (TrackingFrame) -> Void)?

    /// Called on a background queue when a camera is plugged in or unplugged (a virtual camera turning on counts too).
    var onCamerasChanged: (@Sendable () -> Void)?

    private let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "head.tracking.queue")
    private let ciContext = CIContext()
    private var isConfigured = false

    /// The camera to read from. Nil = whichever one the system calls the default. Only touched on `queue`.
    private var selectedCameraID: String?

    private var observers: [NSObjectProtocol] = []

    override init() {
        super.init()
        let center = NotificationCenter.default
        for name in [AVCaptureDevice.wasConnectedNotification, AVCaptureDevice.wasDisconnectedNotification] {
            observers.append(center.addObserver(forName: name, object: nil, queue: nil) { [weak self] _ in
                self?.onCamerasChanged?()
            })
        }
    }

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    // MARK: - Cameras

    /// Every camera the Mac can use right now. The system's default is always in the list, even when it is a kind
    /// of camera the search does not know (so the player can always see which one is being used).
    static func availableCameras() -> [CameraDevice] {
        let found = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .external, .continuityCamera],
            mediaType: .video,
            position: .unspecified
        ).devices

        var devices = found
        if let fallback = AVCaptureDevice.default(for: .video), !devices.contains(where: { $0.uniqueID == fallback.uniqueID }) {
            devices.insert(fallback, at: 0)
        }
        return devices.map { CameraDevice(id: $0.uniqueID, name: $0.localizedName) }
    }

    /// The camera the system would pick on its own. This is the one the game used before there was a choice.
    static var defaultCameraID: String? {
        AVCaptureDevice.default(for: .video)?.uniqueID
    }

    /// Switches to the camera with this id (nil = the system's default). It works while the camera is running.
    /// A camera that is not there any more falls back to the default one.
    func selectCamera(id: String?) {
        queue.async { [self] in
            selectedCameraID = id
            guard isConfigured else { return }          // `configure` uses it when the camera starts
            _ = replaceInput()
        }
    }

    private func cameraDevice(for id: String?) -> AVCaptureDevice? {
        if let id, let device = AVCaptureDevice(uniqueID: id) { return device }
        return AVCaptureDevice.default(for: .video)
    }

    // MARK: - Lifecycle

    /// Returns false if camera permission was denied.
    func start() async -> Bool {
        guard await requestAccess() else { return false }
        queue.async { [self] in
            if !isConfigured { configure() }
            if isConfigured, !session.isRunning { session.startRunning() }
        }
        return true
    }

    func stop() {
        queue.async { [self] in
            if session.isRunning { session.stopRunning() }
        }
    }

    // MARK: - Setup

    private func requestAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return true
        case .notDetermined: return await AVCaptureDevice.requestAccess(for: .video)
        default: return false
        }
    }

    private func configure() {
        guard replaceInput() else { return }

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: queue)
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)

        isConfigured = true
    }

    /// Points the session at the selected camera (the default one if none is selected, or it is gone), in place of the
    /// camera it reads now. Runs on `queue`. Returns false, with the session left as it was, if there is no camera to read from.
    private func replaceInput() -> Bool {
        guard let device = cameraDevice(for: selectedCameraID),
              let input = try? AVCaptureDeviceInput(device: device) else { return false }

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        let previous = session.inputs
        previous.forEach { session.removeInput($0) }
        guard session.canAddInput(input) else {
            previous.forEach { if session.canAddInput($0) { session.addInput($0) } }
            return false
        }
        session.addInput(input)

        // Low resolution is plenty for finding a face, and keeps Vision fast.
        if session.canSetSessionPreset(.vga640x480) {
            session.sessionPreset = .vga640x480
        }
        return true
    }

    // MARK: - Frames

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
        try? handler.perform([request])

        // Report every face; the view model picks which one to follow.
        let boxes = request.results?.map(\.boundingBox) ?? []

        // The frame is only used for the picture-in-picture preview.
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return }

        onFrame?(TrackingFrame(image: cgImage, faceBoxes: boxes))
    }
}
