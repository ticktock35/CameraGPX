import CoreLocation
import Foundation

enum TriggerMode: String, Codable, CaseIterable, Identifiable {
    case either
    case both

    var id: String { rawValue }

    var title: String {
        switch self {
        case .either: "時間或距離"
        case .both: "時間且距離"
        }
    }

    var detail: String {
        switch self {
        case .either:
            "站著也會依時間留點，相片比較對得準。移動超過距離時會提早記一點。"
        case .both:
            "兩個條件都達到才記點。距離大於 0 時，系統會等你移動才更新定位，比較省電；原地拍的照片可能對不到點。"
        }
    }
}

enum FixQuality: String, Codable, CaseIterable, Identifiable {
    case precise
    case balanced
    case saver

    var id: String { rawValue }

    var title: String {
        switch self {
        case .precise: "精準"
        case .balanced: "平衡"
        case .saver: "省電"
        }
    }

    var detail: String {
        switch self {
        case .precise: "最佳定位，最耗電。適合要很準的短途。"
        case .balanced: "大約 10 公尺。走路拍照的預設。"
        case .saver: "大約 100 公尺。路線比較粗，電池撐比較久。"
        }
    }

    var clAccuracy: CLLocationAccuracy {
        switch self {
        case .precise: kCLLocationAccuracyBest
        case .balanced: kCLLocationAccuracyNearestTenMeters
        case .saver: kCLLocationAccuracyHundredMeters
        }
    }

    var acceptableAccuracy: CLLocationAccuracy {
        switch self {
        case .precise: 40
        case .balanced: 65
        case .saver: 200
        }
    }
}

struct RecordingSettings: Codable, Equatable {
    var intervalSeconds: Double = 5
    var distanceMeters: Double = 10
    var trigger: TriggerMode = .either
    var quality: FixQuality = .balanced

    static let intervalChoices: [Double] = [1, 2, 5, 10, 15, 30, 60, 120]
    static let distanceChoices: [Double] = [0, 5, 10, 20, 50, 100]

    var summary: String {
        let time = intervalSeconds < 60
            ? "每 \(Int(intervalSeconds)) 秒"
            : "每 \(Int(intervalSeconds / 60)) 分鐘"
        let distance = distanceMeters <= 0
            ? "不看距離"
            : "移動 \(Int(distanceMeters)) 公尺"
        let join = trigger == .either ? "或" : "且"
        return "\(time)\(join)\(distance) · \(quality.title)"
    }
}

struct CameraProfile: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var offsetSeconds: Double
    var syncedAt: Date?

    init(id: UUID = UUID(), name: String, offsetSeconds: Double = 0, syncedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.offsetSeconds = offsetSeconds
        self.syncedAt = syncedAt
    }
}

struct TrackPoint: Codable, Identifiable, Equatable {
    var id: UUID
    var latitude: Double
    var longitude: Double
    var elevation: Double?
    var timestamp: Date
    var horizontalAccuracy: Double
    var speed: Double?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(location: CLLocation) {
        id = UUID()
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
        elevation = location.verticalAccuracy >= 0 ? location.altitude : nil
        timestamp = location.timestamp
        horizontalAccuracy = location.horizontalAccuracy
        speed = location.speed >= 0 ? location.speed : nil
    }
}

struct Track: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var startedAt: Date
    var endedAt: Date?
    var points: [TrackPoint]
    var distanceMeters: Double
    var cameraID: UUID?
    var cameraName: String?
    var offsetSeconds: Double
    var settingsNote: String
    var wasRecovered: Bool

    var isOpen: Bool { endedAt == nil }

    var duration: TimeInterval {
        let end = endedAt ?? points.last?.timestamp ?? startedAt
        return max(0, end.timeIntervalSince(startedAt))
    }

    var displayName: String {
        if let cameraName, !cameraName.isEmpty {
            return "\(Format.listTitle(startedAt)) · \(cameraName)"
        }
        return Format.listTitle(startedAt)
    }
}

enum GPXTimeBase: String, CaseIterable, Identifiable {
    case gps
    case camera

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gps: "真實 GPS 時間"
        case .camera: "對齊相機時鐘"
        }
    }

    var detail: String {
        switch self {
        case .gps:
            "軌跡是手機收到的 UTC。相片的 EXIF 若和手機有時差，匯入時要另外補正。"
        case .camera:
            "每個點都加上相機時差。電腦用拍攝地的時區打開時，時間數字會跟相機 EXIF 一樣。"
        }
    }
}

enum ClockParts {
    static func date(day: Date, hour: Int, minute: Int, second: Int) -> Date {
        var parts = Calendar.current.dateComponents([.year, .month, .day], from: day)
        parts.hour = hour
        parts.minute = minute
        parts.second = second
        return Calendar.current.date(from: parts) ?? day
    }

    static func split(_ date: Date) -> (hour: Int, minute: Int, second: Int) {
        let parts = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        return (parts.hour ?? 0, parts.minute ?? 0, parts.second ?? 0)
    }
}
