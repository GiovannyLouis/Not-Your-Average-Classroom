//
//  RoadPart.swift
//  NYAC
//
//  Created by Vrz on 19/11/26.
//


/// Which part of a road a road row is. A road is 2 to 5 rows: [start, end], [start, middle, end],
/// [start, middle, middle, middle, end]. The start has the sidewalk below it, the end has the sidewalk above it.
enum RoadPart {
    case start, middle, end

    /// The part of the row at `index` (0 is the first row) in a road of `count` rows.
    static func of(index: Int, count: Int) -> RoadPart {
        if index == 0 { return .start }
        if index == count - 1 { return .end }
        return .middle
    }
}
