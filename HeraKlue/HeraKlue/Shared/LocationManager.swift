//
//  LocationManager.swift
//  HeraKlue
//
//  SHARED. Minimal GPS helper for the city-scale parts of the game: it
//  reports the player's location and how far they are from a target spot
//  (e.g. the loggia, the Four Stone Lions). Use it to trigger AR content
//  once the player is *near* a place — see the note in the chat about why
//  we use proximity rather than ARKit geo-anchors.
//
//  REQUIRES a usage-description key before it will work at runtime:
//  in Xcode, target → Info → add "Privacy - Location When In Use Usage
//  Description". Location works on a real device (or a simulated location
//  in the Simulator).
//

import CoreLocation
import Observation

@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    var location: CLLocation?
    var authorization: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    /// Ask permission and begin receiving location updates.
    func start() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    /// Metres between the player and a target coordinate (nil until we have a fix).
    func distance(to target: CLLocationCoordinate2D) -> CLLocationDistance? {
        guard let location else { return nil }
        let t = CLLocation(latitude: target.latitude, longitude: target.longitude)
        return location.distance(from: t)
    }

    // MARK: CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorization = manager.authorizationStatus
    }
}
