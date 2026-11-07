//
//  AppScreen.swift
//  NYAC
//
//  Created by Vrz on 07/11/26.
//


/// Which screen the app is showing.
enum AppScreen {
    case lobby

    /// Carries the camera preview shown in the settings. It lives only while this screen does.
    case settings(CameraPreviewViewModel)

    /// The run being played. Leaving the game screen throws the run away, so every Start begins with a fresh one.
    case game(GameViewModel)
}
