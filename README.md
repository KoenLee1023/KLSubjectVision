# KLSubjectVision

> Language: [English](README.md) · [简体中文](Documentation/zh-Hans/README.md) · [繁體中文](Documentation/zh-Hant/README.md) · [日本語](Documentation/ja/README.md) · [한국어](Documentation/ko/README.md)

API Documentation: [DocC](https://labs.wondays.space/documentation/en/klsubjectvision)

Turn source images into predictable square thumbnails, with an Apple Vision foreground cutout when the image supports it and a deliberate fallback when it does not.

KLSubjectVision is a focused Swift package from Nuancery Labs, extracted from the thumbnail pipeline used by wondays. It combines Vision, Core Image, and Core Graphics behind one value-oriented API while leaving storage, caching, note identity, and product UI to the caller.

## What problem it solves

Thumbnail code often grows into a mix of subject extraction, crop arithmetic, file management, cache policy, and UI state. That makes geometry difficult to test and causes different features to produce subtly different assets.

KLSubjectVision owns only image processing:

- `.subject` tries to isolate the foreground and aspect-fit it inside a transparent square.
- If extraction is unavailable or fails, `.subject` aspect-fills the original image instead.
- `.room` always aspect-fills the original image into a square.
- Every successful result explains which path produced it.

## Requirements

- Swift 6.0 or newer
- iOS 17 or newer
- macOS 14 or newer
- Apple Vision, Core Image, and Core Graphics
- No third-party runtime dependencies

## Installation

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

## Quick start

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

For scenery, interiors, documents, or any image where the whole frame is the subject:

```swift
let output = processor.process(
    sourceImage,
    request: .room(pixelSize: 384)
)
```

## Geometry semantics

`pixelSize` is the width and height of the output bitmap. Values must be greater than zero. A subject `inset` is usable for cutout composition when it is nonnegative and leaves a positive inner square: `pixelSize > inset × 2`. An unusable inset can still produce a valid zero-inset fallback from the original image.

Subject cutouts use aspect fit, so the complete extracted foreground remains visible. Room and fallback outputs use aspect fill, so the square is filled and content outside its bounds is cropped symmetrically.

The canvas uses an RGBA color space and is cleared before drawing. Cutout transparency is retained when supplied by Vision. A room or fallback source can also contain transparency; the package does not add a background color.

## Deterministic testing and alternate extractors

Inject a `ForegroundExtractor` to avoid depending on Vision in a unit test or to connect a different segmentation pipeline:

```swift
let output = processor.process(
    sourceImage,
    request: .subject(pixelSize: 256, inset: 16),
    foregroundExtractor: { _ in fixtureCutout }
)
```

When a custom extractor is supplied and returns `nil`, the processor goes directly to `.fallback`; it does not call Vision as a second attempt.

## Failure behavior

`process` returns `nil` when it cannot create the requested canvas or a fallback canvas, for example because the size is nonpositive, the source dimensions are unusable, or Core Graphics cannot allocate or finalize the bitmap. An invalid subject inset prevents cutout composition but can still produce `.fallback`. Vision extraction failures are not returned as errors; they intentionally continue to fallback.

## Concurrency

The processor is `Sendable` and owns no mutable shared state. Processing is synchronous and can be computationally expensive. Run it away from the main actor for large images or batches. In current SDKs, `CGImage` itself conforms to `@unchecked Sendable`. `SubjectThumbnailOutput` retains its explicit `@unchecked Sendable` declaration for compatibility with the original public API, and that declaration applies to the complete structure. The output retains the image reference without copying pixels, so custom mutable backing storage must remain valid and must not be mutated concurrently.

## Documentation

- [Getting Started](Documentation/en/GettingStarted.md)
- [API Reference](Documentation/en/API.md)
- [Architecture](Documentation/en/Architecture.md)
- [Migration](Documentation/en/Migration.md)
- [Demo Apps](Examples/Documentation/en/README.md)

## Scope

The package does not load `UIImage`/`NSImage`, choose an output file format, write files, manage caches, deduplicate work, schedule tasks, or define product-specific thumbnail categories. Those choices remain at the application boundary.

## Status and license

The implementation is used locally by wondays and is pre-1.0. KLSubjectVision is distributed under the MIT License.
