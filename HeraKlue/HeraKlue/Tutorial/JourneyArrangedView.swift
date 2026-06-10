//
//  JourneyArrangedView.swift
//  HeraKlue  (Tutorial — Mysha)
//
//  Matches Figma node 213:49 — confirmation that the parent approved.
//  Tap anywhere (i.e. press the headset button) to continue.
//

import SwiftUI

struct JourneyArrangedView: View {
    var onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 28) {
                Text("Your Journey has been arranged!")
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                    .tracking(-0.44)
                    .foregroundStyle(Color(hex: 0x4A5565))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 480)

                Text("Press the button on your headset to continue")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 28)
                    .background(Color(hex: 0x030213, opacity: 0.5),
                                in: RoundedRectangle(cornerRadius: 8))
            }
            .padding(40)
        }
        .contentShape(Rectangle())
        .onTapGesture { onContinue() }
    }
}

#Preview {
    JourneyArrangedView(onContinue: {})
}
