//
//  AriadneARView.swift
//  HeraKlue  (Gameplay — Stephen's section; SCAFFOLD)
//
//  A deliberately tiny AR starting point. It shows the camera passthrough with
//  world tracking and places a placeholder "Ariadne" anchored in the real world
//  ~1.5 m in front of where you start — so you can physically walk around her.
//  She gently bobs and turns to feel "alive". A crosshair sits in the centre
//  (the gaze target from the storyboard) and a caption bar advances on tap.
//
//  This is the skeleton to build on, not finished AR. Things to replace later:
//   • the glowing box  -> a rigged, animated Ariadne USDZ model
//   • the captions     -> Ariadne's real lines + spatial audio (authored by you)
//   • the world anchor -> whichever "relative to" strategy we choose
//

import SwiftUI
import RealityKit

struct AriadneARView: View {
    var onContinue: () -> Void = {}

    @State private var ariadne = Entity()
    @State private var step = 0

    // PLACEHOLDER captions only — not Ariadne's real dialogue.
    private let captions = [
        "[ Ariadne line 1 — tap to continue ]",
        "[ Ariadne line 2 ]",
        "[ Ariadne line 3 ]"
    ]

    var body: some View {
        ZStack {
            // Camera passthrough + a world-anchored Ariadne that stays put in
            // space. TimelineView(.animation) drives the per-frame movement.
            TimelineView(.animation) { timeline in
                RealityView { content in
                    let anchor = AnchorEntity(world: [0, -0.2, -1.5])
                    buildPlaceholder(into: ariadne)
                    anchor.addChild(ariadne)
                    content.add(anchor)
                    content.camera = .spatialTracking
                } update: { _ in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    ariadne.position.y = Float(sin(t * 2)) * 0.05            // bob
                    let angle = (t * 0.4).truncatingRemainder(dividingBy: 2 * .pi)
                    ariadne.orientation = simd_quatf(angle: Float(angle), axis: [0, 1, 0])  // turn
                }
            }
            .ignoresSafeArea()

            // Gaze crosshair in the centre.
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(.white.opacity(0.85))
                .allowsHitTesting(false)

            // Caption bar — tap anywhere (press the headset button) to advance.
            VStack {
                Spacer()
                Text(captions[step])
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity)
                    .background(.black.opacity(0.45))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { advance() }
    }

    private func advance() {
        if step < captions.count - 1 { step += 1 } else { onContinue() }
    }

    /// Placeholder stand-in for the real Ariadne model: a glowing box.
    private func buildPlaceholder(into root: Entity) {
        let box = ModelEntity(
            mesh: .generateBox(size: 0.3, cornerRadius: 0.04),
            materials: [UnlitMaterial(color: .systemPurple)]
        )
        root.addChild(box)
    }
}
