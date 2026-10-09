import SwiftUI

struct SyncView: View {
    @Environment(AppModel.self) private var store
    @State private var showBoard = false
    @State private var showQuick = false
    @State private var showPhoto = false
    @State private var adding = false
    @State private var renaming = false
    @State private var newName = ""
    @State private var appliedNote = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.paper.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        cameras
                        if let camera = store.selectedCamera {
                            offsetCard(camera)
                        }
                        PrimaryButton(title: "打開對時板", systemImage: "camera.viewfinder") {
                            showBoard = true
                        }
                        PrimaryButton(title: "看著相機，立刻對時", systemImage: "clock.arrow.circlepath", filled: false) {
                            showQuick = true
                        }
                        PrimaryButton(title: "已拍下對時板，事後回填", systemImage: "photo", filled: false) {
                            showPhoto = true
                        }
                        if store.tracks.contains(where: { !$0.isOpen }) {
                            Button {
                                store.applySelectedOffsetToLatestTrack()
                                appliedNote = true
                            } label: {
                                Text("把目前時差寫進最近一條軌跡")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Theme.brass)
                            }
                            .buttonStyle(.plain)
                        }
                        if appliedNote {
                            Text("已寫進最近一條軌跡。匯出時可選「對齊相機時鐘」。")
                                .font(.footnote)
                                .foregroundStyle(Theme.inkSoft)
                        }
                        how
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $showBoard) {
                SyncBoard()
            }
            .sheet(isPresented: $showQuick) {
                if let camera = store.selectedCamera {
                    QuickSyncSheet(camera: camera)
                }
            }
            .sheet(isPresented: $showPhoto) {
                if let camera = store.selectedCamera {
                    PhotoSyncSheet(camera: camera)
                }
            }
            .alert("新增相機", isPresented: $adding) {
                TextField("例如 Sony A7C", text: $newName)
                Button("加入") {
                    store.addCamera(named: newName)
                    newName = ""
                }
                Button("取消", role: .cancel) { newName = "" }
            } message: {
                Text("每台相機各自記時差。")
            }
            .alert("重新命名", isPresented: $renaming) {
                TextField("名稱", text: $newName)
                Button("儲存") {
                    if let camera = store.selectedCamera {
                        store.rename(camera, to: newName)
                    }
                    newName = ""
                }
                Button("取消", role: .cancel) { newName = "" }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center) {
                Text("對時")
                    .font(.system(size: 34, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
                Spacer()
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
            }
            Text("相片記的是相機時間，路線記的是手機時間")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
    }

    private var cameras: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("相機")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Button("新增") { adding = true }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.brass)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(store.cameras) { camera in
                        let selected = camera.id == store.selectedCamera?.id
                        Button {
                            store.select(camera)
                        } label: {
                            Text(camera.name)
                                .font(.system(size: 14, weight: .semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .foregroundStyle(selected ? Theme.paper : Theme.ink)
                                .background(selected ? Theme.ink : Theme.card, in: Capsule())
                                .overlay {
                                    if !selected {
                                        Capsule().stroke(Theme.line, lineWidth: 1)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func offsetCard(_ camera: CameraProfile) -> some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(Format.offset(camera.offsetSeconds))
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let syncedAt = camera.syncedAt {
                    Text("上次對時 \(Format.listTitle(syncedAt))")
                        .font(.footnote)
                        .foregroundStyle(Theme.inkSoft)
                } else {
                    Text("還沒對過。正值表示相機比實際時間快。")
                        .font(.footnote)
                        .foregroundStyle(Theme.inkSoft)
                }
                HStack(spacing: 8) {
                    adjust("−1 分", delta: -60, camera: camera)
                    adjust("−1 秒", delta: -1, camera: camera)
                    adjust("+1 秒", delta: 1, camera: camera)
                    adjust("+1 分", delta: 60, camera: camera)
                }
                HStack {
                    Button("改名") {
                        newName = camera.name
                        renaming = true
                    }
                    .foregroundStyle(Theme.inkSoft)
                    Spacer()
                    if store.cameras.count > 1 {
                        Button("刪除這台相機") {
                            store.delete(camera)
                        }
                        .foregroundStyle(Theme.rec)
                    }
                }
                .font(.subheadline.weight(.semibold))
            }
        }
    }

    private func adjust(_ title: String, delta: Double, camera: CameraProfile) -> some View {
        Button(title) {
            store.adjustOffset(by: delta, for: camera.id)
        }
        .font(.system(size: 13, weight: .semibold, design: .rounded))
        .monospacedDigit()
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .foregroundStyle(Theme.ink)
        .background(Theme.paper, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .buttonStyle(.plain)
    }

    private var how: some View {
        Button {
            store.openTutorial()
        } label: {
            PaperCard {
                HStack(spacing: 12) {
                    Image(systemName: "book")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.brass)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("看完整教學")
                            .font(.system(size: 15, weight: .semibold))
                        Text("對時板、當場對時，以及怎麼把 GPX 寫進相片。")
                            .font(.subheadline)
                            .foregroundStyle(Theme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(Theme.ink)
    }
}

struct SyncBoard: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(LocationRecorder.self) private var recorder
    @State private var previousBrightness = UIScreen.main.brightness

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 18) {
                Spacer()
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    VStack(spacing: 10) {
                        Text(Format.day(context.date))
                            .font(.system(size: 20, weight: .medium, design: .serif))
                            .foregroundStyle(.white.opacity(0.72))
                        Text(Format.clock(context.date))
                            .font(.system(size: 76, weight: .medium, design: .rounded))
                            .monospacedDigit()
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .foregroundStyle(.white)
                        Text(Format.zoneLabel(context.date))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white.opacity(0.62))
                    }
                    .padding(.horizontal, 24)
                }
                Spacer()
                Text("用相機拍下這個畫面")
                    .font(.system(size: 17, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)
                Text("回放時，把畫面時間和相機時間填回 App")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
                Button("關閉") { dismiss() }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(.white, in: Capsule())
                    .padding(.bottom, 12)
            }
        }
        .preferredColorScheme(.dark)
        .persistentSystemOverlays(.hidden)
        .onAppear {
            previousBrightness = UIScreen.main.brightness
            UIScreen.main.brightness = 1
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIScreen.main.brightness = previousBrightness
            if !recorder.isRecording {
                UIApplication.shared.isIdleTimerDisabled = false
            }
        }
    }
}
