# KLSubjectVision

> <span lang="zh-TW">[English](../../README.md) · [简体中文](../zh-Hans/README.md) · [繁體中文](../zh-Hant/README.md) · [日本語](../ja/README.md) · [한국어](../ko/README.md)</span>

把來源圖片轉為可預期的正方形縮圖：可擷取主體時使用 Apple Vision，否則明確回退。

KLSubjectVision 將主體去背、裁切幾何與輸出路徑封裝成值語意 API。`.subject` 嘗試擷取前景並等比例放入透明畫布。失敗時以原圖等比例填滿。`.room` 一律保留完整場景意圖並等比例填滿。

## 概覽

- Vision 前景實例遮罩
- 主體等比例縮放與明確 inset
- 房間／回退的置中等比例填滿
- 注入擷取器以取得可重現測試
- 輸出明確回報 cutout、fallback 或 room 路徑

## 需求

- Swift 6.0 或更新版本
- iOS 17 或更新版本
- macOS 14 或更新版本
- 不含第三方執行階段相依套件
- Vision · Core Image · Core Graphics

## 安裝

透過 Xcode 的 Add Package Dependencies 加入儲存庫，或在 `Package.swift` 中宣告：

```swift
dependencies: [
    .package(
        url: "https://github.com/KoenLee1023/KLSubjectVision.git",
        from: "0.1.0"
    )
]
```

```swift
import KLSubjectVision
```

## 快速開始

1. 在 App 邊界將平台圖片轉為方向已正規化的 `CGImage`。
2. 人物、動物、產品使用 `.subject`。場所、文件與截圖使用 `.room`。
3. 大型圖片或批次處理應離開 main actor。
4. 整合端 App 依 `output.kind` 記錄診斷，並自行決定編碼、儲存與快取。

```swift
let processor = SubjectThumbnailProcessor()

let output = processor.process(
    sourceImage,
    request: .subject(pixelSize: 512, inset: 28)
)

guard let output else { return }

switch output.kind {
case .cutout:
    print("Vision produced a foreground cutout")
case .fallback:
    print("The original image was aspect-filled")
case .room:
    print("Room treatment was used")
}

display(output.image)
```

```swift
let output = processor.process(
    sourceImage,
    request: .room(pixelSize: 384)
)
```

## 行為保證

- `SubjectThumbnailRequest`：`.subject(pixelSize:inset:)` 或 `.room(pixelSize:)`。
- `SubjectThumbnailOutputKind`：區分 `.cutout`、`.fallback` 與 `.room`。
- `SubjectThumbnailOutput`：處理器產生的值包含指定尺寸的正方形 `CGImage` 與處理路徑。公開初始化器不驗證圖片尺寸。
- `SubjectThumbnailProcessor`：無共享可變狀態並同步處理。可注入 `ForegroundExtractor`。
- 非正 `pixelSize`、無法使用的來源尺寸或畫布建立失敗會回傳 `nil`。無效 `inset` 可能讓主體合成失敗，但仍可得到原圖回退。只要回退成功，Vision 失敗不會回傳 `nil`。

## 職責邊界

只處理 `CGImage`。不載入 UIImage/NSImage、不負責方向正規化、工作排程、取消、編碼、檔案路徑、快取鍵或附件持久化。

## 文件

- [快速開始](GettingStarted.md)
- [API 參考](API.md)
- [架構](Architecture.md)
- [遷移](Migration.md)
- [示範 App](../../Examples/Documentation/zh-Hant/README.md)
- [安全政策](SECURITY.md)
- [行為準則](CODE_OF_CONDUCT.md)
- [變更記錄](CHANGELOG.md)

## 狀態

此 API 目前仍在 1.0 之前。功能已用於 wondays 的真實產品情境，但在宣告穩定前，小版本仍可能調整命名或策略介面。

## 授權

MIT. [LICENSE](../../LICENSE)
