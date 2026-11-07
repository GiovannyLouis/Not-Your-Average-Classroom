//
//  LaneDirection.swift
//  NYAC
//
//  Created by Vrz on 28/10/26.
//

import Foundation

enum LaneDirection {
    case left, right

    var sign: CGFloat { self == .left ? -1 : 1 }
}
