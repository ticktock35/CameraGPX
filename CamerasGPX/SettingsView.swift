import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppModel.self) private var store
    @Environment(LocationRecorder.self) private var recorder

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    section("時間間隔", "兩次記點至少隔多久。人站著時，就靠這個留下位置。") {
                        chipGrid(RecordingSettings.intervalChoices, selection: store.settings.intervalSeconds) { value in
                            value < 60 ? "\(Int(value)) 秒" : "\(Int(value / 60)) 分"
                        } choose: { value in
                            mutate { $0.intervalSeconds = value }
                        }
                    }

                    section("距離觸發", "移動超過這個距離就記一點。設 0 表示只看時間。") {
                        chipGrid(RecordingSettings.distanceChoices, selection: store.settings.distanceMeters) { value in
                            value <= 0 ? "關閉" : "\(Int(value)) 公尺"
                        } choose: { value in
                            mutate { $0.distanceMeters = value }
                        }
                    }

                    section("什麼時候記", store.settings.trigger.detail) {
                        VStack(spacing: 8) {
                            ForEach(TriggerMode.allCases) { mode in
                                selectRow(title: mode.title, selected: store.settings.trigger == mode) {
                                    mutate { $0.trigger = mode }
                                }
                            }
                        }
                    }

                    section("定位精度", "精度愈粗愈省電，路線也愈粗。真正省電的是「時間且距離」加上較大的距離。") {
                        VStack(spacing: 8) {
                            ForEach(FixQuality.allCases) { quality in
                                selectRow(title: quality.title, subtitle: quality.detail, selected: store.settings.quality == quality) {
                                    mutate { $0.quality = quality }
                                }
                            }
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.paper)
            .navigationTitle("記錄方式")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func mutate(_ change: (inout RecordingSettings) -> Void) {
        var next = store.settings
        change(&next)
        store.updateSettings(next)
        recorder.apply(next)
    }

    private func section<Content: View>(_ title: String, _ footer: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.ink)
            content()
            Text(footer)
                .font(.footnote)
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func chipGrid(
        _ options: [Double],
        selection: Double,
        label: @escaping (Double) -> String,
        choose: @escaping (Double) -> Void
    ) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), spacing: 8)], spacing: 8) {
            ForEach(options, id: \.self) { option in
                let selected = abs(option - selection) < 0.01
                Button {
                    choose(option)
                } label: {
                    Text(label(option))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(selected ? Theme.paper : Theme.ink)
                        .background(selected ? Theme.ink : Theme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay {
                            if !selected {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Theme.line, lineWidth: 1)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func selectRow(title: String, subtitle: String? = nil, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                    if let subtitle {
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundStyle(Theme.inkSoft)
                            .multilineTextAlignment(.leading)
                    }
                }
                Spacer(minLength: 8)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? Theme.brass : Theme.line)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(Theme.ink)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(selected ? Theme.brass : Theme.line, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}
