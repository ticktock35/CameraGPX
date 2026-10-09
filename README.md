# Cameras GPX

給沒有內建 GPS 的相機用的 iPhone 路線記錄器。拍照時用手機留下 GPX，回家再把位置寫進相片。

An iPhone track logger for cameras that have no GPS. Record a GPX on the phone while you shoot, then write those positions into the photos later.

- 需要 iOS 18 或更新版本。Requires iOS 18 or later.
- 套件識別碼 Bundle ID：`app.camerasgpx.ios`
- 用 Xcode 開啟 `CamerasGPX.xcodeproj`。Open `CamerasGPX.xcodeproj` in Xcode.

---

## 繁體中文

### 它解決什麼

沒有 GPS 的相機只會在相片裡留下拍攝時間。這支 App 同時做三件事：

1. 記錄你走路的路線。
2. 量出相機時鐘和手機時間差了幾秒。
3. 把 GPX 分享到電腦、用 Finder 拖走，或存進 iCloud 雲碟。

手機時間來自網路，當作基準。相機 EXIF 的 `DateTimeOriginal` 是相機自己的時鐘，而且通常不帶時區。

### 拍攝當天

第一次打開會出現教學，說明怎麼對時、怎麼記錄、怎麼把 GPX 帶走。之後可以按書本圖示再看一次。記錄、對時、軌跡三頁都有。

1. 在 **對時** 為這台相機建立時差（每台相機各自記一份）。
2. 在 **記錄** 按下紅色按鈕再出發。
3. 定位權限請允許「永遠」，鎖屏或切到其他 App 時路線才不會斷。
4. 拍完再按一次，確認停止。點位會出現在 **軌跡**。

右上角可以改記錄方式：

| 項目 | 預設 | 可以選 |
| --- | --- | --- |
| 時間間隔 | 5 秒 | 1 秒到 2 分鐘 |
| 距離觸發 | 10 公尺 | 關閉、5、10、20、50、100 公尺 |
| 記點條件 | 時間或距離 | 時間且距離 |
| 定位精度 | 平衡（約 10 公尺） | 精準、平衡、省電 |

**時間或距離**：人站著也會依時間留點，相片比較對得準；走得快時，超過距離會提早記一點。

**時間且距離**：兩個條件都達到才記點。距離大於 0 時，系統會等你移動才更新定位，比較省電。原地拍的照片可能對不到點。

精度愈粗愈省電，路線也愈粗。

### 對時

正值表示相機比實際時間快。

- **對時板**：用相機拍下全螢幕時鐘。回放那張照片，把畫面裡的時間和相機顯示的拍攝時間都填回來。
- **立刻對時**：看著相機螢幕，讀到時間的那一刻按下凍結，再把數字調成相機顯示的樣子。
- 也可以用 −1 分、−1 秒、+1 秒、+1 分微調。
- **把目前時差寫進最近一條軌跡**：常常是拍完才回填，用這個把時差補上那條路線。

### 匯出

停止記錄後，App 會把 GPX 寫進這支 App 的文件夾。軌跡頁可以再選時間基準並重新產生。

- **真實 GPS 時間**（檔名結尾 `_gps.gpx`）：手機收到的 UTC。相機若有時差，匯入時要補正。
- **對齊相機時鐘**（檔名結尾 `_camera.gpx`）：每個點都加上相機時差。請把電腦時區設成拍攝當地，時間數字才會和 EXIF 一樣。時差不到半秒時不會另外產生這份。

軌跡頁有三種拿走檔案的方式：

- **分享到電腦或「檔案」**：AirDrop、郵件，或在「檔案」App 裡選一個位置（包含 iCloud 雲碟）。
- **存到 iCloud 雲碟**：寫進 iCloud 裡名為「Cameras GPX」的資料夾。iPhone 要已登入 iCloud，並打開雲碟。
- **Finder**：用線接上 Mac，在 Finder 側邊欄選這支 iPhone，打開 Cameras GPX，把 `.gpx` 拖出來。

軌跡頁會附上可複製的 ExifTool 指令。相機快 1 分 4 秒時，真實 GPS 檔要用負的 geosync，因為要從相機時間扣掉多出來的部分：

```sh
exiftool -geotag "CamerasGPX_20261009_1137_A7C_gps.gpx" -geosync=-0:01:04 DIR
```

對齊相機時鐘的檔案，在電腦時區正確時不用 geosync：

```sh
exiftool -geotag "CamerasGPX_20261009_1137_A7C_camera.gpx" DIR
```

把 `DIR` 換成相片資料夾。超過三分鐘沒有新點時，GPX 會另開一個軌跡段，避免隧道或長時間沒訊號被連成一條直線。

### 在 Xcode 執行

1. 開啟 `CamerasGPX.xcodeproj`。
2. 選好你的 Development Team。專案目前使用自動簽名。
3. 若要在實機使用「存到 iCloud 雲碟」，到 Signing & Capabilities 確認已啟用 iCloud、勾選 iCloud Documents，容器為 `iCloud.app.camerasgpx.ios`。
4. 選一支 iPhone，按 Run。模擬器可以看介面；定位可以在 Xcode 的 Features → Location 模擬。

第一次在實機記錄時，iOS 會先問使用期間的定位，接著再問是否允許永遠定位。

---

## English

### What it does

A camera without GPS stores only the time of each photo. This app does three jobs:

1. Record where you walked.
2. Measure how far the camera clock is from the phone clock.
3. Hand the GPX to a computer, via the share sheet, Finder, or iCloud Drive.

The phone clock, set from the network, is the reference. The camera’s EXIF `DateTimeOriginal` is the camera’s own clock and usually has no time zone.

### On a shoot

The first launch opens a tutorial: how to sync the camera, how to record, and how to take the GPX with you. The book icon on Record, Sync, and Tracks opens it again.

1. On **Sync**, store an offset for this camera. Each camera keeps its own.
2. On **Record**, press the red button, then start walking.
3. Allow location access **Always**, so the track continues on the lock screen and in other apps.
4. Press again and confirm to stop. The track shows up under **Tracks**.

The control at the top right changes how points are saved:

| Setting | Default | Choices |
| --- | --- | --- |
| Time interval | 5 seconds | 1 second to 2 minutes |
| Distance trigger | 10 meters | Off, 5, 10, 20, 50, 100 meters |
| When to save | Time or distance | Time and distance |
| Accuracy | Balanced (about 10 m) | Precise, Balanced, Power saver |

**Time or distance** keeps a point on the timer even while you stand still, which matches photos more reliably. A point is also saved early once you move the chosen distance.

**Time and distance** saves a point only when both conditions are met. With a distance above 0, iOS waits until you move before updating location, which uses less power. Photos taken while standing still can miss a fix.

Coarser accuracy uses less battery and draws a rougher line.

### Syncing the camera clock

A positive offset means the camera is ahead of real time.

- **Sync board**: photograph the full-screen clock. On playback, enter both the time visible in the photo and the capture time shown by the camera.
- **Sync right now**: when you have read the camera display, freeze the phone time, then set the wheels to the numbers on the camera.
- Nudge the stored offset by −1 min, −1 sec, +1 sec, or +1 min.
- **Write this offset into the latest track** if you only compute the difference after the shoot.

### Export

When recording stops, the app writes a GPX into its documents folder. The track screen can rebuild the file with either time base.

- **Real GPS time** (filename ending `_gps.gpx`): UTC from the phone. Apply the camera offset in your geotagging tool.
- **Aligned to the camera clock** (filename ending `_camera.gpx`): every point is shifted by the camera offset. Set the computer’s time zone to the place you shot, and the clock digits match EXIF. This file is skipped when the offset is under half a second.

From a track you can:

- **Share to a computer or Files**: AirDrop, Mail, or a folder you pick in Files, including iCloud Drive.
- **Save to iCloud Drive**: writes into the iCloud folder named Cameras GPX. The iPhone must be signed into iCloud with iCloud Drive on.
- **Finder**: connect the iPhone, select it in the Finder sidebar, open Cameras GPX, and drag the `.gpx` out.

The track screen shows a copyable ExifTool command. If the camera is 1 minute 4 seconds fast, the real-GPS file needs a negative geosync, because that extra time has to be removed from the camera clock:

```sh
exiftool -geotag "CamerasGPX_20261009_1137_A7C_gps.gpx" -geosync=-0:01:04 DIR
```

The camera-aligned file needs no geosync when the computer time zone is the one you shot in:

```sh
exiftool -geotag "CamerasGPX_20261009_1137_A7C_camera.gpx" DIR
```

Replace `DIR` with the photo folder. A gap longer than three minutes starts a new track segment, so a tunnel or a long loss of signal is not drawn as a straight line.

### Run it in Xcode

1. Open `CamerasGPX.xcodeproj`.
2. Select your Development Team. The project uses automatic signing.
3. For **Save to iCloud Drive** on a device, confirm in Signing & Capabilities that iCloud is enabled, iCloud Documents is checked, and the container is `iCloud.app.camerasgpx.ios`.
4. Choose an iPhone and press Run. The simulator is enough to see the interface. Simulate a position from Xcode under Features → Location.

The first time you record on a device, iOS asks for While Using location, then whether the app may use location Always.
