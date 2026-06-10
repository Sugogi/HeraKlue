//
//  TutorialFlowView.swift
//  HeraKlue
//
//  MYSHA owns this folder (Tutorial/): the interactive tutorial — headset
//  intro, loading, parental consent, and Ariadne's welcome.
//
//  This placeholder lives on `main` so the app builds. The real tutorial
//  screens are built on the `Mysha` branch.
//

import SwiftUI

struct TutorialFlowView: View {
    @Environment(GameFlow.self) private var flow

    var body: some View {
        StoryScreen(
            speaker: "Ariadne",
            lines: ["Tutorial coming soon!"],
            continueHint: "Press to start the adventure",
            onPress: { flow.go(to: .gameplay) }
        )
    }
}

#Preview {
    TutorialFlowView()
        .environment(GameFlow())
}
