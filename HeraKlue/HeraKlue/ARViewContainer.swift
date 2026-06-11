import ARKit
import RealityKit
import SwiftUI
import UIKit
import simd

struct ARViewContainer: UIViewRepresentable {
    let currentStep: ARStoryStep
    @Binding var resetAR: Bool
    @Binding var focusedTarget: ARFocusTarget

    private enum MissionMarker {
        static let resourceName = "ar_marker"
        static let resourceExtension = "jpg"
        static let referenceName = "MissionMarker"

        // Match this to the real printed marker width.
        // 0.12 means the printed marker is 12 centimeters wide.
        static let physicalWidth: CGFloat = 0.12
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        context.coordinator.startFocusTracking(in: arView)
        arView.session.delegate = context.coordinator
        context.coordinator.hasMissionMarker = runSession(on: arView, resetTracking: true)

        return arView
    }

    func updateUIView(_ arView: ARView, context: Context) {
        if resetAR {
            arView.scene.anchors.removeAll()
            context.coordinator.clearSceneCache()
            context.coordinator.hasMissionMarker = runSession(on: arView, resetTracking: true)

            DispatchQueue.main.async {
                resetAR = false
            }
        }

        context.coordinator.showScene(for: currentStep)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(focusedTarget: $focusedTarget)
    }

    @discardableResult
    private func runSession(on arView: ARView, resetTracking: Bool) -> Bool {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic

        let referenceImages = makeReferenceImages()

        if !referenceImages.isEmpty {
            configuration.detectionImages = referenceImages
            configuration.maximumNumberOfTrackedImages = 1
        }

        let options: ARSession.RunOptions = resetTracking
            ? [.resetTracking, .removeExistingAnchors]
            : []

        arView.session.run(configuration, options: options)
        return !referenceImages.isEmpty
    }

    private func makeReferenceImages() -> Set<ARReferenceImage> {
        var referenceImages = Set<ARReferenceImage>()

        if let missionMarker = loadMissionMarkerReferenceImage() {
            referenceImages.insert(missionMarker)
        }

        // Keep support for an optional AR Resources asset catalog group.
        // This is not required for the uploaded ar_marker.jpg flow.
        if let assetCatalogImages = ARReferenceImage.referenceImages(
            inGroupNamed: "AR Resources",
            bundle: nil
        ) {
            referenceImages.formUnion(assetCatalogImages)
        }

        return referenceImages
    }

    private func loadMissionMarkerReferenceImage() -> ARReferenceImage? {
        if let image = UIImage(named: MissionMarker.resourceName),
           let cgImage = image.cgImage {
            return makeMissionMarkerReferenceImage(from: cgImage)
        }

        if let url = Bundle.main.url(
            forResource: MissionMarker.resourceName,
            withExtension: MissionMarker.resourceExtension
        ),
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data),
           let cgImage = image.cgImage {
            return makeMissionMarkerReferenceImage(from: cgImage)
        }

        print("Could not load mission marker image: \(MissionMarker.resourceName).\(MissionMarker.resourceExtension)")
        return nil
    }

    private func makeMissionMarkerReferenceImage(from cgImage: CGImage) -> ARReferenceImage {
        let referenceImage = ARReferenceImage(
            cgImage,
            orientation: .up,
            physicalWidth: MissionMarker.physicalWidth
        )
        referenceImage.name = MissionMarker.referenceName
        return referenceImage
    }

    final class Coordinator: NSObject, ARSessionDelegate {
        weak var arView: ARView?
        var hasMissionMarker = false

        private var focusedTarget: Binding<ARFocusTarget>
        private var displayLink: CADisplayLink?
        private var currentStep: ARStoryStep?
        private var lastStepID: String?
        private var activeTransientSceneKey: String?
        private var transientAnchor: AnchorEntity?
        private var persistentPoseidonAnchor: AnchorEntity?
        private var persistentAriadneAnchor: AnchorEntity?
        private var missionMarkerTransform: simd_float4x4?

        init(focusedTarget: Binding<ARFocusTarget>) {
            self.focusedTarget = focusedTarget
            super.init()
        }

        deinit {
            displayLink?.invalidate()
        }

        func startFocusTracking(in arView: ARView) {
            self.arView = arView

            displayLink?.invalidate()
            let link = CADisplayLink(target: self, selector: #selector(updateFocusedTarget))
            link.add(to: .main, forMode: .common)
            displayLink = link
        }

        @objc private func updateFocusedTarget() {
            guard let arView, !arView.bounds.isEmpty else { return }

            let center = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
            let target = arView.hitTest(center)
                .compactMap { focusTarget(for: $0.entity) }
                .first ?? .none

            if focusedTarget.wrappedValue != target {
                focusedTarget.wrappedValue = target
            }
        }

        private func focusTarget(for entity: Entity) -> ARFocusTarget? {
            var current: Entity? = entity

            while let entity = current {
                switch entity.name {
                case ARFocusTarget.ariadne.rawValue:
                    return .ariadne
                case ARFocusTarget.poseidon.rawValue:
                    return .poseidon
                case ARFocusTarget.puzzlePiece.rawValue:
                    return .puzzlePiece
                default:
                    current = entity.parent
                }
            }

            return nil
        }

        private func tagEntity(_ entity: Entity, as target: ARFocusTarget) {
            entity.name = target.rawValue

            for child in entity.children {
                tagEntity(child, as: target)
            }
        }

        private func addFocusHitbox(
            to entity: Entity,
            as target: ARFocusTarget,
            size: SIMD3<Float>,
            centerY: Float
        ) {
            let hitbox = Entity()
            hitbox.name = target.rawValue
            hitbox.position = SIMD3<Float>(0, centerY, 0)
            hitbox.components.set(
                CollisionComponent(shapes: [.generateBox(size: size)])
            )
            entity.addChild(hitbox)
        }

        func clearSceneCache() {
            currentStep = nil
            lastStepID = nil
            activeTransientSceneKey = nil
            transientAnchor = nil
            persistentPoseidonAnchor = nil
            persistentAriadneAnchor = nil
            missionMarkerTransform = nil
            focusedTarget.wrappedValue = .none
        }

        func showScene(for step: ARStoryStep, forceRefresh: Bool = false) {
            currentStep = step

            guard let arView else { return }
            guard forceRefresh || lastStepID != step.id else { return }

            lastStepID = step.id

            if isPoseidon(step.model) {
                // Poseidon is persistent. Once he appears, he is never removed
                // during normal scene changes. This lets the user keep walking
                // toward the same anchored Poseidon while tapping through scenes.
                ensurePoseidonExists(for: step.model, in: arView)
                removeTransientAnchor()
                return
            }

            if shouldUseMissionMarker(for: step) {
                showMarkerGatedScene(for: step, in: arView, forceRefresh: forceRefresh)
                return
            }

            let nextSceneKey = transientSceneKey(for: step.model)

            if nextSceneKey == activeTransientSceneKey, transientAnchor != nil {
                return
            }

            removeTransientAnchor()

            guard step.model != .none else { return }

            let entity = makeEntity(for: step.model)
            let anchor = makeAnchor(for: step.model, arView: arView)
            anchor.addChild(entity)
            arView.scene.addAnchor(anchor)
            transientAnchor = anchor
            activeTransientSceneKey = nextSceneKey
        }

        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            handleMissionMarkerAnchors(anchors)
        }

        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            handleMissionMarkerAnchors(anchors)
        }

        private func handleMissionMarkerAnchors(_ anchors: [ARAnchor]) {
            guard let imageAnchor = anchors
                .compactMap({ $0 as? ARImageAnchor })
                .first(where: { $0.referenceImage.name == MissionMarker.referenceName })
            else { return }

            guard let step = currentStep, isMissionStarted(step) else {
                // Scanning the marker before the mission starts should not spawn
                // Ariadne or the puzzle piece.
                return
            }

            missionMarkerTransform = imageAnchor.transform

            DispatchQueue.main.async { [weak self] in
                guard let self,
                      let step = self.currentStep,
                      self.shouldUseMissionMarker(for: step),
                      self.transientAnchor == nil
                else { return }

                self.showScene(for: step, forceRefresh: true)
            }
        }

        private func showMarkerGatedScene(for step: ARStoryStep, in arView: ARView, forceRefresh: Bool) {
            let nextSceneKey = missionMarkerSceneKey(for: step.model)

            guard missionMarkerTransform != nil else {
                // The mission has started, but the user has not scanned the marker yet.
                // Keep Poseidon persistent, but do not spawn Ariadne or the puzzle piece.
                removeTransientAnchor()
                return
            }

            if step.model == .ariadne {
                // Ariadne should stay in the world after she gives the hints.
                // Keep her on a separate persistent anchor so later puzzle-piece
                // scenes do not remove her.
                removeTransientAnchor()
                ensureAriadneExistsAtMissionMarker(in: arView)
                return
            }

            if !forceRefresh, nextSceneKey == activeTransientSceneKey, transientAnchor != nil {
                return
            }

            removeTransientAnchor()

            let entity = makeMarkerGatedEntity(for: step.model)
            let anchor = AnchorEntity(
                world: markerGroundedTransformFacingCamera(arView: arView)
            )
            anchor.addChild(entity)
            arView.scene.addAnchor(anchor)
            transientAnchor = anchor
            activeTransientSceneKey = nextSceneKey
        }

        private func ensurePoseidonExists(for model: ARModelType, in arView: ARView) {
            guard persistentPoseidonAnchor == nil else { return }

            let entity = makePoseidon(isFar: model == .poseidonFar)
            let anchor = makeAnchor(for: model, arView: arView)
            anchor.addChild(entity)
            arView.scene.addAnchor(anchor)
            persistentPoseidonAnchor = anchor
        }

        private func ensureAriadneExistsAtMissionMarker(in arView: ARView) {
            guard persistentAriadneAnchor == nil else { return }

            let entity = makeMarkerGatedEntity(for: .ariadne)
            let anchor = AnchorEntity(
                world: markerGroundedTransformFacingCamera(arView: arView)
            )
            anchor.addChild(entity)
            arView.scene.addAnchor(anchor)
            persistentAriadneAnchor = anchor
        }

        private func removeTransientAnchor() {
            transientAnchor?.removeFromParent()
            transientAnchor = nil
            activeTransientSceneKey = nil
        }

        private func isPoseidon(_ model: ARModelType) -> Bool {
            switch model {
            case .poseidonFar, .poseidonClose:
                return true
            default:
                return false
            }
        }

        private func isMissionStarted(_ step: ARStoryStep) -> Bool {
            step.id.hasPrefix("mission_accepted")
                || step.id.hasPrefix("journey_")
                || step.id.hasPrefix("puzzle_")
        }

        private func shouldUseMissionMarker(for step: ARStoryStep) -> Bool {
            guard isMissionStarted(step) else { return false }

            switch step.model {
            case .ariadne, .puzzlePiece:
                return true
            default:
                return false
            }
        }

        private func missionMarkerSceneKey(for model: ARModelType) -> String? {
            switch model {
            case .ariadne:
                return "missionMarkerAriadne"
            case .puzzlePiece:
                return "missionMarkerPuzzlePiece"
            default:
                return nil
            }
        }

        private func transientSceneKey(for model: ARModelType) -> String? {
            switch model {
            case .none, .poseidonFar, .poseidonClose:
                return nil
            case .ariadne:
                return "ariadne"
            case .puzzlePiece:
                return "puzzlePiece"
            case .puzzleSet:
                return "puzzleSet"
            }
        }

        private func makeAnchor(for model: ARModelType, arView: ARView) -> AnchorEntity {
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
                // toward him. Because the Poseidon anchor is persistent, this
                // is only used the first time Poseidon appears.
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

        private func markerGroundedTransformFacingCamera(arView: ARView) -> simd_float4x4 {
            guard let markerTransform = missionMarkerTransform else {
                return groundedTransformInFrontOfCamera(arView: arView, distance: -1.2)
            }

            let markerPosition = SIMD3<Float>(
                markerTransform.columns.3.x,
                markerTransform.columns.3.y,
                markerTransform.columns.3.z
            )

            let cameraTransform = arView.session.currentFrame?.camera.transform
            let cameraPosition = cameraTransform.map {
                SIMD3<Float>($0.columns.3.x, $0.columns.3.y, $0.columns.3.z)
            } ?? SIMD3<Float>(markerPosition.x, markerPosition.y, markerPosition.z + 1)

            let toCamera = horizontalUnitVector(
                from: cameraPosition - markerPosition,
                fallback: SIMD3<Float>(0, 0, 1)
            )

            let right = horizontalUnitVector(
                from: SIMD3<Float>(toCamera.z, 0, -toCamera.x),
                fallback: SIMD3<Float>(1, 0, 0)
            )

            let groundY = detectedGroundY(in: arView)
                ?? cameraPosition.y - 1.45

            var transform = matrix_identity_float4x4
            transform.columns.0 = SIMD4<Float>(right.x, 0, right.z, 0)
            transform.columns.1 = SIMD4<Float>(0, 1, 0, 0)
            transform.columns.2 = SIMD4<Float>(toCamera.x, 0, toCamera.z, 0)
            transform.columns.3 = SIMD4<Float>(markerPosition.x, groundY, markerPosition.z, 1)

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
            case .ariadne:
                return makeAriadne()
            case .poseidonFar:
                return makePoseidon(isFar: true)
            case .poseidonClose:
                return makePoseidon(isFar: false)
            case .puzzlePiece:
                return makePuzzlePiece()
            case .puzzleSet:
                return makePuzzleSet()
            }
        }

        private func makeMarkerGatedEntity(for model: ARModelType) -> Entity {
            switch model {
            case .ariadne:
                let ariadne = makeAriadne()
                ariadne.position = SIMD3<Float>(0, 0, 0)
                return ariadne
            case .puzzlePiece:
                let puzzlePiece = makePuzzlePiece()
                puzzlePiece.position = SIMD3<Float>(0, 0.45, 0)
                // Stand the flat puzzle piece upright when it appears from the scanned marker.
                puzzlePiece.orientation = simd_quatf(
                    angle: .pi / 2,
                    axis: SIMD3<Float>(1, 0, 0)
                )
                return puzzlePiece
            default:
                return makeEntity(for: model)
            }
        }

        private func makePoseidon(isFar: Bool) -> Entity {
            do {
                let poseidon = try Entity.load(named: "Poseidon_Stylized")
                poseidon.scale = isFar
                    ? SIMD3<Float>(0.9, 0.9, 0.9)
                    : SIMD3<Float>(1.0, 1.0, 1.0)
                poseidon.position = SIMD3<Float>(0, 0, 0)
                tagEntity(poseidon, as: .poseidon)
                addFocusHitbox(
                    to: poseidon,
                    as: .poseidon,
                    size: SIMD3<Float>(0.9, 1.8, 0.6),
                    centerY: 0.9
                )
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
            tagEntity(group, as: .poseidon)
            addFocusHitbox(
                to: group,
                as: .poseidon,
                size: SIMD3<Float>(0.55, 1.0, 0.45),
                centerY: 0.5
            )
            group.generateCollisionShapes(recursive: true)

            return group
        }

        private func makeAriadne() -> Entity {
            do {
                let ariadne = try Entity.load(named: "Ariadne_Stylized")
                ariadne.scale = SIMD3<Float>(0.85, 0.85, 0.85)
                ariadne.position = SIMD3<Float>(0, 0, 0)
                ariadne.orientation = simd_quatf(angle: .pi, axis: SIMD3<Float>(0, 1, 0))
                tagEntity(ariadne, as: .ariadne)
                addFocusHitbox(
                    to: ariadne,
                    as: .ariadne,
                    size: SIMD3<Float>(0.8, 1.6, 0.55),
                    centerY: 0.8
                )
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
            tagEntity(group, as: .ariadne)
            addFocusHitbox(
                to: group,
                as: .ariadne,
                size: SIMD3<Float>(0.45, 0.9, 0.4),
                centerY: 0.45
            )
            group.generateCollisionShapes(recursive: true)

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
            tagEntity(root, as: .puzzlePiece)
            addFocusHitbox(
                to: root,
                as: .puzzlePiece,
                size: SIMD3<Float>(0.35, 0.35, 0.2),
                centerY: 0.08
            )
            root.generateCollisionShapes(recursive: true)

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
