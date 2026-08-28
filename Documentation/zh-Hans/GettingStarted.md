# KLSubjectVision 快速开始

> <span lang="zh-CN">[English](../en/GettingStarted.md) · [简体中文](GettingStarted.md) · [繁體中文](../zh-Hant/GettingStarted.md) · [日本語](../ja/GettingStarted.md) · [한국어](../ko/GettingStarted.md)</span>

## 添加软件包

在 Xcode 的 Add Package Dependencies 中添加 `https://github.com/KoenLee1023/KLSubjectVision.git`，最低版本选择 `0.1.0`。也可以在 `Package.swift` 中声明：

```swift
dependencies: [
    .package(
        url: "https://github.com/KoenLee1023/KLSubjectVision.git",
        from: "0.1.0"
    )
]
```

在需要处理 `CGImage` 的文件中导入 `KLSubjectVision`。

## 准备来源图像

平台图像的转换放在应用边界完成。如果读取器尚未处理方向信息，请先校正方向，再取得 `CGImage`。

```swift
guard let source = uiImage.cgImage else { return }
```

KLSubjectVision 按像素工作。它不会替接入应用解释 `UIImage.scale`、EXIF 方向、显示点数或色彩配置策略。

## 选择请求

适合抠出主体时使用 `.subject`。需要保留完整场景时使用 `.room`。

```swift
let request: SubjectThumbnailRequest = isContextualScene
    ? .room(pixelSize: 512)
    : .subject(pixelSize: 512, inset: 24)
```

`.subject` 的 `inset` 以输出像素为单位，只在主体图像成功合成时生效。提取失败后，处理器会用原图零内边距回退。场所、室内、文档、截图以及其他不能丢失环境信息的图像更适合 `.room`。

## 处理图像

```swift
let processor = SubjectThumbnailProcessor()

guard let output = processor.process(source, request: request) else {
    throw ThumbnailError.couldNotCreateCanvas
}
```

`process` 是同步方法，可能执行 Vision、Core Image 和 Core Graphics 工作。处理大图或批量任务时，应在接入应用管理的后台执行环境中完成图像解码与处理，例如专用 actor、`OperationQueue` 或调度队列。任务优先级、取消以及自定义图像后备存储的生命周期仍由接入应用控制。

## 读取处理路径

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

`kind` 只说明实际使用的路径，不是置信度。产品如果对分割质量有要求，需要另行预览或校验。

## 注入前景提取器

确定性测试或接入其他分割引擎时，可以传入 `ForegroundExtractor`。

```swift
let output = processor.process(
    source,
    request: .subject(pixelSize: 256, inset: 16),
    foregroundExtractor: { image in
        customSegmenter.maskedForeground(from: image)
    }
)
```

注入提取器会完全替代 Vision。闭包返回 `nil` 时直接使用原图回退。

## 保存结果

由接入应用按照自己的格式和持久化策略编码 `output.image`。软件包不会选择 PNG、HEIF 或 JPEG，也不定义文件路径、缓存键、附件身份和失效规则。

输出会持有 `CGImage`，但不会复制像素。如果图像使用自定义可变内存作为后备存储，应用必须保证这段内存在图像使用期间有效，并且不能并发修改。

## 集成检查

- 创建来源 `CGImage` 前先校正图像方向
- 为每种界面用途固定像素尺寸策略
- 确认最小尺寸下的 `inset` 仍能留下正尺寸内部区域
- 覆盖 `.cutout`、`.fallback`、`.room` 和画布创建失败
- 把调度、取消、存储和缓存留在接入应用
- 迁移期间保持已有媒体身份和缓存键不变
