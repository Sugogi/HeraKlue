//
//  TutorialFlowView.swift
//  HeraKlue
//
//  MYSHA owns this folder (Tutorial/). This drives the tutorial in order:
//  each `step` shows one screen, and calling next() moves forward. After the
//  last screen we hand the player over to the gameplay (AR) section.
//
//  To add or reorder screens: add a `case` below and a matching View file
//  in this folder. Nobody else edits these files, so you won't get conflicts.
//

import SwiftUI

struct TutorialFlowView: View {
    @Environment(GameFlow.self) private var flow
    @State private var step = 0

    var body: some View {
        ZStack {
            switch step {
            case 0: HeadsetInstructions1View(onContinue: next)
            case 1: HeadsetInstructions2View(onContinue: next)
            case 2: LoadingView(onContinue: next)
            case 3: ParentalConsentView(onContinue: next)
            case 4: WelcomeView(onContinue: next)
            default:
                // Tutorial finished -> start the AR adventure (Stephen's section).
                Color.clear.onAppear { flow.go(to: .gameplay) }
            }
        }
        .animation(.easeInOut, value: step)
    }

    private func next() {
        step += 1
    }
}

#Preview {
    TutorialFlowView()
        .environment(GameFlow())
}
