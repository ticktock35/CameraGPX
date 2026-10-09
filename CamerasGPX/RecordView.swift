import MapKit
import SwiftUI

struct RecordView: View {
    @Environment(AppModel.self) private var store
    @Environment(LocationRecorder.self) private var recorder
    @State private var showSettings = false
    @State private var confirmStop = false
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.paper.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header
                        if recorder.needsAlwaysUpgrade {
                            upgradeBanner
                        }
                        if let statusMessage = recorder.statusMessage {
                            notice(statusMessage, actionTitle: "打開設定") {
                                openSettings()
                            }
                        }
                        stats
                        policy
                        map
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                recordPlate
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .confirmationDialog("停止這段路線？", isPresented: $confirmStop, titleVisibility: .visible) {
                Button("停止並儲存", role: .destructive) {
                    Haptic.tap()
                    recorder.stop()
                }
                Button("繼續記錄", role: .cancel) {}
            } message: {
                Text("點位會留在「軌跡」，之後可以匯出 GPX。")
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("記錄")
                    .font(.system(size: 34, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
                Text("沒有 GPS 的相機，用這支手機留路線")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            tutorialButton
            Button {
                showSettings = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 44, height: 44)
                    .background(Theme.card, in: Circle())
                    .overlay { Circle().stroke(Theme.line, lineWidth: 1) }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("記錄方式")
        }
        .padding(.top, 8)
    }

    private var tutorialButton: some View {
        Button {
            store.openTutorial()
        } label: {
            Image(systemName: "book")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .frame(width: 44, height: 44)
                .background(Theme.card, in: Circle())
                .overlay { Circle().stroke(Theme.line, lineWidth: 1) }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("教學")
        .padding(.trailing, 8)
    }

    private var upgradeBanner: some View {
        notice("目前只有使用期間能定位。鎖屏後路線會停。請改成「永遠」，拍照時才不會斷。", actionTitle: "打開設定") {
            openSettings()
        }
    }

    private func notice(_ text: String, actionTitle: String, action: @escaping () -> Void) -> some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.brass)
            }
        }
    }

    private var map: some View {
        Map(position: $position) {
            if recorder.isRecording || !(store.activeTrack?.points.isEmpty ?? true) {
                let points = store.activeTrack?.points ?? []
                if points.count >= 2 {
                    MapPolyline(coordinates: points.map(\.coordinate))
                        .stroke(Theme.brass, lineWidth: 4)
                }
            }
            UserAnnotation()
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Theme.line, lineWidth: 1)
        }
        .overlay(alignment: .topLeading) {
            statusPill
                .padding(12)
        }
        .overlay(alignment: .bottomLeading) {
            if let fix = recorder.fix {
                Text("\(Format.coordinate(fix.coordinate.latitude)), \(Format.coordinate(fix.coordinate.longitude))")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(12)
            }
        }
    }

    private var statusPill: some View {
        let meters = recorder.fix?.horizontalAccuracy
        let ready = (meters ?? -1) >= 0 && (meters ?? 999) < 50
        return HStack(spacing: 6) {
            Circle()
                .fill(ready ? Theme.gps : Theme.brass)
                .frame(width: 8, height: 8)
            Text(ready ? "GPS \(Format.accuracy(meters))" : "正在找衛星")
                .font(.system(size: 12, weight: .semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
    }

    private var stats: some View {
        let track = store.activeTrack
        return PaperCard {
            VStack(alignment: .leading, spacing: 14) {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(Format.timer(elapsed(at: context.date, track: track)))
                        .font(.system(size: 44, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                HStack(spacing: 0) {
                    stat("距離", Format.distance(track?.distanceMeters ?? 0))
                    stat("點數", "\(track?.points.count ?? 0)")
                    stat("速度", Format.speed(recorder.fix?.speed))
                }
            }
        }
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.inkSoft)
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var policy: some View {
        VStack(alignment: .leading, spacing: 6) {
            cameraMenu
            Text(store.settings.summary)
                .font(.footnote)
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(.horizontal, 4)
    }

    private var cameraMenu: some View {
        Menu {
            ForEach(store.cameras) { camera in
                Button {
                    store.select(camera)
                } label: {
                    if camera.id == store.selectedCamera?.id {
                        Label(camera.name, systemImage: "checkmark")
                    } else {
                        Text(camera.name)
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "camera")
                Text(cameraLine)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 10, weight: .bold))
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Theme.ink)
        }
    }

    private var cameraLine: String {
        let name = store.selectedCamera?.name ?? "未選相機"
        let offset = Format.offset(store.selectedCamera?.offsetSeconds ?? 0)
        return "\(name) · \(offset)"
    }

    private var recordPlate: some View {
        VStack(spacing: 8) {
            Button {
                if recorder.isRecording {
                    confirmStop = true
                } else {
                    recorder.begin()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(recorder.isRecording ? Theme.night : Theme.rec)
                        .frame(width: 84, height: 84)
                    Circle()
                        .stroke(Theme.paper.opacity(0.85), lineWidth: 3)
                        .frame(width: 72, height: 72)
                    if recorder.isRecording {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Theme.rec)
                            .frame(width: 26, height: 26)
                    } else {
                        Circle()
                            .fill(Theme.paper)
                            .frame(width: 28, height: 28)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(recorder.isRecording ? "停止記錄" : "開始記錄")

            HStack(spacing: 6) {
                if recorder.isRecording {
                    RecordingDot()
                }
                Text(recorder.isRecording ? "記錄中，可以鎖屏" : "開始記錄")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.paper.opacity(0.86))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
        .padding(.bottom, 10)
        .background(Theme.night)
    }

    private func elapsed(at now: Date, track: Track?) -> TimeInterval {
        guard let track, recorder.isRecording else { return track?.duration ?? 0 }
        return now.timeIntervalSince(track.startedAt)
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

private struct RecordingDot: View {
    @State private var bright = false

    var body: some View {
        Circle()
            .fill(Theme.rec)
            .frame(width: 8, height: 8)
            .opacity(bright ? 1 : 0.35)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    bright = true
                }
            }
    }
}
