# KLSubjectVision 快速開始

將 KLSubjectVision 整合至 App，選擇縮圖策略，並明確處理每一種輸出結果。

## 概覽

### 加入套件

加入套件儲存庫，最低版本設為 `0.1.0`，並連結 `KLSubjectVision` 函式庫產品。

```swift
dependencies: [
    .package(
        url: "https://github.com/KoenLee1023/KLSubjectVision.git",
        from: "0.1.0"
    )
]
```

在已取得方向正確的 `CGImage` 之處匯入模組。

```swift
import KLSubjectVision
```

KLSubjectVision 不含第三方執行階段相依套件。套件宣告的 Swift-DocC 外掛程式只用於建立文件，不會連結至整合端 App。

### 選擇請求

需要擷取前景主體時，使用 ``SubjectThumbnailRequest/subject(pixelSize:inset:)``。需要保留場景資訊時，使用 ``SubjectThumbnailRequest/room(pixelSize:)``。

```swift
let request: SubjectThumbnailRequest = keepsSceneContext
    ? .room(pixelSize: 512)
    : .subject(pixelSize: 512, inset: 24)
```

`pixelSize` 同時代表輸出寬度與高度，單位為像素。主體請求的 `inset` 也以輸出像素為單位，只在主體圖片成功合成時生效。

### 處理圖片

建立 ``SubjectThumbnailProcessor``，再呼叫 ``SubjectThumbnailProcessor/process(_:request:foregroundExtractor:)``。

```swift
let processor = SubjectThumbnailProcessor()

guard let output = processor.process(sourceImage, request: request) else {
    throw ThumbnailError.couldNotCreateCanvas
}
```

處理過程為同步執行，可能使用 Vision、Core Image 與 Core Graphics。大型圖片或批次工作應放在整合端 App 管理的背景執行環境。工作優先順序、取消、持久化與快取也由整合端 App 負責。

### 讀取結果

``SubjectThumbnailOutput/kind`` 表示 ``SubjectThumbnailOutput/image`` 的產生路徑。

```swift
switch output.kind {
case .cutout:
    present(output.image)
case .fallback:
    present(output.image)
case .room:
    present(output.image)
}
```

``SubjectThumbnailOutputKind/cutout`` 表示擷取圖片已成功等比例縮放。``SubjectThumbnailOutputKind/fallback`` 表示前景擷取或主體合成沒有產生結果，處理器改用原圖等比例填滿。``SubjectThumbnailOutputKind/room`` 表示呼叫端選擇直接合成場景。這些值只描述處理路徑，不表示分割信心程度。

### 理解回退與 `nil`

主體請求在 Vision 執行失敗、沒有偵測到前景實例、無法產生遮罩圖片，或無法依指定 `inset` 合成擷取圖片時進入回退路徑。注入的擷取器回傳 `nil` 時也會回退。回退使用原圖與零內距。

只有請求路徑與回退路徑都無法建立畫布時，方法才會回傳 `nil`。常見原因包括 `pixelSize` 不大於零、來源尺寸無法使用，或 Core Graphics 無法配置資源或產生最終圖片。無效的 `inset` 可能使主體合成失敗，但回退仍可能成功。

### 注入前景擷取器

需要可重現測試或整合其他分割實作時，傳入 ``SubjectThumbnailProcessor/ForegroundExtractor``。

```swift
let output = processor.process(
    sourceImage,
    request: .subject(pixelSize: 256, inset: 16),
    foregroundExtractor: { image in
        customSegmenter.maskedForeground(from: image)
    }
)
```

傳入擷取器後，本次呼叫不會再使用內建 Vision。擷取器同步執行，而且沒有宣告為 `@Sendable`。呼叫 `process` 時，應選擇對擷取器捕捉狀態安全的隔離環境。

在目前的 SDK 中，`CGImage` 本身已遵循 `@unchecked Sendable`。``SubjectThumbnailOutput`` 仍明確宣告 `@unchecked Sendable`，以維持原始公開 API 的相容性。此宣告作用於整個輸出結構。如果圖片以自訂可變記憶體作為後備儲存空間，請確保該記憶體在圖片使用期間持續有效，而且不要並行修改。

### 其他語言

- <doc:GettingStarted>
- <doc:GettingStarted-zh-Hans>
- <doc:GettingStarted-ja>
- <doc:GettingStarted-ko>
