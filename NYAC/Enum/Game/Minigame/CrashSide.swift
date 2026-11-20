//
//  CrashSide.swift
//  NYAC
//
//  Created by Vrz on 19/11/26.
//


/// Which part of the car the chicken ran into, as seen on screen.
/// The front is the end the car drives toward, the back is the other end.
/// `bottom` is the side that faces down the screen (the chicken hopped up into it), `top` the side that faces up.
enum CrashSide {
    case front, back, bottom, top
}
