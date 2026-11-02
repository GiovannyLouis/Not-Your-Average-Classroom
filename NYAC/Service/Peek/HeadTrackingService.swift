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

    private let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "head.tracking.queue")
    private let ciContext = CIContext()
    private var isConfigured = false

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
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        // Low resolution is plenty for finding a face, and keeps Vision fast.
        if session.canSetSessionPreset(.vga640x480) {
            session.sessionPreset = .vga640x480
        }

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }
        session.addInput(input)

        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: queue)
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)

        isConfigured = true
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
