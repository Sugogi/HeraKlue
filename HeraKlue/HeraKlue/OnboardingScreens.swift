//
//  OnboardingScreens.swift
//  HeraKlue
//
//  The Figma-designed 2D onboarding screens, shown over the AR camera during
//  the early steps. Advancing is handled by ContentView's global tap (the
//  headset's physical button), so these are purely visual — no on-screen
//  buttons. "Press the button" appears as a quiet ButtonHint, not a pill.
//

import SwiftUI

struct OnboardingScreenView: View {
    let screen: OnboardingScreen

    var body: some View {
        switch screen {
        case .headsetButtonSpeakers: HeadsetButtonSpeakersScreen()
        case .headsetCamera:         HeadsetCameraScreen()
        case .loading:               LoadingOnboarding()
        case .pressToContinue:       PressToContinueOnboarding()
        case .waitingForParent:
            StatusOnboarding(
                message: "HeraKlue needs your parent’s approval before the myth hunt begins.",
                messageSize: 20,
                footer: .waiting
            )
        case .journeyArranged:
            StatusOnboarding(
                message: "Your Journey has been arranged!",
                messageSize: 36,
                footer: .hint("Press the button to continue")
            )
        }
    }
}

// MARK: - Shared pieces

private struct CalloutLabel: View {
    let text: String
    var size: CGFloat = 22

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .medium, design: .rounded))
            .foregroundStyle(.black)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(hex: 0xD9D9D9), in: Capsule())
            .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
    }
}

// MARK: - Headset screens (501:7, 501:8)

private struct HeadsetButtonSpeakersScreen: View {
    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()

            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(Color(hex: 0x7340C4, opacity: 0.55))
                Image("HeadsetButtonSpeakers").resizable().scaledToFit().padding(18)
            }
            .frame(width: 330, height: 300)
            .overlay(alignment: .topTrailing) { CalloutLabel(text: "Button", size: 24).offset(x: 78, y: 4) }
            .overlay(alignment: .bottomLeading) { CalloutLabel(text: "Speakers", size: 20).offset(x: -36, y: 14) }

            ButtonHint(text: "Press the button to continue")
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 30)
        }
    }
}

private struct HeadsetCameraScreen: View {
    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()

            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(Color(hex: 0x753EB4, opacity: 0.55))
                Image("HeadsetCamera").resizable().scaledToFit().padding(18)
            }
            .frame(width: 300, height: 320)
            .overlay(alignment: .bottomLeading) { CalloutLabel(text: "Camera", size: 24).offset(x: -34, y: 6) }

            VStack(spacing: 0) {
                Spacer()
                ButtonHint(text: "Press the button to continue")
                    .padding(.bottom, 14)
                Text("Make sure nothing is blocking your camera")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundStyle(.black)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.7))
            }
        }
    }
}

// MARK: - Loading (213:12)

private struct LoadingOnboarding: View {
    @State private var progress: CGFloat = 0

    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()

            VStack(spacing: 28) {
                Image("HeraklueLogo").resizable().scaledToFit().frame(maxWidth: 460)
                    .shadow(color: .black.opacity(0.3), radius: 10)

                VStack(spacing: 14) {
                    Text("Loading your adventure...")
                        .font(.system(size: 18)).tracking(-0.44).foregroundStyle(.black)
                        .shadow(color: .white.opacity(0.85), radius: 5)

                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(hex: 0x030213, opacity: 0.2)).frame(width: 256, height: 12)
                        Capsule().fill(Color(hex: 0x4A5565)).frame(width: 256 * progress, height: 12)
                    }
                    .frame(width: 256, height: 12)
                }
            }
            .padding(40)
        }
        .task {
            withAnimation(.easeInOut(duration: 2.5)) { progress = 1 }
        }
    }
}

// MARK: - Press to continue (213:21)

private struct PressToContinueOnboarding: View {
    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()

            VStack(spacing: 24) {
                Image("HeraklueLogo").resizable().scaledToFit().frame(maxWidth: 460)
                    .shadow(color: .black.opacity(0.3), radius: 10)
                ButtonHint(text: "Press the button to continue")
            }
            .padding(40)

            Image("HeadsetDevice")
                .resizable().scaledToFit().frame(width: 130)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, 24)
                .padding(.bottom, 24)
        }
    }
}

// MARK: - Status screens (213:36, 213:49)

private struct StatusOnboarding: View {
    enum Footer {
        case waiting              // a non-interactive "waiting" status
        case hint(String)         // a physical-button hint
    }

    let message: String
    let messageSize: CGFloat
    let footer: Footer

    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()

            VStack(spacing: 28) {
                Text(message)
                    .font(.system(size: messageSize,
                                  weight: messageSize >= 30 ? .semibold : .regular,
                                  design: .rounded))
                    .tracking(-0.44)
                    .foregroundStyle(Color(hex: 0x4A5565))
                    .shadow(color: .white.opacity(0.85), radius: 5)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 480)

                switch footer {
                case .waiting:
                    HStack(spacing: 10) {
                        ProgressView().tint(Color(hex: 0x4A5565))
                        Text("Waiting for parent approval…")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundStyle(Color(hex: 0x4A5565).opacity(0.75))
                    }
                case .hint(let text):
                    ButtonHint(text: text)
                }
            }
            .padding(40)
        }
    }
}
