//
//  OnboardingScreens.swift
//  HeraKlue
//
//  The Figma-designed 2D onboarding screens, shown over the AR camera during
//  the early steps (headset intro, loading, consent). Advancing is handled by
//  ContentView's global tap, so these are purely visual. A step opts in via
//  ARStoryStep.onboarding.
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
                pill: "Please wait..."
            )
        case .journeyArranged:
            StatusOnboarding(
                message: "Your Journey has been arranged!",
                messageSize: 36,
                pill: "Press the button on your headset to continue"
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

private struct ContinuePill: View {
    var body: some View {
        Text("Press the button to continue")
            .font(.system(size: 20, weight: .medium, design: .rounded))
            .foregroundStyle(.black)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 22)
            .padding(.vertical, 16)
            .frame(maxWidth: 230)
            .background(Color(hex: 0x6EBCEF, opacity: 0.82), in: RoundedRectangle(cornerRadius: 20))
            .shadow(color: .white.opacity(0.7), radius: 14)
    }
}

// MARK: - Headset screens (501:7, 501:8)

private struct HeadsetButtonSpeakersScreen: View {
    var body: some View {
        ZStack {
            Color.white.opacity(0.5).ignoresSafeArea()

            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(Color(hex: 0x7340C4, opacity: 0.55))
                Image("HeadsetButtonSpeakers").resizable().scaledToFit().padding(18)
            }
            .frame(width: 330, height: 300)
            .overlay(alignment: .topTrailing) { CalloutLabel(text: "Button", size: 24).offset(x: 78, y: 4) }
            .overlay(alignment: .bottomLeading) { CalloutLabel(text: "Speakers", size: 20).offset(x: -36, y: 14) }

            ContinuePill()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(24)
        }
    }
}

private struct HeadsetCameraScreen: View {
    var body: some View {
        ZStack {
            Color.white.opacity(0.5).ignoresSafeArea()

            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(Color(hex: 0x753EB4, opacity: 0.55))
                Image("HeadsetCamera").resizable().scaledToFit().padding(18)
            }
            .frame(width: 300, height: 320)
            .overlay(alignment: .bottomLeading) { CalloutLabel(text: "Camera", size: 24).offset(x: -34, y: 6) }

            ContinuePill()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(24)

            Text("Make sure nothing is blocking your camera")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundStyle(.black)
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.7))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }
}

// MARK: - Loading (213:12)

private struct LoadingOnboarding: View {
    @State private var progress: CGFloat = 0

    var body: some View {
        ZStack {
            Color.white.opacity(0.48).ignoresSafeArea()

            VStack(spacing: 28) {
                Image("HeraklueLogo").resizable().scaledToFit().frame(maxWidth: 460)

                VStack(spacing: 14) {
                    Text("Loading your adventure...")
                        .font(.system(size: 18)).tracking(-0.44).foregroundStyle(.black)

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
            Color.white.opacity(0.48).ignoresSafeArea()

            VStack(spacing: 24) {
                Image("HeraklueLogo").resizable().scaledToFit().frame(maxWidth: 460)
                blueButton
            }
            .padding(40)

            Image("HeadsetDevice")
                .resizable().scaledToFit().frame(width: 130)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, 24)
                .padding(.bottom, 24)
        }
    }

    private var blueButton: some View {
        ZStack {
            Capsule().fill(Color(hex: 0x4B93C3)).frame(width: 426, height: 42).offset(x: 3, y: -3)
            Capsule().fill(Color(hex: 0x73B9E7)).frame(width: 426, height: 41)
            Text("Press The Button to Continue")
                .font(.system(size: 24, design: .rounded))
                .tracking(-0.44)
                .foregroundStyle(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 16)
        }
        .frame(width: 426, height: 45)
    }
}

// MARK: - Status screens (213:36, 213:49)

private struct StatusOnboarding: View {
    let message: String
    let messageSize: CGFloat
    let pill: String

    var body: some View {
        ZStack {
            Color.white.opacity(0.62).ignoresSafeArea()

            VStack(spacing: 28) {
                Text(message)
                    .font(.system(size: messageSize,
                                  weight: messageSize >= 30 ? .semibold : .regular,
                                  design: .rounded))
                    .tracking(-0.44)
                    .foregroundStyle(Color(hex: 0x4A5565))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 480)

                Text(pill)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 28)
                    .background(Color(hex: 0x030213, opacity: 0.5), in: RoundedRectangle(cornerRadius: 8))
            }
            .padding(40)
        }
    }
}
