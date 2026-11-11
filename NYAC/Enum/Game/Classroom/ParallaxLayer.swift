//
//  ParallaxLayer.swift
//  NYAC
//
//  Created by Vrz on 11/11/26.
//


/// A set of classroom items that move at the same speed when the head moves.
/// The speed (the multiplier) belongs to the layer, so every item in it moves together.
/// Which item is drawn in front of which is a separate thing: that is the item's z position (see ClassroomLayout).
///
/// The laptop is also a parallax layer (the closest one), but it is not listed here:
/// it is a SwiftUI view that ParallaxScene moves on its own.
enum ParallaxLayer: CaseIterable {
    /// B, C, D: the closest desks after the laptop.
    case secondRowDesks
    /// E, F, G: the desks behind them.
    case firstRowDesks
    /// H and I: the window and the door.
    case windowAndDoor
    /// J: the whiteboard, the furthest thing in the room.
    case whiteboard
}
