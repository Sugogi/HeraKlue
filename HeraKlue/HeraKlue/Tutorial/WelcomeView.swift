//
//  WelcomeView.swift
//  HeraKlue  (Tutorial — Mysha)
//
//  Screens 1.1–1.7 — Ariadne welcomes the player and explains the quest.
//  Press to advance through her lines; HOLD to repeat the current line
//  (on the real headset this re-plays Ariadne's audio).
//

import SwiftUI

struct WelcomeView: View {
    var onContinue: () -> Void
    @State private var index = 0

    private let lines = [
        "Welcome, young explorer!",
        "I am Ariadne, and I am your guide for this journey.",
        "The Minotaur has vanished from the city, and the gods are here to help us find him.",
        "As gods, we cannot interfere directly in the mortal world — so we need your help.",
        "Collect all 25 puzzle pieces around the city to reveal a hidden map.",
        "That map will lead you to the Minotaur's secret location.",
        "Walk around to find your first mission: Poseidon, at the loggia.",
        "Good luck, adventurer!"
    ]

    private var isLastLine: Bool { index == lines.count - 1 }

    var body: some View {
        StoryScreen(
            speaker: "Ariadne",
            lines: [lines[index]],
            systemImage: "sparkles",
            continueHint: isLastLine
                ? "Press to begin  •  Hold to repeat"
                : "Press to continue  •  Hold to repeat",
            onPress: advance,
            onHold: repeatLine
        )
    }

    private func advance() {
        if isLastLine {
            onContinue()
        } else {
            index += 1
        }
    }

    private func repeatLine() {
        // On the real headset this replays Ariadne's audio for the current
        // line. For now, the line simply stays on screen.
    }
}

#Preview {
    WelcomeView(onContinue: {})
}
