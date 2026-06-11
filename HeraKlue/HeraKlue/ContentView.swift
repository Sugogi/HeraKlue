import AVFoundation
import SwiftUI

struct ContentView: View {
    @State private var currentIndex = 0
    @State private var resetAR = false
    @State private var focusedTarget: ARFocusTarget = .none
    @State private var focusedTargetDistance: Float? = nil
    @State private var lastSpokenStepID: String? = nil
    @State private var speech = SpeechController()

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
            speakCurrentLineIfVisible()
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
                VStack(spacing: 6) {
                    Text("MISSION")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(ink.opacity(0.6))

                    Text(mission)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(ink)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(card)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
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

        return HStack(spacing: 8) {
            Image(systemName: shouldShowDialogueCard ? "checkmark.circle.fill" : "scope")
            Text(prompt)
                .multilineTextAlignment(.center)
        }
        .font(.system(size: 15, weight: .semibold, design: .rounded))
        .foregroundStyle(.white)
        .padding(.vertical, 9)
        .padding(.horizontal, 16)
        .background(accentBlue.opacity(0.88))
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.18), radius: 6, y: 2)
    }

    private var dialogueCard: some View {
        VStack(spacing: 12) {
            Text(currentStep.title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(ink)
                .multilineTextAlignment(.center)

            Text(currentStep.bodyText)
                .font(.system(size: 18, design: .rounded))
                .foregroundColor(ink)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(card)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
    }

    private var missionPromptCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "location.north.line.fill")
                    .font(.system(size: 14, weight: .bold))

                Text("OBJECTIVE UPDATE")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .tracking(1.1)
            }
            .foregroundStyle(accentBlue)

            Text(currentStep.title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)

            Text(currentStep.bodyText)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.leading)

            Divider()
                .background(.white.opacity(0.3))

            ButtonHint(text: currentStep.promptText, color: .white)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(missionDark)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(accentBlue.opacity(0.55), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 12, y: 5)
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

        speech.speak(currentStep.bodyText)
        lastSpokenStepID = currentStep.id
    }

    private func repeatCurrentLine() {
        guard isDialogueStep, shouldShowDialogueCard else { return }
        speech.speak(currentStep.repeatLine ?? currentStep.bodyText)
    }
}

private final class SpeechController {
    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)

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
