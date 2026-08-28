# KLSubjectVision 快速開始

> <span lang="zh-TW">[English](../en/GettingStarted.md) · [简体中文](../zh-Hans/GettingStarted.md) · [繁體中文](GettingStarted.md) · [日本語](../ja/GettingStarted.md) · [한국어](../ko/GettingStarted.md)</span>

## 加入套件

在 Xcode 的 Add Package Dependencies 中加入 `https://github.com/KoenLee1023/KLSubjectVision.git`，最低版本選擇 `0.1.0`。也可以在 `Package.swift` 中宣告：

```swift
dependencies: [
    .package(
        url: "https://github.com/KoenLee1023/KLSubjectVision.git",
        from: "0.1.0"
    )
]
```

在需要處理 `CGImage` 的檔案中匯入 `KLSubjectVision`。

## 準備來源圖片

平台圖片的轉換應在 App 邊界完成。如果讀取器尚未處理方向資訊，請先修正方向，再取得 `CGImage`。

```swift
guard let source = uiImage.cgImage else { return }
```

KLSubjectVision 以像素為單位。它不會替整合端 App 解讀 `UIImage.scale`、EXIF 方向、顯示點數或色彩描述檔策略。

## 選擇請求

適合擷取主體時使用 `.subject`。需要保留完整場景時使用 `.room`。

```swift
let request: SubjectThumbnailRequest = isContextualScene
    ? .room(pixelSize: 512)
    : .subject(pixelSize: 512, inset: 24)
```

`.subject` 的 `inset` 以輸出像素為單位，只在主體圖片成功合成時生效。擷取失敗後，處理器會使用原圖零內距回退。場所、室內、文件、螢幕截圖，以及其他不能失去環境資訊的圖片，更適合 `.room`。

## 處理圖片

```swift
let processor = SubjectThumbnailProcessor()

guard let output = processor.process(source, request: request) else {
    throw ThumbnailError.couldNotCreateCanvas
}
```

`process` 是同步方法，可能執行 Vision、Core Image 與 Core Graphics 工作。處理大型圖片或批次工作時，應在整合端 App 管理的背景執行環境內完成圖片解碼與處理，例如專用 actor、`OperationQueue` 或 DispatchQueue。工作優先順序、取消，以及自訂圖片後備儲存空間的生命週期，仍由整合端 App 控制。

## 讀取處理路徑

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

`kind` 只說明實際使用的路徑，不是信心分數。產品若對分割品質有要求，必須另外預覽或驗證。

## 注入前景擷取器

進行可重現測試或接入其他分割引擎時，可以傳入 `ForegroundExtractor`。

```swift
let output = processor.process(
    source,
    request: .subject(pixelSize: 256, inset: 16),
    foregroundExtractor: { image in
        customSegmenter.maskedForeground(from: image)
    }
)
```

注入擷取器會完全取代 Vision。閉包回傳 `nil` 時，處理器會立即使用原圖回退。

## 儲存結果

由整合端 App 依自身格式與持久化策略編碼 `output.image`。套件不會選擇 PNG、HEIF 或 JPEG，也不定義檔案路徑、快取鍵、附件識別與失效規則。

輸出會保留 `CGImage`，但不會複製像素。如果圖片以自訂可變記憶體作為後備儲存空間，App 必須確保該記憶體在圖片使用期間有效，而且不得並行修改。

## 整合檢查

- 建立來源 `CGImage` 前先修正圖片方向
- 為每種介面用途固定像素尺寸策略
- 確認最小尺寸下的 `inset` 仍保留正尺寸的內部區域
- 覆蓋 `.cutout`、`.fallback`、`.room` 與畫布建立失敗
- 將排程、取消、儲存與快取留在整合端 App
- 遷移期間維持既有媒體識別與快取鍵不變
