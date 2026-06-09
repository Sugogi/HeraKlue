import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var currentIndex = 0
    @State private var resetAR = false
    @State private var spokenText = ""

    private let speechSynthesizer = AVSpeechSynthesizer()

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
        .contentShape(Rectangle())
        .onTapGesture {
            goToNextScene()
        }
        .onLongPressGesture(minimumDuration: 1.0) {
            repeatCurrentLine()
        }
        .onAppear {
            speak(currentStep.bodyText)
        }
    }

    private var topMissionView: some View {
        VStack(spacing: 8) {
            if let mission = currentStep.missionText {
                Text("Mission")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))

                Text(mission)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(.black.opacity(currentStep.missionText == nil ? 0 : 0.65))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var bottomStoryView: some View {
        VStack(spacing: 12) {
            Text(currentStep.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(currentStep.bodyText)
                .font(.body)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text(currentStep.promptText)
                .font(.headline)
                .foregroundColor(.yellow)
                .padding(.top, 4)
        }
        .padding()
        .background(.black.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 22))
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
            Rectangle()
                .fill(.white)
                .frame(width: 30, height: 2)

            Rectangle()
                .fill(.white)
                .frame(width: 2, height: 30)

            Circle()
                .stroke(.white, lineWidth: 2)
                .frame(width: 42, height: 42)
        }
        .opacity(0.9)
    }
}
