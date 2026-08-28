# KLSubjectVision 遷移

> <span lang="zh-TW">[English](../../README.md) · [简体中文](../zh-Hans/README.md) · [繁體中文](../zh-Hant/README.md) · [日本語](../ja/README.md) · [한국어](../ko/README.md)</span>

先記錄每種縮圖角色的像素尺寸、裁切方式、透明度、格式、路徑與快取鍵。在單一適配層把產品角色映射至請求。以注入擷取器覆蓋 cutout、fallback、room 三條路徑，並保留原有的取消、去重、儲存與快取編排。確認輸出一致後，再移除原有的幾何方法。

## 檢查清單

- [ ] 在 App 邊界將平台圖片轉為方向已正規化的 `CGImage`。
- [ ] 人物、動物、產品使用 `.subject`。場所、文件與截圖使用 `.room`。
- [ ] 大型圖片或批次處理應離開 main actor。
- [ ] 整合端 App 依 `output.kind` 記錄診斷，並自行決定編碼、儲存與快取。
- [ ] KLSubjectVision 單元測試
- [ ] 整合端 App 回歸測試
- [ ] API 參考 · 變更記錄
