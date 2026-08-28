# KLSubjectVision を使い始める

KLSubjectVision をアプリへ追加し、サムネイルの生成方法と各出力結果の扱いを設定します。

## 概要

### パッケージを追加する

パッケージのリポジトリを追加し、最小バージョンに `0.1.0` を指定して `KLSubjectVision` ライブラリ製品をリンクします。

```swift
dependencies: [
    .package(
        url: "https://github.com/KoenLee1023/KLSubjectVision.git",
        from: "0.1.0"
    )
]
```

向きが補正された `CGImage` を扱うファイルでモジュールをインポートします。

```swift
import KLSubjectVision
```

KLSubjectVision は、実行時にサードパーティ製ライブラリへ依存しません。パッケージで宣言している Swift-DocC プラグインはドキュメントの生成にだけ使われ、組み込み先アプリにはリンクされません。

### リクエストを選ぶ

前景の被写体を切り抜く場合は ``SubjectThumbnailRequest/subject(pixelSize:inset:)`` を使います。場面全体を残す場合は ``SubjectThumbnailRequest/room(pixelSize:)`` を使います。

```swift
let request: SubjectThumbnailRequest = keepsSceneContext
    ? .room(pixelSize: 512)
    : .subject(pixelSize: 512, inset: 24)
```

`pixelSize` は出力画像の幅と高さです。単位はピクセルです。`.subject` の `inset` も出力ピクセル単位で、切り抜き画像を正常に配置できた場合だけ適用されます。

### 画像を処理する

``SubjectThumbnailProcessor`` を作成し、``SubjectThumbnailProcessor/process(_:request:foregroundExtractor:)`` を呼び出します。

```swift
let processor = SubjectThumbnailProcessor()

guard let output = processor.process(sourceImage, request: request) else {
    throw ThumbnailError.couldNotCreateCanvas
}
```

処理は同期的に実行され、Vision、Core Image、Core Graphics を使用することがあります。大きな画像や複数の画像は、組み込み先アプリが管理するバックグラウンド実行環境で処理してください。タスクの優先度、キャンセル、保存、キャッシュもアプリ側で管理します。

### 結果を確認する

``SubjectThumbnailOutput/kind`` は、``SubjectThumbnailOutput/image`` を生成した処理経路を示します。

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

``SubjectThumbnailOutputKind/cutout`` は、抽出画像を正常に配置できたことを示します。``SubjectThumbnailOutputKind/fallback`` は、前景抽出または切り抜き画像の配置に失敗し、元画像を正方形いっぱいに配置したことを示します。``SubjectThumbnailOutputKind/room`` は、呼び出し側が場面全体の配置を選んだことを示します。いずれも処理経路を表す値であり、分割品質の確信度ではありません。

### フォールバックと `nil`

Vision の実行に失敗した場合、前景が見つからない場合、マスク画像を生成できない場合、指定した `inset` では抽出画像を配置できない場合は、元画像へフォールバックします。差し替えた抽出器が `nil` を返した場合も同じです。フォールバックでは余白を設けません。

指定した方法とフォールバックのどちらでもキャンバスを生成できない場合に限り、メソッドは `nil` を返します。主な原因は、`pixelSize` が 0 以下、元画像の寸法を利用できない、Core Graphics が必要な領域または最終画像を生成できないことです。不正な `inset` で切り抜き画像を配置できなくても、フォールバックは成功する場合があります。

### 前景抽出器を差し替える

再現可能なテストを行う場合や別の分割処理を組み込む場合は、``SubjectThumbnailProcessor/ForegroundExtractor`` を渡します。

```swift
let output = processor.process(
    sourceImage,
    request: .subject(pixelSize: 256, inset: 16),
    foregroundExtractor: { image in
        customSegmenter.maskedForeground(from: image)
    }
)
```

抽出器を渡すと、その呼び出しでは組み込みの Vision 抽出を行いません。抽出器は同期的に実行され、`@Sendable` ではありません。抽出器が参照する状態を安全に扱える隔離コンテキストで `process` を呼び出してください。

現在の SDK では、`CGImage` 自体が `@unchecked Sendable` に適合しています。``SubjectThumbnailOutput`` にも、当初の公開 API との互換性を保つため `@unchecked Sendable` を明示しています。この宣言は出力構造体全体に適用されます。独自の可変メモリーを画像のデータソースに使う場合は、画像の使用中もそのメモリーを有効に保ち、並行して書き換えないでください。

### その他の言語

- <doc:GettingStarted>
- <doc:GettingStarted-zh-Hans>
- <doc:GettingStarted-zh-Hant>
- <doc:GettingStarted-ko>
