//
//  LoadingView.swift
//  HeraKlue  (Tutorial — Mysha)
//
//  Screens 1.1 + 1.2 — the loading screen. Shows a spinner while we
//  "load the adventure", then asks the player to press the button.
//

import SwiftUI

struct LoadingView: View {
    var onContinue: () -> Void
    @State private var isReady = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.07, blue: 0.18),
                         Color(red: 0.10, green: 0.13, blue: 0.32)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("HeraKlue")
                    .font(.system(size: 52, weight: .bold, design: .serif))
                    .foregroundStyle(.white)

                if isReady {
                    Label("Press the button to continue", systemImage: "hand.tap.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                } else {
                    ProgressView()
                        .controlSize(.large)
                        .tint(.white)
                    Text("Loading your adventure…")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isReady { onContinue() }
        }
        .task {
            // Simulated load. Later this is where real assets / the parent's
            // settings would be fetched before continuing.
            try? await Task.sleep(for: .seconds(2.5))
            isReady = true
        }
    }
}

#Preview {
    LoadingView(onContinue: {})
}
