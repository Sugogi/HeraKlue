//
//  WelcomeView.swift
//  HeraKlue  (Tutorial — Mysha)
//
//  Ariadne's welcome. Content intentionally left blank until the real script
//  / design is provided — do NOT fill in placeholder dialogue here.
//

import SwiftUI

struct WelcomeView: View {
    var onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.white.opacity(0.48).ignoresSafeArea()   // scrim over the camera

            VStack(spacing: 12) {
                Text("Ariadne’s welcome")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(hex: 0x4A5565))
                Text("Awaiting content")
                    .font(.system(size: 18, design: .rounded))
                    .foregroundStyle(Color(hex: 0x4A5565).opacity(0.7))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onContinue() }
    }
}

#Preview {
    WelcomeView(onContinue: {})
}
