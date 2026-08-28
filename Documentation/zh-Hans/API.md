# KLSubjectVision API 参考

> <span lang="zh-CN">[English](../en/API.md) · [简体中文](API.md) · [繁體中文](../zh-Hant/API.md) · [日本語](../ja/API.md) · [한국어](../ko/API.md)</span>

本文覆盖 KLSubjectVision 0.1.0 的全部公开声明。精确签名和符号关系以编译器生成的 Swift-DocC 页面为准。

## `SubjectThumbnailRequest`

```swift
public enum SubjectThumbnailRequest: Sendable, Equatable {
    case subject(pixelSize: Int, inset: CGFloat)
    case room(pixelSize: Int)
}
```

这个值类型用于描述正方形画布和图像合成方式。

### `.subject(pixelSize:inset:)`

先提取前景，再将提取结果等比缩放并居中放入正方形。

- `pixelSize` 同时表示输出宽度和高度，单位为像素。小于或等于零时无法生成结果。
- `inset` 表示主体图像与画布每条边之间预留的像素数。有效值必须大于或等于零，并且要给内部区域留下正尺寸。

`inset` 只影响主体合成。提取失败、提取器返回 `nil`，或者提取结果无法按指定 `inset` 合成时，处理器会改用原图，以零内边距等比填满画布。正因如此，无效 `inset` 也可能得到有效的 `.fallback`，不一定返回 `nil`。

### `.room(pixelSize:)`

跳过前景提取，让原图居中等比填满正方形。超出正方形的部分会在两侧对称裁掉。处理器不会添加不透明背景，原图已有的透明度会被保留。

## `SubjectThumbnailOutputKind`

```swift
public enum SubjectThumbnailOutputKind: Sendable, Equatable {
    case cutout
    case fallback
    case room
}
```

| 枚举值 | 实际处理路径 |
| --- | --- |
| `.cutout` | 注入的提取器或 Vision 返回了图像，并且该图像已成功等比适配。 |
| `.fallback` | 前景提取或主体合成未生成结果，处理器改用原图等比填满。 |
| `.room` | 调用方选择了 `.room(pixelSize:)`，原图合成成功。 |

这个值只说明走过的处理路径，不表示分割质量或语义置信度。注入提取器可以返回任意 `CGImage`。只要合成成功，结果就是 `.cutout`。

## `SubjectThumbnailOutput`

```swift
public struct SubjectThumbnailOutput: @unchecked Sendable {
    public let image: CGImage
    public let kind: SubjectThumbnailOutputKind

    public init(image: CGImage, kind: SubjectThumbnailOutputKind)
}
```

### `image`

合成后的图像。由处理器生成时，它是指定像素尺寸的正方形，使用 device RGB 色彩空间和 premultiplied-last alpha。该属性会持有 `CGImage` 引用。

### `kind`

与 `image` 对应的处理路径。

### `init(image:kind:)`

直接保存传入的图像与路径标记。初始化器不会复制像素，不检查图像是否为正方形，也不会确认 `kind` 是否与图像来源一致。

在当前 SDK 中，`CGImage` 本身已经遵循 `@unchecked Sendable`。`SubjectThumbnailOutput` 仍显式声明 `@unchecked Sendable`，用于保持原始公开 API 的兼容性。该声明作用于整个结构体，并非只覆盖 `image`。两个存储属性都是不可变的。如果调用方使用自定义可变内存作为图像后备存储，就必须保证这段内存在图像使用期间一直有效，并且不能并发修改。

## `SubjectThumbnailProcessor`

```swift
public struct SubjectThumbnailProcessor: Sendable {
    public typealias ForegroundExtractor = (CGImage) -> CGImage?

    public init()

    public func process(
        _ source: CGImage,
        request: SubjectThumbnailRequest,
        foregroundExtractor: ForegroundExtractor? = nil
    ) -> SubjectThumbnailOutput?
}
```

处理器不保存状态，也不会持有 Vision 请求、`CIContext`、缓存或共享可变数据。所有处理都是同步完成的。

### `ForegroundExtractor`

这个同步闭包接收传给 `process` 的原始 `CGImage`。它应返回用于主体合成的图像，或返回 `nil` 进入回退路径。

只要传入提取器，本次调用就不会使用内置 Vision。即使提取器返回 `nil`，处理器也会直接改用原图，不会再尝试 Vision。闭包没有声明为 `@Sendable`。接入应用需要根据闭包捕获的状态选择安全的隔离环境。

### `init()`

创建一个无状态处理器。初始化过程不会执行图像处理或系统框架请求。

### `process(_:request:foregroundExtractor:)`

处理 `.room` 时，方法验证画布后直接让原图等比填满。

处理 `.subject` 时，方法优先使用注入的提取器。没有提取器时，它会执行 `VNGenerateForegroundInstanceMaskRequest`，读取第一项结果并包含其中检测到的全部实例。随后生成按实例组合范围裁切的蒙版图像，通过 Core Image 转换，再按指定内边距等比适配。

Vision 请求报错、没有结果、实例集合为空、蒙版图像生成失败，以及 Core Image 转换失败都不会抛给调用方。这些情况会被视为提取失败，接着尝试原图回退。

当主体路径和回退路径都无法建立画布时，方法返回 `nil`。常见原因包括：

- 来源图像尺寸不可用
- `pixelSize <= 0`
- Core Graphics 无法分配位图上下文或生成最终图像

对 `.subject` 而言，负数或过大的 `inset` 会阻止主体合成，但仍可能通过零内边距回退得到结果。只要回退成功，Vision 失败本身不会导致 `nil`。

方法同步读取 `source`，不会转移调用方对图像的所有权，也没有内置取消检查。调度、取消、去重、持久化和缓存都由接入应用负责。

## 绘制几何

- 画布为正方形，使用 device RGB 与 premultiplied-last alpha
- 插值质量为 high
- 图像始终居中
- 主体路径在 `pixelSize - inset * 2` 的区域内等比适配
- 房间路径和回退路径让原图等比填满整个正方形
- 超出的内容围绕图像中心对称裁切
