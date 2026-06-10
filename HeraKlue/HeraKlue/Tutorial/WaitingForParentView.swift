//
//  WaitingForParentView.swift
//  HeraKlue  (Tutorial — Mysha)
//
//  Matches Figma node 213:36 — the headset waits while the parent approves
//  the journey in their own app. Auto-continues once approval "arrives".
//

import SwiftUI

struct WaitingForParentView: View {
    var onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.white.opacity(0.62).ignoresSafeArea()

            VStack(spacing: 28) {
                Text("HeraKlue needs your parent’s approval before the myth hunt begins.")
                    .font(.system(size: 20, design: .rounded))
                    .tracking(-0.44)
                    .foregroundStyle(Color(hex: 0x4A5565))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 480)

                // Status pill (not tappable) — waiting on the parent app.
                Text("Please wait...")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 28)
                    .background(Color(hex: 0x030213, opacity: 0.5),
                                in: RoundedRectangle(cornerRadius: 8))
            }
            .padding(40)
        }
        .task {
            // Simulate the parent approving in their app. Replace with the
            // real signal from the parent app later.
            try? await Task.sleep(for: .seconds(3))
            onContinue()
        }
    }
}

#Preview {
    WaitingForParentView(onContinue: {})
}
