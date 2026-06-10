//
//  HeadsetInstructions2View.swift
//  HeraKlue  (Tutorial — Mysha)
//
//  Screen 1.2 — how to use the headset: the Camera.
//

import SwiftUI

struct HeadsetInstructions2View: View {
    var onContinue: () -> Void

    var body: some View {
        StoryScreen(
            title: "Your Headset",
            lines: [
                "Camera — it sees what you're looking at, so the right images can appear around you.",
                "Keep the camera clear — don't block it with your hands."
            ],
            systemImage: "camera.fill",
            onPress: onContinue
        )
    }
}

#Preview {
    HeadsetInstructions2View(onContinue: {})
}
