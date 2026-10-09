import CoreLocation
import Foundation
import Observation

@Observable
final class AppModel {
    var tracks: [Track] = []
    var cameras: [CameraProfile] = []
    var settings = RecordingSettings()
    var selectedCameraID: UUID?
    var didDismissIntro = false
    var tutorialPresented = false

    var selectedCamera: CameraProfile? {
        cameras.first { $0.id == selectedCameraID } ?? cameras.first
    }

    var activeTrack: Track? {
        tracks.first { $0.isOpen }
    }

    init() {
        load()
        ensureCamera()
        recoverOpenTracks()
    }

    func updateSettings(_ settings: RecordingSettings) {
        self.settings = settings
        save()
    }

    func select(_ camera: CameraProfile) {
        selectedCameraID = camera.id
        save()
    }

    func addCamera(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let camera = CameraProfile(name: trimmed)
        cameras.append(camera)
        selectedCameraID = camera.id
        save()
    }

    func rename(_ camera: CameraProfile, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = cameras.firstIndex(where: { $0.id == camera.id }) else { return }
        cameras[index].name = trimmed
        save()
    }

    func delete(_ camera: CameraProfile) {
        cameras.removeAll { $0.id == camera.id }
        if selectedCameraID == camera.id {
            selectedCameraID = cameras.first?.id
        }
        ensureCamera()
        save()
    }

    func setOffset(_ seconds: Double, for cameraID: UUID, syncedAt: Date = Date()) {
        guard let index = cameras.firstIndex(where: { $0.id == cameraID }) else { return }
        cameras[index].offsetSeconds = seconds
        cameras[index].syncedAt = syncedAt
        save()
    }

    func adjustOffset(by delta: Double, for cameraID: UUID) {
        guard let camera = cameras.first(where: { $0.id == cameraID }) else { return }
        setOffset(camera.offsetSeconds + delta, for: cameraID)
    }

    func beginTrack() -> Track {
        let camera = selectedCamera
        let track = Track(
            id: UUID(),
            name: makeName(camera: camera?.name, date: Date()),
            startedAt: Date(),
            endedAt: nil,
            points: [],
            distanceMeters: 0,
            cameraID: camera?.id,
            cameraName: camera?.name,
            offsetSeconds: camera?.offsetSeconds ?? 0,
            settingsNote: settings.summary,
            wasRecovered: false
        )
        tracks.insert(track, at: 0)
        save()
        return track
    }

    func append(_ location: CLLocation, to trackID: UUID) {
        guard let index = tracks.firstIndex(where: { $0.id == trackID }) else { return }
        var track = tracks[index]
        let point = TrackPoint(location: location)
        if let last = track.points.last {
            let previous = CLLocation(latitude: last.latitude, longitude: last.longitude)
            track.distanceMeters += location.distance(from: previous)
        }
        track.points.append(point)
        tracks[index] = track
        save()
    }

    func finishActiveTrack() {
        guard let index = tracks.firstIndex(where: { $0.isOpen }) else { return }
        var track = tracks[index]
        track.endedAt = track.points.last?.timestamp ?? Date()
        tracks[index] = track
        save()
    }

    func deleteTrack(_ track: Track) {
        for base in [GPXTimeBase.gps, GPXTimeBase.camera] {
            let url = Exporter.documentsFolder().appendingPathComponent(Exporter.filename(for: track, timeBase: base))
            try? FileManager.default.removeItem(at: url)
        }
        tracks.removeAll { $0.id == track.id }
        save()
    }

    func renameTrack(_ track: Track, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = tracks.firstIndex(where: { $0.id == track.id }) else { return }
        tracks[index].name = trimmed
        save()
    }

    func apply(camera: CameraProfile, to trackID: UUID) {
        guard let index = tracks.firstIndex(where: { $0.id == trackID }) else { return }
        tracks[index].cameraID = camera.id
        tracks[index].cameraName = camera.name
        tracks[index].offsetSeconds = camera.offsetSeconds
        save()
    }

    func applySelectedOffsetToLatestTrack() {
        guard let camera = selectedCamera, let track = tracks.first(where: { !$0.isOpen }) ?? tracks.first else { return }
        apply(camera: camera, to: track.id)
    }

    func openTutorial() {
        tutorialPresented = true
    }

    func dismissIntro() {
        didDismissIntro = true
        save()
    }

    private func makeName(camera: String?, date: Date) -> String {
        if let camera, !camera.isEmpty {
            return "\(Format.listTitle(date)) · \(camera)"
        }
        return Format.listTitle(date)
    }

    private func ensureCamera() {
        if cameras.isEmpty {
            let camera = CameraProfile(name: "我的相機")
            cameras = [camera]
            selectedCameraID = camera.id
            save()
        } else if selectedCameraID == nil {
            selectedCameraID = cameras[0].id
        }
    }

    private func recoverOpenTracks() {
        var changed = false
        for index in tracks.indices where tracks[index].isOpen {
            tracks[index].endedAt = tracks[index].points.last?.timestamp ?? tracks[index].startedAt
            tracks[index].wasRecovered = true
            changed = true
        }
        if changed { save() }
    }

    private struct Snapshot: Codable {
        var tracks: [Track] = []
        var cameras: [CameraProfile] = []
        var settings = RecordingSettings()
        var selectedCameraID: UUID?
        var didDismissIntro = false
    }

    private var fileURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CamerasGPX", isDirectory: true)
            .appendingPathComponent("library.json")
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let snapshot = try? decoder.decode(Snapshot.self, from: data) else { return }
        tracks = snapshot.tracks
        cameras = snapshot.cameras
        settings = snapshot.settings
        selectedCameraID = snapshot.selectedCameraID
        didDismissIntro = snapshot.didDismissIntro
    }

    private func save() {
        let snapshot = Snapshot(
            tracks: tracks,
            cameras: cameras,
            settings: settings,
            selectedCameraID: selectedCameraID,
            didDismissIntro: didDismissIntro
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(snapshot) else { return }
        let url = fileURL
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }
}
