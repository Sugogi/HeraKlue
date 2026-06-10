//
//  GameplayFlowView.swift
//  HeraKlue
//
//  STEPHEN owns this folder (Gameplay/): the AR missions — Poseidon at the
//  loggia, the journey to the Four Stone Lions, and collecting puzzle pieces.
//
//  Placeholder: shows the existing AR scene (ContentView) with a temporary
//  button to continue to the map. Stephen builds the real missions here.
//

import SwiftUI

struct GameplayFlowView: View {
    @Environment(GameFlow.self) private var flow

    var body: some View {
        // Scaffold: Ariadne gives her AR tutorial, then we head to the map.
        // Stephen's section — Poseidon, the journey, and the puzzles build
        // from here. (Stephen's original demo scene is still in ContentView.)
        AriadneARView(onContinue: { flow.go(to: .journeyMap) })
    }
}
