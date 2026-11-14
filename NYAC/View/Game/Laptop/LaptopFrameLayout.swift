//
//  LaptopFrameLayout.swift
//  NYAC
//
//  Created by Vrz on 14/11/26.
//

import AppKit
import Foundation

/// How the laptop picture (laptop.png) sits around the LaptopView.
///
/// The LaptopView is the screen: the tab bar, the minigame and the study text. The picture is drawn in front of it,
/// and the see-through cutout in the picture's screen is where the LaptopView shows through. Everything the LaptopView
/// draws outside the cutout is hidden behind the picture's frame.
///
/// The picture is stretched so its cutout is exactly the LaptopView's size (shrunk by `cutoutTuck`), and both are
/// centered on each other. The three values under "Tweaks" move and resize the picture against the LaptopView.
/// While the project has no laptop.png, none of this applies and the laptop looks like it did before.
enum LaptopFrameLayout {

    /// The name of the picture in the project: the file name without ".png".
    static let assetName = "laptop"

    /// Whether the project has laptop.png yet.
    static let hasArt: Bool = NSImage(named: NSImage.Name(assetName)) != nil

    // MARK: - The picture

    /// Where the see-through screen is in laptop.png, as fractions of the whole picture (0...1, from the top left).
    /// Measured on the current laptop.png (1542 x 1133 px): the cutout is 964 x 590 px and starts at x 295, y 80.
    /// They are fractions, so exporting the picture at another resolution needs no change here.
    /// If you redraw the laptop (a new cutout), measure it again and change the numbers.
    static let cutout = CGRect(x: 295.0 / 1542.0,
                               y: 80.0 / 1133.0,
                               width: 964.0 / 1542.0,
                               height: 590.0 / 1133.0)

    // MARK: - Tweaks

    /// Resizes the picture around the middle of its cutout; width and height separately. 1 = the cutout has the size of
    /// the LaptopView (less the tuck).
    ///  - below 1: the cutout gets smaller than the screen, so the edges of the LaptopView hide behind the frame
    ///  - above 1: the cutout gets bigger than the screen, so a gap shows around the LaptopView. Avoid.
    static let frameScale = CGSize(width: 1, height: 1)

    /// Slides the picture against the LaptopView, in points (+x moves the picture right, +y moves it down).
    /// The screen's content then seems to move the other way inside the cutout.
    static let frameOffset = CGSize(width: 0, height: 0)

    /// How far the LaptopView runs under the frame on each side, in points. It stops a hairline gap from showing
    /// at the edge of the cutout. Bigger = more of the screen's edge is hidden.
    static let cutoutTuck: CGFloat = 2

    // MARK: - What the view and the scene read

    /// The picture's size on screen, in points.
    static var size: CGSize {
        let screen = LaptopLayout.size
        return CGSize(width: (screen.width - 2 * cutoutTuck) / cutout.width * frameScale.width,
                      height: (screen.height - 2 * cutoutTuck) / cutout.height * frameScale.height)
    }

    /// Where the picture's center is, measured from the LaptopView's center (SwiftUI axes: +x right, +y down).
    static var offset: CGSize {
        let size = self.size
        // The cutout's center is not the picture's center (the keyboard makes the picture longer below the screen),
        // so the picture is moved by that much the other way to bring the two cutout centers together.
        let cutoutFromCenterX = (cutout.midX - 0.5) * size.width
        let cutoutFromCenterY = (cutout.midY - 0.5) * size.height
        return CGSize(width: -cutoutFromCenterX + frameOffset.width,
                      height: -cutoutFromCenterY + frameOffset.height)
    }

    /// How far the picture's top edge sticks out above the LaptopView's top edge, in points (0 without the picture).
    /// The scene adds it in peek mode, so that the top of the picture, the real top of the laptop, is what sits at
    /// `peekLaptopTop`, not the top of the screen behind it.
    static var topOverhang: CGFloat {
        guard hasArt else { return 0 }
        return size.height / 2 - offset.height - LaptopLayout.size.height / 2
    }
}
