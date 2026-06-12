import ARKit
import RealityKit
import SwiftUI
import UIKit
import simd

struct ARViewContainer: UIViewRepresentable {
    let currentStep: ARStoryStep
    @Binding var resetAR: Bool
    @Binding var focusedTarget: ARFocusTarget
    @Binding var focusedTargetDistance: Float?

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
        runSession(on: arView, resetTracking: true)

        return arView
    }

    func updateUIView(_ arView: ARView, context: Context) {
        if resetAR {
            arView.scene.anchors.removeAll()
            context.coordinator.clearSceneCache()
            runSession(on: arView, resetTracking: true)

            DispatchQueue.main.async {
                resetAR = false
            }
        }

        context.coordinator.showScene(for: currentStep)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(focusedTarget: $focusedTarget, focusedTargetDistance: $focusedTargetDistance)
    }

    private func runSession(on arView: ARView, resetTracking: Bool) {
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

        private var focusedTarget: Binding<ARFocusTarget>
        private var focusedTargetDistance: Binding<Float?>
        private var displayLink: CADisplayLink?
        private var currentStep: ARStoryStep?
        private var lastStepID: String?
        private var activeTransientSceneKey: String?
        private var transientAnchor: AnchorEntity?
        private var persistentPoseidonAnchor: AnchorEntity?
        private var persistentAriadneAnchor: AnchorEntity?
        private var missionPuzzlePieceEntity: Entity?
        private var missionMarkerTransform: simd_float4x4?

        init(focusedTarget: Binding<ARFocusTarget>, focusedTargetDistance: Binding<Float?>) {
            self.focusedTarget = focusedTarget
            self.focusedTargetDistance = focusedTargetDistance
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
            let focusedHit = arView.hitTest(center)
                .compactMap { result -> (target: ARFocusTarget, distance: Float)? in
                    guard let target = focusTarget(for: result.entity) else { return nil }
                    return (target, result.distance)
                }
                .first

            let target = focusedHit?.target ?? .none
            let distance = focusedHit?.distance

            if focusedTarget.wrappedValue != target {
                focusedTarget.wrappedValue = target
            }

            if shouldUpdateFocusedDistance(to: distance) {
                focusedTargetDistance.wrappedValue = distance
            }
        }

        private func shouldUpdateFocusedDistance(to newDistance: Float?) -> Bool {
            switch (focusedTargetDistance.wrappedValue, newDistance) {
            case (nil, nil):
                return false
            case (nil, .some), (.some, nil):
                return true
            case let (.some(oldDistance), .some(newDistance)):
                return abs(oldDistance - newDistance) > 0.05
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
            missionPuzzlePieceEntity = nil
            missionMarkerTransform = nil
            focusedTarget.wrappedValue = .none
            focusedTargetDistance.wrappedValue = nil
        }

        func showScene(for step: ARStoryStep, forceRefresh: Bool = false) {
            currentStep = step

            guard let arView else { return }
            guard forceRefresh || lastStepID != step.id else { return }

            lastStepID = step.id

            removeCollectedMissionPuzzlePieceIfNeeded(for: step)

            if shouldKeepPoseidonVisible(for: step) {
                // Poseidon is part of the world from the Ariadne tutorial onward.
                // Spawn him once beside Ariadne and keep the same anchor for the
                // rest of the prototype so he never disappears between story steps.
                ensurePoseidonExists(for: .poseidonFar, in: arView)
            }

            if isPoseidon(step.model) {
                // Poseidon is persistent. Once he appears, he is never removed
                // during normal scene changes.
                removeTransientAnchor()
                return
            }

            if shouldUseMissionMarker(for: step) {
                showMarkerGatedScene(for: step, in: arView)
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

        private func showMarkerGatedScene(for step: ARStoryStep, in arView: ARView) {
            guard missionMarkerTransform != nil else {
                removeTransientAnchor()
                return
            }

            if step.model == .ariadne || step.model == .puzzlePiece {
                removeTransientAnchor()
                ensureAriadneAndPuzzlePieceExistAtMissionMarker(in: arView)
            }
        }

        private func ensurePoseidonExists(for model: ARModelType, in arView: ARView) {
            guard persistentPoseidonAnchor == nil else { return }

            let entity = makePoseidon(isFar: model == .poseidonFar)
            let anchor = makeAnchor(for: model, arView: arView)
            anchor.addChild(entity)
            arView.scene.addAnchor(anchor)
            persistentPoseidonAnchor = anchor
        }

        private func ensureAriadneAndPuzzlePieceExistAtMissionMarker(in arView: ARView) {
            guard persistentAriadneAnchor == nil else { return }

            let entity = makeAriadneWithPuzzlePieceAbove()
            let anchor = AnchorEntity(
                world: markerGroundedTransformFacingCamera(
                    arView: arView,
                    distanceFromMarker: 2.0
                )
            )
            anchor.addChild(entity)
            arView.scene.addAnchor(anchor)
            persistentAriadneAnchor = anchor
        }

        private func removeCollectedMissionPuzzlePieceIfNeeded(for step: ARStoryStep) {
            guard isPuzzleCollected(step) else { return }

            missionPuzzlePieceEntity?.removeFromParent()
            missionPuzzlePieceEntity = nil

            if focusedTarget.wrappedValue == .puzzlePiece {
                focusedTarget.wrappedValue = .none
                focusedTargetDistance.wrappedValue = nil
            }
        }

        private func isPuzzleCollected(_ step: ARStoryStep) -> Bool {
            step.id == "puzzle_1_3"
                || step.id == "puzzle_1_4"
                || step.id == "puzzle_1_5"
                || step.id == "puzzle_1_6"
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

        private func shouldKeepPoseidonVisible(for step: ARStoryStep) -> Bool {
            // Poseidon should first appear as soon as the Ariadne tutorial begins,
            // then stay in the AR world for every step after that.
            step.id.hasPrefix("welcome_")
                || step.id.hasPrefix("poseidon_")
                || isMissionStarted(step)
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
            let lateralOffset = spawnLateralOffset(for: model)

            if usesGroundAnchor(for: model) {
                return AnchorEntity(
                    world: groundedTransformInFrontOfCamera(
                        arView: arView,
                        distance: distance,
                        lateralOffset: lateralOffset
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

        private func spawnLateralOffset(for model: ARModelType) -> Float {
            switch model {
            case .poseidonFar, .poseidonClose:
                // Keep Poseidon visible during Ariadne's tutorial without placing
                // him directly behind Ariadne's hitbox. Positive values place him
                // to the user's right at initial spawn.
                return 1.25
            default:
                return 0
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

        private func groundedTransformInFrontOfCamera(
            arView: ARView,
            distance: Float,
            lateralOffset: Float = 0
        ) -> simd_float4x4 {
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

            var spawnPosition = cameraPosition
                + cameraBackward * distance
                + cameraRight * lateralOffset
            spawnPosition.y = detectedGroundY(in: arView) ?? cameraPosition.y - 1.45

            var transform = matrix_identity_float4x4
            transform.columns.0 = SIMD4<Float>(cameraRight.x, 0, cameraRight.z, 0)
            transform.columns.1 = SIMD4<Float>(0, 1, 0, 0)
            transform.columns.2 = SIMD4<Float>(cameraBackward.x, 0, cameraBackward.z, 0)
            transform.columns.3 = SIMD4<Float>(spawnPosition.x, spawnPosition.y, spawnPosition.z, 1)

            return transform
        }


        private func markerGroundedTransformFacingCamera(
            arView: ARView,
            distanceFromMarker: Float = 0
        ) -> simd_float4x4 {
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

            // Direction from the marker toward the player/camera. Ariadne uses
            // this to spawn away from the reference marker instead of directly
            // on top of the printed image.
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

            let spawnPosition = markerPosition + toCamera * distanceFromMarker

            var transform = matrix_identity_float4x4
            transform.columns.0 = SIMD4<Float>(right.x, 0, right.z, 0)
            transform.columns.1 = SIMD4<Float>(0, 1, 0, 0)
            transform.columns.2 = SIMD4<Float>(toCamera.x, 0, toCamera.z, 0)
            transform.columns.3 = SIMD4<Float>(spawnPosition.x, groundY, spawnPosition.z, 1)

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

        private func setEntityVisualHeight(_ entity: Entity, to targetHeight: Float) {
            let bounds = entity.visualBounds(relativeTo: entity)
            let currentHeight = bounds.extents.y

            guard currentHeight.isFinite, currentHeight > 0.001 else { return }

            let scaleFactor = targetHeight / currentHeight
            entity.scale = SIMD3<Float>(scaleFactor, scaleFactor, scaleFactor)
        }

        private func makePoseidon(isFar: Bool) -> Entity {
            do {
                let root = Entity()
                let poseidonModel = try Entity.load(named: "Poseidon_Stylized")

                // Normalize Poseidon to a real world height of about 2 meters.
                setEntityVisualHeight(poseidonModel, to: 2.0)

                root.addChild(poseidonModel)
                root.position = SIMD3<Float>(0, 0, 0)

                tagEntity(root, as: .poseidon)
                addFocusHitbox(
                    to: root,
                    as: .poseidon,
                    size: SIMD3<Float>(1.0, 2.1, 0.75),
                    centerY: 1.05
                )
                root.generateCollisionShapes(recursive: true)
                return root
            } catch {
                print("Could not load Poseidon_Stylized.usdz: \(error)")
                return makePoseidonPlaceholder(isFar: isFar)
            }
        }

        private func makePoseidonPlaceholder(isFar: Bool) -> Entity {
            let group = Entity()

            let body = ModelEntity(
                mesh: .generateBox(width: 0.45, height: 1.25, depth: 0.28),
                materials: [SimpleMaterial(color: .systemBlue, roughness: 0.35, isMetallic: false)]
            )
            body.position = SIMD3<Float>(0, 0.625, 0)

            let head = ModelEntity(
                mesh: .generateSphere(radius: 0.24),
                materials: [SimpleMaterial(color: .cyan, roughness: 0.35, isMetallic: false)]
            )
            head.position = SIMD3<Float>(0, 1.42, 0)

            let exclamation = ModelEntity(
                mesh: .generateSphere(radius: 0.07),
                materials: [SimpleMaterial(color: .systemYellow, roughness: 0.2, isMetallic: false)]
            )
            exclamation.position = SIMD3<Float>(0, 1.88, 0)

            group.addChild(body)
            group.addChild(head)
            group.addChild(exclamation)
            group.position = SIMD3<Float>(0, 0, 0)
            tagEntity(group, as: .poseidon)
            addFocusHitbox(
                to: group,
                as: .poseidon,
                size: SIMD3<Float>(1.0, 2.1, 0.75),
                centerY: 1.05
            )
            group.generateCollisionShapes(recursive: true)

            return group
        }

        private func makeAriadneWithPuzzlePieceAbove() -> Entity {
            let group = Entity()

            let ariadne = makeAriadne()
            ariadne.position = SIMD3<Float>(0, 0, 0)
            group.addChild(ariadne)

            let puzzlePiece = makePuzzlePiece()
            // Place the puzzle piece above Ariadne's head and keep it upright.
            // Ariadne is normalized to 2 meters tall, so 2.45 meters puts the
            // puzzle piece clearly above her without blocking her face.
            puzzlePiece.position = SIMD3<Float>(0, 2.45, 0)
            puzzlePiece.orientation = simd_quatf(
                angle: .pi / 2,
                axis: SIMD3<Float>(1, 0, 0)
            )
            missionPuzzlePieceEntity = puzzlePiece
            group.addChild(puzzlePiece)

            group.generateCollisionShapes(recursive: true)
            return group
        }

        private func makeAriadne() -> Entity {
            do {
                let root = Entity()
                let ariadneModel = try Entity.load(named: "Ariadne_Stylized")

                // Normalize Ariadne to a real world height of about 2 meters.
                setEntityVisualHeight(ariadneModel, to: 2.0)

                root.addChild(ariadneModel)
                root.position = SIMD3<Float>(0, 0, 0)
                root.orientation = simd_quatf(angle: .pi, axis: SIMD3<Float>(0, 1, 0))

                tagEntity(root, as: .ariadne)
                addFocusHitbox(
                    to: root,
                    as: .ariadne,
                    size: SIMD3<Float>(0.9, 2.1, 0.65),
                    centerY: 1.05
                )
                root.generateCollisionShapes(recursive: true)
                return root
            } catch {
                print("Could not load Ariadne_Stylized.usdz: \(error)")
                return makeAriadnePlaceholder()
            }
        }

        private func makeAriadnePlaceholder() -> Entity {
            let group = Entity()

            let body = ModelEntity(
                mesh: .generateBox(width: 0.4, height: 1.15, depth: 0.25),
                materials: [SimpleMaterial(color: .systemPurple, roughness: 0.35, isMetallic: false)]
            )
            body.position = SIMD3<Float>(0, 0.575, 0)

            let head = ModelEntity(
                mesh: .generateSphere(radius: 0.24),
                materials: [SimpleMaterial(color: .magenta, roughness: 0.35, isMetallic: false)]
            )
            head.position = SIMD3<Float>(0, 1.35, 0)

            let guideMarker = ModelEntity(
                mesh: .generateSphere(radius: 0.07),
                materials: [SimpleMaterial(color: .systemYellow, roughness: 0.25, isMetallic: false)]
            )
            guideMarker.position = SIMD3<Float>(0.42, 1.15, 0)

            group.addChild(body)
            group.addChild(head)
            group.addChild(guideMarker)
            group.position = SIMD3<Float>(0, 0, 0)
            group.orientation = simd_quatf(angle: .pi, axis: SIMD3<Float>(0, 1, 0))
            tagEntity(group, as: .ariadne)
            addFocusHitbox(
                to: group,
                as: .ariadne,
                size: SIMD3<Float>(0.9, 2.1, 0.65),
                centerY: 1.05
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
            // Rotate the flat puzzle piece so it sits upright on the vertical board
            // instead of lying sideways/edge-on. The board face is on the X/Y plane.
            collectedPiece.orientation = simd_quatf(
                angle: .pi / 2,
                axis: SIMD3<Float>(1, 0, 0)
            )

            group.addChild(board)
            group.addChild(collectedPiece)

            return group
        }
    }
}
