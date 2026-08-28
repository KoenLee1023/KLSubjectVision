# Getting Started

Add KLSubjectVision to an app, choose a thumbnail policy, and handle every processing outcome explicitly.

## Overview

### Add the package

Add the package repository from version `0.1.0` and link the `KLSubjectVision` library product.

```swift
dependencies: [
    .package(
        url: "https://github.com/KoenLee1023/KLSubjectVision.git",
        from: "0.1.0"
    )
]
```

Import the module where a normalized `CGImage` is available.

```swift
import KLSubjectVision
```

KLSubjectVision has no third-party runtime dependencies. The Swift-DocC plugin declared by the package is a documentation build tool and is not linked into an integrating app.

### Choose a request

Use ``SubjectThumbnailRequest/subject(pixelSize:inset:)`` when the thumbnail should isolate foreground instances. Use ``SubjectThumbnailRequest/room(pixelSize:)`` when the complete scene matters.

```swift
let request: SubjectThumbnailRequest = keepsSceneContext
    ? .room(pixelSize: 512)
    : .subject(pixelSize: 512, inset: 24)
```

`pixelSize` is both the output width and height in pixels. A subject inset is measured in output pixels and applies only to successful cutout composition.

### Process the image

Create a ``SubjectThumbnailProcessor`` and call ``SubjectThumbnailProcessor/process(_:request:foregroundExtractor:)``.

```swift
let processor = SubjectThumbnailProcessor()

guard let output = processor.process(sourceImage, request: request) else {
    throw ThumbnailError.couldNotCreateCanvas
}
```

Processing is synchronous and may perform Vision, Core Image, and Core Graphics work. Large images and batches should run in a background execution context managed by the integrating app. The app also owns task priority, cancellation, persistence, and caching.

### Interpret the result

``SubjectThumbnailOutput/kind`` identifies the path that produced ``SubjectThumbnailOutput/image``.

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

``SubjectThumbnailOutputKind/cutout`` means an extracted image was successfully aspect-fitted. ``SubjectThumbnailOutputKind/fallback`` means extraction or cutout composition did not produce an image and the original source was aspect-filled. ``SubjectThumbnailOutputKind/room`` means the caller selected direct scene composition. These values report execution paths, not segmentation confidence.

### Understand fallback and `nil`

A subject request falls back when Vision fails, finds no foreground instances, cannot create the masked image, or cannot compose the extracted image with the requested inset. An injected extractor returning `nil` also selects fallback. Fallback uses the original source with zero inset.

The method returns `nil` only when neither the requested path nor fallback can create a canvas. Common causes are a nonpositive `pixelSize`, unusable source dimensions, or a Core Graphics allocation or finalization failure. An invalid subject inset can reject cutout composition while fallback still succeeds.

### Inject a foreground extractor

Pass a ``SubjectThumbnailProcessor/ForegroundExtractor`` for deterministic tests or another segmentation implementation.

```swift
let output = processor.process(
    sourceImage,
    request: .subject(pixelSize: 256, inset: 16),
    foregroundExtractor: { image in
        customSegmenter.maskedForeground(from: image)
    }
)
```

Supplying an extractor completely replaces built-in Vision extraction for that call. The extractor is synchronous and is not `@Sendable`; invoke `process` in an isolation context that is safe for the state captured by the extractor.

In current SDKs, `CGImage` itself conforms to `@unchecked Sendable`. ``SubjectThumbnailOutput`` retains its own explicit `@unchecked Sendable` declaration for compatibility with the original public API. That declaration applies to the complete output structure. If an image uses custom mutable backing storage, keep that storage valid and do not mutate it concurrently while the image is in use.

### Other languages

- <doc:GettingStarted-zh-Hans>
- <doc:GettingStarted-zh-Hant>
- <doc:GettingStarted-ja>
- <doc:GettingStarted-ko>
