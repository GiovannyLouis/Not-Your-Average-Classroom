//
//  MenuLayout.swift
//  NYAC
//
//  Created by Vrz on 17/11/26.
//

import Foundation
import CoreGraphics

/// Where everything sits on the main screen (the lobby and its settings), and how it moves with your head.
///
/// The main screen is the classroom seen from the player's seat, with only three things in it: the wall, the board and
/// the front row desks. It uses the same design space as the game's classroom (ClassroomLayout.designSize, 1946 x 1272,
/// the middle is (0, 0), y points up), so the room is scaled and cropped to the screen exactly like in the game.
///
/// The numbers come from the two mock-ups: the title and the buttons from the greybox one, the desks and the board's
/// size from the one with the assets. Everything here is a "design unit", change a number and the whole screen follows.
enum MenuLayout {

    // MARK: - Parallax

    // The same speeds as the game, so the main screen is a real preview of it: the further a thing is, the less it moves.
    // There is no focus / peek here, only the head's position.

    /// Multiplies the speed of both layers. 1 = exactly what the game does. Raise it if the main screen feels too still.
    static let parallaxStrength: CGFloat = 1

    /// The board is the furthest thing in the room, like the game's whiteboard.
    static var boardMultiplier: CGFloat {
        ClassroomLayout.multiplier(of: .whiteboard) * parallaxStrength
    }

    /// The desks are the front row of the game.
    static var desksMultiplier: CGFloat {
        ClassroomLayout.multiplier(of: .firstRowDesks) * parallaxStrength
    }

    /// Screen shift in points for a multiplier of 1 when the head is at the edge of its range, and how fast the head offset eases.
    /// These two are copies of ParallaxScene's (`maxShift`, `smoothing`), so the main screen feels like the game. Change them together.
    static let maxShift: CGFloat = 220
    static let smoothing: CGFloat = 0.2

    // MARK: - The board

    /// The name of the board's art. It is the game's whiteboard, so it is the same file.
    static let boardAssetName = ClassroomItem.whiteboard.assetName

    /// Where the middle of the board is.
    static let boardCenter = CGPoint(x: 0, y: 15)

    /// How wide the board art is drawn. Its height follows from the picture's proportions, so the drawing is never squashed.
    static let boardWidth: CGFloat = 1400

    /// The plain board that stands in for the art (white, with a black outline) while the project has no board image.
    static let greyboxBoardSize = CGSize(width: 1306, height: 805)

    // MARK: - What sits on the board

    /// Shifted slightly upward (y: -290 instead of -324) so content clears the marker tray at the bottom of the board art.
    static let contentFrame = CGRect(x: -590, y: -290, width: 1180, height: 620)

    /// The title's picture, if the project has one (the file name without ".png"). Until then the title is drawn as text.
    static let titleAssetName = "title"

    /// Slightly smaller box to accommodate the 20° tilt without crowding the top border or Start button.
    static let titleSize = CGSize(width: 560, height: 245)
    static let titleRotation: Double = -5 // Negative = counter-clockwise in SwiftUI

    /// The font that stands in for the hand lettering, and its size (the name has to be the font's PostScript name).
    static let titleFontName = "MarkerFelt-Wide"
    static let titleFontSize: CGFloat = 80

    // Slightly smaller buttons so the full stack fits cleanly inside the board frame.
    static let startButtonSize = CGSize(width: 410, height: 120)
    static let startButtonFontSize: CGFloat = 44
    static let smallButtonSize = CGSize(width: 270, height: 80)
    static let smallButtonFontSize: CGFloat = 30

    // MARK: - The desks

    /// The three front row desks, from left to right.
    static let desks: [ClassroomItem] = [.firstRowLeft, .firstRowMiddle, .firstRowRight]

    /// Wider desks (~40% of the 1946 design width) to match the hi-fi scale.
    static let deskWidth: CGFloat = 780

    /// Brought slightly closer together so the gaps between desks match the hi-fi framing.
    static let deskPitch: CGFloat = 930

    /// Raised slightly from -500 so more of the desk tops show at the bottom edge.
    static let deskTop: CGFloat = -475

    /// The height of the plain boxes that stand in for the desk art. Taller than what is left of the screen below `deskTop`.
    static let greyboxDeskHeight: CGFloat = 420

    static func deskCenterX(of item: ClassroomItem) -> CGFloat {
        switch item {
        case .firstRowLeft:  return -deskPitch
        case .firstRowRight: return deskPitch
        default:             return 0
        }
    }

    // MARK: - Draw order

    /// The wall is the game's background, and the board and the desks use the game's z positions,
    /// so the desks are in front of the board like in the classroom.
    static let wallAssetName = ClassroomLayout.backgroundAssetName
    static let wallZPosition = ClassroomLayout.backgroundZPosition
    static let wallDimOpacity: CGFloat = 0.20
    static let boardZPosition = ClassroomLayout.zPosition(of: .whiteboard)

    static func deskZPosition(of item: ClassroomItem) -> CGFloat {
        ClassroomLayout.zPosition(of: item)
    }
}
