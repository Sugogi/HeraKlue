import AVFoundation
import SwiftUI

struct ContentView: View {
    @State private var currentIndex = 0
    @State private var resetAR = false
    @State private var speech = SpeechController()
    @State private var isNearPoseidon = false

    private let ink = Color(hex: 0x4A5565)
    private let card = Color.white.opacity(0.9)
    private let accentBlue = Color(hex: 0x6EBCEF)

    private var currentStep: ARStoryStep {
        ARStoryStep.steps[currentIndex]
    }

    var body: some View {
        ZStack {
            ARViewContainer(
                currentStep: currentStep,
                resetAR: $resetAR,
                onNearPoseidonChanged: { near in
                    withAnimation(.easeInOut(duration: 0.2)) { isNearPoseidon = near }
                }
            )
            .ignoresSafeArea()

            if let onboarding = currentStep.onboarding {
                OnboardingScreenView(screen: onboarding)
            } else {
                if currentStep.showsCrosshair {
                    CrosshairView(accentBlue: accentBlue)
                }

                VStack {
                    missionCard
                    Spacer()
                    storyCard
                }
                .padding()

                // Appears when the player walks within ~1.5 m of Poseidon.
                // Tapping anywhere still advances the story (the "interact").
                if isNearPoseidon {
                    Label("Tap to interact", systemImage: "hand.tap.fill")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 12)
                        .background(accentBlue, in: Capsule())
                        .shadow(color: .black.opacity(0.3), radius: 8, y: 3)
                        .offset(y: 80)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard currentStep.allowsTap else { return }
            goToNextScene()
        }
        .onLongPressGesture(minimumDuration: 1.0) {
            repeatCurrentLine()
        }
        .task(id: currentStep.id) {
            speech.speak(currentStep.bodyText)
        }
    }

    private var missionCard: some View {
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

    private var storyCard: some View {
        VStack(spacing: 12) {
            Text(currentStep.title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(ink)
                .multilineTextAlignment(.center)

            Text(currentStep.bodyText)
                .font(.system(size: 18, design: .rounded))
                .foregroundColor(ink)
                .multilineTextAlignment(.center)

            ButtonHint(text: currentStep.promptText)
                .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(card)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
    }

    private func goToNextScene() {
        if currentIndex < ARStoryStep.steps.count - 1 {
            currentIndex += 1
        } else {
            currentIndex = 0
            resetAR.toggle()
        }
    }

    private func repeatCurrentLine() {
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
