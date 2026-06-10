//
//  LoadingView.swift
//  HeraKlue  (Tutorial — Mysha)
//
//  The loading screen — matches Figma node 213:12.
//  White background, the Minotaur/HERAKLUE logo, "Loading your adventure...",
//  and a pill progress bar. Once the bar fills, the player presses the
//  headset button to continue (storyboard Loading 1.2).
//

import SwiftUI

struct LoadingView: View {
    var onContinue: () -> Void

    @State private var progress: CGFloat = 0
    @State private var isReady = false

    // Colors taken straight from the Figma design (node 213:12).
    private let trackColor = Color(red: 3 / 255, green: 2 / 255, blue: 19 / 255).opacity(0.2)
    private let fillColor  = Color(red: 0x4A / 255, green: 0x55 / 255, blue: 0x65 / 255)

    private let barWidth: CGFloat = 256
    private let barHeight: CGFloat = 12

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 28) {
                Image("HeraklueLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 460)
                    .accessibilityLabel("HeraKlue")

                VStack(spacing: 14) {
                    Text(isReady ? "Press the button to continue" : "Loading your adventure...")
                        .font(.system(size: 18))
                        .tracking(-0.44)
                        .foregroundStyle(.black)

                    // Pill progress bar: a track with a fill that grows left→right.
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(trackColor)
                            .frame(width: barWidth, height: barHeight)
                        Capsule()
                            .fill(fillColor)
                            .frame(width: barWidth * progress, height: barHeight)
                    }
                    .frame(width: barWidth, height: barHeight)
                }
            }
            .padding(40)
        }
        // The whole screen is the headset button (tap = press).
        .contentShape(Rectangle())
        .onTapGesture {
            if isReady { onContinue() }
        }
        .task {
            // Fill the bar, then wait for the player to press the button.
            // Replace the timer with real asset / consent loading later.
            withAnimation(.easeInOut(duration: 2.5)) {
                progress = 1
            }
            try? await Task.sleep(for: .seconds(2.5))
            isReady = true
        }
    }
}

#Preview {
    LoadingView(onContinue: {})
}
