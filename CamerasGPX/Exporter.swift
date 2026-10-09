import CoreTransferable
import Foundation
import UniformTypeIdentifiers

enum ExportError: LocalizedError {
    case empty
    case iCloudUnavailable
    case writeFailed

    var errorDescription: String? {
        switch self {
        case .empty:
            "這條軌跡還沒有點，無法匯出。"
        case .iCloudUnavailable:
            "這台 iPhone 還沒有可用的 iCloud 雲碟。請先登入 iCloud，或改用分享，在「檔案」裡自己選 iCloud 雲碟。"
        case .writeFailed:
            "寫入檔案失敗。"
        }
    }
}

struct GPXDocument: Transferable {
    var url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .gpx) { document in
            SentTransferredFile(document.url)
        }
    }
}

extension UTType {
    static var gpx: UTType {
        UTType(importedAs: "com.topografix.gpx", conformingTo: .xml)
    }
}

enum Exporter {
    static func filename(for track: Track, timeBase: GPXTimeBase) -> String {
        let stamp = Format.filenameStamp(track.startedAt)
        let camera = sanitize(track.cameraName ?? "camera")
        let suffix = timeBase == .camera ? "camera" : "gps"
        return "CamerasGPX_\(stamp)_\(camera)_\(suffix).gpx"
    }

    static func writeLocal(track: Track, timeBase: GPXTimeBase) throws -> URL {
        guard !track.points.isEmpty else { throw ExportError.empty }
        let folder = documentsFolder()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appendingPathComponent(filename(for: track, timeBase: timeBase))
        let data = GPXWriter.make(track: track, timeBase: timeBase)
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw ExportError.writeFailed
        }
        return url
    }

    static func saveToICloud(track: Track, timeBase: GPXTimeBase) async throws -> URL {
        guard !track.points.isEmpty else { throw ExportError.empty }
        let data = GPXWriter.make(track: track, timeBase: timeBase)
        let name = filename(for: track, timeBase: timeBase)
        return try await Task.detached {
            guard let container = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
                throw ExportError.iCloudUnavailable
            }
            let folder = container.appendingPathComponent("Documents", isDirectory: true)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let url = folder.appendingPathComponent(name)
            do {
                try data.write(to: url, options: .atomic)
            } catch {
                throw ExportError.writeFailed
            }
            return url
        }.value
    }

    static func documentsFolder() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private static func sanitize(_ name: String) -> String {
        let forbidden = CharacterSet(charactersIn: "/\\:?%*|\"<>\n\r\t")
        let cleaned = name.components(separatedBy: forbidden).joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.isEmpty { return "camera" }
        return String(cleaned.prefix(40))
    }
}
