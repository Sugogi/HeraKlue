import AVFoundation
import MediaPlayer
import SwiftUI
import UIKit

struct ContentView: View {
    @State private var currentIndex = 0
    @State private var resetAR = false
    @State private var focusedTarget: ARFocusTarget = .none
    @State private var focusedTargetDistance: Float? = nil
    @State private var lastSpokenStepID: String? = nil
    @State private var audio = StoryAudioController()
    @State private var headsetButtonController = HeadsetButtonController()
    @State private var volumeButtonController = VolumeButtonController()
    @State private var ariadneHelpRequested = false
    @State private var showAriadneHelpOffer = false
    @State private var helpOfferDismissed = false
    @State private var lastAriadneAssistantAudioTime = Date.distantPast

    private let ink = Color(hex: 0x4A5565)
    private let card = Color.white.opacity(0.9)
    private let accentBlue = Color(hex: 0x6EBCEF)
    private let poseidonDialogueRange: Float = 2.25

    private var currentStep: ARStoryStep {
        ARStoryStep.steps[currentIndex]
    }

    private var isDialogueStep: Bool {
        currentStep.textFocusTarget != nil
    }

    var body: some View {
        ZStack {
            // Keeps iOS volume-button events available for the Betron wired-earbud fallback.
            // The view is invisible and does not block touches.
            SystemVolumeControlView()
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .allowsHitTesting(false)

            ARViewContainer(
                currentStep: currentStep,
                resetAR: $resetAR,
                focusedTarget: $focusedTarget,
                focusedTargetDistance: $focusedTargetDistance
            )
            .ignoresSafeArea()

            if let onboarding = currentStep.onboarding {
                OnboardingScreenView(screen: onboarding)
            } else {
                if currentStep.showsCrosshair {
                    CrosshairView(accentBlue: accentBlue)
                }

                VStack(spacing: 12) {
                    missionHUD

                    if showAriadneHelpOffer {
                        compactAriadneHelpOffer
                    }

                    Spacer()

                    if isDialogueStep, shouldShowDialogueCard {
                        dialogueCard
                    } else if shouldShowAriadneAssistantCard {
                        ariadneAssistantCard
                    } else if shouldShowCompactActionPrompt {
                        compactActionPrompt
                    }
                }
                .padding()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            handlePrimaryTap()
        }
        .onLongPressGesture(minimumDuration: 1.0) {
            repeatCurrentLine()
        }
        .onReceive(NotificationCenter.default.publisher(for: .heraklueHeadsetButtonPressed)) { _ in
            handlePrimaryTap()
        }
        .onAppear {
            headsetButtonController.start {
                handlePrimaryTap()
            }
            volumeButtonController.start {
                handlePrimaryTap()
            }
        }
        .onDisappear {
            headsetButtonController.stop()
            volumeButtonController.stop()
        }
        .task(id: currentStep.id) {
            playCurrentAudioIfAllowed()
            playAriadneAssistantHelpIfNeeded()
        }
        .task(id: isMissionStartedStep) {
            await scheduleAriadneHelpOfferIfNeeded()
        }
        .onChange(of: focusedTarget) { _ in
            advanceFromAriadneToPoseidonIfReady()
            playAriadneAssistantHelpIfNeeded()
            guard isDialogueStep else { return }
            playCurrentAudioIfAllowed()
        }
        .onChange(of: focusedTargetDistance) { _ in
            advanceFromAriadneToPoseidonIfReady()
            playAriadneAssistantHelpIfNeeded()
            guard isDialogueStep else { return }
            playCurrentAudioIfAllowed()
        }
    }

    private var shouldShowDialogueCard: Bool {
        guard let requiredFocusTarget = currentStep.textFocusTarget else {
            return false
        }

        guard focusedTarget == requiredFocusTarget else {
            return false
        }

        return isCloseEnoughForCurrentDialogue
    }

    private var shouldShowAriadneAssistantCard: Bool {
        guard focusedTarget == .ariadne else { return false }
        guard currentStep.textFocusTarget != .ariadne else { return false }
        return isMissionStartedStep || currentStep.id.hasPrefix("puzzle_")
    }

    private var canInteractWithCurrentStep: Bool {
        if isPoseidonHandoffStep {
            // The Ariadne-to-Poseidon handoff should not require a button tap.
            // The player advances by physically walking to Poseidon and aiming at him.
            return false
        }

        if requiresPuzzleCrosshairToCollect {
            return focusedTarget == .puzzlePiece
        }

        guard currentStep.textFocusTarget != nil else {
            // Mission prompts and non dialogue steps are never locked behind
            // the crosshair. Only speaker dialogue requires aiming at the speaker.
            // The puzzle pickup step is the exception and requires the crosshair
            // to be centered on the puzzle piece before collection.
            return true
        }

        return shouldShowDialogueCard
    }

    private var isCloseEnoughForCurrentDialogue: Bool {
        guard currentStep.textFocusTarget == .poseidon else {
            return true
        }

        guard let focusedTargetDistance else {
            return false
        }

        return focusedTargetDistance <= poseidonDialogueRange
    }

    private var isAcceptMissionStep: Bool {
        currentStep.id == "poseidon_speaks_2_5"
    }

    private var isPoseidonHandoffStep: Bool {
        currentStep.id == "welcome_1_7"
    }

    private var requiresPuzzleCrosshairToCollect: Bool {
        currentStep.id == "puzzle_1_2"
    }

    private var isMissionStartedStep: Bool {
        currentStep.id.hasPrefix("mission_accepted")
            || currentStep.id.hasPrefix("journey_")
            || currentStep.id.hasPrefix("puzzle_")
    }

    private var isReadyToStartPoseidonDialogue: Bool {
        guard isPoseidonHandoffStep, focusedTarget == .poseidon else {
            return false
        }

        guard let focusedTargetDistance else {
            return false
        }

        return focusedTargetDistance <= poseidonDialogueRange
    }

    private var shouldShowMissionObjectiveCard: Bool {
        if isAcceptMissionStep {
            return shouldShowDialogueCard
        }

        return true
    }

    private var missionHUD: some View {
        VStack(spacing: 8) {
            if shouldShowMissionObjectiveCard {
                missionObjectiveCard
            }
        }
    }

    private var missionObjectiveCard: some View {
        Group {
            if let mission = currentStep.missionText {
                Text(mission)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(ink)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(card)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.10), radius: 4, y: 2)
            }
        }
    }

    private var dialogueCard: some View {
        VStack(spacing: 12) {
            Text(currentStep.title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(ink)
                .multilineTextAlignment(.center)

            Text(currentStep.bodyText)
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(ink)
                .multilineTextAlignment(.center)
        }
        .padding(14)
        .frame(maxWidth: 340)
        .background(card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.14), radius: 8, y: 3)
    }

    private var ariadneAssistantCard: some View {
        VStack(spacing: 8) {
            Text("Ariadne")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(ink)

            Text("Psst... over here. Look above me for the puzzle piece.")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(ink)
                .multilineTextAlignment(.center)
        }
        .padding(12)
        .frame(maxWidth: 300)
        .background(card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.12), radius: 7, y: 3)
    }

    private var shouldShowCompactActionPrompt: Bool {
        requiresPuzzleCrosshairToCollect && focusedTarget == .puzzlePiece
    }

    private var compactActionPrompt: some View {
        Text("Collect")
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.vertical, 7)
            .padding(.horizontal, 16)
            .background(accentBlue.opacity(0.92))
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.22), radius: 8, y: 3)
    }

    private var compactAriadneHelpOffer: some View {
        Text("Need help? Press button.")
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.vertical, 7)
            .padding(.horizontal, 14)
            .background(Color.black.opacity(0.68))
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.18), radius: 8, y: 3)
    }


    private func handlePrimaryTap() {
        if showAriadneHelpOffer {
            requestAriadneHelp()
            return
        }

        guard currentStep.allowsTap, canInteractWithCurrentStep else { return }
        goToNextScene()
    }

    private func goToNextScene() {
        if currentIndex < ARStoryStep.steps.count - 1 {
            var nextIndex = currentIndex + 1

            // The UI is intentionally minimal now, so some older mission/objective
            // steps would appear blank. Skip those transition-only steps so every
            // button press lands on something the player can actually see or do.
            while nextIndex < ARStoryStep.steps.count - 1,
                  shouldSkipTransitionStep(ARStoryStep.steps[nextIndex]) {
                nextIndex += 1
            }

            currentIndex = nextIndex
        } else {
            currentIndex = 0
            resetAR.toggle()
            ariadneHelpRequested = false
            showAriadneHelpOffer = false
            helpOfferDismissed = false
        }
    }

    private func shouldSkipTransitionStep(_ step: ARStoryStep) -> Bool {
        transitionOnlyStepIDs.contains(step.id)
    }

    private var transitionOnlyStepIDs: Set<String> {
        [
            "mission_accepted_1_1",
            "mission_accepted_1_2",
            "mission_accepted_1_3",
            "journey_1_1",
            "journey_1_2",
            "journey_1_3",
            "journey_1_4",
            "puzzle_1_1",
            "puzzle_1_3",
            "puzzle_1_4"
        ]
    }

    @MainActor
    private func scheduleAriadneHelpOfferIfNeeded() async {
        guard isMissionStartedStep else {
            showAriadneHelpOffer = false
            return
        }

        guard !ariadneHelpRequested, !helpOfferDismissed else { return }

        showAriadneHelpOffer = false
        try? await Task.sleep(for: .seconds(45))

        guard !Task.isCancelled,
              isMissionStartedStep,
              !ariadneHelpRequested,
              !helpOfferDismissed
        else { return }

        showAriadneHelpOffer = true
    }

    private func requestAriadneHelp() {
        ariadneHelpRequested = true
        showAriadneHelpOffer = false
        helpOfferDismissed = true

        audio.play(
            fileName: "13 pssst..over here.mp3",
            fallbackText: "Psst... over here! I will guide you."
        )
    }

    private func advanceFromAriadneToPoseidonIfReady() {
        guard isReadyToStartPoseidonDialogue else { return }
        goToNextScene()
    }

    private func playCurrentAudioIfAllowed() {
        if isDialogueStep {
            guard shouldShowDialogueCard else { return }
        }

        // Only auto-play supplied MP3 files, except speaker dialogue can still
        // fall back to iOS text-to-speech if a matching file is missing.
        guard currentStep.audioFileName != nil || isDialogueStep else { return }
        guard lastSpokenStepID != currentStep.id else { return }

        audio.play(
            fileName: currentStep.audioFileName,
            fallbackText: currentStep.bodyText
        )
        lastSpokenStepID = currentStep.id
    }

    private func playAriadneAssistantHelpIfNeeded() {
        guard shouldShowAriadneAssistantCard else { return }

        let now = Date()
        guard now.timeIntervalSince(lastAriadneAssistantAudioTime) > 2.0 else { return }

        lastAriadneAssistantAudioTime = now
        audio.play(
            fileName: "13 pssst..over here.mp3",
            fallbackText: "Psst... over here. Look above me for the puzzle piece."
        )
    }

    private func repeatCurrentLine() {
        if isDialogueStep {
            guard shouldShowDialogueCard else { return }
        }

        audio.play(
            fileName: currentStep.audioFileName,
            fallbackText: currentStep.repeatLine ?? currentStep.bodyText
        )
    }
}


private final class VolumeButtonController {
    private enum Config {
        // The volume buttons are not exposed by iOS as normal app buttons.
        // This fallback observes the system volume value and treats a volume-up
        // change as the same action as tapping the screen.
        // Betron 3-button wired earbuds usually expose the center button as a
        // play/pause remote command. If iOS does not deliver that command, the
        // + and - buttons still change system volume. For the prototype, either
        // volume direction can also advance the scene.
        static let triggerOnVolumeUp = true
        static let triggerOnVolumeDown = true
        static let minimumDelta: Float = 0.01
        static let debounceInterval: TimeInterval = 0.35
    }

    private var observation: NSKeyValueObservation?
    private var primaryAction: (() -> Void)?
    private var lastVolume: Float = AVAudioSession.sharedInstance().outputVolume
    private var lastTriggerDate = Date.distantPast
    private var isRunning = false

    func start(action: @escaping () -> Void) {
        primaryAction = action

        guard !isRunning else { return }
        isRunning = true

        configureAudioSession()
        lastVolume = AVAudioSession.sharedInstance().outputVolume

        observation = AVAudioSession.sharedInstance().observe(
            \.outputVolume,
             options: [.new]
        ) { [weak self] _, change in
            guard let newVolume = change.newValue else { return }
            self?.handleVolumeChange(newVolume)
        }
    }

    func stop() {
        observation?.invalidate()
        observation = nil
        primaryAction = nil
        isRunning = false
    }

    private func handleVolumeChange(_ newVolume: Float) {
        let delta = newVolume - lastVolume
        lastVolume = newVolume

        guard abs(delta) >= Config.minimumDelta else { return }

        let isVolumeUp = delta > 0
        let shouldTrigger = (isVolumeUp && Config.triggerOnVolumeUp)
            || (!isVolumeUp && Config.triggerOnVolumeDown)

        guard shouldTrigger else { return }

        let now = Date()
        guard now.timeIntervalSince(lastTriggerDate) >= Config.debounceInterval else { return }
        lastTriggerDate = now

        DispatchQueue.main.async { [weak self] in
            self?.primaryAction?()
        }
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Volume button observer audio session setup failed: \(error)")
        }
    }
}

private final class HeadsetButtonController {
    private var primaryAction: (() -> Void)?
    private var isRunning = false
    private var silentKeepAlivePlayer: AVAudioPlayer?

    func start(action: @escaping () -> Void) {
        primaryAction = action

        guard !isRunning else { return }
        isRunning = true

        configureAudioSession()
        startSilentKeepAliveAudio()
        UIApplication.shared.beginReceivingRemoteControlEvents()
        configureRemoteCommands()
        publishNowPlayingInfo(isPlaying: true)
    }

    func stop() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.togglePlayPauseCommand.removeTarget(nil)
        commandCenter.nextTrackCommand.removeTarget(nil)
        commandCenter.previousTrackCommand.removeTarget(nil)
        commandCenter.stopCommand.removeTarget(nil)

        silentKeepAlivePlayer?.stop()
        silentKeepAlivePlayer = nil

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        UIApplication.shared.endReceivingRemoteControlEvents()
        isRunning = false
    }

    private func configureRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()

        // Remove old targets first so repeated app foregrounding does not stack
        // duplicate handlers and accidentally advance more than one scene.
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.togglePlayPauseCommand.removeTarget(nil)
        commandCenter.nextTrackCommand.removeTarget(nil)
        commandCenter.previousTrackCommand.removeTarget(nil)
        commandCenter.stopCommand.removeTarget(nil)

        // The center button on most 3-button wired earbuds maps to play/pause
        // or togglePlayPause. The volume up/down buttons are controlled by iOS
        // system volume and are not available as normal app controls.
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.stopCommand.isEnabled = true

        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.triggerPrimaryAction()
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.triggerPrimaryAction()
            return .success
        }

        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.triggerPrimaryAction()
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.triggerPrimaryAction()
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.triggerPrimaryAction()
            return .success
        }

        commandCenter.stopCommand.addTarget { [weak self] _ in
            self?.triggerPrimaryAction()
            return .success
        }
    }

    private func triggerPrimaryAction() {
        DispatchQueue.main.async { [weak self] in
            self?.primaryAction?()
            self?.publishNowPlayingInfo(isPlaying: true)

            if self?.silentKeepAlivePlayer?.isPlaying != true {
                self?.silentKeepAlivePlayer?.play()
            }
        }
    }

    private func configureAudioSession() {
        do {
            // Wired headset middle buttons are delivered to apps as media remote
            // play/pause events. Using playAndRecord with Bluetooth/headset options
            // makes iOS more likely to route those events to HeraKlue while the
            // AR scene is active.
            try AVAudioSession.sharedInstance().setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Headset button audio session setup failed: \(error)")
        }
    }

    private func startSilentKeepAliveAudio() {
        do {
            let url = try makeSilentControlAudioFileIfNeeded()
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 1.0
            player.prepareToPlay()
            player.play()
            silentKeepAlivePlayer = player
        } catch {
            print("Could not start silent headset control audio: \(error)")
        }
    }

    private func makeSilentControlAudioFileIfNeeded() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("heraklue_headset_button_keepalive.wav")

        if FileManager.default.fileExists(atPath: url.path) {
            return url
        }

        let sampleRate: UInt32 = 44_100
        let channels: UInt16 = 1
        let bitsPerSample: UInt16 = 16
        let durationSeconds: UInt32 = 1
        let bytesPerSample = UInt32(bitsPerSample / 8)
        let dataSize = sampleRate * UInt32(channels) * bytesPerSample * durationSeconds
        let byteRate = sampleRate * UInt32(channels) * bytesPerSample
        let blockAlign = channels * (bitsPerSample / 8)

        var data = Data()

        func appendString(_ value: String) {
            data.append(value.data(using: .ascii)!)
        }

        func appendUInt16(_ value: UInt16) {
            var littleEndianValue = value.littleEndian
            withUnsafeBytes(of: &littleEndianValue) { buffer in
                data.append(contentsOf: buffer)
            }
        }

        func appendUInt32(_ value: UInt32) {
            var littleEndianValue = value.littleEndian
            withUnsafeBytes(of: &littleEndianValue) { buffer in
                data.append(contentsOf: buffer)
            }
        }

        appendString("RIFF")
        appendUInt32(36 + dataSize)
        appendString("WAVE")
        appendString("fmt ")
        appendUInt32(16)
        appendUInt16(1)
        appendUInt16(channels)
        appendUInt32(sampleRate)
        appendUInt32(byteRate)
        appendUInt16(blockAlign)
        appendUInt16(bitsPerSample)
        appendString("data")
        appendUInt32(dataSize)
        data.append(Data(count: Int(dataSize)))

        try data.write(to: url, options: .atomic)
        return url
    }

    private func publishNowPlayingInfo(isPlaying: Bool) {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: "HeraKlue",
            MPMediaItemPropertyArtist: "Headset Button Control",
            MPMediaItemPropertyPlaybackDuration: 3600,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: 0,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
            MPNowPlayingInfoPropertyIsLiveStream: true
        ]
    }
}

private struct SystemVolumeControlView: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView {
        let view = MPVolumeView(frame: .zero)
        view.showsRouteButton = false
        view.showsVolumeSlider = true
        return view
    }

    func updateUIView(_ uiView: MPVolumeView, context: Context) { }
}

private final class StoryAudioController {
    private let synthesizer = AVSpeechSynthesizer()
    private var player: AVAudioPlayer?

    func play(fileName: String?, fallbackText: String) {
        stopCurrentAudio()

        if let fileName, let url = bundledAudioURL(for: fileName) {
            do {
                try configureAudioSession()
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                player.play()
                self.player = player
                return
            } catch {
                print("Could not play audio file \(fileName): \(error)")
            }
        } else if let fileName {
            print("Could not find audio file in app bundle: \(fileName)")
        }

        speakFallback(fallbackText)
    }

    private func stopCurrentAudio() {
        player?.stop()
        player = nil
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func bundledAudioURL(for fileName: String) -> URL? {
        let nsFileName = fileName as NSString
        let resourceName = nsFileName.deletingPathExtension
        let fileExtension = nsFileName.pathExtension.isEmpty ? "mp3" : nsFileName.pathExtension

        return Bundle.main.url(forResource: resourceName, withExtension: fileExtension)
    }

    private func configureAudioSession() throws {
        try AVAudioSession.sharedInstance().setCategory(
            .playback,
            mode: .spokenAudio,
            options: [.duckOthers]
        )
        try AVAudioSession.sharedInstance().setActive(true)
    }

    private func speakFallback(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.48
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        synthesizer.speak(utterance)
    }
}

struct CrosshairView: View {
    let accentBlue: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.9), lineWidth: 3)
                .frame(width: 44, height: 44)

            Circle()
                .fill(accentBlue)
                .frame(width: 8, height: 8)
        }
        .shadow(color: .black.opacity(0.35), radius: 4)
    }
}
