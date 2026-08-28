# KLSubjectVision 示範 App

> <span lang="zh-TW">[English](../en/README.md) · [简体中文](../zh-Hans/README.md) · [繁體中文](../zh-Hant/README.md) · [日本語](../ja/README.md) · [한국어](../ko/README.md)</span>

KLSubjectVision 將主體去背、裁切幾何與輸出路徑封裝成值語意 API。`.subject` 嘗試擷取前景並等比例放入透明畫布。失敗時以原圖等比例填滿。`.room` 一律保留完整場景意圖並等比例填滿。

## Subject Studio

Vision 前景實例遮罩 · 主體等比例縮放與明確 inset · 房間／回退的置中等比例填滿

## Thumbnail Matrix

房間／回退的置中等比例填滿 · 注入擷取器以取得可重現測試 · 輸出明確回報 cutout、fallback 或 room 路徑

兩個示範 App 都有獨立的 `Package.swift` 與 App 進入點，只依賴儲存庫根目錄中的套件，不會匯入 wondays 的程式碼或資源。

只處理 `CGImage`。不載入 UIImage/NSImage、不負責方向正規化、工作排程、取消、編碼、檔案路徑、快取鍵或附件持久化。
