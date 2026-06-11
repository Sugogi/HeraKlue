import AVFoundation
import MediaPlayer
import SwiftUI

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
    @State private var audio = AudioController()
    @State private var pendingAdvance: Task<Void, Never>? = nil
    @State private var hintAvailable = true
    let airPods: AirPodsController

    private let ink = Color(hex: 0x4A5565)
    private let card = Color.white.opacity(0.9)
    private let accentBlue = Color(hex: 0x6EBCEF)
    private let missionDark = Color.black.opacity(0.68)
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

                ZStack(alignment: .trailing) {
                    VStack(spacing: 12) {
                        missionHUD
                        Spacer()

                        if isDialogueStep {
                            if shouldShowDialogueCard {
                                dialogueCard
                            }
                        } else {
                            missionPromptCard
                        }
                    }
                    .padding()

                    if showsHintButton {
                        hintButton
                            .padding(.trailing, 12)
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard currentStep.allowsTap, canInteractWithCurrentStep else { return }
            goToNextScene()
        }
        .onLongPressGesture(minimumDuration: 1.0) {
            repeatCurrentLine()
        }
        .task(id: currentStep.id) {
            if isDialogueStep {
                speakCurrentLineIfVisible()
            } else {
                audio.play(stepID: currentStep.id)
            }
        }
        .onChange(of: focusedTarget) { _ in
            advanceFromAriadneToPoseidonIfReady()
            guard isDialogueStep else { return }
            speakCurrentLineIfVisible()
        }
        .onChange(of: focusedTargetDistance) { _ in
            advanceFromAriadneToPoseidonIfReady()
            guard isDialogueStep else { return }
            speakCurrentLineIfVisible()
        }
        .onAppear {
            airPods.reactivateSession()
            airPods.onSingleTap = {
                guard currentStep.allowsTap, canInteractWithCurrentStep else { return }
                goToNextScene()
            }
            airPods.onDoubleTap = {
                if showsHintButton {
                    triggerAriadneHint()
                } else {
                    repeatCurrentLine()
                }
            }
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

        guard currentStep.textFocusTarget != nil else {
            // Mission prompts and non dialogue steps are never locked behind
            // the crosshair. Only speaker dialogue requires aiming at the speaker.
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
        currentStep.id == "poseidon_speaks_2_4"
    }

    private var isPoseidonHandoffStep: Bool {
        currentStep.id == "welcome_1_7"
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

    private var showsHintButton: Bool {
        !isDialogueStep && currentStep.missionText != nil && hintAvailable
    }

    private var hintButton: some View {
        Button {
            triggerAriadneHint()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 20))
                Text("tap twice\nfor a hint")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(.white)
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
            .background(accentBlue.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.2), radius: 6, y: 2)
        }
    }

    private func triggerAriadneHint() {
        hintAvailable = false
        if let idx = ARStoryStep.steps.firstIndex(where: { $0.id == "journey_1_3" }) {
            pendingAdvance?.cancel()
            pendingAdvance = nil
            currentIndex = idx
        }
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

            if isDialogueStep {
                dialogueInteractionPrompt
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

    private var dialoguePromptText: String {
        if isPoseidonHandoffStep {
            if focusedTarget == .poseidon {
                return "Move closer to Poseidon"
            }

            return "Walk to Poseidon and aim at him"
        }

        if shouldShowDialogueCard {
            return currentStep.promptText
        }

        if currentStep.textFocusTarget == .poseidon, focusedTarget == .poseidon {
            return "Move closer to Poseidon"
        }

        return "Aim the crosshair at \(speakerName(for: currentStep.textFocusTarget))"
    }

    private var dialogueInteractionPrompt: some View {
        let prompt = dialoguePromptText

        return HStack(spacing: 6) {
            Image(systemName: shouldShowDialogueCard ? "checkmark.circle.fill" : "scope")
            Text(prompt)
                .lineLimit(1)
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

    private var missionPromptCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(currentStep.bodyText)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.95))
                .multilineTextAlignment(.leading)
                .lineLimit(3)

            ButtonHint(text: currentStep.promptText, color: .white.opacity(0.7))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(missionDark)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(accentBlue.opacity(0.4), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.15), radius: 8, y: 3)
    }

    private func speakerName(for target: ARFocusTarget?) -> String {
        switch target {
        case .some(.ariadne):
            return "Ariadne"
        case .some(.poseidon):
            return "Poseidon"
        case .some(.puzzlePiece):
            return "the puzzle piece"
        case .some(.none), .none:
            return "the speaker"
        }
    }

    private func goToNextScene() {
        pendingAdvance?.cancel()
        pendingAdvance = nil
        if currentIndex < ARStoryStep.steps.count - 1 {
            currentIndex += 1
        } else {
            currentIndex = 0
            resetAR.toggle()
        }
    }

    private func advanceFromAriadneToPoseidonIfReady() {
        guard isReadyToStartPoseidonDialogue else { return }
        goToNextScene()
    }

    private func speakCurrentLineIfVisible() {
        guard isDialogueStep, shouldShowDialogueCard else { return }
        guard lastSpokenStepID != currentStep.id else { return }
        lastSpokenStepID = currentStep.id

        guard let duration = audio.play(stepID: currentStep.id) else { return }

        guard autoAdvanceStepIDs.contains(currentStep.id) else { return }
        pendingAdvance?.cancel()
        pendingAdvance = Task {
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            goToNextScene()
        }
    }

    private func repeatCurrentLine() {
        guard isDialogueStep, shouldShowDialogueCard else { return }
        audio.play(stepID: currentStep.id)
    }
}

private final class AudioController {
    private var player: AVAudioPlayer?

    private let stepAudioMap: [String: String] = [
        "parental_consent_1_2": "1 your journey has been arranged",
        "welcome_1_1":          "2 Welcome!",
        "welcome_1_2":          "3 Minotaur vanished",
        "welcome_1_3":          "4 As gods",
        "welcome_1_4":          "5 25 puzzle pieces",
        "welcome_1_5":          "6 secret location",
        "welcome_1_7":          "7 good luck adventurer",
        "poseidon_speaks_1_1":  "yoohoo!",
        "poseidon_speaks_2_1":  "9 Whatsup! im poseidon",
        "poseidon_speaks_2_2":  "10 i cant say much but",
        "poseidon_speaks_2_3":  "11 you have to find",
        "mission_accepted_1_1": "12 The FOUR.STONE.LIONS",
        "journey_1_5":          "13 pssst..over here",
        "journey_1_4":          "hey, follow me!",
        "puzzle_1_2":           "0 press the button to interact",
    ]

    @discardableResult
    func play(stepID: String) -> TimeInterval? {
        guard let filename = stepAudioMap[stepID],
              let url = Bundle.main.url(forResource: filename, withExtension: "mp3"),
              let newPlayer = try? AVAudioPlayer(contentsOf: url) else {
            return nil
        }
        player?.stop()
        player = newPlayer
        player?.play()
        return newPlayer.duration
    }
}

final class AirPodsController {
    var onSingleTap: (() -> Void)?
    var onDoubleTap: (() -> Void)?

    func reactivateSession() {
        try? AVAudioSession.sharedInstance().setCategory(
            .playAndRecord,
            mode: .default,
            options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP]
        )
        try? AVAudioSession.sharedInstance().setActive(true)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: "HeraKlue",
            MPNowPlayingInfoPropertyPlaybackRate: 1.0,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: 0.0,
            MPMediaItemPropertyPlaybackDuration: 9999.0
        ]
    }

    init() {
        try? AVAudioSession.sharedInstance().setCategory(
            .playAndRecord,
            mode: .default,
            options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP]
        )
        try? AVAudioSession.sharedInstance().setActive(true)

        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: "HeraKlue",
            MPNowPlayingInfoPropertyPlaybackRate: 1.0,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: 0.0,
            MPMediaItemPropertyPlaybackDuration: 9999.0
        ]

        let center = MPRemoteCommandCenter.shared()

        center.togglePlayPauseCommand.isEnabled = true
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            print("🎧 AirPods: single tap fired")
            DispatchQueue.main.async { self?.onSingleTap?() }
            return .success
        }

        center.nextTrackCommand.isEnabled = true
        center.nextTrackCommand.addTarget { [weak self] _ in
            print("🎧 AirPods: double tap fired")
            DispatchQueue.main.async { self?.onDoubleTap?() }
            return .success
        }
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
