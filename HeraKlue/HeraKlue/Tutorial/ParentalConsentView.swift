//
//  ParentalConsentView.swift
//  HeraKlue  (Tutorial — Mysha)
//
//  Screens 1.1 + 1.2 — parental consent. In the real product these values
//  arrive from the parent's phone app; here the parent sets them, then we
//  confirm: "Your journey has been arranged!".
//

import SwiftUI

struct ParentalConsentView: View {
    var onContinue: () -> Void

    @State private var childName = ""
    @State private var language = "English"
    @State private var ageRange = "6–8"
    @State private var wanderDistance = 20.0
    @State private var isArranged = false

    private let languages = ["English", "Greek"]
    private let ageRanges = ["3–5", "6–8", "9–12"]

    var body: some View {
        if isArranged {
            // Screen 1.2 — confirmation.
            StoryScreen(
                title: "All set!",
                lines: [
                    "Your journey has been arranged,",
                    "\(childName.isEmpty ? "young explorer" : childName)!"
                ],
                systemImage: "checkmark.seal.fill",
                onPress: onContinue
            )
        } else {
            // Screen 1.1 — the parent fills this in.
            NavigationStack {
                Form {
                    Section("Child") {
                        TextField("Child's name", text: $childName)
                        Picker("Age range", selection: $ageRange) {
                            ForEach(ageRanges, id: \.self) { Text($0) }
                        }
                    }
                    Section("Experience") {
                        Picker("Language", selection: $language) {
                            ForEach(languages, id: \.self) { Text($0) }
                        }
                        VStack(alignment: .leading) {
                            Text("Wander distance: \(Int(wanderDistance)) m")
                            Slider(value: $wanderDistance, in: 5...100, step: 5)
                        }
                    }
                    Section {
                        Button("Arrange the journey") {
                            isArranged = true
                        }
                    }
                }
                .navigationTitle("Parental Consent")
            }
        }
    }
}

#Preview {
    ParentalConsentView(onContinue: {})
}
