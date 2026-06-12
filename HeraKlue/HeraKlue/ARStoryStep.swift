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
    case headsetButtonPopup      // Single headset button intro popup
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
    let audioFileName: String?
    var textFocusTarget: ARFocusTarget?
    var onboarding: OnboardingScreen?   // if set, show the Figma 2D screen instead of AR + dialogs

    init(
        id: String,
        title: String,
        bodyText: String,
        missionText: String?,
        promptText: String,
        model: ARModelType,
        showsCrosshair: Bool,
        repeatLine: String?,
        audioFileName: String? = nil,
        textFocusTarget: ARFocusTarget? = nil,
        onboarding: OnboardingScreen? = nil
    ) {
        self.id = id
        self.title = title
        self.bodyText = bodyText
        self.missionText = missionText
        self.promptText = promptText
        self.model = model
        self.showsCrosshair = showsCrosshair
        self.repeatLine = repeatLine
        self.audioFileName = audioFileName
        self.textFocusTarget = textFocusTarget
        self.onboarding = onboarding
    }

    /// Every story step now advances only by user tap.
    /// This keeps the app from changing scenes automatically while the user is looking around in AR.
    var allowsTap: Bool { true }

    static let steps: [ARStoryStep] = [

        // MARK: Headset Instructions

        ARStoryStep(
            id: "headset_button_popup_1_1",
            title: "Headset Button",
            bodyText: "The button is on the side of your headset! Reach up and press it to continue!",
            missionText: nil,
            promptText: "Press the headset button to continue",
            model: .none,
            showsCrosshair: false,
            repeatLine: nil,
            audioFileName: "0 press the button to interact.mp3",
            onboarding: .headsetButtonPopup
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
            audioFileName: "1 your journey has been arranged.mp3",
            onboarding: .journeyArranged
        ),

        // MARK: Welcome Screens with Ariadne

        ARStoryStep(
            id: "welcome_1_1",
            title: "Welcome",
            bodyText: "Welcome, young explorer! I am Ariadne, and I am your guide for this journey.",
            missionText: nil,
            promptText: "Press the button to continue",
            model: .ariadne,
            showsCrosshair: true,
            repeatLine: "Welcome, young explorer! I am Ariadne, and I am your guide for this journey.",
            audioFileName: "2 Welcome!.mp3",
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
            audioFileName: "3 Minotaur vanished.mp3",
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
            audioFileName: "4 As gods.mp3",
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
            audioFileName: "5 25 puzzle pieces.mp3",
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
            audioFileName: "6 secret location.mp3",
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
            bodyText: "Good luck, adventurer. Poseidon is nearby when you are ready for your first mission.",
            missionText: "Talk to Poseidon",
            promptText: "Walk to Poseidon and aim at him",
            model: .ariadne,
            showsCrosshair: true,
            repeatLine: "Good luck, adventurer. Poseidon is nearby when you are ready for your first mission.",
            audioFileName: "7 good luck adventurer.mp3",
            textFocusTarget: .ariadne
        ),

        // MARK: Poseidon Encounter

        ARStoryStep(
            id: "poseidon_speaks_1_1",
            title: "Poseidon",
            bodyText: "Yoohoo! Come here! Over here! I have your first mission.",
            missionText: "Talk to Poseidon",
            promptText: "Press the button while looking at Poseidon",
            model: .poseidonFar,
            showsCrosshair: true,
            repeatLine: "Yoohoo! Come here! Over here! I have your first mission.",
            audioFileName: "yoohoo!.mp3",
            textFocusTarget: .poseidon
        ),

        ARStoryStep(
            id: "poseidon_speaks_1_2",
            title: "Poseidon",
            bodyText: "You found me. Keep your crosshair on me so I can give you the mission.",
            missionText: "Talk to Poseidon",
            promptText: "Press the button to continue",
            model: .poseidonClose,
            showsCrosshair: true,
            repeatLine: "You found me. Keep your crosshair on me so I can give you the mission.",
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
            audioFileName: "9 Whatsup! im poseidon.mp3",
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
            audioFileName: "10 i cant say much but.mp3",
            textFocusTarget: .poseidon
        ),

        ARStoryStep(
            id: "poseidon_speaks_2_3",
            title: "Poseidon",
            bodyText: "You have to find...",
            missionText: "Talk to Poseidon",
            promptText: "Press the button to continue",
            model: .poseidonClose,
            showsCrosshair: true,
            repeatLine: "You have to find...",
            audioFileName: "11 you have to find.mp3",
            textFocusTarget: .poseidon
        ),

        ARStoryStep(
            id: "poseidon_speaks_2_4",
            title: "Poseidon",
            bodyText: "The Four Stone Lions.",
            missionText: "Talk to Poseidon",
            promptText: "Press the button to continue",
            model: .poseidonClose,
            showsCrosshair: true,
            repeatLine: "The Four Stone Lions.",
            audioFileName: "12 The FOUR.STONE.LIONS.mp3",
            textFocusTarget: .poseidon
        ),

        ARStoryStep(
            id: "poseidon_speaks_2_5",
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
            bodyText: "Using Poseidon’s hint, travel to the Four Stone Lions and scan the reference marker to reveal the puzzle piece.",
            missionText: "Find the puzzle piece near the Four Stone Lions",
            promptText: "Hold the button to repeat Poseidon’s hint",
            model: .poseidonClose,
            showsCrosshair: true,
            repeatLine: "Find the four stone lions in the heart of the city."
        ),

        ARStoryStep(
            id: "mission_accepted_1_2",
            title: "Mission",
            bodyText: "Your mission is active. The puzzle piece is hidden near the Four Stone Lions marker.",
            missionText: "Find the puzzle piece near the Four Stone Lions",
            promptText: "Press the button to continue",
            model: .none,
            showsCrosshair: true,
            repeatLine: "Find the puzzle piece near the Four Stone Lions."
        ),

        ARStoryStep(
            id: "mission_accepted_1_3",
            title: "Begin the Journey",
            bodyText: "Travel to the Four Stone Lions. When you find the marker, scan it to reveal Ariadne and the puzzle piece.",
            missionText: "Find the puzzle piece near the Four Stone Lions",
            promptText: "Press the button to continue",
            model: .poseidonFar,
            showsCrosshair: true,
            repeatLine: "Find the four stone lions in the heart of the city."
        ),

        // MARK: Journey

        ARStoryStep(
            id: "journey_1_1",
            title: "Four Stone Lions",
            bodyText: "You are near the Four Stone Lions. Scan the reference marker to reveal the puzzle piece.",
            missionText: "Find the puzzle piece near the Four Stone Lions",
            promptText: "Press the button when ready",
            model: .none,
            showsCrosshair: true,
            repeatLine: "Look around the Four Stone Lions carefully."
        ),

        ARStoryStep(
            id: "journey_1_2",
            title: "Need Help?",
            bodyText: "If you need help, Ariadne will appear near the scanned marker and guide you to the puzzle piece.",
            missionText: "Find the puzzle piece near the Four Stone Lions",
            promptText: "After a short search, press the help prompt to call Ariadne",
            model: .none,
            showsCrosshair: true,
            repeatLine: "Look carefully around the Four Stone Lions."
        ),

        ARStoryStep(
            id: "journey_1_3",
            title: "Help Accepted",
            bodyText: "Ariadne is on her way. She will appear farther away from the marker near the puzzle piece.",
            missionText: "Find the puzzle piece near the Four Stone Lions",
            promptText: "Look around the puzzle location for Ariadne",
            model: .ariadne,
            showsCrosshair: true,
            repeatLine: "Ariadne is on her way. She will appear farther away from the marker near the puzzle piece."
        ),

        ARStoryStep(
            id: "journey_1_4",
            title: "Follow Ariadne",
            bodyText: "Ariadne appears farther away from the marker near the puzzle piece. Follow her voice and look where she is guiding you.",
            missionText: "Find the puzzle piece near the Four Stone Lions",
            promptText: "Follow Ariadne near the puzzle location",
            model: .ariadne,
            showsCrosshair: true,
            repeatLine: "Follow my voice. I will guide you.",
            audioFileName: "hey, follow me!.mp3"
        ),

        ARStoryStep(
            id: "journey_1_5",
            title: "Ariadne Appears",
            bodyText: "Psst... over here!",
            missionText: "Find the puzzle piece near the Four Stone Lions",
            promptText: "Aim at Ariadne to hear her hint",
            model: .ariadne,
            showsCrosshair: true,
            repeatLine: "Psst... over here!",
            audioFileName: "13 pssst..over here.mp3",
            textFocusTarget: .ariadne
        ),

        // MARK: Puzzle Interaction

        ARStoryStep(
            id: "puzzle_1_1",
            title: "Puzzle Piece Nearby",
            bodyText: "A floating puzzle piece appears above Ariadne after the reference marker is scanned.",
            missionText: "Find the puzzle piece near the Four Stone Lions",
            promptText: "Look for Ariadne and the floating puzzle piece",
            model: .puzzlePiece,
            showsCrosshair: true,
            repeatLine: "Center the crosshair on the puzzle piece."
        ),

        ARStoryStep(
            id: "puzzle_1_2",
            title: "Interact",
            bodyText: "Center your crosshair on the puzzle piece, then press the headset button to collect it.",
            missionText: "Collect the puzzle piece",
            promptText: "Aim at the puzzle piece, then press the button",
            model: .puzzlePiece,
            showsCrosshair: true,
            repeatLine: "Center your crosshair on the puzzle piece, then press the button to collect it.",
            audioFileName: "0 press the button to interact.mp3"
        ),

        ARStoryStep(
            id: "puzzle_1_3",
            title: "Mission Completed",
            bodyText: "Mission completed. The puzzle piece was collected while the crosshair was centered on it.",
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
