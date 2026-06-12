import AVFoundation
import MediaPlayer
import SwiftUI
import UIKit

// Steps that auto-advance when their audio finishes (if the user hasn't tapped first).
private let autoAdvanceStepIDs: Set<String> = [
    "welcome_1_1", "welcome_1_2", "welcome_1_3",
    "welcome_1_4", "welcome_1_5", "welcome_1_7",
    "poseidon_speaks_1_1", "poseidon_speaks_2_1",
    "poseidon_speaks_2_2", "poseidon_speaks_2_3"
]

struct ContentView: View {
    @State private var currentIndex = 0
    @State private var resetAR = false
    @State private var focusedTarget: ARFocusTarget = .none
    @State private var focusedTargetDistance: Float? = nil
    @State private var lastSpokenStepID: String? = nil
    @State private var audio = StoryAudioController()
    @State private var pendingAdvance: Task<Void, Never>? = nil
    @State private var ariadneHelpRequested = false
    @State private var showAriadneHelpOffer = false
    @State private var helpOfferDismissed = false
    let airPods: AirPodsController

    private let ink = Color(hex: 0x4A5565)
    private let card = Color.white.opacity(0.9)
    private let accentBlue = Color(hex: 0x6EBCEF)
    private let poseidonDialogueRange: Float = 2.25

    private var currentStep: ARStoryStep {
        ARStoryStep.steps[currentIndex]
    }

    private var isDialogueStep: Bool {
        currentStep.textFocusTarget != nil
    }

    var body: some View {
        ZStack {
            ARViewContainer(
                currentStep: currentStep,
                resetAR: $resetAR,
                focusedTarget: $focusedTarget,
                focusedTargetDistance: $focusedTargetDistance
            )
            .ignoresSafeArea()

            if let onboarding = currentStep.onboarding {
                OnboardingScreenView(screen: onboarding)
            } else {
                if currentStep.showsCrosshair {
                    CrosshairView(accentBlue: accentBlue)
                }

                VStack(spacing: 12) {
                    missionHUD

                    if showAriadneHelpOffer {
                        compactAriadneHelpOffer
                    }

                    Spacer()

                    if isDialogueStep {
                        if shouldShowDialogueCard {
                            dialogueCard
                        } else {
                            aimPrompt
                        }
                    } else if shouldShowCompactActionPrompt {
                        compactActionPrompt
                    }
                }
                .padding()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            handlePrimaryTap()
        }
        .onLongPressGesture(minimumDuration: 1.0) {
            repeatCurrentLine()
        }
        .onAppear {
            airPods.reactivateSession()
            airPods.onSingleTap = {
                handlePrimaryTap()
            }
            airPods.onDoubleTap = {
                if showAriadneHelpOffer || isMissionStartedStep {
                    requestAriadneHelp()
                } else {
                    repeatCurrentLine()
                }
            }
        }
        .task(id: currentStep.id) {
            playCurrentAudioIfAllowed()
        }
        .task(id: isMissionStartedStep) {
            await scheduleAriadneHelpOfferIfNeeded()
        }
        .onChange(of: focusedTarget) { _ in
            advanceFromAriadneToPoseidonIfReady()
            guard isDialogueStep else { return }
            playCurrentAudioIfAllowed()
        }
        .onChange(of: focusedTargetDistance) { _ in
            advanceFromAriadneToPoseidonIfReady()
            guard isDialogueStep else { return }
            playCurrentAudioIfAllowed()
        }
    }

    private var shouldShowDialogueCard: Bool {
        guard let requiredFocusTarget = currentStep.textFocusTarget else { return false }
        guard focusedTarget == requiredFocusTarget else { return false }
        return isCloseEnoughForCurrentDialogue
    }

    private var canInteractWithCurrentStep: Bool {
        if isPoseidonHandoffStep { return false }
        if requiresPuzzleCrosshairToCollect { return focusedTarget == .puzzlePiece }
        guard currentStep.textFocusTarget != nil else { return true }
        return shouldShowDialogueCard
    }

    private var isCloseEnoughForCurrentDialogue: Bool {
        guard currentStep.textFocusTarget == .poseidon else { return true }
        guard let focusedTargetDistance else { return false }
        return focusedTargetDistance <= poseidonDialogueRange
    }

    private var isAcceptMissionStep: Bool { currentStep.id == "poseidon_speaks_2_5" }
    private var isPoseidonHandoffStep: Bool { currentStep.id == "welcome_1_7" }
    private var requiresPuzzleCrosshairToCollect: Bool { currentStep.id == "puzzle_1_2" }

    private var isMissionStartedStep: Bool {
        currentStep.id.hasPrefix("mission_accepted")
            || currentStep.id.hasPrefix("journey_")
            || currentStep.id.hasPrefix("puzzle_")
    }

    private var isReadyToStartPoseidonDialogue: Bool {
        guard isPoseidonHandoffStep, focusedTarget == .poseidon else { return false }
        guard let focusedTargetDistance else { return false }
        return focusedTargetDistance <= poseidonDialogueRange
    }

    private var shouldShowMissionObjectiveCard: Bool {
        isAcceptMissionStep ? shouldShowDialogueCard : true
    }

    private var missionHUD: some View {
        VStack(spacing: 8) {
            if shouldShowMissionObjectiveCard {
                missionObjectiveCard
            }
        }
    }

    private var missionObjectiveCard: some View {
        Group {
            if let mission = currentStep.missionText {
                HStack(spacing: 6) {
                    Image(systemName: "mappin")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(accentBlue)
                    Text(mission)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(ink)
                        .lineLimit(1)
                }
                .padding(.vertical, 7)
                .padding(.horizontal, 12)
                .background(card)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.1), radius: 4, y: 1)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var dialogueCard: some View {
        Text(currentStep.bodyText)
            .font(.system(size: 15, design: .rounded))
            .foregroundColor(ink)
            .multilineTextAlignment(.leading)
            .lineLimit(3)
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(card)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.1), radius: 6, y: 2)
    }

    private var aimPrompt: some View {
        let name: String
        switch currentStep.textFocusTarget {
        case .ariadne: name = "Ariadne"
        case .poseidon: name = "Poseidon"
        default: name = "the character"
        }
        let text = (currentStep.textFocusTarget == .poseidon && focusedTarget == .poseidon)
            ? "Move closer to Poseidon"
            : "Aim at \(name)"
        return HStack(spacing: 6) {
            Image(systemName: "scope")
            Text(text).lineLimit(1)
        }
        .font(.system(size: 13, weight: .semibold, design: .rounded))
        .foregroundStyle(.white)
        .padding(.vertical, 7)
        .padding(.horizontal, 12)
        .background(accentBlue.opacity(0.82))
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.15), radius: 4, y: 1)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var shouldShowCompactActionPrompt: Bool {
        requiresPuzzleCrosshairToCollect && focusedTarget == .puzzlePiece
    }

    private var compactActionPrompt: some View {
        Text("Collect")
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.vertical, 7)
            .padding(.horizontal, 16)
            .background(accentBlue.opacity(0.92))
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.22), radius: 8, y: 3)
    }

    private var compactAriadneHelpOffer: some View {
        Text("Need help? Press headphone button.")
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.vertical, 7)
            .padding(.horizontal, 14)
            .background(Color.black.opacity(0.68))
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.18), radius: 8, y: 3)
    }

    private func handlePrimaryTap() {
        if showAriadneHelpOffer {
            requestAriadneHelp()
            return
        }
        guard currentStep.allowsTap, canInteractWithCurrentStep else { return }
        goToNextScene()
    }

    private func goToNextScene() {
        pendingAdvance?.cancel()
        pendingAdvance = nil
        if currentIndex < ARStoryStep.steps.count - 1 {
            var nextIndex = currentIndex + 1
            while nextIndex < ARStoryStep.steps.count - 1,
                  shouldSkipTransitionStep(ARStoryStep.steps[nextIndex]) {
                nextIndex += 1
            }
            currentIndex = nextIndex
        } else {
            currentIndex = 0
            resetAR.toggle()
            ariadneHelpRequested = false
            showAriadneHelpOffer = false
            helpOfferDismissed = false
        }
    }

    private func shouldSkipTransitionStep(_ step: ARStoryStep) -> Bool {
        transitionOnlyStepIDs.contains(step.id)
    }

    private var transitionOnlyStepIDs: Set<String> {
        [
            "mission_accepted_1_1", "mission_accepted_1_2", "mission_accepted_1_3",
            "journey_1_1", "journey_1_2", "journey_1_3", "journey_1_4", "journey_1_5",
            "puzzle_1_1", "puzzle_1_3", "puzzle_1_4"
        ]
    }

    @MainActor
    private func scheduleAriadneHelpOfferIfNeeded() async {
        guard isMissionStartedStep else {
            showAriadneHelpOffer = false
            return
        }
        guard !ariadneHelpRequested, !helpOfferDismissed else { return }

        showAriadneHelpOffer = false
        try? await Task.sleep(for: .seconds(45))

        guard !Task.isCancelled, isMissionStartedStep, !ariadneHelpRequested, !helpOfferDismissed
        else { return }

        showAriadneHelpOffer = true
    }

    private func requestAriadneHelp() {
        ariadneHelpRequested = true
        showAriadneHelpOffer = false
        helpOfferDismissed = true
        audio.play(fileName: "13 pssst..over here.mp3", fallbackText: "Psst... over here! I will guide you.")
    }

    private func advanceFromAriadneToPoseidonIfReady() {
        guard isReadyToStartPoseidonDialogue else { return }
        goToNextScene()
    }

    private func playCurrentAudioIfAllowed() {
        if isDialogueStep {
            guard shouldShowDialogueCard else { return }
        }
        guard currentStep.audioFileName != nil || isDialogueStep else { return }
        guard lastSpokenStepID != currentStep.id else { return }

        let duration = audio.play(fileName: currentStep.audioFileName, fallbackText: currentStep.bodyText)
        lastSpokenStepID = currentStep.id

        guard let duration, autoAdvanceStepIDs.contains(currentStep.id) else { return }
        pendingAdvance?.cancel()
        pendingAdvance = Task {
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            goToNextScene()
        }
    }

    private func repeatCurrentLine() {
        if isDialogueStep { guard shouldShowDialogueCard else { return } }
        audio.play(fileName: currentStep.audioFileName, fallbackText: currentStep.repeatLine ?? currentStep.bodyText)
    }
}

final class AirPodsController {
    var onSingleTap: (() -> Void)?
    var onDoubleTap: (() -> Void)?

    func reactivateSession() {
        try? AVAudioSession.sharedInstance().setCategory(
            .playback, mode: .spokenAudio, options: [.allowBluetooth, .allowBluetoothA2DP, .duckOthers]
        )
        try? AVAudioSession.sharedInstance().setActive(true)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: "HeraKlue",
            MPMediaItemPropertyArtist: "Adventure Controls",
            MPNowPlayingInfoPropertyPlaybackRate: 0.0
        ]
    }

    init() {
        try? AVAudioSession.sharedInstance().setCategory(
            .playback, mode: .spokenAudio, options: [.allowBluetooth, .allowBluetoothA2DP, .duckOthers]
        )
        try? AVAudioSession.sharedInstance().setActive(true)

        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: "HeraKlue",
            MPMediaItemPropertyArtist: "Adventure Controls",
            MPNowPlayingInfoPropertyPlaybackRate: 0.0
        ]

        let center = MPRemoteCommandCenter.shared()

        center.playCommand.isEnabled = true
        center.pauseCommand.isEnabled = true
        center.togglePlayPauseCommand.isEnabled = true
        center.nextTrackCommand.isEnabled = true

        center.playCommand.addTarget { [weak self] _ in
            print("🎧 single tap (play)")
            DispatchQueue.main.async { self?.onSingleTap?() }
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            print("🎧 single tap (pause)")
            DispatchQueue.main.async { self?.onSingleTap?() }
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            print("🎧 single tap (toggle)")
            DispatchQueue.main.async { self?.onSingleTap?() }
            return .success
        }
        center.nextTrackCommand.addTarget { [weak self] _ in
            print("🎧 double tap")
            DispatchQueue.main.async { self?.onDoubleTap?() }
            return .success
        }
    }
}

private final class StoryAudioController {
    private let synthesizer = AVSpeechSynthesizer()
    private var player: AVAudioPlayer?

    @discardableResult
    func play(fileName: String?, fallbackText: String) -> TimeInterval? {
        stopCurrentAudio()

        if let fileName, let url = bundledAudioURL(for: fileName) {
            if let player = try? AVAudioPlayer(contentsOf: url) {
                player.prepareToPlay()
                player.play()
                self.player = player
                return player.duration
            }
            print("Could not play audio file \(fileName)")
        } else if let fileName {
            print("Could not find audio file: \(fileName)")
        }

        speakFallback(fallbackText)
        return nil
    }

    private func stopCurrentAudio() {
        player?.stop()
        player = nil
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func bundledAudioURL(for fileName: String) -> URL? {
        let nsFileName = fileName as NSString
        let resourceName = nsFileName.deletingPathExtension
        let ext = nsFileName.pathExtension.isEmpty ? "mp3" : nsFileName.pathExtension
        return Bundle.main.url(forResource: resourceName, withExtension: ext)
    }

    private func speakFallback(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.48
        synthesizer.speak(utterance)
    }
}

struct CrosshairView: View {
    let accentBlue: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.9), lineWidth: 3)
                .frame(width: 44, height: 44)
            Circle()
                .fill(accentBlue)
                .frame(width: 8, height: 8)
        }
        .shadow(color: .black.opacity(0.35), radius: 4)
    }
}
