//
//  HeadsetInstructions1View.swift
//  HeraKlue  (Tutorial — Mysha)
//
//  Matches Figma node 501:7 — the first headset-intro screen. A photo of the
//  headset on a purple card, with "Button" and "Speakers" callouts and the
//  "Press the button to continue" pill. Tap anywhere to continue.
//
//  NOTE: callout positions are approximate (offsets nudge the labels toward
//  the parts they point at) — easy to fine-tune once previewed in Xcode.
//

import SwiftUI

struct HeadsetInstructions1View: View {
    var onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            // Purple card holding the headset photo, with the two callouts.
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: 0x7340C4, opacity: 0.55))
                Image("HeadsetButtonSpeakers")
                    .resizable()
                    .scaledToFit()
                    .padding(18)
            }
            .frame(width: 330, height: 300)
            .overlay(alignment: .topTrailing) {
                CalloutLabel(text: "Button", size: 24).offset(x: 78, y: 4)
            }
            .overlay(alignment: .bottomLeading) {
                CalloutLabel(text: "Speakers", size: 20).offset(x: -36, y: 14)
            }

            // "Press the button to continue" — top-right of the screen.
            ContinuePill()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(24)
        }
        .contentShape(Rectangle())
        .onTapGesture { onContinue() }
    }
}

#Preview {
    HeadsetInstructions1View(onContinue: {})
}
