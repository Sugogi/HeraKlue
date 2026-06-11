import Foundation

enum ARModelType: Equatable {
    case none
    case ariadne
    case poseidonFar
    case poseidonClose
    case puzzlePiece
    case puzzleSet
}

enum ARFocusTarget: String, Equatable {
    case none
    case ariadne
    case poseidon
    case puzzlePiece
}

enum OnboardingScreen: Equatable {
    case headsetButtonSpeakers   // Figma 501:7
    case headsetCamera           // Figma 501:8
    case loading                 // Figma 213:12
    case pressToContinue         // Figma 213:21
    case waitingForParent        // Figma 213:36
    case journeyArranged         // Figma 213:49
}

struct ARStoryStep: Identifiable, Equatable {
    let id: String
    let title: String
    let bodyText: String
    let missionText: String?
    let promptText: String
    let model: ARModelType
    let showsCrosshair: Bool
    let repeatLine: String?
    var textFocusTarget: ARFocusTarget? = nil
    var onboarding: OnboardingScreen? = nil   // if set, show the Figma 2D screen instead of AR + dialogs

    /// Every story step now advances only by user tap.
    /// This keeps the app from changing scenes automatically while the user is looking around in AR.
    var allowsTap: Bool { true }

    static let steps: [ARStoryStep] = [

        // MARK: Headset Instructions

        ARStoryStep(
            id: "headset_instructions_1_1",
            title: "Headset Instructions",
            bodyText: "Press the headset button to select, continue, or interact. Hold the button to notify your parent. The speakers provide audio guides and enhance the AR experience.",
            missionText: nil,
            promptText: "Press the button to continue",
            model: .none,
            showsCrosshair: false,
            repeatLine: nil,
            onboarding: .headsetButtonSpeakers
        ),

        ARStoryStep(
            id: "headset_instructions_1_2",
            title: "Headset Camera",
            bodyText: "The camera identifies what you are looking at so HeraKlue can project relevant images. Do not block the camera.",
            missionText: nil,
            promptText: "Press the button to continue",
            model: .none,
            showsCrosshair: false,
            repeatLine: nil,
            onboarding: .headsetCamera
        ),

        // MARK: Loading Screens

        ARStoryStep(
            id: "loading_1_1",
            title: "HeraKlue",
            bodyText: "Loading your adventure...",
            missionText: nil,
            promptText: "Loading...",
            model: .none,
            showsCrosshair: false,
            repeatLine: nil,
            onboarding: .loading
        ),

        ARStoryStep(
            id: "loading_1_2",
            title: "HeraKlue",
            bodyText: "Your headset is ready.",
            missionText: nil,
            promptText: "Press the button to continue",
            model: .none,
            showsCrosshair: false,
            repeatLine: nil,
            onboarding: .pressToContinue
        ),

        // MARK: Parent Consent

        ARStoryStep(
            id: "parental_consent_1_1",
            title: "Waiting for Parent",
            bodyText: "Waiting for the parent app to give consent. The parent will set the child’s name, language, age range, and the distance the child can wander from the parent.",
            missionText: nil,
            promptText: "Waiting for parent approval",
            model: .none,
            showsCrosshair: false,
            repeatLine: nil,
            onboarding: .waitingForParent
        ),

        ARStoryStep(
            id: "parental_consent_1_2",
            title: "Journey Arranged",
            bodyText: "Your journey has been arranged!",
            missionText: nil,
            promptText: "Press the button to continue",
            model: .none,
            showsCrosshair: false,
            repeatLine: nil,
            onboarding: .journeyArranged
        ),

        // MARK: Welcome Screens with Ariadne

        ARStoryStep(
            id: "welcome_1_1",
            title: "Ariadne",
            bodyText: "Welcome, young explorer! I am Ariadne, and I am your guide for this journey.",
            missionText: nil,
            promptText: "Press the button to continue",
            model: .ariadne,
            showsCrosshair: true,
            repeatLine: "Welcome, young explorer! I am Ariadne, and I am your guide for this journey.",
            textFocusTarget: .ariadne
        ),

        ARStoryStep(
            id: "welcome_1_2",
            title: "Ariadne",
            bodyText: "The Minotaur has vanished from the city, and the gods are here to help us find him.",
            missionText: nil,
            promptText: "Press the button to continue",
            model: .ariadne,
            showsCrosshair: true,
            repeatLine: "The Minotaur has vanished from the city, and the gods are here to help us find him.",
            textFocusTarget: .ariadne
        ),

        ARStoryStep(
            id: "welcome_1_3",
            title: "Ariadne",
            bodyText: "As gods, we cannot interfere directly in the mortal world, so we need your help.",
            missionText: nil,
            promptText: "Press the button to continue",
            model: .ariadne,
            showsCrosshair: true,
            repeatLine: "As gods, we cannot interfere directly in the mortal world, so we need your help.",
            textFocusTarget: .ariadne
        ),

        ARStoryStep(
            id: "welcome_1_4",
            title: "Ariadne",
            bodyText: "Collect all 25 puzzle pieces around the city to reveal the map and find the Minotaur.",
            missionText: nil,
            promptText: "Press the button to continue",
            model: .ariadne,
            showsCrosshair: true,
            repeatLine: "Collect all 25 puzzle pieces around the city to reveal the map and find the Minotaur.",
            textFocusTarget: .ariadne
        ),

        ARStoryStep(
            id: "welcome_1_5",
            title: "Ariadne",
            bodyText: "These puzzle pieces will reveal a map that leads to the Minotaur’s secret location.",
            missionText: nil,
            promptText: "Press the button to continue",
            model: .ariadne,
            showsCrosshair: true,
            repeatLine: "These puzzle pieces will reveal a map that leads to the Minotaur’s secret location.",
            textFocusTarget: .ariadne
        ),

        ARStoryStep(
            id: "welcome_1_6",
            title: "Explore the City",
            bodyText: "Walk around the city and approach any quest you like. Gods to meet and puzzle pieces to collect are scattered everywhere — there is no set order.",
            missionText: "Explore — approach any quest you find",
            promptText: "Hold the button to repeat Ariadne’s message",
            model: .ariadne,
            showsCrosshair: true,
            repeatLine: "Walk around the city and approach any quest you like. Gods to meet and puzzle pieces to collect are scattered everywhere — there is no set order.",
            textFocusTarget: .ariadne
        ),

        ARStoryStep(
            id: "welcome_1_7",
            title: "Ariadne",
            bodyText: "Good luck, adventurer.",
            missionText: "Explore — approach any quest you find",
            promptText: "Press the button to begin",
            model: .ariadne,
            showsCrosshair: true,
            repeatLine: "Good luck, adventurer.",
            textFocusTarget: .ariadne
        ),

        // MARK: Poseidon Encounter

        ARStoryStep(
            id: "poseidon_speaks_1_1",
            title: "Poseidon Nearby",
            bodyText: "You have approached Poseidon, one of the gods scattered across the city. A glowing exclamation point floats above his head. Move closer to interact.",
            missionText: "Approach Poseidon",
            promptText: "Press the button to move closer",
            model: .poseidonFar,
            showsCrosshair: true,
            repeatLine: nil,
            textFocusTarget: .poseidon
        ),

        ARStoryStep(
            id: "poseidon_speaks_1_2",
            title: "Poseidon Calls Out",
            bodyText: "Yoohoo! Come here! Over here!",
            missionText: "Approach Poseidon",
            promptText: "Press the button to approach Poseidon",
            model: .poseidonClose,
            showsCrosshair: true,
            repeatLine: "Yoohoo! Come here! Over here!",
            textFocusTarget: .poseidon
        ),

        ARStoryStep(
            id: "poseidon_speaks_1_3",
            title: "Poseidon",
            bodyText: "I am Poseidon. I have a mission for you.",
            missionText: "Talk to Poseidon",
            promptText: "Press the button to accept Poseidon’s mission",
            model: .poseidonClose,
            showsCrosshair: true,
            repeatLine: "I am Poseidon. I have a mission for you.",
            textFocusTarget: .poseidon
        ),

        ARStoryStep(
            id: "poseidon_speaks_2_1",
            title: "Poseidon",
            bodyText: "Whatsup, I’m Poseidon, and I’m here to help you, man.",
            missionText: "Talk to Poseidon",
            promptText: "Press the button to continue",
            model: .poseidonClose,
            showsCrosshair: true,
            repeatLine: "Whatsup, I’m Poseidon, and I’m here to help you, man.",
            textFocusTarget: .poseidon
        ),

        ARStoryStep(
            id: "poseidon_speaks_2_2",
            title: "Poseidon",
            bodyText: "I can’t say much, but to find your first puzzle piece...",
            missionText: "Talk to Poseidon",
            promptText: "Press the button to continue",
            model: .poseidonClose,
            showsCrosshair: true,
            repeatLine: "I can’t say much, but to find your first puzzle piece...",
            textFocusTarget: .poseidon
        ),

        ARStoryStep(
            id: "poseidon_speaks_2_3",
            title: "Poseidon",
            bodyText: "You have to find the four stone lions in the heart of the city.",
            missionText: "Talk to Poseidon",
            promptText: "Press the button to continue",
            model: .poseidonClose,
            showsCrosshair: true,
            repeatLine: "You have to find the four stone lions in the heart of the city.",
            textFocusTarget: .poseidon
        ),

        ARStoryStep(
            id: "poseidon_speaks_2_4",
            title: "Accept Mission?",
            bodyText: "Poseidon offers you a mission. You can accept it or walk away and find another quest.",
            missionText: "Accept Poseidon’s mission",
            promptText: "Press the button to accept mission",
            model: .poseidonClose,
            showsCrosshair: true,
            repeatLine: "You have to find the four stone lions in the heart of the city.",
            textFocusTarget: .poseidon
        ),

        // MARK: Mission Accepted

        ARStoryStep(
            id: "mission_accepted_1_1",
            title: "Mission Started",
            bodyText: "Using Poseidon’s hint, you must find the puzzle piece.",
            missionText: "Find the puzzle piece near the Four Stone Lions",
            promptText: "Hold the button to repeat Poseidon’s hint",
            model: .poseidonClose,
            showsCrosshair: true,
            repeatLine: "Find the four stone lions in the heart of the city.",
            textFocusTarget: .poseidon
        ),

        ARStoryStep(
            id: "mission_accepted_1_2",
            title: "Mission",
            bodyText: "Your mission is active.",
            missionText: "Find the puzzle piece near the Four Stone Lions",
            promptText: "Press the button to continue",
            model: .none,
            showsCrosshair: true,
            repeatLine: "Find the puzzle piece near the Four Stone Lions."
        ),

        ARStoryStep(
            id: "mission_accepted_1_3",
            title: "Begin the Journey",
            bodyText: "You start moving away from Poseidon. Poseidon fades into the distance.",
            missionText: "Find the puzzle piece near the Four Stone Lions",
            promptText: "Press the button to continue",
            model: .poseidonFar,
            showsCrosshair: true,
            repeatLine: "Find the four stone lions in the heart of the city."
        ),

        // MARK: Journey

        ARStoryStep(
            id: "journey_1_1",
            title: "Lion Fountain",
            bodyText: "You are near the lion fountain. Look around carefully.",
            missionText: "Find the puzzle piece near the Four Stone Lions",
            promptText: "Press the button when ready",
            model: .none,
            showsCrosshair: true,
            repeatLine: "Look around the lion fountain carefully."
        ),

        ARStoryStep(
            id: "journey_1_2",
            title: "Need Help?",
            bodyText: "You have been searching for a while. Help is available.",
            missionText: "Find the puzzle piece near the Four Stone Lions",
            promptText: "Press the button to ask for help",
            model: .none,
            showsCrosshair: true,
            repeatLine: "Look carefully around the lion fountain."
        ),

        ARStoryStep(
            id: "journey_1_3",
            title: "Help Accepted",
            bodyText: "Find Ariadne. She will guide you.",
            missionText: "Find the puzzle piece near the Four Stone Lions",
            promptText: "Scan the marker to reveal Ariadne",
            model: .ariadne,
            showsCrosshair: true,
            repeatLine: "Find Ariadne. She will guide you."
        ),

        ARStoryStep(
            id: "journey_1_4",
            title: "Follow Ariadne",
            bodyText: "Ariadne guides you through audio. Follow her voice.",
            missionText: "Find the puzzle piece near the Four Stone Lions",
            promptText: "Scan the marker to keep following Ariadne",
            model: .ariadne,
            showsCrosshair: true,
            repeatLine: "Follow my voice. I will guide you."
        ),

        ARStoryStep(
            id: "journey_1_5",
            title: "Ariadne Appears",
            bodyText: "Psst... over here!",
            missionText: "Find the puzzle piece near the Four Stone Lions",
            promptText: "Scan the marker to follow Ariadne",
            model: .ariadne,
            showsCrosshair: true,
            repeatLine: "Psst... over here!",
            textFocusTarget: .ariadne
        ),

        // MARK: Puzzle Interaction

        ARStoryStep(
            id: "puzzle_1_1",
            title: "Puzzle Piece Nearby",
            bodyText: "Following Ariadne, a floating puzzle piece appears in your view.",
            missionText: "Find the puzzle piece near the Four Stone Lions",
            promptText: "Scan the marker to reveal the puzzle piece",
            model: .puzzlePiece,
            showsCrosshair: true,
            repeatLine: "Center the crosshair on the puzzle piece."
        ),

        ARStoryStep(
            id: "puzzle_1_2",
            title: "Interact",
            bodyText: "Center your crosshair on the puzzle piece, then press the headset button to interact.",
            missionText: "Collect the puzzle piece",
            promptText: "Press the button to collect the scanned puzzle piece",
            model: .puzzlePiece,
            showsCrosshair: true,
            repeatLine: "Center your crosshair on the puzzle piece, then press the button to interact."
        ),

        ARStoryStep(
            id: "puzzle_1_3",
            title: "Mission Completed",
            bodyText: "Mission completed. The crosshair is centered on the puzzle piece.",
            missionText: "Puzzle piece found",
            promptText: "Press the button to continue",
            model: .puzzlePiece,
            showsCrosshair: true,
            repeatLine: "Mission completed."
        ),

        ARStoryStep(
            id: "puzzle_1_4",
            title: "Map Piece Earned",
            bodyText: "You have earned a map piece.",
            missionText: "Collect the puzzle piece",
            promptText: "Press the button to continue",
            model: .puzzlePiece,
            showsCrosshair: true,
            repeatLine: "You have earned a map piece."
        ),

        ARStoryStep(
            id: "puzzle_1_5",
            title: "Puzzle Set",
            bodyText: "The collected puzzle piece has been added to the puzzle set. You have collected 1 out of 25 pieces. Collect all 25 pieces to complete the game. Each puzzle is a different story and level.",
            missionText: "1/25 pieces collected",
            promptText: "Press the button to continue",
            model: .puzzleSet,
            showsCrosshair: false,
            repeatLine: "You have collected 1 out of 25 pieces. Collect all 25 pieces to complete the game."
        ),

        ARStoryStep(
            id: "puzzle_1_6",
            title: "New Journey",
            bodyText: "A new journey awaits you, young explorer!",
            missionText: "1/25 pieces collected",
            promptText: "Press the button to restart prototype",
            model: .none,
            showsCrosshair: true,
            repeatLine: "A new journey awaits you, young explorer!"
        )
    ]
}
