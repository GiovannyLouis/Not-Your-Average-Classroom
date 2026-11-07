//
//  CameraPiPView.swift
//  NYAC
//
//  Created by Vrz on 01/11/26.
//

import SwiftUI

/// Picture-in-picture: the camera image (mirrored like a mirror), the face we're locked onto
/// (green rectangle + red center dot), other faces (dashed orange, ignored), and the y threshold line.
struct CameraPiPView: View {
    let source: any CameraPreviewSource
    let settings: GameSettings
    var size = CGSize(width: 240, height: 180)

    var body: some View {
        // Read everything here (not inside Canvas) so SwiftUI refreshes the view when it changes.
        let image = source.cameraImage
        let box = source.faceBox
        let others = source.otherFaceBoxes
        let thresholdY = settings.thresholdY

        ZStack {
            if let image {
                Image(decorative: image, scale: 1)
                    .resizable()
            } else {
                Color.black
            }

            Canvas { context, size in
                // Threshold line
                let lineY = (1 - thresholdY) * size.height
                var line = Path()
                line.move(to: CGPoint(x: 0, y: lineY))
                line.addLine(to: CGPoint(x: size.width, y: lineY))
                context.stroke(line, with: .color(.yellow),
                               style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))

                // Other people: tracked by Vision but ignored by the parallax
                for other in others {
                    context.stroke(Path(roundedRect: rect(for: other, in: size), cornerRadius: 4),
                                   with: .color(.orange),
                                   style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                }

                // The locked face + its center dot
                guard let box else { return }
                let faceRect = rect(for: box, in: size)
                context.stroke(Path(roundedRect: faceRect, cornerRadius: 4),
                               with: .color(.green), lineWidth: 2)
                context.fill(Path(ellipseIn: CGRect(x: faceRect.midX - 4, y: faceRect.midY - 4, width: 8, height: 8)),
                             with: .color(.red))
            }
        }
        .frame(width: size.width, height: size.height)
        .scaleEffect(x: -1, y: 1)   // mirror image and overlays together, so they stay aligned
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.4), lineWidth: 1))
    }

    /// Vision's y points up, SwiftUI's points down, so flip with (1 - y).
    private func rect(for box: CGRect, in size: CGSize) -> CGRect {
        CGRect(x: box.minX * size.width,
               y: (1 - box.maxY) * size.height,
               width: box.width * size.width,
               height: box.height * size.height)
    }
}
