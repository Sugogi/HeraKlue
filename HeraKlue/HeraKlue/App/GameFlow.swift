//
//  GameFlow.swift
//  HeraKlue
//
//  SHARED — please coordinate with the team before changing this file.
//  Tracks which section of the experience the player is in, and lets any
//  screen move the player to another section. The actual screens live in
//  the per-person folders: Tutorial/ (Mysha), Gameplay/ (Stephen),
//  JourneyMap/ (Hibba).
//

import SwiftUI
import Observation

/// The top-level sections of HeraKlue. Each case is built in its own folder.
enum GamePhase {
    case tutorial     // Mysha   -> Tutorial/
    case gameplay     // Stephen -> Gameplay/
    case journeyMap   // Hibba   -> JourneyMap/
}

/// App-wide state. Created once in `RootView` and shared via the environment.
@Observable
final class GameFlow {
    /// The section currently on screen.
    var phase: GamePhase = .tutorial

    /// Move the player to a different section.
    func go(to phase: GamePhase) {
        self.phase = phase
    }
}
