import SwiftUI
import UIKit

enum Theme {
    static let paper = Color(red: 0.953, green: 0.937, blue: 0.902)
    static let ink = Color(red: 0.110, green: 0.098, blue: 0.082)
    static let inkSoft = Color(red: 0.365, green: 0.337, blue: 0.298)
    static let line = Color(red: 0.847, green: 0.812, blue: 0.753)
    static let card = Color(red: 0.992, green: 0.980, blue: 0.957)
    static let brass = Color(red: 0.620, green: 0.420, blue: 0.180)
    static let rec = Color(red: 0.769, green: 0.227, blue: 0.169)
    static let gps = Color(red: 0.122, green: 0.455, blue: 0.290)
    static let night = Color(red: 0.067, green: 0.063, blue: 0.055)

    static let paperUI = UIColor(red: 0.953, green: 0.937, blue: 0.902, alpha: 1)
}

enum Haptic {
    static func tap() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

struct PaperCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Theme.line, lineWidth: 1)
            }
    }
}

struct PrimaryButton: View {
    var title: String
    var systemImage: String?
    var filled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(.system(size: 16, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(filled ? Theme.paper : Theme.ink)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(filled ? Theme.ink : Color.clear)
            }
            .overlay {
                if !filled {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Theme.line, lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

enum Format {
    static func clock(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hant_TW")
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }

    static func day(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hant_TW")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter.string(from: date)
    }

    static func listTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hant_TW")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: date)
    }

    static func filenameStamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyyMMdd_HHmm"
        return formatter.string(from: date)
    }

    static func timer(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval.rounded(.down)))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    static func distance(_ meters: Double) -> String {
        if meters < 1000 {
            return String(format: "%.0f 公尺", meters)
        }
        return String(format: "%.2f 公里", meters / 1000)
    }

    static func speed(_ metersPerSecond: Double?) -> String {
        guard let metersPerSecond, metersPerSecond >= 0 else { return "— km/h" }
        return String(format: "%.1f km/h", metersPerSecond * 3.6)
    }

    static func accuracy(_ meters: Double?) -> String {
        guard let meters, meters >= 0 else { return "尚未定位" }
        return String(format: "±%.0f 公尺", meters)
    }

    static func coordinate(_ value: Double) -> String {
        String(format: "%.5f", value)
    }

    static func offset(_ seconds: Double) -> String {
        let rounded = Int(seconds.rounded())
        if rounded == 0 { return "相機與手機一致" }
        let ahead = rounded > 0
        let body = offsetBody(abs(rounded))
        return ahead ? "相機快 \(body)" : "相機慢 \(body)"
    }

    static func offsetCompact(_ seconds: Double) -> String {
        let rounded = Int(seconds.rounded())
        if rounded == 0 { return "時差 0 秒" }
        let sign = rounded > 0 ? "+" : "−"
        return "時差 \(sign)\(offsetBody(abs(rounded)))"
    }

    /// ExifTool `-geosync`: negative when the camera clock is ahead of real time.
    static func geosync(_ seconds: Double) -> String {
        let total = Int(seconds.rounded())
        let sign = total >= 0 ? "-" : "+"
        let absolute = abs(total)
        let hours = absolute / 3600
        let minutes = (absolute % 3600) / 60
        let secs = absolute % 60
        return String(format: "%@%d:%02d:%02d", sign, hours, minutes, secs)
    }

    static func zoneLabel(_ date: Date = Date()) -> String {
        let zone = TimeZone.current
        let name = zone.localizedName(for: zone.isDaylightSavingTime(for: date) ? .daylightSaving : .standard, locale: Locale(identifier: "zh_Hant_TW"))
            ?? zone.identifier
        let offset = zone.secondsFromGMT(for: date)
        let sign = offset >= 0 ? "+" : "-"
        let hours = abs(offset) / 3600
        let minutes = (abs(offset) / 60) % 60
        return "\(name) UTC\(sign)\(hours):\(String(format: "%02d", minutes))"
    }

    private static func offsetBody(_ absolute: Int) -> String {
        let hours = absolute / 3600
        let minutes = (absolute % 3600) / 60
        let seconds = absolute % 60
        if hours > 0 {
            return "\(hours) 小時 \(minutes) 分 \(seconds) 秒"
        }
        if minutes > 0 {
            return "\(minutes) 分 \(seconds) 秒"
        }
        return "\(seconds) 秒"
    }
}
