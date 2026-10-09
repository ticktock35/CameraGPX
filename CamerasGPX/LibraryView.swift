import SwiftUI

struct LibraryView: View {
    @Environment(AppModel.self) private var store

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.paper.ignoresSafeArea()
                Group {
                    if store.tracks.isEmpty {
                        empty
                    } else {
                        List {
                            ForEach(store.tracks) { track in
                                NavigationLink {
                                    TrackDetailView(trackID: track.id)
                                } label: {
                                    TrackRow(track: track)
                                }
                                .listRowBackground(Theme.card)
                            }
                            .onDelete(perform: delete)
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("軌跡")
            .toolbarBackground(Theme.paper, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.openTutorial()
                    } label: {
                        Image(systemName: "book")
                    }
                    .accessibilityLabel("教學")
                }
            }
        }
    }

    private var empty: some View {
        VStack(spacing: 10) {
            Image(systemName: "map")
                .font(.system(size: 36))
                .foregroundStyle(Theme.brass)
            Text("還沒有路線")
                .font(.system(size: 22, weight: .semibold, design: .serif))
            Text("在「記錄」按下開始。結束後 GPX 會出現在這裡，也能從 Finder 或 iCloud 拿走。")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private func delete(at offsets: IndexSet) {
        let removing = offsets.map { store.tracks[$0] }
        for track in removing {
            store.deleteTrack(track)
        }
    }
}

private struct TrackRow: View {
    let track: Track

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(track.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                if track.isOpen {
                    Text("記錄中")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.rec)
                }
            }
            Text("\(Format.distance(track.distanceMeters)) · \(track.points.count) 點 · \(Format.timer(track.duration))")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSoft)
                .monospacedDigit()
            HStack(spacing: 8) {
                if let cameraName = track.cameraName {
                    Text(cameraName)
                }
                Text(Format.offsetCompact(track.offsetSeconds))
                if track.wasRecovered {
                    Text("已恢復")
                }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Theme.brass)
        }
        .padding(.vertical, 6)
    }
}
