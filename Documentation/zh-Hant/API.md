# KLSubjectVision API 參考

> <span lang="zh-TW">[English](../en/API.md) · [简体中文](../zh-Hans/API.md) · [繁體中文](API.md) · [日本語](../ja/API.md) · [한국어](../ko/API.md)</span>

本文涵蓋 KLSubjectVision 0.1.0 的所有公開宣告。精確簽章與符號關係以編譯器產生的 Swift-DocC 頁面為準。

## `SubjectThumbnailRequest`

```swift
public enum SubjectThumbnailRequest: Sendable, Equatable {
    case subject(pixelSize: Int, inset: CGFloat)
    case room(pixelSize: Int)
}
```

此值型別描述正方形畫布與圖片合成方式。

### `.subject(pixelSize:inset:)`

先擷取前景，再把擷取結果等比例縮放並置中放入正方形。

- `pixelSize` 同時代表輸出寬度與高度，單位為像素。小於或等於零時無法產生結果。
- `inset` 代表主體圖片與畫布各邊之間預留的像素數。可用的值不得小於零，並且必須保留正尺寸的內部區域。

`inset` 只影響主體合成。擷取失敗、擷取器回傳 `nil`，或擷取結果無法依指定 `inset` 合成時，處理器會改用原圖，以零內距等比例填滿畫布。因此，無效的 `inset` 仍可能得到有效的 `.fallback`，不一定會回傳 `nil`。

### `.room(pixelSize:)`

略過前景擷取，讓原圖置中等比例填滿正方形。超出正方形的部分會由兩側對稱裁切。處理器不會加入不透明背景，原圖既有的透明度會保留。

## `SubjectThumbnailOutputKind`

```swift
public enum SubjectThumbnailOutputKind: Sendable, Equatable {
    case cutout
    case fallback
    case room
}
```

| 列舉值 | 實際處理路徑 |
| --- | --- |
| `.cutout` | 注入的擷取器或 Vision 回傳圖片，而且該圖片已成功等比例縮放。 |
| `.fallback` | 前景擷取或主體合成未產生結果，處理器改用原圖等比例填滿。 |
| `.room` | 呼叫端選擇 `.room(pixelSize:)`，原圖合成成功。 |

此值只表示實際執行的路徑，不代表分割品質或語意信心程度。注入的擷取器可以回傳任何 `CGImage`。只要合成成功，結果就是 `.cutout`。

## `SubjectThumbnailOutput`

```swift
public struct SubjectThumbnailOutput: @unchecked Sendable {
    public let image: CGImage
    public let kind: SubjectThumbnailOutputKind

    public init(image: CGImage, kind: SubjectThumbnailOutputKind)
}
```

### `image`

合成後的圖片。由處理器產生時，它是指定像素尺寸的正方形，使用 device RGB 色彩空間與 premultiplied-last alpha。此屬性會保留 `CGImage` 參照。

### `kind`

與 `image` 對應的處理路徑。

### `init(image:kind:)`

直接保存傳入的圖片與路徑標記。初始化器不會複製像素、不檢查圖片是否為正方形，也不會確認 `kind` 是否符合圖片來源。

在目前的 SDK 中，`CGImage` 本身已遵循 `@unchecked Sendable`。`SubjectThumbnailOutput` 仍明確宣告 `@unchecked Sendable`，以維持原始公開 API 的相容性。此宣告作用於整個結構，而不是只涵蓋 `image`。兩個儲存屬性都不可變。如果呼叫端以自訂可變記憶體作為圖片的後備儲存空間，就必須確保該記憶體在圖片使用期間持續有效，而且不得並行修改。

## `SubjectThumbnailProcessor`

```swift
public struct SubjectThumbnailProcessor: Sendable {
    public typealias ForegroundExtractor = (CGImage) -> CGImage?

    public init()

    public func process(
        _ source: CGImage,
        request: SubjectThumbnailRequest,
        foregroundExtractor: ForegroundExtractor? = nil
    ) -> SubjectThumbnailOutput?
}
```

處理器不保留狀態，也不會持有 Vision 前景遮罩請求、`CIContext`、快取或共享可變資料。所有處理都同步完成。

### `ForegroundExtractor`

此同步閉包會收到傳入 `process` 的原始 `CGImage`。它應回傳用於主體合成的圖片，或回傳 `nil` 進入回退路徑。

只要傳入擷取器，本次呼叫就不會使用內建 Vision。即使擷取器回傳 `nil`，處理器也會直接改用原圖，不會再嘗試 Vision。此閉包沒有宣告為 `@Sendable`。整合端 App 必須依據閉包捕捉的狀態，選擇安全的隔離環境。

### `init()`

建立無狀態的處理器。初始化過程不會執行圖片處理或系統框架請求。

### `process(_:request:foregroundExtractor:)`

處理 `.room` 時，方法驗證畫布後直接讓原圖等比例填滿。

處理 `.subject` 時，方法優先使用注入的擷取器。沒有擷取器時，它會執行 `VNGenerateForegroundInstanceMaskRequest`，讀取第一筆結果並納入其中偵測到的所有實例。接著產生依實例組合範圍裁切的遮罩圖片，透過 Core Image 轉換，再按指定內距等比例縮放。

Vision 前景遮罩請求發生錯誤、沒有結果、實例集合為空、遮罩圖片產生失敗，以及 Core Image 轉換失敗，都不會拋給呼叫端。這些情況會視為擷取失敗，接著嘗試原圖回退。

主體路徑與回退路徑都無法建立畫布時，方法回傳 `nil`。常見原因包括：

- 來源圖片尺寸無法使用
- `pixelSize <= 0`
- Core Graphics 無法建立點陣圖繪圖環境或產生最終圖片

對 `.subject` 而言，負數或過大的 `inset` 會阻止主體合成，但仍可能透過零內距回退得到結果。只要回退成功，Vision 失敗本身不會導致 `nil`。

方法會同步讀取 `source`，不會轉移呼叫端對圖片的所有權，也沒有內建取消檢查。排程、取消、去重、持久化與快取都由整合端 App 負責。

## 繪製幾何

- 畫布為正方形，使用 device RGB 與 premultiplied-last alpha
- 插值品質為 high
- 圖片保持置中
- 主體路徑在 `pixelSize - inset * 2` 的區域內等比例縮放
- 場景路徑與回退路徑讓原圖等比例填滿整個正方形
- 超出的內容以圖片中心為基準對稱裁切
