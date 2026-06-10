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
        ZStack(alignment: .bottom) {
            ContentView()                 // the RealityKit AR scene
                .ignoresSafeArea()

            Button("Skip to map (placeholder)") {
                flow.go(to: .journeyMap)
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom, 40)
        }
    }
}
