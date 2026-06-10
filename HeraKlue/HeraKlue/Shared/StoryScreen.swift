//
//  StoryScreen.swift
//  HeraKlue
//
//  SHARED helper. A reusable narration screen: an optional title and
//  speaker, one or more lines of text, an optional picture, and a prompt to
//  use the headset button. Most story screens are only a few lines of code
//  because of this — see the Tutorial/ folder for examples.
//
//  The headset button on this prototype:
//    • tap the screen  = PRESS the button (continue / select / interact)
//    • long-press      = HOLD the button (repeat a line / notify parent)
//

import SwiftUI

struct StoryScreen: View {
    var title: String? = nil
    var speaker: String? = nil
    var lines: [String]
    var systemImage: String? = nil
    var imageName: String? = nil
    var continueHint: String? = "Press the button to continue"
    var onPress: () -> Void = {}
    var onHold: (() -> Void)? = nil

    var body: some View {
        ZStack {
            // Deep "night in the city" backdrop.
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.07, blue: 0.18),
                         Color(red: 0.10, green: 0.13, blue: 0.32)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer(minLength: 0)

                picture

                if let title {
                    Text(title)
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                }

                if let speaker {
                    Text(speaker.uppercased())
                        .font(.headline)
                        .foregroundStyle(.yellow)
                }

                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.title2)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                }

                Spacer(minLength: 0)

                if let continueHint {
                    Label(continueHint, systemImage: "hand.tap.fill")
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.bottom, 36)
                }
            }
            .padding(.horizontal, 40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        // The whole screen acts as the headset button.
        .contentShape(Rectangle())
        .onTapGesture { onPress() }
        .onLongPressGesture(minimumDuration: 0.6) { onHold?() }
    }

    @ViewBuilder
    private var picture: some View {
        if let imageName {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 200)
        } else if let systemImage {
            Image(systemName: systemImage)
                .font(.system(size: 90))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    StoryScreen(
        speaker: "Ariadne",
        lines: ["Welcome, young explorer!",
                "I am Ariadne, and I am your guide for this journey."],
        systemImage: "sparkles"
    )
}
