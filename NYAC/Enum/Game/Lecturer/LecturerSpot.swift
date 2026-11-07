//
//  LecturerSpot.swift
//  NYAC
//
//  Created by Vrz on 04/11/26.
//


/// The four places the lecturer can stand. They sit around the room in a loop: A - B - C - D - back to A.
enum LecturerSpot: String, CaseIterable {
    case a = "A"
    case b = "B"
    case c = "C"
    case d = "D"

    /// The two spots next to this one in the loop. The lecturer only ever walks to a neighbor.
    var neighbors: [LecturerSpot] {
        switch self {
        case .a: return [.b, .d]
        case .b: return [.a, .c]
        case .c: return [.b, .d]
        case .d: return [.a, .c]
        }
    }

    /// The player can game without being caught while the lecturer is at B or C.
    var isSafe: Bool {
        switch self {
        case .a, .d: return false
        case .b, .c: return true
        }
    }
}