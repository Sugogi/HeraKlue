import AVFoundation
import MediaPlayer
import SwiftUI
import UIKit

struct ContentView: View {
    @State private var currentIndex = 0
    @State private var resetAR = false
    @State private var focusedTarget: ARFocusTarget = .none
    @State private var focusedTargetDistance: Float? = nil
    @State private var lastSpokenStepID: String? = nil
    @State private var audio = StoryAudioController()
    @State private var headsetButtonController = HeadsetButtonController()
    @State private var ariadneHelpRequested = false
    @State private var showAriadneHelpOffer = false
    @State private var helpOfferDismissed = false

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

                    if isDialogueStep, shouldShowDialogueCard {
                        dialogueCard
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
            headsetButtonController.start {
                handlePrimaryTap()
            }
        }
        .onDisappear {
            headsetButtonController.stop()
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
        guard let requiredFocusTarget = currentStep.textFocusTarget else {
            return false
        }

        guard focusedTarget == requiredFocusTarget else {
            return false
        }

        return isCloseEnoughForCurrentDialogue
    }

    private var canInteractWithCurrentStep: Bool {
        if isPoseidonHandoffStep {
            // The Ariadne-to-Poseidon handoff should not require a button tap.
            // The player advances by physically walking to Poseidon and aiming at him.
            return false
        }

        if requiresPuzzleCrosshairToCollect {
            return focusedTarget == .puzzlePiece
        }

        guard currentStep.textFocusTarget != nil else {
            // Mission prompts and non dialogue steps are never locked behind
            // the crosshair. Only speaker dialogue requires aiming at the speaker.
            // The puzzle pickup step is the exception and requires the crosshair
            // to be centered on the puzzle piece before collection.
            return true
        }

        return shouldShowDialogueCard
    }

    private var isCloseEnoughForCurrentDialogue: Bool {
        guard currentStep.textFocusTarget == .poseidon else {
            return true
        }

        guard let focusedTargetDistance else {
            return false
        }

        return focusedTargetDistance <= poseidonDialogueRange
    }

    private var isAcceptMissionStep: Bool {
        currentStep.id == "poseidon_speaks_2_5"
    }

    private var isPoseidonHandoffStep: Bool {
        currentStep.id == "welcome_1_7"
    }

    private var requiresPuzzleCrosshairToCollect: Bool {
        currentStep.id == "puzzle_1_2"
    }

    private var isMissionStartedStep: Bool {
        currentStep.id.hasPrefix("mission_accepted")
            || currentStep.id.hasPrefix("journey_")
            || currentStep.id.hasPrefix("puzzle_")
    }

    private var isReadyToStartPoseidonDialogue: Bool {
        guard isPoseidonHandoffStep, focusedTarget == .poseidon else {
            return false
        }

        guard let focusedTargetDistance else {
            return false
        }

        return focusedTargetDistance <= poseidonDialogueRange
    }

    private var shouldShowMissionObjectiveCard: Bool {
        if isAcceptMissionStep {
            return shouldShowDialogueCard
        }

        return true
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
                Text(mission)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(ink)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(card)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.10), radius: 4, y: 2)
            }
        }
    }

    private var dialogueCard: some View {
        VStack(spacing: 12) {
            Text(currentStep.title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(ink)
                .multilineTextAlignment(.center)

            Text(currentStep.bodyText)
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(ink)
                .multilineTextAlignment(.center)
        }
        .padding(14)
        .frame(maxWidth: 340)
        .background(card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.14), radius: 8, y: 3)
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
        Text("Need help? Press button.")
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
        if currentIndex < ARStoryStep.steps.count - 1 {
            var nextIndex = currentIndex + 1

            // The UI is intentionally minimal now, so some older mission/objective
            // steps would appear blank. Skip those transition-only steps so every
            // button press lands on something the player can actually see or do.
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
            "mission_accepted_1_1",
            "mission_accepted_1_2",
            "mission_accepted_1_3",
            "journey_1_1",
            "journey_1_2",
            "journey_1_3",
            "journey_1_4",
            "journey_1_5",
            "puzzle_1_1",
            "puzzle_1_3",
            "puzzle_1_4"
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

        guard !Task.isCancelled,
              isMissionStartedStep,
              !ariadneHelpRequested,
              !helpOfferDismissed
        else { return }

        showAriadneHelpOffer = true
    }

    private func requestAriadneHelp() {
        ariadneHelpRequested = true
        showAriadneHelpOffer = false
        helpOfferDismissed = true

        audio.play(
            fileName: "13 pssst..over here.mp3",
            fallbackText: "Psst... over here! I will guide you."
        )
    }

    private func advanceFromAriadneToPoseidonIfReady() {
        guard isReadyToStartPoseidonDialogue else { return }
        goToNextScene()
    }

    private func playCurrentAudioIfAllowed() {
        if isDialogueStep {
            guard shouldShowDialogueCard else { return }
        }

        // Only auto-play supplied MP3 files, except speaker dialogue can still
        // fall back to iOS text-to-speech if a matching file is missing.
        guard currentStep.audioFileName != nil || isDialogueStep else { return }
        guard lastSpokenStepID != currentStep.id else { return }

        audio.play(
            fileName: currentStep.audioFileName,
            fallbackText: currentStep.bodyText
        )
        lastSpokenStepID = currentStep.id
    }

    private func repeatCurrentLine() {
        if isDialogueStep {
            guard shouldShowDialogueCard else { return }
        }

        audio.play(
            fileName: currentStep.audioFileName,
            fallbackText: currentStep.repeatLine ?? currentStep.bodyText
        )
    }
}

private final class HeadsetButtonController {
    private var primaryAction: (() -> Void)?
    private var isRunning = false

    func start(action: @escaping () -> Void) {
        primaryAction = action

        guard !isRunning else { return }
        isRunning = true

        configureAudioSession()
        UIApplication.shared.beginReceivingRemoteControlEvents()
        configureRemoteCommands()
        publishNowPlayingInfo()
    }

    func stop() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.togglePlayPauseCommand.removeTarget(nil)
        commandCenter.nextTrackCommand.removeTarget(nil)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        UIApplication.shared.endReceivingRemoteControlEvents()
        isRunning = false
    }

    private func configureRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.nextTrackCommand.isEnabled = true

        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.triggerPrimaryAction()
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.triggerPrimaryAction()
            return .success
        }

        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.triggerPrimaryAction()
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.triggerPrimaryAction()
            return .success
        }
    }

    private func triggerPrimaryAction() {
        DispatchQueue.main.async { [weak self] in
            self?.primaryAction?()
        }
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.duckOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Headset button audio session setup failed: \(error)")
        }
    }

    private func publishNowPlayingInfo() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: "HeraKlue",
            MPMediaItemPropertyArtist: "Adventure Controls",
            MPNowPlayingInfoPropertyPlaybackRate: 0.0
        ]
    }
}

private final class StoryAudioController {
    private let synthesizer = AVSpeechSynthesizer()
    private var player: AVAudioPlayer?

    func play(fileName: String?, fallbackText: String) {
        stopCurrentAudio()

        if let fileName, let url = bundledAudioURL(for: fileName) {
            do {
                try configureAudioSession()
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                player.play()
                self.player = player
                return
            } catch {
                print("Could not play audio file \(fileName): \(error)")
            }
        } else if let fileName {
            print("Could not find audio file in app bundle: \(fileName)")
        }

        speakFallback(fallbackText)
    }

    private func stopCurrentAudio() {
        player?.stop()
        player = nil
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func bundledAudioURL(for fileName: String) -> URL? {
        let nsFileName = fileName as NSString
        let resourceName = nsFileName.deletingPathExtension
        let fileExtension = nsFileName.pathExtension.isEmpty ? "mp3" : nsFileName.pathExtension

        return Bundle.main.url(forResource: resourceName, withExtension: fileExtension)
    }

    private func configureAudioSession() throws {
        try AVAudioSession.sharedInstance().setCategory(
            .playback,
            mode: .spokenAudio,
            options: [.duckOthers]
        )
        try AVAudioSession.sharedInstance().setActive(true)
    }

    private func speakFallback(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.48
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

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
