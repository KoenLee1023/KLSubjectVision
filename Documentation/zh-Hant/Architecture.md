# KLSubjectVision 架構

> <span lang="zh-TW">[English](../../README.md) · [简体中文](../zh-Hans/README.md) · [繁體中文](../zh-Hant/README.md) · [日本語](../ja/README.md) · [한국어](../ko/README.md)</span>

## 概覽

輸入為 `CGImage` 與明確請求，輸出為正方形圖片及路徑識別。預設主體路徑執行 Vision 實例遮罩，裁切至合併範圍，經 Core Image 轉換後等比例放入已清空的 RGBA 畫布。注入擷取器會完全取代 Vision。失敗路徑與 room 共用等比例填滿畫布。

## 行為保證

- Vision 前景實例遮罩
- 主體等比例縮放與明確 inset
- 房間／回退的置中等比例填滿
- 注入擷取器以取得可重現測試
- 輸出明確回報 cutout、fallback 或 room 路徑

## 職責邊界

只處理 `CGImage`。不載入 UIImage/NSImage、不負責方向正規化、工作排程、取消、編碼、檔案路徑、快取鍵或附件持久化。

API 只回傳計算結果，不會修改整合端 App 的狀態。輸入、設定與系統框架行為相同時，結果也會保持一致。
