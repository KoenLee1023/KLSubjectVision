# KLSubjectVision 架构

> <span lang="zh-CN">[English](../../README.md) · [简体中文](../zh-Hans/README.md) · [繁體中文](../zh-Hant/README.md) · [日本語](../ja/README.md) · [한국어](../ko/README.md)</span>

## 概览

输入是 `CGImage` 与明确请求，输出是正方形图像及路径标识。默认主体路径运行 Vision 实例蒙版，裁切到组合范围，经 Core Image 转换后等比适配到清空的 RGBA 画布。注入提取器会完全替代 Vision。失败路径与 room 共用等比填充画布。

## 行为保证

- Vision 前景实例蒙版
- 主体等比适配与明确 inset
- 房间/回退的居中等比填充
- 注入提取器以获得确定性测试
- 输出明确报告 cutout、fallback 或 room 路径

## 职责边界

只处理 `CGImage`。不加载 UIImage/NSImage、不负责方向归一化、任务调度、取消、编码、文件路径、缓存键或附件持久化。

API 只返回计算结果，不会修改接入应用的状态。在输入、配置和系统框架行为一致时，结果保持一致。
