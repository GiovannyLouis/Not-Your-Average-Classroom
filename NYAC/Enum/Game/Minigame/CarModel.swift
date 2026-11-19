//
//  CarModel.swift
//  NYAC
//
//  Created by Vrz on 19/11/26.
//

import Foundation

/// The three cars. Every road row picks one of them, and all the cars of that row are that car.
/// They differ by length (the art is car_1, car_2 and car_3, see MinigameLayout).
enum CarModel: CaseIterable {
    case car1, car2, car3

    /// How long the car is, in cells. The collision uses it, and the art is drawn exactly this wide,
    /// so car_1 has to be drawn 1.5 cells long, car_2 1.7 and car_3 2.2.
    var width: CGFloat {
        switch self {
        case .car1: return 1.5
        case .car2: return 1.7
        case .car3: return 2.2
        }
    }
}
