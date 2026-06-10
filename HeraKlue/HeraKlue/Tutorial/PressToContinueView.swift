//
//  PressToContinueView.swift
//  HeraKlue  (Tutorial — Mysha)
//
//  Matches Figma node 213:21 — shown right after loading. The logo, a blue
//  "Press The Button to Continue" pill, and a picture of the headset.
//  Tap anywhere (i.e. press the headset button) to continue.
//

import SwiftUI

struct PressToContinueView: View {
    var onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 24) {
                Image("HeraklueLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 460)
                    .accessibilityLabel("HeraKlue")

                continueButton
            }
            .padding(40)

            // The headset device, lower-right (decorative, from the design).
            Image("HeadsetDevice")
                .resizable()
                .scaledToFit()
                .frame(width: 130)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, 24)
                .padding(.bottom, 24)
                .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .onTapGesture { onContinue() }
    }

    // Blue pill with a subtle layered edge (two shades from the design).
    private var continueButton: some View {
        ZStack {
            Capsule()
                .fill(Color(hex: 0x4B93C3))
                .frame(width: 426, height: 42)
                .offset(x: 3, y: -3)
            Capsule()
                .fill(Color(hex: 0x73B9E7))
                .frame(width: 426, height: 41)
            Text("Press The Button to Continue")
                .font(.system(size: 24, design: .rounded))
                .tracking(-0.44)
                .foregroundStyle(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 16)
        }
        .frame(width: 426, height: 45)
    }
}

#Preview {
    PressToContinueView(onContinue: {})
}
