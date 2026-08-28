# KLSubjectVision

> <span lang="ja">[English](../../README.md) · [简体中文](../zh-Hans/README.md) · [繁體中文](../zh-Hant/README.md) · [日本語](../ja/README.md) · [한국어](../ko/README.md)</span>

画像から正方形のサムネイルを生成します。被写体を切り抜けるときは Apple Vision を使い、抽出できない場合は元画像を使った表示へ自動で切り替えます。

KLSubjectVision は、被写体の切り抜きと正方形への配置をまとめた Swift パッケージです。`.subject` は切り抜いた被写体全体を透明な正方形の中に収め、抽出できなかった場合は元画像を正方形いっぱいに配置します。`.room` は、場所や室内写真など、画面全体を残したい画像向けです。

## 概要

- Apple Vision による前景の切り抜き
- 余白を指定できる、被写体全体を収める配置
- 場所写真とフォールバック時は正方形いっぱいに配置
- テスト用の切り抜き処理を差し替え可能
- cutout、fallback、room のどの経路を使ったか結果から確認可能

## 要件

- Swift 6.0 以降
- iOS 17 以降
- macOS 14 以降
- サードパーティ製ランタイムへの依存なし
- Vision · Core Image · Core Graphics

## 導入

Xcode の「Add Package Dependencies」からリポジトリを追加するか、`Package.swift` に次のように記述します。

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

## はじめに

1. アプリとの境界で画像の向きを補正し、`CGImage` に変換します。
2. 人物、動物、商品には `.subject` を、場所、文書、スクリーンショットには `.room` を指定します。
3. 大きな画像や複数画像の処理は、メインアクターの外で実行します。
4. `output.kind` を診断に利用し、エンコード、保存、キャッシュはアプリ側で管理します。

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

## 動作保証

- `SubjectThumbnailRequest`：被写体を切り抜く `.subject(pixelSize:inset:)` と、画像全体を使う `.room(pixelSize:)` を選べます。
- `SubjectThumbnailOutputKind`：処理結果が `.cutout`、`.fallback`、`.room` のどれかを示します。
- `SubjectThumbnailOutput`：プロセッサーが生成した値には、指定したピクセル寸法の正方形 `CGImage` と処理経路が入ります。公開イニシャライザーは画像の寸法を検証しません。
- `SubjectThumbnailProcessor`：共有の可変状態を持たない同期処理です。テストでは `ForegroundExtractor` を差し替えられます。
- `pixelSize` が 0 以下の場合、元画像の寸法を利用できない場合、キャンバスを生成できない場合は `nil` を返します。不正な `inset` では切り抜き画像を配置できませんが、元画像へのフォールバックは成功することがあります。Vision で抽出できない場合も、フォールバックできれば `nil` にはなりません。

## 責務の境界

このパッケージが扱うのは `CGImage` の変換だけです。UIImage または NSImage の読み込み、画像の向きの補正、タスクの実行管理とキャンセル、エンコード、保存先、キャッシュキー、添付ファイルの管理はアプリ側で行ってください。

## ドキュメント

- [はじめに](GettingStarted.md)
- [API リファレンス](API.md)
- [アーキテクチャ](Architecture.md)
- [移行](Migration.md)
- [デモアプリ](../../Examples/Documentation/ja/README.md)
- [コントリビューション](CONTRIBUTING.md)
- [セキュリティポリシー](SECURITY.md)
- [行動規範](CODE_OF_CONDUCT.md)
- [変更履歴](CHANGELOG.md)

## ステータス

現在の API は 1.0 未満です。wondays で実際に使用していますが、安定版にするまでは、マイナーアップデートで名前や設定方法を見直すことがあります。

## ライセンス

MIT. [LICENSE](../../LICENSE)
