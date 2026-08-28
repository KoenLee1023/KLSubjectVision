# KLSubjectVision 迁移

> <span lang="zh-CN">[English](../../README.md) · [简体中文](../zh-Hans/README.md) · [繁體中文](../zh-Hant/README.md) · [日本語](../ja/README.md) · [한국어](../ko/README.md)</span>

先记录每种缩略图角色的像素尺寸、裁切方式、透明度、格式、路径和缓存键。在单一适配层把产品角色映射到请求。用注入提取器覆盖 cutout、fallback、room 三条路径，保留原有取消、去重、存储和缓存编排。对齐后再移除本地几何帮助方法。

## 检查清单

- [ ] 在应用边界把平台图片转换为方向已归一化的 `CGImage`。
- [ ] 人物、动物、产品使用 `.subject`。场所、文档和截图使用 `.room`。
- [ ] 大图或批量处理放到主 actor 之外。
- [ ] 由接入应用根据 `output.kind` 记录诊断，并自行决定编码、存储和缓存。
- [ ] KLSubjectVision 单元测试
- [ ] 接入应用回归测试
- [ ] API 参考 · 变更记录
