import SwiftUI

@main
struct CamerasGPXApp: App {
    @State private var store = AppModel()

    init() {
        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = Theme.paperUI
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
    }

    var body: some Scene {
        WindowGroup {
            RootShell(store: store)
        }
    }
}

struct RootShell: View {
    let store: AppModel
    @State private var recorder: LocationRecorder?

    var body: some View {
        ZStack {
            Theme.paper.ignoresSafeArea()
            if let recorder {
                RootTabView()
                    .environment(store)
                    .environment(recorder)
            }
        }
        .preferredColorScheme(.light)
        .tint(Theme.brass)
        .task {
            if recorder == nil {
                recorder = LocationRecorder(store: store)
            }
        }
    }
}

struct RootTabView: View {
    @Environment(AppModel.self) private var store

    var body: some View {
        @Bindable var store = store
        TabView {
            RecordView()
                .tabItem { Label("記錄", systemImage: "record.circle") }
            SyncView()
                .tabItem { Label("對時", systemImage: "clock") }
            LibraryView()
                .tabItem { Label("軌跡", systemImage: "map") }
        }
        .fullScreenCover(isPresented: $store.tutorialPresented, onDismiss: {
            store.dismissIntro()
        }) {
            TutorialView()
        }
        .task {
            if !store.didDismissIntro {
                store.openTutorial()
            }
        }
    }
}
