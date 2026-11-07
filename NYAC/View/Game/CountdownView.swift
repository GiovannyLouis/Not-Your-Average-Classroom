//
//  CountdownView.swift
//  NYAC
//
//  Created by Vrz on 08/11/26.
//

import SwiftUI

/// The big 3, 2, 1 in front of the game before it starts. The game behind it is only dimmed a little.
struct CountdownView: View {
    let number: Int

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)

            Text("\(number)")
                .font(.system(size: 160, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(radius: 8)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    CountdownView(number: 3)
        .frame(width: 1000, height: 650)
}
