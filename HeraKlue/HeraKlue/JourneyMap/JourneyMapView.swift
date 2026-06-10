//
//  JourneyMapView.swift
//  HeraKlue
//
//  HIBBA owns this folder (JourneyMap/): the map that assembles the 25
//  puzzle pieces into the storyline that leads to the Minotaur.
//
//  Placeholder — Hibba builds the real map here.
//

import SwiftUI

struct JourneyMapView: View {
    @Environment(GameFlow.self) private var flow

    var body: some View {
        StoryScreen(
            title: "Journey Map",
            lines: ["0 / 25 pieces collected", "(Hibba builds this section)"],
            continueHint: "Press to replay the tutorial",
            onPress: { flow.go(to: .tutorial) }
        )
    }
}

#Preview {
    JourneyMapView()
        .environment(GameFlow())
}
