import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var currentIndex = 0
    @State private var resetAR = false
    @State private var spokenText = ""

    private let speechSynthesizer = AVSpeechSynthesizer()

    // Figma palette — Stephen's structure, the Figma look.
    private let ink = Color(red: 74 / 255, green: 85 / 255, blue: 101 / 255)         // #4A5565
    private let card = Color.white.opacity(0.9)
    private let accentBlue = Color(red: 110 / 255, green: 188 / 255, blue: 239 / 255) // #6EBCEF

    var currentStep: ARStoryStep {
        ARStoryStep.steps[currentIndex]
    }

    var body: some View {
        ZStack {
            ARViewContainer(
                currentStep: currentStep,
                resetAR: $resetAR
            )
            .ignoresSafeArea()

            if let onboarding = currentStep.onboarding {
                // Early steps show the Figma 2D screens over the camera.
                OnboardingScreenView(screen: onboarding)
            } else {
                if currentStep.showsCrosshair {
                    CrosshairView()
                }

                VStack {
                    topMissionView

                    Spacer()

                    bottomStoryView
                }
                .padding()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if currentStep.allowsTap { goToNextScene() }
        }
        .task(id: currentStep.id) {
            // Timed auto-advance for steps that opt in (waiting screen,
            // Ariadne's welcome sequence). Restarts whenever the step changes.
            guard let delay = currentStep.autoAdvance else { return }
            try? await Task.sleep(for: .seconds(delay))
            if !Task.isCancelled { goToNextScene() }
        }
        .onLongPressGesture(minimumDuration: 1.0) {
            repeatCurrentLine()
        }
        .onAppear {
            speak(currentStep.bodyText)
        }
    }

    private var topMissionView: some View {
        VStack(spacing: 6) {
            if let mission = currentStep.missionText {
                Text("MISSION")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(ink.opacity(0.6))

                Text(mission)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(ink)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
        .opacity(currentStep.missionText == nil ? 0 : 1)
    }

    private var bottomStoryView: some View {
        VStack(spacing: 12) {
            Text(currentStep.title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(ink)
                .multilineTextAlignment(.center)

            Text(currentStep.bodyText)
                .font(.system(size: 18, design: .rounded))
                .foregroundColor(ink)
                .multilineTextAlignment(.center)

            if currentStep.autoAdvance == nil {
                ButtonHint(text: currentStep.promptText)
                    .padding(.top, 4)
            }
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

        speak(currentStep.bodyText)
    }

    private func repeatCurrentLine() {
        if let repeatLine = currentStep.repeatLine {
            speak(repeatLine)
        } else {
            speak(currentStep.bodyText)
        }
    }

    private func speak(_ text: String) {
        speechSynthesizer.stopSpeaking(at: .immediate)

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.48
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        speechSynthesizer.speak(utterance)
    }
}

struct CrosshairView: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.9), lineWidth: 3)
                .frame(width: 44, height: 44)

            Circle()
                .fill(Color(red: 110 / 255, green: 188 / 255, blue: 239 / 255)) // #6EBCEF
                .frame(width: 8, height: 8)
        }
        .shadow(color: .black.opacity(0.35), radius: 4)
    }
}
