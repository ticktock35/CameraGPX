import SwiftUI

struct QuickSyncSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppModel.self) private var store
    let camera: CameraProfile

    @State private var frozen: Date?
    @State private var day = Date()
    @State private var hour = 0
    @State private var minute = 0
    @State private var second = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("看著相機螢幕。讀到時間的那一刻按下凍結，再把下面調成相機顯示的數字。")
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)

                    if let frozen {
                        Text("手機凍結在 \(Format.clock(frozen))")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                        timeWheels
                        result(cameraTime.timeIntervalSince(frozen))
                        PrimaryButton(title: "儲存時差", systemImage: "checkmark") {
                            store.setOffset(cameraTime.timeIntervalSince(frozen), for: camera.id)
                            Haptic.success()
                            dismiss()
                        }
                    } else {
                        TimelineView(.periodic(from: .now, by: 1)) { context in
                            Text(Format.clock(context.date))
                                .font(.system(size: 56, weight: .medium, design: .rounded))
                                .monospacedDigit()
                                .frame(maxWidth: .infinity)
                        }
                        PrimaryButton(title: "凍結手機時間", systemImage: "pause.circle") {
                            let now = Date()
                            frozen = now
                            day = now
                            let parts = ClockParts.split(now)
                            hour = parts.hour
                            minute = parts.minute
                            second = parts.second
                            Haptic.tap()
                        }
                    }
                }
                .padding(20)
            }
            .background(Theme.paper)
            .navigationTitle(camera.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("關閉") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }

    private var cameraTime: Date {
        ClockParts.date(day: day, hour: hour, minute: minute, second: second)
    }

    private var timeWheels: some View {
        VStack(alignment: .leading, spacing: 8) {
            DatePicker("日期", selection: $day, displayedComponents: .date)
            HStack(spacing: 0) {
                wheel("時", selection: $hour, range: 0..<24)
                wheel("分", selection: $minute, range: 0..<60)
                wheel("秒", selection: $second, range: 0..<60)
            }
            .frame(height: 140)
        }
        .padding(12)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func result(_ seconds: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Format.offset(seconds))
                .font(.headline)
            if abs(seconds) > 86_400 {
                Text("時差超過一天，請確認日期有沒有選錯。")
                    .font(.footnote)
                    .foregroundStyle(Theme.rec)
            }
        }
    }

    private func wheel(_ unit: String, selection: Binding<Int>, range: Range<Int>) -> some View {
        Picker(unit, selection: selection) {
            ForEach(range, id: \.self) { value in
                Text("\(value) \(unit)").tag(value)
            }
        }
        .pickerStyle(.wheel)
    }
}

struct PhotoSyncSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppModel.self) private var store
    let camera: CameraProfile

    @State private var boardDay = Date()
    @State private var boardHour = 0
    @State private var boardMinute = 0
    @State private var boardSecond = 0
    @State private var cameraDay = Date()
    @State private var cameraHour = 0
    @State private var cameraMinute = 0
    @State private var cameraSecond = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("打開相機回放那張對時板。左邊填照片裡的手機時間，右邊填相機寫的拍攝時間。")
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                    clockBlock(
                        title: "照片裡的時間",
                        day: $boardDay,
                        hour: $boardHour,
                        minute: $boardMinute,
                        second: $boardSecond
                    )
                    clockBlock(
                        title: "相機回放的時間",
                        day: $cameraDay,
                        hour: $cameraHour,
                        minute: $cameraMinute,
                        second: $cameraSecond
                    )
                    result(cameraDate.timeIntervalSince(boardDate))
                    PrimaryButton(title: "儲存時差", systemImage: "checkmark") {
                        store.setOffset(cameraDate.timeIntervalSince(boardDate), for: camera.id)
                        Haptic.success()
                        dismiss()
                    }
                }
                .padding(20)
            }
            .background(Theme.paper)
            .navigationTitle("回填對時板")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("關閉") { dismiss() }
                }
            }
            .onAppear {
                let now = Date()
                let parts = ClockParts.split(now)
                boardDay = now
                cameraDay = now
                boardHour = parts.hour
                boardMinute = parts.minute
                boardSecond = parts.second
                cameraHour = parts.hour
                cameraMinute = parts.minute
                cameraSecond = parts.second
            }
        }
        .presentationDetents([.large])
    }

    private var boardDate: Date {
        ClockParts.date(day: boardDay, hour: boardHour, minute: boardMinute, second: boardSecond)
    }

    private var cameraDate: Date {
        ClockParts.date(day: cameraDay, hour: cameraHour, minute: cameraMinute, second: cameraSecond)
    }

    private func result(_ seconds: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Format.offset(seconds))
                .font(.headline)
            if abs(seconds) > 86_400 {
                Text("時差超過一天，請確認兩個日期。")
                    .font(.footnote)
                    .foregroundStyle(Theme.rec)
            }
        }
    }

    private func clockBlock(
        title: String,
        day: Binding<Date>,
        hour: Binding<Int>,
        minute: Binding<Int>,
        second: Binding<Int>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
            DatePicker("日期", selection: day, displayedComponents: .date)
            HStack {
                wheel("時", selection: hour, range: 0..<24)
                wheel("分", selection: minute, range: 0..<60)
                wheel("秒", selection: second, range: 0..<60)
            }
            .frame(height: 120)
        }
        .padding(12)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.line, lineWidth: 1)
        }
    }

    private func wheel(_ unit: String, selection: Binding<Int>, range: Range<Int>) -> some View {
        Picker(unit, selection: selection) {
            ForEach(range, id: \.self) { value in
                Text("\(value)").tag(value)
            }
        }
        .pickerStyle(.wheel)
    }
}
