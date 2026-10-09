import MapKit
import SwiftUI

struct TrackDetailView: View {
    @Environment(AppModel.self) private var store
    let trackID: UUID

    @State private var timeBase: GPXTimeBase = .gps
    @State private var file: GPXDocument?
    @State private var banner: String?
    @State private var savingCloud = false
    @State private var renaming = false
    @State private var newName = ""
    @State private var position: MapCameraPosition = .automatic

    private var track: Track? {
        store.tracks.first { $0.id == trackID }
    }

    var body: some View {
        ZStack {
            Theme.paper.ignoresSafeArea()
            if let track {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        map(track)
                        summary(track)
                        if track.wasRecovered {
                            Text("這條路線上次沒有正常結束，已用最後一個點當作結束時間。")
                                .font(.footnote)
                                .foregroundStyle(Theme.inkSoft)
                        }
                        export(track)
                    }
                    .padding(20)
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .navigationTitle(track.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button("重新命名") {
                                newName = track.name
                                renaming = true
                            }
                            if !track.isOpen {
                                Button("刪除", role: .destructive) {
                                    store.deleteTrack(track)
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
                .task(id: exportKey(track)) {
                    refreshFile(track)
                }
            } else {
                ContentUnavailableView("這條軌跡已刪除", systemImage: "map")
            }
        }
        .toolbarBackground(Theme.paper, for: .navigationBar)
        .alert("重新命名", isPresented: $renaming) {
            TextField("名稱", text: $newName)
            Button("儲存") {
                if let track {
                    store.renameTrack(track, to: newName)
                }
            }
            Button("取消", role: .cancel) {}
        }
    }

    private func exportKey(_ track: Track) -> String {
        "\(timeBase.rawValue)|\(track.offsetSeconds)|\(track.points.count)|\(track.cameraName ?? "")"
    }

    private func map(_ track: Track) -> some View {
        Map(position: $position) {
            if track.points.count >= 2 {
                MapPolyline(coordinates: track.points.map(\.coordinate))
                    .stroke(Theme.brass, lineWidth: 4)
            }
            if let first = track.points.first {
                Annotation("起點", coordinate: first.coordinate, anchor: .center) {
                    Circle().fill(Theme.gps).frame(width: 12, height: 12)
                        .overlay { Circle().stroke(.white, lineWidth: 2) }
                }
            }
            if let last = track.points.last, track.points.count > 1 {
                Annotation("終點", coordinate: last.coordinate, anchor: .center) {
                    Circle().fill(Theme.rec).frame(width: 12, height: 12)
                        .overlay { Circle().stroke(.white, lineWidth: 2) }
                }
            }
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .frame(height: 240)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Theme.line, lineWidth: 1)
        }
        .onAppear {
            position = .region(region(for: track.points))
        }
    }

    private func summary(_ track: Track) -> some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(Format.distance(track.distanceMeters)) · \(track.points.count) 點")
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                Text("\(Format.listTitle(track.startedAt))  ·  \(Format.timer(track.duration))")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft)
                    .monospacedDigit()
                Text(track.settingsNote)
                    .font(.footnote)
                    .foregroundStyle(Theme.inkSoft)
                Text(Format.offset(track.offsetSeconds))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.brass)
                if !store.cameras.isEmpty && !track.isOpen {
                    Menu {
                        ForEach(store.cameras) { camera in
                            Button(camera.name) {
                                store.apply(camera: camera, to: track.id)
                            }
                        }
                    } label: {
                        Text("套用相機時差")
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }
        }
    }

    private func export(_ track: Track) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("匯出")
                .font(.system(size: 15, weight: .semibold))
            if track.points.isEmpty {
                Text("沒有點位，無法做成 GPX。")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft)
            } else if track.isOpen {
                Text("先停止記錄，再匯出。")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft)
            } else {
                Picker("時間基準", selection: $timeBase) {
                    ForEach(GPXTimeBase.allCases) { base in
                        Text(base.title).tag(base)
                    }
                }
                .pickerStyle(.segmented)

                Text(timeBase.detail)
                    .font(.footnote)
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)

                if timeBase == .camera {
                    Text("請把電腦時區設成拍攝當地，ExifTool 才會和相片對上。")
                        .font(.footnote)
                        .foregroundStyle(Theme.inkSoft)
                }

                commandBox(track)

                if let file {
                    ShareLink(item: file, preview: SharePreview(file.url.lastPathComponent, image: Image(systemName: "map"))) {
                        Label("分享到電腦或「檔案」", systemImage: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(Theme.paper)
                            .background(Theme.ink, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }

                Button {
                    saveCloud(track)
                } label: {
                    HStack {
                        if savingCloud { ProgressView() }
                        Text(savingCloud ? "正在存到 iCloud" : "存到 iCloud 雲碟")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(Theme.ink)
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Theme.line, lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
                .disabled(savingCloud)

                Text("檔案也在這支 iPhone 的 Cameras GPX 文件夾。用線接上 Mac，可在 Finder 側邊欄直接拖走。")
                    .font(.footnote)
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)

                if let banner {
                    Text(banner)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Theme.gps)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func commandBox(_ track: Track) -> some View {
        let name = Exporter.filename(for: track, timeBase: timeBase)
        let command = GPXWriter.command(for: track, timeBase: timeBase, filename: name)
        return VStack(alignment: .leading, spacing: 8) {
            Text(command)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(Theme.ink)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
            Button("複製 ExifTool 指令") {
                UIPasteboard.general.string = command
                banner = "已複製。在相片資料夾執行時，把 DIR 換成路徑。"
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Theme.brass)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.line, lineWidth: 1)
        }
    }

    private func refreshFile(_ track: Track) {
        file = nil
        guard !track.points.isEmpty, !track.isOpen else { return }
        if let url = try? Exporter.writeLocal(track: track, timeBase: timeBase) {
            file = GPXDocument(url: url)
        }
    }

    private func saveCloud(_ track: Track) {
        savingCloud = true
        banner = nil
        Task {
            do {
                _ = try await Exporter.saveToICloud(track: track, timeBase: timeBase)
                banner = "已存到 iCloud 雲碟的「Cameras GPX」資料夾。"
                Haptic.success()
            } catch {
                banner = error.localizedDescription
            }
            savingCloud = false
        }
    }

    private func region(for points: [TrackPoint]) -> MKCoordinateRegion {
        guard let first = points.first else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 25.03, longitude: 121.56),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
        var minLat = first.latitude
        var maxLat = first.latitude
        var minLon = first.longitude
        var maxLon = first.longitude
        for point in points {
            minLat = min(minLat, point.latitude)
            maxLat = max(maxLat, point.latitude)
            minLon = min(minLon, point.longitude)
            maxLon = max(maxLon, point.longitude)
        }
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.5, 0.004),
            longitudeDelta: max((maxLon - minLon) * 1.5, 0.004)
        )
        return MKCoordinateRegion(center: center, span: span)
    }
}
