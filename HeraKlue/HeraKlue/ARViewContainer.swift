//
//  ARViewContainer.swift
//  HeraKlue
//
//  Created by Stephen Lee on 6/9/26.
//


import SwiftUI
import RealityKit
import ARKit
import UIKit

struct ARViewContainer: UIViewRepresentable {
    let currentStep: ARStoryStep
    @Binding var resetAR: Bool

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic

        arView.session.run(config)

        context.coordinator.arView = arView

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            context.coordinator.showScene(for: currentStep)
        }

        return arView
    }

    func updateUIView(_ arView: ARView, context: Context) {
        if resetAR {
            arView.scene.anchors.removeAll()

            let config = ARWorldTrackingConfiguration()
            config.planeDetection = [.horizontal]
            config.environmentTexturing = .automatic

            arView.session.run(
                config,
                options: [.resetTracking, .removeExistingAnchors]
            )

            DispatchQueue.main.async {
                resetAR = false
            }
        }

        context.coordinator.showScene(for: currentStep)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject {
        weak var arView: ARView?
        private var lastSceneId: String?

        func showScene(for step: ARStoryStep) {
            guard let arView else { return }

            if lastSceneId == step.id {
                return
            }

            lastSceneId = step.id
            arView.scene.anchors.removeAll()

            guard step.model != .none else {
                return
            }

            let anchor = AnchorEntity(world: positionInFrontOfCamera(arView: arView))
            let entity = createEntity(for: step.model)

            anchor.addChild(entity)
            arView.scene.addAnchor(anchor)
        }

        private func positionInFrontOfCamera(arView: ARView) -> simd_float4x4 {
            guard let cameraTransform = arView.session.currentFrame?.camera.transform else {
                var fallback = matrix_identity_float4x4
                fallback.columns.3.z = -1.0
                return fallback
            }

            var transform = cameraTransform
            let distance: Float = -1.2

            transform.columns.3.x += cameraTransform.columns.2.x * distance
            transform.columns.3.y += cameraTransform.columns.2.y * distance
            transform.columns.3.z += cameraTransform.columns.2.z * distance

            return transform
        }

        private func createEntity(for model: ARModelType) -> Entity {
            switch model {
            case .none:
                return Entity()

            case .headsetDiagramOne:
                return createHeadsetDiagramOne()

            case .headsetDiagramTwo:
                return createHeadsetDiagramTwo()

            case .poseidonFar:
                return createPoseidon(isFar: true)

            case .poseidonClose:
                return createPoseidon(isFar: false)

            case .ariadne:
                return createAriadne()

            case .lionFountain:
                return createLionFountain()

            case .puzzlePiece:
                return createPuzzlePiece()
                
            case .ariadneGuide:
                return createAriadne()

            case .puzzleSet:
                return createPuzzleSet()
            }
        }

        private func createPuzzleSet() -> Entity {
            let group = Entity()

            let board = ModelEntity(
                mesh: .generateBox(width: 0.55, height: 0.35, depth: 0.03),
                materials: [SimpleMaterial(color: .systemGray, roughness: 0.4, isMetallic: false)]
            )

            let collectedPiece = ModelEntity(
                mesh: .generateBox(width: 0.1, height: 0.1, depth: 0.04),
                materials: [SimpleMaterial(color: .systemYellow, roughness: 0.2, isMetallic: true)]
            )

            collectedPiece.position = SIMD3<Float>(-0.2, 0.08, 0.04)

            group.addChild(board)
            group.addChild(collectedPiece)

            return group
            }
        
        private func createHeadsetDiagramOne() -> Entity {
            let group = Entity()

            let headset = ModelEntity(
                mesh: .generateBox(width: 0.45, height: 0.2, depth: 0.12),
                materials: [SimpleMaterial(color: .darkGray, roughness: 0.4, isMetallic: false)]
            )

            let button = ModelEntity(
                mesh: .generateSphere(radius: 0.045),
                materials: [SimpleMaterial(color: .systemYellow, roughness: 0.3, isMetallic: false)]
            )
            button.position = SIMD3<Float>(0.28, 0.03, 0)

            let speakerLeft = ModelEntity(
                mesh: .generateSphere(radius: 0.04),
                materials: [SimpleMaterial(color: .systemBlue, roughness: 0.3, isMetallic: false)]
            )
            speakerLeft.position = SIMD3<Float>(-0.24, -0.02, 0)

            let speakerRight = ModelEntity(
                mesh: .generateSphere(radius: 0.04),
                materials: [SimpleMaterial(color: .systemBlue, roughness: 0.3, isMetallic: false)]
            )
            speakerRight.position = SIMD3<Float>(0.16, -0.02, 0)

            group.addChild(headset)
            group.addChild(button)
            group.addChild(speakerLeft)
            group.addChild(speakerRight)

            return group
        }

        private func createHeadsetDiagramTwo() -> Entity {
            let group = Entity()

            let headset = ModelEntity(
                mesh: .generateBox(width: 0.45, height: 0.2, depth: 0.12),
                materials: [SimpleMaterial(color: .darkGray, roughness: 0.4, isMetallic: false)]
            )

            let camera = ModelEntity(
                mesh: .generateSphere(radius: 0.055),
                materials: [SimpleMaterial(color: .systemRed, roughness: 0.2, isMetallic: false)]
            )
            camera.position = SIMD3<Float>(0, 0.05, -0.08)

            group.addChild(headset)
            group.addChild(camera)

            return group
        }

        private func createPoseidon(isFar: Bool) -> Entity {
            guard let url = Bundle.main.url(
                forResource: "Poseidon",
                withExtension: "usdz"
            ) else {
                print("❌ Could not find Poseidon.usdz in app bundle.")
                return createPoseidonPlaceholder(isFar: isFar)
            }

            do {
                let poseidon = try Entity.load(contentsOf: url)

                diagnoseModelDepth(entity: poseidon, name: "Poseidon.usdz")

                poseidon.scale = isFar
                    ? SIMD3<Float>(0.03, 0.03, 0.03)
                    : SIMD3<Float>(0.045, 0.045, 0.045)

                poseidon.position = isFar
                    ? SIMD3<Float>(0, -0.15, -0.5)
                    : SIMD3<Float>(0, -0.2, 0)

                poseidon.generateCollisionShapes(recursive: true)

                print("✅ Poseidon.usdz loaded successfully.")
                return poseidon
            } catch {
                print("❌ Failed to load Poseidon.usdz: \(error)")
                return createPoseidonPlaceholder(isFar: isFar)
            }
        }
        
        private func diagnoseModelDepth(entity: Entity, name: String) {
            let bounds = entity.visualBounds(relativeTo: nil)
            let size = bounds.extents

            print("----- \(name) MODEL DIAGNOSTIC -----")
            print("Width X: \(size.x)")
            print("Height Y: \(size.y)")
            print("Depth Z: \(size.z)")

            if size.z < 0.01 {
                print("⚠️ \(name) appears very flat. It may be a 2D plane/card instead of a full 3D model.")
            } else {
                print("✅ \(name) has visible depth and should be a real 3D model.")
            }

            print("-----------------------------------")
        }
        private func createPoseidonPlaceholder(isFar: Bool) -> Entity {
            let group = Entity()

            let body = ModelEntity(
                mesh: .generateBox(width: 0.18, height: 0.42, depth: 0.12),
                materials: [
                    SimpleMaterial(
                        color: .systemBlue,
                        roughness: 0.35,
                        isMetallic: false
                    )
                ]
            )
            body.position = SIMD3<Float>(0, 0, 0)

            let head = ModelEntity(
                mesh: .generateSphere(radius: 0.1),
                materials: [
                    SimpleMaterial(
                        color: .cyan,
                        roughness: 0.35,
                        isMetallic: false
                    )
                ]
            )
            head.position = SIMD3<Float>(0, 0.32, 0)

            let exclamation = ModelEntity(
                mesh: .generateSphere(radius: 0.045),
                materials: [
                    SimpleMaterial(
                        color: .systemYellow,
                        roughness: 0.2,
                        isMetallic: false
                    )
                ]
            )
            exclamation.position = SIMD3<Float>(0, 0.58, 0)

            group.addChild(body)
            group.addChild(head)
            group.addChild(exclamation)

            if isFar {
                group.scale = SIMD3<Float>(0.55, 0.55, 0.55)
                group.position = SIMD3<Float>(0, -0.15, -0.5)
            } else {
                group.scale = SIMD3<Float>(1.0, 1.0, 1.0)
                group.position = SIMD3<Float>(0, -0.2, 0)
            }

            return group
        }
        private func createAriadne() -> Entity {
            let group = Entity()

            let body = ModelEntity(
                mesh: .generateBox(width: 0.16, height: 0.36, depth: 0.1),
                materials: [SimpleMaterial(color: .systemPurple, roughness: 0.35, isMetallic: false)]
            )

            let head = ModelEntity(
                mesh: .generateSphere(radius: 0.09),
                materials: [SimpleMaterial(color: .magenta, roughness: 0.35, isMetallic: false)]
            )
            head.position = SIMD3<Float>(0, 0.28, 0)

            let guideMarker = ModelEntity(
                mesh: .generateSphere(radius: 0.04),
                materials: [SimpleMaterial(color: .systemYellow, roughness: 0.25, isMetallic: false)]
            )
            guideMarker.position = SIMD3<Float>(0.22, 0.18, 0)

            group.addChild(body)
            group.addChild(head)
            group.addChild(guideMarker)

            return group
        }

        private func createLionFountain() -> Entity {
            let group = Entity()

            let fountain = ModelEntity(
                mesh: .generateBox(width: 0.35, height: 0.08, depth: 0.35),
                materials: [SimpleMaterial(color: .systemGray, roughness: 0.5, isMetallic: false)]
            )

            let positions: [SIMD3<Float>] = [
                SIMD3<Float>(-0.28, 0.08, -0.28),
                SIMD3<Float>(0.28, 0.08, -0.28),
                SIMD3<Float>(-0.28, 0.08, 0.28),
                SIMD3<Float>(0.28, 0.08, 0.28)
            ]

            for position in positions {
                let lion = ModelEntity(
                    mesh: .generateBox(width: 0.12, height: 0.12, depth: 0.18),
                    materials: [SimpleMaterial(color: .lightGray, roughness: 0.5, isMetallic: false)]
                )
                lion.position = position
                group.addChild(lion)
            }

            group.addChild(fountain)
            group.position = SIMD3<Float>(0, -0.25, 0)

            return group
        }

        private func createPuzzlePiece() -> Entity {
            let piece = ModelEntity(
                mesh: .generateBox(width: 0.18, height: 0.18, depth: 0.04),
                materials: [SimpleMaterial(color: .systemYellow, roughness: 0.2, isMetallic: true)]
            )

            piece.position = SIMD3<Float>(0, -0.1, 0)

            return piece
        }
    }
}
