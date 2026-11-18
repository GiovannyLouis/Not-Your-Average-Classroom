//
//  BoardCameraPicker.swift
//  NYAC
//
//  Created by Vrz on 17/11/26.
//


import SwiftUI

/// Chooses the camera, in the board's style: an outlined pill with the name of the camera in use, and a menu with all of
/// them. Picking one switches the camera right away, so the camera view next to it shows the new one.
/// Sizes are in design units (see MenuLayout), the page is scaled as a whole. The in-game settings card has a plain Picker instead.
struct BoardCameraPicker: View {
    let peek: PeekViewModel

    var body: some View {
        Menu {
            Picker("Camera", selection: Binding(get: { peek.activeCameraID ?? "" }, set: { peek.selectCamera($0) })) {
                ForEach(peek.cameras) { camera in
                    Text(camera.name).tag(camera.id)
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "video.fill")
                Text(currentName)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer(minLength: 0)
                Image(systemName: "chevron.up.chevron.down")
            }
            .font(.system(size: 16))
            .foregroundStyle(.black)
            .padding(.horizontal, 22)
            .frame(height: 40)
            .overlay(Capsule().stroke(.black, lineWidth: 3))
            .background(
                Capsule()
                    .fill(.white.opacity(0.92))
            )
            .overlay(
                Capsule()
                    .strokeBorder(.black, lineWidth: 2)
            )
            .contentShape(Capsule())
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .opacity(peek.cameras.isEmpty ? 0.5 : 1.0)
        .disabled(peek.cameras.isEmpty)
    }

    /// The name of the camera in use, or a note when the Mac has none.
    private var currentName: String {
        peek.cameras.first { $0.id == peek.activeCameraID }?.name ?? "No camera found"
    }
}

#Preview {
    let settings = GameSettings()
    BoardCameraPicker(peek: PeekViewModel(settings: settings))
        .frame(width: 380)
        .padding(40)
        .background(Color.white)
}
