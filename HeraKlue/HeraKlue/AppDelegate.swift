import AVFoundation
import SwiftUI
import UIKit

extension Notification.Name {
    static let heraklueHeadsetButtonPressed = Notification.Name("heraklueHeadsetButtonPressed")
}

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        configureAudioSession()

        let window = UIWindow(frame: UIScreen.main.bounds)
        let rootViewController = RemoteControlHostingController(rootView: ContentView())
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()
        self.window = window

        application.beginReceivingRemoteControlEvents()
        rootViewController.becomeFirstResponder()

        return true
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
            print("Audio session setup failed: \(error)")
        }
    }
}

final class RemoteControlHostingController<Content: View>: UIHostingController<Content> {
    override var canBecomeFirstResponder: Bool {
        true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.beginReceivingRemoteControlEvents()
        becomeFirstResponder()
    }

    override var keyCommands: [UIKeyCommand]? {
        [
            UIKeyCommand(input: " ", modifierFlags: [], action: #selector(handleExternalButtonCommand)),
            UIKeyCommand(input: "\r", modifierFlags: [], action: #selector(handleExternalButtonCommand)),
            UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(handleExternalButtonCommand)),
            UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(handleExternalButtonCommand))
        ]
    }

    override func remoteControlReceived(with event: UIEvent?) {
        guard event?.type == .remoteControl else {
            super.remoteControlReceived(with: event)
            return
        }

        switch event?.subtype {
        case .remoteControlPlay,
             .remoteControlPause,
             .remoteControlTogglePlayPause,
             .remoteControlNextTrack,
             .remoteControlPreviousTrack,
             .remoteControlStop:
            postHeadsetButtonPress()
        default:
            super.remoteControlReceived(with: event)
        }
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            switch press.type {
            case .playPause, .select:
                postHeadsetButtonPress()
                return
            default:
                continue
            }
        }

        super.pressesBegan(presses, with: event)
    }

    @objc private func handleExternalButtonCommand() {
        postHeadsetButtonPress()
    }

    private func postHeadsetButtonPress() {
        NotificationCenter.default.post(name: .heraklueHeadsetButtonPressed, object: nil)
    }
}
