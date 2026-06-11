//
//  CombinedARView.swift
//  HeraKlue
//
//  PHYSICAL-SPACE AR building block for `test-mix`.
//
//  It shows two kinds of "anchor" at once — the two mechanics this game needs:
//    1) FLOOR anchor  -> a 3D Poseidon (USDZ) stands on a detected horizontal
//                        surface, so it's planted in the real room.
//    2) IMAGE anchor  -> a puzzle piece appears on top of a recognised printed
//                        marker image ("PoseidonMarker").
//
//  ── To actually SEE things, this needs 3 setup items (not code): ──────────
//    • a model file  "Poseidon_Stylized.usdz"  added to the app target
//    • an AR Resource Group named "AR Resources" in Assets.xcassets, containing
//      an image named "PoseidonMarker" with its real-world size set
//    Without those it still runs (camera only) and just prints a message.
//
//  ── How to use it right now ──────────────────────────────────────────────
//    In ContentView, swap `ARViewContainer(...)` for `CombinedARView()` to try
//    it. (It is NOT story-aware yet — it places everything at once. Making it
//    follow `currentStep` is the next step.)
//
//  ── Things to improve later ──────────────────────────────────────────────
//    • load the model ASYNC (Entity.load runs on the main thread = brief freeze)
//    • make Poseidon face the player
//    • drive it from the story (currentStep) + a "got close -> talk" trigger
//

import SwiftUI
import RealityKit
import ARKit
import UIKit

struct CombinedARView: UIViewRepresentable {

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        // Load the printed marker images we want to recognise (from Assets).
        guard let referenceImages = ARReferenceImage.referenceImages(
            inGroupNamed: "AR Resources",
            bundle: nil
        ) else {
            print("Could not load AR Resources.")
            return arView
        }

        let configuration = ARWorldTrackingConfiguration()

        // Floor detection for Poseidon
        configuration.planeDetection = [.horizontal]

        // Image tracking for puzzle piece
        configuration.detectionImages = referenceImages
        configuration.maximumNumberOfTrackedImages = 1

        configuration.environmentTexturing = .automatic

        arView.session.run(configuration, options: [
            .resetTracking,
            .removeExistingAnchors
        ])

        // MARK: - Poseidon on floor

        let floorAnchor = AnchorEntity(
            .plane(
                .horizontal,
                classification: .any,
                minimumBounds: [0.25, 0.25]
            )
        )

        do {
            let poseidon = try Entity.load(named: "Poseidon_Stylized")

            // Make Poseidon bigger or smaller here
            poseidon.scale = [2.0, 2.0, 2.0]
            poseidon.position = [0, 0, 0]

            floorAnchor.addChild(poseidon)
            arView.scene.addAnchor(floorAnchor)

        } catch {
            print("Failed to load Poseidon model: \(error)")
        }

        // MARK: - Puzzle piece on reference image

        let imageAnchor = AnchorEntity(
            .image(
                group: "AR Resources",
                name: "PoseidonMarker"
            )
        )

        let puzzlePiece = makePuzzlePiece()
        puzzlePiece.position = [0, 0.02, 0]

        imageAnchor.addChild(puzzlePiece)
        arView.scene.addAnchor(imageAnchor)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    private func makePuzzlePiece() -> Entity {
        let root = Entity()

        let material = SimpleMaterial(
            color: UIColor.systemPurple,
            roughness: 0.35,
            isMetallic: false
        )

        let body = ModelEntity(
            mesh: .generateBox(width: 0.08, height: 0.012, depth: 0.08),
            materials: [material]
        )
        body.position = [0, 0, 0]
        root.addChild(body)

        let topBump = ModelEntity(
            mesh: .generateSphere(radius: 0.018),
            materials: [material]
        )
        topBump.scale = [1.0, 0.35, 1.0]
        topBump.position = [0, 0.006, -0.043]
        root.addChild(topBump)

        let rightBump = ModelEntity(
            mesh: .generateSphere(radius: 0.018),
            materials: [material]
        )
        rightBump.scale = [1.0, 0.35, 1.0]
        rightBump.position = [0.043, 0.006, 0]
        root.addChild(rightBump)

        let socketMaterial = SimpleMaterial(
            color: UIColor.black.withAlphaComponent(0.35),
            roughness: 0.5,
            isMetallic: false
        )

        let leftSocket = ModelEntity(
            mesh: .generateSphere(radius: 0.014),
            materials: [socketMaterial]
        )
        leftSocket.scale = [1.0, 0.08, 1.0]
        leftSocket.position = [-0.041, 0.008, 0]
        root.addChild(leftSocket)

        let bottomSocket = ModelEntity(
            mesh: .generateSphere(radius: 0.014),
            materials: [socketMaterial]
        )
        bottomSocket.scale = [1.0, 0.08, 1.0]
        bottomSocket.position = [0, 0.008, 0.041]
        root.addChild(bottomSocket)

        return root
    }
}
