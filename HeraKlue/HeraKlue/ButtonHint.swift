//
//  ButtonHint.swift
//  HeraKlue
//
//  A non-interactive hint telling the player to use the headset's PHYSICAL
//  button. Deliberately styled as guidance — no pill, nothing that looks
//  tappable on screen. Used wherever a "press/hold the button" prompt appears.
//

import SwiftUI

struct ButtonHint: View {
    let text: String
    var color: Color = Color(hex: 0x4A5565)

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "smallcircle.filled.circle")
            Text(text)
        }
        .font(.system(size: 15, weight: .medium, design: .rounded))
        .foregroundStyle(color.opacity(0.75))
        .shadow(color: .white.opacity(0.7), radius: 4)
    }
}
