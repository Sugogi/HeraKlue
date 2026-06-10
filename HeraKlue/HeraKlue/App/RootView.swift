//
//  RootView.swift
//  HeraKlue
//
//  SHARED — please coordinate with the team before changing this file.
//  The first screen the app shows. It watches the current phase and shows
//  the matching section. You normally only edit this when adding or
//  reordering whole sections — not when building screens inside a section.
//

import SwiftUI

struct RootView: View {
    // Created here, lives for the whole app, shared with every screen.
    @State private var flow = GameFlow()

    var body: some View {
        Group {
            switch flow.phase {
            case .tutorial:
                TutorialFlowView()      // Mysha
            case .gameplay:
                GameplayFlowView()      // Stephen
            case .journeyMap:
                JourneyMapView()        // Hibba
            }
        }
        .environment(flow)
    }
}

#Preview {
    RootView()
}
