import ARKit
import RealityKit
import SwiftUI
import UIKit
import simd

struct ARViewContainer: UIViewRepresentable {
    let currentStep: ARStoryStep
    @Binding var resetAR: Bool

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        context.coordinator.arView = arView
        context.coordinator.hasPoseidonMarker = runSession(on: arView, resetTracking: true)

        return arView
    }

    func updateUIView(_ arView: ARView, context: Context) {
        if resetAR {
            arView.scene.anchors.removeAll()
            context.coordinator.clearSceneCache()
            context.coordinator.hasPoseidonMarker = runSession(on: arView, resetTracking: true)

            DispatchQueue.main.async {
                resetAR = false
            }
        }

        context.coordinator.showScene(for: currentStep)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    @discardableResult
    private func runSession(on arView: ARView, resetTracking: Bool) -> Bool {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic

        let referenceImages = ARReferenceImage.referenceImages(
            inGroupNamed: "AR Resources",
            bundle: nil
        )

        if let referenceImages, !referenceImages.isEmpty {
            configuration.detectionImages = referenceImages
            configuration.maximumNumberOfTrackedImages = 1
        }

        let options: ARSession.RunOptions = resetTracking
            ? [.resetTracking, .removeExistingAnchors]
            : []

        arView.session.run(configuration, options: options)
        return referenceImages?.isEmpty == false
    }

    final class Coordinator: NSObject {
        weak var arView: ARView?
        var hasPoseidonMarker = false

        private var lastStepID: String?
        private var activeSceneKey: String?

        func clearSceneCache() {
            lastStepID = nil
            activeSceneKey = nil
        }

        func showScene(for step: ARStoryStep) {
            guard let arView, lastStepID != step.id else { return }

            lastStepID = step.id

            let nextSceneKey = stableSceneKey(for: step.model)

            // Important: do not remove and respawn the same character/object
            // during consecutive dialogue steps. Recreating the anchor places it
            // in front of the current camera again, which makes Poseidon jump
            // whenever the user taps to the next Poseidon scene.
            if nextSceneKey == activeSceneKey {
                return
            }

            activeSceneKey = nextSceneKey
            arView.scene.anchors.removeAll()

            guard step.model != .none else { return }

            let entity = makeEntity(for: step.model)
            let anchor = makeAnchor(for: step.model, arView: arView)
            anchor.addChild(entity)
            arView.scene.addAnchor(anchor)
        }

        private func stableSceneKey(for model: ARModelType) -> String? {
            switch model {
            case .none:
                return nil
            case .poseidonFar, .poseidonClose:
                return "poseidon"
            case .ariadne:
                return "ariadne"
            case .headsetDiagramOne:
                return "headsetDiagram"
            case .lionFountain:
                return "lionFountain"
            case .puzzlePiece:
                return "puzzlePiece"
            case .puzzleSet:
                return "puzzleSet"
            }
        }

        private func makeAnchor(for model: ARModelType, arView: ARView) -> AnchorEntity {
            if model == .puzzlePiece, hasPoseidonMarker {
                return AnchorEntity(.image(group: "AR Resources", name: "PoseidonMarker"))
            }

            let distance = spawnDistance(for: model)

            if usesGroundAnchor(for: model) {
                return AnchorEntity(
                    world: groundedTransformInFrontOfCamera(
                        arView: arView,
                        distance: distance
                    )
                )
            }

            return AnchorEntity(
                world: transformInFrontOfCamera(
                    arView: arView,
                    distance: distance
                )
            )
        }

        private func usesGroundAnchor(for model: ARModelType) -> Bool {
            switch model {
            case .poseidonFar, .poseidonClose, .ariadne:
                return true
            default:
                return false
            }
        }

        private func spawnDistance(for model: ARModelType) -> Float {
            switch model {
            case .poseidonFar, .poseidonClose:
                // Spawn Poseidon several meters away so the player has to walk
                // toward him. Because all Poseidon dialogue steps share the
                // same stable scene key, this anchor is created once and then
                // reused instead of jumping to the camera on each line.
                return -3.2
            case .ariadne:
                return -1.4
            default:
                return -1.2
            }
        }

        private func transformInFrontOfCamera(arView: ARView, distance: Float) -> simd_float4x4 {
            guard let cameraTransform = arView.session.currentFrame?.camera.transform else {
                var fallback = matrix_identity_float4x4
                fallback.columns.3.z = distance
                return fallback
            }

            var transform = cameraTransform

            transform.columns.3.x += cameraTransform.columns.2.x * distance
            transform.columns.3.y += cameraTransform.columns.2.y * distance
            transform.columns.3.z += cameraTransform.columns.2.z * distance

            return transform
        }

        private func groundedTransformInFrontOfCamera(arView: ARView, distance: Float) -> simd_float4x4 {
            guard let cameraTransform = arView.session.currentFrame?.camera.transform else {
                var fallback = matrix_identity_float4x4
                fallback.columns.3.z = distance
                fallback.columns.3.y = 0
                return fallback
            }

            let cameraPosition = SIMD3<Float>(
                cameraTransform.columns.3.x,
                cameraTransform.columns.3.y,
                cameraTransform.columns.3.z
            )

            // Use only the user's horizontal facing direction. This keeps the
            // character upright on the floor instead of inheriting camera pitch.
            let cameraRight = horizontalUnitVector(
                from: SIMD3<Float>(
                    cameraTransform.columns.0.x,
                    cameraTransform.columns.0.y,
                    cameraTransform.columns.0.z
                ),
                fallback: SIMD3<Float>(1, 0, 0)
            )

            let cameraBackward = horizontalUnitVector(
                from: SIMD3<Float>(
                    cameraTransform.columns.2.x,
                    cameraTransform.columns.2.y,
                    cameraTransform.columns.2.z
                ),
                fallback: SIMD3<Float>(0, 0, 1)
            )

            var spawnPosition = cameraPosition + cameraBackward * distance
            spawnPosition.y = detectedGroundY(in: arView) ?? cameraPosition.y - 1.45

            var transform = matrix_identity_float4x4
            transform.columns.0 = SIMD4<Float>(cameraRight.x, 0, cameraRight.z, 0)
            transform.columns.1 = SIMD4<Float>(0, 1, 0, 0)
            transform.columns.2 = SIMD4<Float>(cameraBackward.x, 0, cameraBackward.z, 0)
            transform.columns.3 = SIMD4<Float>(spawnPosition.x, spawnPosition.y, spawnPosition.z, 1)

            return transform
        }

        private func horizontalUnitVector(from vector: SIMD3<Float>, fallback: SIMD3<Float>) -> SIMD3<Float> {
            let horizontal = SIMD3<Float>(vector.x, 0, vector.z)
            let length = simd_length(horizontal)

            guard length > 0.0001 else { return fallback }
            return horizontal / length
        }

        private func detectedGroundY(in arView: ARView) -> Float? {
            guard !arView.bounds.isEmpty else { return nil }

            let samplePoints = [
                CGPoint(x: arView.bounds.midX, y: arView.bounds.midY),
                CGPoint(x: arView.bounds.midX, y: arView.bounds.height * 0.65),
                CGPoint(x: arView.bounds.midX, y: arView.bounds.height * 0.8)
            ]

            for point in samplePoints {
                let results = arView.raycast(
                    from: point,
                    allowing: .estimatedPlane,
                    alignment: .horizontal
                )

                if let result = results.first {
                    return result.worldTransform.columns.3.y
                }
            }

            return nil
        }

        private func makeEntity(for model: ARModelType) -> Entity {
            switch model {
            case .none:
                return Entity()
            case .headsetDiagramOne:
                return makeHeadsetDiagram()
            case .ariadne:
                return makeAriadne()
            case .poseidonFar:
                return makePoseidon(isFar: true)
            case .poseidonClose:
                return makePoseidon(isFar: false)
            case .lionFountain:
                return makeLionFountain()
            case .puzzlePiece:
                return makePuzzlePiece()
            case .puzzleSet:
                return makePuzzleSet()
            }
        }

        private func makePoseidon(isFar: Bool) -> Entity {
            do {
                let poseidon = try Entity.load(named: "Poseidon_Stylized")
                poseidon.scale = isFar
                    ? SIMD3<Float>(0.9, 0.9, 0.9)
                    : SIMD3<Float>(1.0, 1.0, 1.0)
                poseidon.position = SIMD3<Float>(0, 0, 0)
                poseidon.generateCollisionShapes(recursive: true)
                return poseidon
            } catch {
                print("Could not load Poseidon_Stylized.usdz: \(error)")
                return makePoseidonPlaceholder(isFar: isFar)
            }
        }

        private func makePoseidonPlaceholder(isFar: Bool) -> Entity {
            let group = Entity()

            let body = ModelEntity(
                mesh: .generateBox(width: 0.18, height: 0.42, depth: 0.12),
                materials: [SimpleMaterial(color: .systemBlue, roughness: 0.35, isMetallic: false)]
            )
            body.position = SIMD3<Float>(0, 0.21, 0)

            let head = ModelEntity(
                mesh: .generateSphere(radius: 0.1),
                materials: [SimpleMaterial(color: .cyan, roughness: 0.35, isMetallic: false)]
            )
            head.position = SIMD3<Float>(0, 0.53, 0)

            let exclamation = ModelEntity(
                mesh: .generateSphere(radius: 0.045),
                materials: [SimpleMaterial(color: .systemYellow, roughness: 0.2, isMetallic: false)]
            )
            exclamation.position = SIMD3<Float>(0, 0.79, 0)

            group.addChild(body)
            group.addChild(head)
            group.addChild(exclamation)
            group.scale = isFar ? SIMD3<Float>(0.9, 0.9, 0.9) : SIMD3<Float>(1, 1, 1)
            group.position = SIMD3<Float>(0, 0, 0)

            return group
        }

        private func makeHeadsetDiagram() -> Entity {
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

            let leftSpeaker = ModelEntity(
                mesh: .generateSphere(radius: 0.04),
                materials: [SimpleMaterial(color: .systemBlue, roughness: 0.3, isMetallic: false)]
            )
            leftSpeaker.position = SIMD3<Float>(-0.24, -0.02, 0)

            let rightSpeaker = ModelEntity(
                mesh: .generateSphere(radius: 0.04),
                materials: [SimpleMaterial(color: .systemBlue, roughness: 0.3, isMetallic: false)]
            )
            rightSpeaker.position = SIMD3<Float>(0.16, -0.02, 0)

            group.addChild(headset)
            group.addChild(button)
            group.addChild(leftSpeaker)
            group.addChild(rightSpeaker)

            return group
        }

        private func makeAriadne() -> Entity {
            do {
                let ariadne = try Entity.load(named: "Ariadne_Stylized")
                ariadne.scale = SIMD3<Float>(0.85, 0.85, 0.85)
                ariadne.position = SIMD3<Float>(0, 0, 0)
                ariadne.orientation = simd_quatf(angle: .pi, axis: SIMD3<Float>(0, 1, 0))
                ariadne.generateCollisionShapes(recursive: true)
                return ariadne
            } catch {
                print("Could not load Ariadne_Stylized.usdz: \(error)")
                return makeAriadnePlaceholder()
            }
        }

        private func makeAriadnePlaceholder() -> Entity {
            let group = Entity()

            let body = ModelEntity(
                mesh: .generateBox(width: 0.16, height: 0.36, depth: 0.1),
                materials: [SimpleMaterial(color: .systemPurple, roughness: 0.35, isMetallic: false)]
            )
            body.position = SIMD3<Float>(0, 0.18, 0)

            let head = ModelEntity(
                mesh: .generateSphere(radius: 0.09),
                materials: [SimpleMaterial(color: .magenta, roughness: 0.35, isMetallic: false)]
            )
            head.position = SIMD3<Float>(0, 0.46, 0)

            let guideMarker = ModelEntity(
                mesh: .generateSphere(radius: 0.04),
                materials: [SimpleMaterial(color: .systemYellow, roughness: 0.25, isMetallic: false)]
            )
            guideMarker.position = SIMD3<Float>(0.22, 0.36, 0)

            group.addChild(body)
            group.addChild(head)
            group.addChild(guideMarker)
            group.orientation = simd_quatf(angle: .pi, axis: SIMD3<Float>(0, 1, 0))

            return group
        }

        private func makeLionFountain() -> Entity {
            let group = Entity()

            let fountain = ModelEntity(
                mesh: .generateBox(width: 0.35, height: 0.08, depth: 0.35),
                materials: [SimpleMaterial(color: .systemGray, roughness: 0.5, isMetallic: false)]
            )
            group.addChild(fountain)

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

            group.position = SIMD3<Float>(0, -0.25, 0)
            return group
        }

        private func makePuzzlePiece() -> Entity {
            let root = Entity()
            let material = SimpleMaterial(color: .systemPurple, roughness: 0.35, isMetallic: false)

            let body = ModelEntity(
                mesh: .generateBox(width: 0.08, height: 0.012, depth: 0.08),
                materials: [material]
            )
            root.addChild(body)

            let topBump = ModelEntity(mesh: .generateSphere(radius: 0.018), materials: [material])
            topBump.scale = SIMD3<Float>(1.0, 0.35, 1.0)
            topBump.position = SIMD3<Float>(0, 0.006, -0.043)
            root.addChild(topBump)

            let rightBump = ModelEntity(mesh: .generateSphere(radius: 0.018), materials: [material])
            rightBump.scale = SIMD3<Float>(1.0, 0.35, 1.0)
            rightBump.position = SIMD3<Float>(0.043, 0.006, 0)
            root.addChild(rightBump)

            let socketMaterial = SimpleMaterial(
                color: UIColor.black.withAlphaComponent(0.35),
                roughness: 0.5,
                isMetallic: false
            )

            let leftSocket = ModelEntity(mesh: .generateSphere(radius: 0.014), materials: [socketMaterial])
            leftSocket.scale = SIMD3<Float>(1.0, 0.08, 1.0)
            leftSocket.position = SIMD3<Float>(-0.041, 0.008, 0)
            root.addChild(leftSocket)

            let bottomSocket = ModelEntity(mesh: .generateSphere(radius: 0.014), materials: [socketMaterial])
            bottomSocket.scale = SIMD3<Float>(1.0, 0.08, 1.0)
            bottomSocket.position = SIMD3<Float>(0, 0.008, 0.041)
            root.addChild(bottomSocket)

            root.position = SIMD3<Float>(0, -0.1, 0)
            root.scale = SIMD3<Float>(2.2, 2.2, 2.2)

            return root
        }

        private func makePuzzleSet() -> Entity {
            let group = Entity()

            let board = ModelEntity(
                mesh: .generateBox(width: 0.55, height: 0.35, depth: 0.03),
                materials: [SimpleMaterial(color: .systemGray, roughness: 0.4, isMetallic: false)]
            )

            let collectedPiece = makePuzzlePiece()
            collectedPiece.position = SIMD3<Float>(-0.2, 0.08, 0.04)
            collectedPiece.scale = SIMD3<Float>(1.2, 1.2, 1.2)

            group.addChild(board)
            group.addChild(collectedPiece)

            return group
        }
    }
}
