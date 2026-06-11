//
//  OnboardingScreens.swift
//  HeraKlue
//
//  The Figma intro/onboarding screens, shown over the AR camera. Content sits
//  inside a slightly-transparent COMPONENT CARD sized to fit it (NOT a full-
//  screen film), so it's readable while the camera still shows through behind
//  and around it. Advancing is handled by ContentView's global tap.
//

import SwiftUI

// === The one knob ===
// Background opacity of the intro cards/pills. 1.0 = solid white,
// lower = more see-through (e.g. 0.6 lets more camera show).
private let cardOpacity: Double = 0.82

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

// MARK: - Reusable translucent backings (sized to content, not full-screen)

private extension View {
    /// A slightly-transparent rounded card behind a block of content.
    func onboardingCard(padding: CGFloat = 28) -> some View {
        self
            .padding(padding)
            .background(Color.white.opacity(cardOpacity), in: RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.25), radius: 16, y: 6)
    }

    /// A small translucent pill behind a single line (hints, the camera banner).
    func whiteChip() -> some View {
        self
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Color.white.opacity(cardOpacity), in: Capsule())
            .shadow(color: .black.opacity(0.2), radius: 8, y: 3)
    }
}

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
                .whiteChip()
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

            VStack(spacing: 12) {
                Spacer()
                Text("Make sure nothing is blocking your camera")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)
                    .whiteChip()
                ButtonHint(text: "Press the button to continue")
                    .whiteChip()
            }
            .padding(.bottom, 26)
        }
    }
}

// MARK: - Loading (213:12)

private struct LoadingOnboarding: View {
    @State private var progress: CGFloat = 0

    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()

            VStack(spacing: 22) {
                Image("HeraklueLogo").resizable().scaledToFit().frame(maxWidth: 320)

                Text("Loading your adventure...")
                    .font(.system(size: 18)).tracking(-0.44).foregroundStyle(.black)

                ZStack(alignment: .leading) {
                    Capsule().fill(Color(hex: 0x030213, opacity: 0.2)).frame(width: 256, height: 12)
                    Capsule().fill(Color(hex: 0x4A5565)).frame(width: 256 * progress, height: 12)
                }
                .frame(width: 256, height: 12)
            }
            .onboardingCard()
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

            VStack(spacing: 18) {
                Image("HeraklueLogo").resizable().scaledToFit().frame(maxWidth: 320)
                ButtonHint(text: "Press the button to continue")
            }
            .onboardingCard()

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

            VStack(spacing: 22) {
                Text(message)
                    .font(.system(size: messageSize,
                                  weight: messageSize >= 30 ? .semibold : .regular,
                                  design: .rounded))
                    .tracking(-0.44)
                    .foregroundStyle(Color(hex: 0x4A5565))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)

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
            .onboardingCard()
        }
    }
}
