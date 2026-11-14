//
//  ClassroomItem.swift
//  NYAC
//
//  Created by Vrz on 11/11/26.
//


/// Everything that stands in the classroom scene, named after the letters on the greybox sketch.
/// A is the laptop, which is not part of this scene.
enum ClassroomItem: CaseIterable {
    case secondRowLeft      // B
    case secondRowMiddle    // C
    case secondRowRight     // D
    case firstRowLeft       // E
    case firstRowMiddle     // F
    case firstRowRight      // G
    case window             // H
    case door               // I
    case whiteboard         // J

    /// The letter on the sketch. The greybox prints it on the item so it is easy to tell them apart.
    var letter: String {
        switch self {
        case .secondRowLeft:   return "B"
        case .secondRowMiddle: return "C"
        case .secondRowRight:  return "D"
        case .firstRowLeft:    return "E"
        case .firstRowMiddle:  return "F"
        case .firstRowRight:   return "G"
        case .window:          return "H"
        case .door:            return "I"
        case .whiteboard:      return "J"
        }
    }

    /// The name of the item's art in the project: the file name without ".png".
    /// While the project has no image with this name, the greybox box stands in for the item.
    var assetName: String {
        switch self {
        case .secondRowLeft:   return "srl"
        case .secondRowMiddle: return "srm"
        case .secondRowRight:  return "srr"
        case .firstRowLeft:    return "frl"
        case .firstRowMiddle:  return "frm"
        case .firstRowRight:   return "frr"
        case .window:          return "window"
        case .door:            return "door"
        case .whiteboard:      return "board"
        }
    }

    /// Which parallax layer the item moves with, so how fast it moves.
    var layer: ParallaxLayer {
        switch self {
        case .secondRowLeft, .secondRowMiddle, .secondRowRight: return .secondRowDesks
        case .firstRowLeft, .firstRowMiddle, .firstRowRight:    return .firstRowDesks
        case .window, .door:                                    return .windowAndDoor
        case .whiteboard:                                       return .whiteboard
        }
    }

    /// The desk in the middle of its row. It is drawn in front of the desks at the sides of its row,
    /// because from the player's seat it is the closest one. This only changes the draw order, not the speed.
    var isMiddleOfRow: Bool {
        self == .secondRowMiddle || self == .firstRowMiddle
    }
}
