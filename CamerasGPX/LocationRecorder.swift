import CoreLocation
import Observation
import UIKit

@Observable
final class LocationRecorder: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let store: AppModel
    private var lastSaved: CLLocation?
    private var recordingStarted: Date?
    private var wantsStart = false
    private var didAskAlways = false

    var fix: CLLocation?
    var isRecording = false
    var authorization: CLAuthorizationStatus = .notDetermined
    var statusMessage: String?

    var needsAlwaysUpgrade: Bool {
        isRecording && authorization == .authorizedWhenInUse
    }

    init(store: AppModel) {
        self.store = store
        super.init()
        authorization = manager.authorizationStatus
        manager.delegate = self
        manager.activityType = .otherNavigation
        manager.pausesLocationUpdatesAutomatically = false
        manager.showsBackgroundLocationIndicator = true
        apply(store.settings)
    }

    func apply(_ settings: RecordingSettings) {
        manager.desiredAccuracy = settings.quality.clAccuracy
        if settings.trigger == .both, settings.distanceMeters > 0 {
            manager.distanceFilter = settings.distanceMeters
        } else {
            manager.distanceFilter = kCLDistanceFilterNone
        }
    }

    func toggle() {
        if isRecording {
            stop()
        } else {
            begin()
        }
    }

    func begin() {
        wantsStart = true
        statusMessage = nil
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            askAlwaysIfNeeded()
            startUpdates()
        case .authorizedAlways:
            startUpdates()
        case .denied, .restricted:
            wantsStart = false
            statusMessage = "定位已關閉。到「設定」允許 Cameras GPX 取用位置，才記得到路線。"
        @unknown default:
            wantsStart = false
        }
    }

    func stop() {
        wantsStart = false
        isRecording = false
        lastSaved = nil
        recordingStarted = nil
        let finishedID = store.activeTrack?.id
        store.finishActiveTrack()
        if let finishedID, let track = store.tracks.first(where: { $0.id == finishedID }) {
            try? Exporter.writeLocal(track: track, timeBase: .gps)
            if abs(track.offsetSeconds) >= 0.5 {
                try? Exporter.writeLocal(track: track, timeBase: .camera)
            }
        }
        manager.stopUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = false
        UIApplication.shared.isIdleTimerDisabled = false
    }

    private func askAlwaysIfNeeded() {
        guard !didAskAlways else { return }
        didAskAlways = true
        manager.requestAlwaysAuthorization()
    }

    private func startUpdates() {
        guard !isRecording else { return }
        wantsStart = false
        apply(store.settings)
        if manager.authorizationStatus == .authorizedAlways {
            manager.allowsBackgroundLocationUpdates = true
        }
        _ = store.beginTrack()
        isRecording = true
        recordingStarted = Date()
        lastSaved = nil
        UIApplication.shared.isIdleTimerDisabled = true
        manager.startUpdatingLocation()
        Haptic.tap()
    }

    private func consume(_ locations: [CLLocation]) {
        guard let location = locations.last else { return }
        if abs(location.timestamp.timeIntervalSinceNow) > 12 { return }
        fix = location
        guard isRecording, let trackID = store.activeTrack?.id else { return }
        guard shouldKeep(location) else { return }
        lastSaved = location
        store.append(location, to: trackID)
    }

    private func shouldKeep(_ location: CLLocation) -> Bool {
        let settings = store.settings
        guard location.horizontalAccuracy >= 0 else { return false }

        guard let lastSaved else {
            if location.horizontalAccuracy <= settings.quality.acceptableAccuracy { return true }
            if let recordingStarted, Date().timeIntervalSince(recordingStarted) > 8, location.horizontalAccuracy <= 180 {
                return true
            }
            return false
        }

        let elapsed = location.timestamp.timeIntervalSince(lastSaved.timestamp)
        if elapsed < 1 { return false }
        let moved = location.distance(from: lastSaved)
        let timeReached = elapsed >= settings.intervalSeconds
        let distanceReached = settings.distanceMeters > 0 && moved >= settings.distanceMeters

        switch settings.trigger {
        case .either:
            if settings.distanceMeters <= 0 { return timeReached }
            return timeReached || distanceReached
        case .both:
            if settings.distanceMeters <= 0 { return timeReached }
            return timeReached && distanceReached
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorization = status
            if self.wantsStart {
                switch status {
                case .authorizedWhenInUse:
                    self.askAlwaysIfNeeded()
                    self.startUpdates()
                case .authorizedAlways:
                    self.startUpdates()
                case .denied, .restricted:
                    self.wantsStart = false
                    self.statusMessage = "定位已關閉。到「設定」允許 Cameras GPX 取用位置，才記得到路線。"
                default:
                    break
                }
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let snapshot = locations
        Task { @MainActor in
            self.consume(snapshot)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let text = error.localizedDescription
        Task { @MainActor in
            self.statusMessage = text
        }
    }
}
