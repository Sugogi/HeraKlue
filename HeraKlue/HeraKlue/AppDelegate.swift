import AVFoundation
import MediaPlayer
import SwiftUI
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    let airPods = AirPodsController()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        application.beginReceivingRemoteControlEvents()

        let window = UIWindow(windowScene: application.connectedScenes.first as! UIWindowScene)
        let contentView = ContentView(airPods: airPods)
        window.rootViewController = UIHostingController(rootView: contentView)
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}
