# KLSubjectVision を使い始める

> <span lang="ja">[English](../en/GettingStarted.md) · [简体中文](../zh-Hans/GettingStarted.md) · [繁體中文](../zh-Hant/GettingStarted.md) · [日本語](GettingStarted.md) · [한국어](../ko/GettingStarted.md)</span>

## パッケージを追加する

Xcode の「Add Package Dependencies」で `https://github.com/KoenLee1023/KLSubjectVision.git` を追加し、最小バージョンに `0.1.0` を指定します。`Package.swift` へ直接記述する場合は次のようにします。

```swift
dependencies: [
    .package(
        url: "https://github.com/KoenLee1023/KLSubjectVision.git",
        from: "0.1.0"
    )
]
```

`CGImage` を扱うファイルで `KLSubjectVision` をインポートします。

## 元画像を準備する

プラットフォーム固有の画像型からの変換はアプリ側で行います。読み込み時に向きが補正されていない場合は、補正してから `CGImage` を取得してください。

```swift
guard let source = uiImage.cgImage else { return }
```

KLSubjectVision はピクセル単位で処理します。`UIImage.scale`、EXIF の向き、画面上のポイント数、カラープロファイルの扱いは組み込み先アプリが決定します。

## リクエストを選ぶ

被写体を背景から分離したい画像には `.subject` を、場面全体を残したい画像には `.room` を使います。

```swift
let request: SubjectThumbnailRequest = isContextualScene
    ? .room(pixelSize: 512)
    : .subject(pixelSize: 512, inset: 24)
```

`.subject` の `inset` は出力ピクセル単位です。切り抜き画像を配置できた場合だけ適用されます。抽出に失敗すると、元画像を余白なしで配置します。場所、室内、文書、スクリーンショットなど、周囲の情報を残す必要がある画像には `.room` が適しています。

## 画像を処理する

```swift
let processor = SubjectThumbnailProcessor()

guard let output = processor.process(source, request: request) else {
    throw ThumbnailError.couldNotCreateCanvas
}
```

`process` は同期メソッドです。Vision、Core Image、Core Graphics の処理が行われることがあります。大きな画像や複数の画像を扱う場合は、アプリ側で管理するバックグラウンド実行環境で画像のデコードから処理までを行ってください。専用のアクター、`OperationQueue`、DispatchQueue などを利用できます。タスクの優先度、キャンセル、独自の画像データソースの寿命はアプリ側で管理します。

## 処理経路を確認する

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

`kind` は実際に使われた処理経路を示します。確信度ではありません。製品要件として分割品質の確認が必要な場合は、別の検査やプレビューを用意してください。

## 前景抽出器を差し替える

再現可能なテストを行う場合や別の分割エンジンを使う場合は、`ForegroundExtractor` を渡します。

```swift
let output = processor.process(
    source,
    request: .subject(pixelSize: 256, inset: 16),
    foregroundExtractor: { image in
        customSegmenter.maskedForeground(from: image)
    }
)
```

抽出器を渡すと、その呼び出しでは Vision を使いません。クロージャが `nil` を返した場合は、直ちに元画像へフォールバックします。

## 結果を保存する

`output.image` の画像形式と保存方法は組み込み先アプリで決めます。このパッケージは PNG、HEIF、JPEG の選択、ファイルパス、キャッシュキー、添付ファイルの識別子、無効化規則を定義しません。

出力は `CGImage` への参照を保持しますが、ピクセルはコピーしません。独自の可変メモリーを画像のデータソースに使う場合は、画像の使用中もメモリーを有効に保ち、並行して書き換えないでください。

## 組み込み時の確認項目

- 元の `CGImage` を作る前に画像の向きを補正する
- UI 上の用途ごとにピクセル寸法の方針を決める
- 最小寸法でも `inset` の内側に正の大きさが残ることを確認する
- `.cutout`、`.fallback`、`.room`、キャンバス生成失敗をテストする
- スケジューリング、キャンセル、保存、キャッシュは組み込み先アプリで管理する
- 移行中は既存メディアの識別子とキャッシュキーを維持する
