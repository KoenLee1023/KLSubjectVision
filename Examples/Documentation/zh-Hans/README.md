# KLSubjectVision 演示应用

> <span lang="zh-CN">[English](../en/README.md) · [简体中文](../zh-Hans/README.md) · [繁體中文](../zh-Hant/README.md) · [日本語](../ja/README.md) · [한국어](../ko/README.md)</span>

KLSubjectVision 将主体抠图、裁切几何和输出路径封装成值语义 API。`.subject` 尝试提取前景并等比适配到透明画布。失败时原图等比填充。`.room` 始终保留完整场景意图并等比填充。

## Subject Studio

Vision 前景实例蒙版 · 主体等比适配与明确 inset · 房间/回退的居中等比填充

## Thumbnail Matrix

房间/回退的居中等比填充 · 注入提取器以获得确定性测试 · 输出明确报告 cutout、fallback 或 room 路径

两个演示 App 都有独立的 `Package.swift` 和应用入口，仅依赖仓库根目录中的软件包，不会导入 wondays 的代码或资源。

只处理 `CGImage`。不加载 UIImage/NSImage、不负责方向归一化、任务调度、取消、编码、文件路径、缓存键或附件持久化。
