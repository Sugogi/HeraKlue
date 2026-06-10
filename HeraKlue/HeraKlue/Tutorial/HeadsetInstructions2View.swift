//
//  HeadsetInstructions2View.swift
//  HeraKlue  (Tutorial — Mysha)
//
//  Matches Figma node 501:8 — the second headset-intro screen. The headset
//  photo on a purple card with a "Camera" callout, the "Press the button to
//  continue" pill, and a banner: "Make sure nothing is blocking your camera".
//  Tap anywhere to continue.
//

import SwiftUI

struct HeadsetInstructions2View: View {
    var onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            // Purple card holding the headset photo, with the camera callout.
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: 0x753EB4, opacity: 0.55))
                Image("HeadsetCamera")
                    .resizable()
                    .scaledToFit()
                    .padding(18)
            }
            .frame(width: 300, height: 320)
            .overlay(alignment: .bottomLeading) {
                CalloutLabel(text: "Camera", size: 24).offset(x: -34, y: 6)
            }

            // "Press the button to continue" — top-right of the screen.
            ContinuePill()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(24)

            // Bottom banner.
            Text("Make sure nothing is blocking your camera")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundStyle(.black)
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.7))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .contentShape(Rectangle())
        .onTapGesture { onContinue() }
    }
}

#Preview {
    HeadsetInstructions2View(onContinue: {})
}
