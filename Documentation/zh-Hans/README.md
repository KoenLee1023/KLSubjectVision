# KLSubjectVision

> <span lang="zh-CN">[English](../../README.md) · [简体中文](../zh-Hans/README.md) · [繁體中文](../zh-Hant/README.md) · [日本語](../ja/README.md) · [한국어](../ko/README.md)</span>

将来源图片变成可预测的正方形缩略图：能提取主体时使用 Apple Vision，不能时明确回退。

KLSubjectVision 将主体抠图、裁切几何和输出路径封装成值语义 API。`.subject` 尝试提取前景并等比适配到透明画布。失败时原图等比填充。`.room` 始终保留完整场景意图并等比填充。

## 概览

- Vision 前景实例蒙版
- 主体等比适配与明确 inset
- 房间/回退的居中等比填充
- 注入提取器以获得确定性测试
- 输出明确报告 cutout、fallback 或 room 路径

## 要求

- Swift 6.0 或更高版本
- iOS 17 或更高版本
- macOS 14 或更高版本
- 无第三方运行时依赖
- Vision · Core Image · Core Graphics

## 安装

通过 Xcode 的 Add Package Dependencies 添加仓库，或在 `Package.swift` 中声明：

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

## 快速开始

1. 在应用边界把平台图片转换为方向已归一化的 `CGImage`。
2. 人物、动物、产品使用 `.subject`。场所、文档和截图使用 `.room`。
3. 大图或批量处理放到主 actor 之外。
4. 由接入应用根据 `output.kind` 记录诊断，并自行决定编码、存储和缓存。

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

## 行为保证

- `SubjectThumbnailRequest`：`.subject(pixelSize:inset:)` 或 `.room(pixelSize:)`。
- `SubjectThumbnailOutputKind`：区分 `.cutout`、`.fallback` 与 `.room`。
- `SubjectThumbnailOutput`：处理器生成的值包含请求尺寸的正方形 `CGImage` 与处理路径。公开初始化器不验证图像尺寸。
- `SubjectThumbnailProcessor`：无共享可变状态、同步处理。可注入 `ForegroundExtractor`。
- 非正 `pixelSize`、不可用的来源尺寸或画布创建失败会返回 `nil`。无效 `inset` 可能让主体合成失败，但仍可得到原图回退。Vision 失败只要回退成功就不会返回 `nil`。

## 职责边界

只处理 `CGImage`。不加载 UIImage/NSImage、不负责方向归一化、任务调度、取消、编码、文件路径、缓存键或附件持久化。

## 文档

- [快速开始](GettingStarted.md)
- [API 参考](API.md)
- [架构](Architecture.md)
- [迁移](Migration.md)
- [演示应用](../../Examples/Documentation/zh-Hans/README.md)
- [参与贡献](CONTRIBUTING.md)
- [安全策略](SECURITY.md)
- [行为准则](CODE_OF_CONDUCT.md)
- [变更记录](CHANGELOG.md)

## 状态

该 API 目前处于 1.0 之前。功能已在 wondays 的真实产品场景中使用，但在声明稳定前，小版本仍可能调整命名或策略接口。

## 许可证

MIT. [LICENSE](../../LICENSE)
