# KLSubjectVision 快速开始

把 KLSubjectVision 接入应用，选择缩略图策略，并明确处理每一种输出结果。

## 概览

### 添加软件包

添加软件包仓库，最低版本设为 `0.1.0`，并链接 `KLSubjectVision` 库产品。

```swift
dependencies: [
    .package(
        url: "https://github.com/KoenLee1023/KLSubjectVision.git",
        from: "0.1.0"
    )
]
```

在已经取得方向正确的 `CGImage` 的位置导入模块。

```swift
import KLSubjectVision
```

KLSubjectVision 没有第三方运行时依赖。软件包声明的 Swift-DocC 插件只用于构建文档，不会链接进接入应用。

### 选择请求

需要分离前景主体时使用 ``SubjectThumbnailRequest/subject(pixelSize:inset:)``。需要保留场景信息时使用 ``SubjectThumbnailRequest/room(pixelSize:)``。

```swift
let request: SubjectThumbnailRequest = keepsSceneContext
    ? .room(pixelSize: 512)
    : .subject(pixelSize: 512, inset: 24)
```

`pixelSize` 同时表示输出宽度和高度，单位为像素。主体请求的 `inset` 也以输出像素为单位，只在主体图像成功合成时生效。

### 处理图像

创建 ``SubjectThumbnailProcessor``，然后调用 ``SubjectThumbnailProcessor/process(_:request:foregroundExtractor:)``。

```swift
let processor = SubjectThumbnailProcessor()

guard let output = processor.process(sourceImage, request: request) else {
    throw ThumbnailError.couldNotCreateCanvas
}
```

处理过程是同步的，可能执行 Vision、Core Image 和 Core Graphics 工作。大图或批量任务应在接入应用管理的后台执行环境中运行。任务优先级、取消、持久化和缓存也由接入应用负责。

### 读取结果

``SubjectThumbnailOutput/kind`` 表示 ``SubjectThumbnailOutput/image`` 的生成路径。

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

``SubjectThumbnailOutputKind/cutout`` 表示提取图像已成功等比适配。``SubjectThumbnailOutputKind/fallback`` 表示前景提取或主体合成没有生成结果，处理器改用原图等比填满。``SubjectThumbnailOutputKind/room`` 表示调用方选择了直接场景合成。这些值只描述处理路径，不表示分割置信度。

### 理解回退与 `nil`

主体请求在 Vision 执行失败、没有检测到前景实例、无法生成蒙版图像，或无法使用指定 `inset` 合成提取图像时进入回退路径。注入的提取器返回 `nil` 时也会回退。回退使用原图和零内边距。

只有请求路径和回退路径都无法建立画布时，方法才返回 `nil`。常见原因包括 `pixelSize` 不大于零、来源尺寸不可用，或 Core Graphics 无法分配或生成最终图像。无效 `inset` 可以让主体合成失败，但回退仍可能成功。

### 注入前景提取器

需要确定性测试或接入其他分割实现时，传入 ``SubjectThumbnailProcessor/ForegroundExtractor``。

```swift
let output = processor.process(
    sourceImage,
    request: .subject(pixelSize: 256, inset: 16),
    foregroundExtractor: { image in
        customSegmenter.maskedForeground(from: image)
    }
)
```

传入提取器后，本次调用不会再使用内置 Vision。提取器同步执行，并且没有声明为 `@Sendable`。调用 `process` 时，应选择对提取器捕获状态安全的隔离环境。

在当前 SDK 中，`CGImage` 本身已经遵循 `@unchecked Sendable`。``SubjectThumbnailOutput`` 仍显式声明 `@unchecked Sendable`，用于保持原始公开 API 的兼容性。该声明作用于整个输出结构体。如果图像使用自定义可变内存作为后备存储，请保证这段内存在图像使用期间一直有效，并且不要并发修改。

### 其他语言

- <doc:GettingStarted>
- <doc:GettingStarted-zh-Hant>
- <doc:GettingStarted-ja>
- <doc:GettingStarted-ko>
