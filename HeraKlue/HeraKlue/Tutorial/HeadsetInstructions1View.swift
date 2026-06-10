//
//  HeadsetInstructions1View.swift
//  HeraKlue  (Tutorial — Mysha)
//
//  Screen 1.1 — how to use the headset: the Button and the Speakers.
//
//  TODO: swap the SF Symbol for a real headset photo with arrows. Drop the
//        image into Assets.xcassets, then use `imageName: "headset"` instead
//        of `systemImage:`.
//

import SwiftUI

struct HeadsetInstructions1View: View {
    var onContinue: () -> Void

    var body: some View {
        StoryScreen(
            title: "Your Headset",
            lines: [
                "The Button — press to select, continue, or interact. Hold it to notify your parent.",
                "Speakers — audio guides that bring the AR world to life."
            ],
            systemImage: "visionpro",
            onPress: onContinue
        )
    }
}

#Preview {
    HeadsetInstructions1View(onContinue: {})
}
