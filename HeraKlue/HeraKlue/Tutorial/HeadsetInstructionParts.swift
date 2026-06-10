//
//  HeadsetInstructionParts.swift
//  HeraKlue  (Tutorial — Mysha)
//
//  Small pieces shared by the two headset-instruction screens (501:7, 501:8):
//  the gray callout labels and the blue "Press the button to continue" pill.
//

import SwiftUI

/// A gray callout label (like "Button", "Speakers", "Camera" in the design).
struct CalloutLabel: View {
    let text: String
    var size: CGFloat = 22

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .medium, design: .rounded))
            .foregroundStyle(.black)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(hex: 0xD9D9D9), in: Capsule())
            .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
    }
}

/// The blue "Press the button to continue" pill (top-right of both screens).
struct ContinuePill: View {
    var body: some View {
        Text("Press the button to continue")
            .font(.system(size: 20, weight: .medium, design: .rounded))
            .foregroundStyle(.black)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 22)
            .padding(.vertical, 16)
            .frame(maxWidth: 230)
            .background(Color(hex: 0x6EBCEF, opacity: 0.82),
                        in: RoundedRectangle(cornerRadius: 20))
            .shadow(color: .white.opacity(0.7), radius: 14)
    }
}
