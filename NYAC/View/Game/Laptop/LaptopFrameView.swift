//
//  LaptopFrameView.swift
//  NYAC
//
//  Created by Vrz on 14/11/26.
//


import SwiftUI

/// The laptop picture, drawn over the LaptopView (see LaptopFrameLayout for how it lines up).
/// It is meant to be the LaptopView's overlay, so it moves with it and sits in front of it. It never takes clicks or keys.
/// It draws nothing while the project has no laptop.png.
struct LaptopFrameView: View {
    private let image = NSImage(named: NSImage.Name(LaptopFrameLayout.assetName))

    var body: some View {
        if let image {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .frame(width: LaptopFrameLayout.size.width, height: LaptopFrameLayout.size.height)
                .offset(LaptopFrameLayout.offset)
                .allowsHitTesting(false)
        }
    }
}
