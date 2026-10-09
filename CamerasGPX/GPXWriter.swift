import Foundation

enum GPXWriter {
    /// Camera EXIF is local wall-clock time with no zone. Shifting each GPS
    /// instant by `offsetSeconds` makes a local-time reading of the GPX match
    /// the camera clock. Positive offset means the camera is ahead.
    static func make(track: Track, timeBase: GPXTimeBase) -> Data {
        let shift = timeBase == .camera ? track.offsetSeconds : 0
        let fileTime = track.startedAt.addingTimeInterval(shift)
        var xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="CamerasGPX 1.0"
          xmlns="http://www.topografix.com/GPX/1/1"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">
          <metadata>
            <name>\(escape(track.displayName))</name>
            <desc>\(escape(description(for: track, timeBase: timeBase)))</desc>
            <time>\(stamp(fileTime))</time>
          </metadata>
          <trk>
            <name>\(escape(track.displayName))</name>
            <desc>\(escape(track.settingsNote))</desc>

        """

        var segmentOpen = false
        var previous: TrackPoint?
        for point in track.points {
            if let previous, point.timestamp.timeIntervalSince(previous.timestamp) > 180 {
                if segmentOpen {
                    xml += "    </trkseg>\n"
                    segmentOpen = false
                }
            }
            if !segmentOpen {
                xml += "    <trkseg>\n"
                segmentOpen = true
            }
            xml += pointXML(point, shift: shift)
            previous = point
        }
        if segmentOpen {
            xml += "    </trkseg>\n"
        }
        xml += """
          </trk>
        </gpx>
        """
        return Data(xml.utf8)
    }

    static func command(for track: Track, timeBase: GPXTimeBase, filename: String) -> String {
        switch timeBase {
        case .gps:
            let sync = Format.geosync(track.offsetSeconds)
            return "exiftool -geotag \"\(filename)\" -geosync=\(sync) DIR"
        case .camera:
            return "exiftool -geotag \"\(filename)\" DIR"
        }
    }

    private static func description(for track: Track, timeBase: GPXTimeBase) -> String {
        let camera = track.cameraName ?? "未指定相機"
        let offset = Format.offset(track.offsetSeconds)
        switch timeBase {
        case .gps:
            return "相機 \(camera)。\(offset)。此檔為真實 GPS 時間（UTC）。ExifTool：-geosync=\(Format.geosync(track.offsetSeconds))。"
        case .camera:
            return "相機 \(camera)。\(offset)。此檔已把每個點平移 \(Int(track.offsetSeconds.rounded())) 秒，讓拍攝地時區的時間數字對上相機 EXIF。"
        }
    }

    private static func pointXML(_ point: TrackPoint, shift: TimeInterval) -> String {
        var body = String(format: "      <trkpt lat=\"%.7f\" lon=\"%.7f\">\n", point.latitude, point.longitude)
        if let elevation = point.elevation {
            body += String(format: "        <ele>%.1f</ele>\n", elevation)
        }
        body += "        <time>\(stamp(point.timestamp.addingTimeInterval(shift)))</time>\n"
        body += "      </trkpt>\n"
        return body
    }

    private static func stamp(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: date)
    }

    private static func escape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
