# KLSubjectVision API リファレンス

> <span lang="ja">[English](../en/API.md) · [简体中文](../zh-Hans/API.md) · [繁體中文](../zh-Hant/API.md) · [日本語](API.md) · [한국어](../ko/API.md)</span>

この文書では、KLSubjectVision 0.1.0 の公開宣言をすべて説明します。正確なシグネチャとシンボル間の関係については、コンパイラーから生成された Swift-DocC ページを参照してください。

## `SubjectThumbnailRequest`

```swift
public enum SubjectThumbnailRequest: Sendable, Equatable {
    case subject(pixelSize: Int, inset: CGFloat)
    case room(pixelSize: Int)
}
```

正方形キャンバスの寸法と画像の配置方法を表す値型です。

### `.subject(pixelSize:inset:)`

前景を抽出し、抽出結果の縦横比を保ったまま正方形の中央へ収めます。

- `pixelSize` は出力画像の幅と高さです。単位はピクセルです。0 以下を指定すると出力を生成できません。
- `inset` は、切り抜いた画像とキャンバスの各辺との間に確保するピクセル数です。0 以上で、内側に正の大きさの領域が残る値を指定します。

`inset` が適用されるのは切り抜き画像を配置するときだけです。抽出に失敗した場合、抽出器が `nil` を返した場合、または指定した `inset` では画像を配置できない場合は、元画像を余白なしで正方形いっぱいに配置します。そのため、不正な `inset` を指定しても `.fallback` を返せることがあり、必ずしも `nil` にはなりません。

### `.room(pixelSize:)`

前景抽出を行わず、元画像を正方形いっぱいに配置します。正方形からはみ出す部分は、画像の中央を基準に両側から同じように切り取られます。背景色は追加されないため、元画像に透明部分があればそのまま残ります。

## `SubjectThumbnailOutputKind`

```swift
public enum SubjectThumbnailOutputKind: Sendable, Equatable {
    case cutout
    case fallback
    case room
}
```

| 値 | 実際に使われた処理 |
| --- | --- |
| `.cutout` | 差し替えた抽出器または Vision が画像を返し、その画像を正常に配置できた。 |
| `.fallback` | 前景抽出または切り抜き画像の配置に失敗したため、元画像を正方形いっぱいに配置した。 |
| `.room` | 呼び出し側が `.room(pixelSize:)` を指定し、元画像の配置に成功した。 |

この値が示すのは処理経路であり、分割品質や意味的な確信度ではありません。差し替えた抽出器が返した画像は内容を検証されません。配置に成功すれば `.cutout` になります。

## `SubjectThumbnailOutput`

```swift
public struct SubjectThumbnailOutput: @unchecked Sendable {
    public let image: CGImage
    public let kind: SubjectThumbnailOutputKind

    public init(image: CGImage, kind: SubjectThumbnailOutputKind)
}
```

### `image`

合成された画像です。プロセッサーが生成した画像は、指定したピクセル寸法の正方形です。device RGB 色空間と premultiplied-last alpha を使用します。このプロパティは `CGImage` への参照を保持します。

### `kind`

`image` を生成した処理経路です。

### `init(image:kind:)`

渡された画像と処理経路をそのまま保存します。ピクセルはコピーされません。画像が正方形かどうか、また `kind` が画像の生成方法と一致するかどうかも検証されません。

現在の SDK では、`CGImage` 自体が `@unchecked Sendable` に適合しています。`SubjectThumbnailOutput` にも `@unchecked Sendable` を明示していますが、これは当初の公開 API との互換性を保つためです。この宣言は `image` だけでなく、構造体全体に適用されます。2 つの保存プロパティはいずれも変更できません。独自の可変メモリーを画像のデータソースに使う場合は、画像の使用中もそのメモリーを有効に保ち、並行して書き換えないでください。

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

状態を保持しないプロセッサーです。Vision リクエスト、`CIContext`、キャッシュ、共有される可変データは保存しません。処理は同期的に実行されます。

### `ForegroundExtractor`

`process` に渡された元の `CGImage` を受け取り、配置する前景画像または `nil` を返す同期クロージャです。`nil` は元画像へのフォールバックを指示します。

抽出器を渡した呼び出しでは、組み込みの Vision 抽出を一切実行しません。抽出器が `nil` を返しても、その後に Vision を試すことはありません。このクロージャは `@Sendable` ではないため、捕捉する状態に適した隔離コンテキストを組み込み先アプリで選んでください。

### `init()`

状態を持たないプロセッサーを作成します。初期化時に画像処理やフレームワークへの要求は行いません。

### `process(_:request:foregroundExtractor:)`

`.room` ではキャンバスを検証し、元画像を正方形いっぱいに配置します。

`.subject` では、指定されていれば差し替え用の抽出器を使います。指定されていない場合は `VNGenerateForegroundInstanceMaskRequest` を実行します。最初の結果に含まれるすべてのインスタンスを対象に、全体を囲む範囲へ切り詰めたマスク画像を生成します。そのピクセルバッファを Core Image で変換し、指定した余白の内側へ収めます。

Vision リクエストのエラー、結果がない場合、インスタンスが空の場合、マスク画像を生成できない場合、Core Image で変換できない場合は、呼び出し側へエラーを投げません。いずれも抽出失敗として扱い、元画像へのフォールバックを試します。

切り抜き画像と元画像のどちらでもキャンバスを生成できない場合は `nil` を返します。主な原因は次のとおりです。

- 元画像の寸法を利用できない
- `pixelSize <= 0`
- Core Graphics がビットマップコンテキストまたは最終画像を生成できない

`.subject` の `inset` が負数または大きすぎる場合、切り抜き画像は配置できません。ただし、余白なしのフォールバックは成功することがあります。フォールバックできる限り、Vision の失敗だけを理由に `nil` にはなりません。

このメソッドは `source` を同期的に読み取り、呼び出し側から画像の所有権を奪いません。キャンセル確認は内蔵していません。実行のスケジューリング、キャンセル、重複排除、保存、キャッシュは組み込み先アプリが管理します。

## 描画の仕様

- キャンバスは正方形で、device RGB と premultiplied-last alpha を使用
- 補間品質は high
- 画像は中央に配置
- 切り抜き画像は `pixelSize - inset * 2` の領域内に収まるように配置
- `.room` と `.fallback` は正方形全体を埋めるように配置
- はみ出す部分は画像中央を基準に対称に切り取り
