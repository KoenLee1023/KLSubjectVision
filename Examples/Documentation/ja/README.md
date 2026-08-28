# KLSubjectVision デモアプリ

> <span lang="ja">[English](../en/README.md) · [简体中文](../zh-Hans/README.md) · [繁體中文](../zh-Hant/README.md) · [日本語](../ja/README.md) · [한국어](../ko/README.md)</span>

KLSubjectVision は、被写体の切り抜きと正方形への配置をまとめた Swift パッケージです。`.subject` は切り抜いた被写体全体を透明な正方形の中に収め、抽出できなかった場合は元画像を正方形いっぱいに配置します。`.room` は、場所や室内写真など、画面全体を残したい画像向けです。

## Subject Studio

Apple Vision による前景の切り抜き · 余白を指定できる、被写体全体を収める配置 · 場所写真とフォールバック時は正方形いっぱいに配置

## Thumbnail Matrix

場所写真とフォールバック時は正方形いっぱいに配置 · テスト用の切り抜き処理を差し替え可能 · cutout、fallback、room のどの経路を使ったか結果から確認可能

どちらのデモにも専用の `Package.swift` とアプリのエントリポイントがあります。リポジトリ直下のパッケージだけに依存し、wondays のコードやリソースは読み込みません。

このパッケージが扱うのは `CGImage` の変換だけです。UIImage または NSImage の読み込み、画像の向きの補正、タスクの実行管理とキャンセル、エンコード、保存先、キャッシュキー、添付ファイルの管理はアプリ側で行ってください。
