import SwiftUI

struct TutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var page = 0

    private let pages = TutorialPage.pages

    var body: some View {
        ZStack {
            Theme.paper.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                        pageView(item)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                footer
            }
        }
        .preferredColorScheme(.light)
    }

    private var topBar: some View {
        HStack {
            Text("\(page + 1) / \(pages.count)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Theme.inkSoft)
            Spacer()
            Button("略過") { dismiss() }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    private func pageView(_ item: TutorialPage) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: item.symbol)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Theme.brass)
                    .frame(width: 56, height: 56)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Theme.line, lineWidth: 1)
                    }
                Text(item.eyebrow)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.brass)
                Text(item.title)
                    .font(.system(size: 32, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(item.body)
                    .font(.body)
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if !item.steps.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(item.steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(Theme.paper)
                                    .frame(width: 24, height: 24)
                                    .background(Theme.ink, in: Circle())
                                Text(step)
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Theme.line, lineWidth: 1)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var footer: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                ForEach(pages.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? Theme.brass : Theme.line)
                        .frame(width: index == page ? 18 : 7, height: 7)
                }
            }
            HStack(spacing: 12) {
                if page > 0 {
                    Button("上一步") { page -= 1 }
                        .buttonStyle(.plain)
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(Theme.ink)
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Theme.line, lineWidth: 1)
                        }
                }
                Button(page == pages.count - 1 ? "開始使用" : "下一步") {
                    if page == pages.count - 1 {
                        dismiss()
                    } else {
                        page += 1
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(Theme.paper)
                .background(Theme.ink, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Theme.paper)
    }
}

private struct TutorialPage {
    var eyebrow: String
    var title: String
    var symbol: String
    var body: String
    var steps: [String]

    static let pages: [TutorialPage] = [
        TutorialPage(
            eyebrow: "開始之前",
            title: "用手機補上相機沒有的位置",
            symbol: "camera",
            body: "沒有 GPS 的相機只會在相片裡留下拍攝時間。這支 App 在你走路時記下路線。回家把 GPX 和相片放在一起，就能把位置寫回去。",
            steps: [
                "對時：量出相機時鐘和手機差幾秒。",
                "記錄：按下開始。鎖屏之後也會繼續記。",
                "軌跡：把 GPX 分享到電腦、用 Finder 拖走，或存進 iCloud。"
            ]
        ),
        TutorialPage(
            eyebrow: "對時",
            title: "相片時間和路線時間要是同一套",
            symbol: "clock",
            body: "相片 EXIF 用的是相機自己的時鐘。GPX 用的是這支手機的時間，手機時間來自網路。差了幾十秒，照片就會落到你還沒走到、或已經走過的地方。正值表示相機比實際時間快。每台相機各自記一份。",
            steps: []
        ),
        TutorialPage(
            eyebrow: "對時",
            title: "最準的做法：拍下對時板",
            symbol: "camera.viewfinder",
            body: "對時板是黑底白字的大時鐘。用相機拍下來，之後可以慢慢對兩個時間，不用在當場搶秒。",
            steps: [
                "打開「對時」，選這台相機。沒有的話先按新增，例如 A7C。",
                "按「打開對時板」。",
                "用相機拍下這個畫面。讓時、分、秒都清楚。",
                "在相機回放，看這張照片顯示的拍攝時間。",
                "回到 App，按「已拍下對時板，事後回填」。",
                "左邊填照片裡的時間，右邊填相機回放的時間，然後儲存。"
            ]
        ),
        TutorialPage(
            eyebrow: "對時",
            title: "看得到相機螢幕，也可以當場對",
            symbol: "clock.arrow.circlepath",
            body: "這種做法快，但要在你讀到相機時間的那一刻凍結手機。拍完才算出來也沒關係，可以再寫進已經錄好的路線。",
            steps: [
                "在「對時」按「看著相機，立刻對時」。",
                "讀到相機時間的那一刻，按「凍結手機時間」。",
                "把日期和時、分、秒調成相機上的數字，然後儲存。",
                "之後可用 −1 分、−1 秒、+1 秒、+1 分修正。",
                "若路線已經錄完，按「把目前時差寫進最近一條軌跡」，或在該軌跡裡按「套用相機時差」。"
            ]
        ),
        TutorialPage(
            eyebrow: "記錄",
            title: "出發前按下開始",
            symbol: "record.circle",
            body: "開始記錄前記得選對相機。右上角可以改多久記一個點。走路拍照建議維持預設：每 5 秒，或移動 10 公尺。",
            steps: [
                "回到「記錄」，確認名稱和時差是這台相機。",
                "按紅色按鈕開始。",
                "定位請允許「永遠」。只允許使用期間的話，鎖屏後路線會停。",
                "「時間或距離」在站著時也會留點，相片比較對得準。",
                "想省電就改成「時間且距離」，把距離調大，精度改成省電。原地拍的照片比較可能對不到點。",
                "拍完再按一次，選「停止並儲存」。"
            ]
        ),
        TutorialPage(
            eyebrow: "軌跡",
            title: "把 GPX 帶走，寫進相片",
            symbol: "square.and.arrow.up",
            body: "停止之後，檔案在「軌跡」裡。兩種時間基準差在要不要先把相機時差算進去。",
            steps: [
                "打開這一天的軌跡。",
                "真實 GPS 時間是手機收到的 UTC。匯入時要另行補正時差。",
                "對齊相機時鐘會把每個點加上時差，時間數字就跟相機 EXIF 一樣。電腦時區請設成拍攝當地。",
                "用「分享」AirDrop 或存到「檔案」、按「存到 iCloud 雲碟」，或用線接上 Mac，在 Finder 側邊欄把 GPX 拖出來。",
                "頁面上的 ExifTool 指令可以直接複製。相機比較快時，真實 GPS 檔的 geosync 是負的。"
            ]
        )
    ]
}
