# KLSubjectVision API Reference

This reference documents every public declaration in KLSubjectVision 0.1.0. The compiler-derived Swift-DocC pages remain the authority for exact signatures and symbol relationships.

## `SubjectThumbnailRequest`

```swift
public enum SubjectThumbnailRequest: Sendable, Equatable {
    case subject(pixelSize: Int, inset: CGFloat)
    case room(pixelSize: Int)
}
```

A value-semantic request describing the square canvas and composition policy.

### `.subject(pixelSize:inset:)`

Requests foreground extraction followed by centered aspect-fit composition.

- `pixelSize` is both the output width and height in pixels. A value less than or equal to zero cannot produce an output.
- `inset` reserves pixels at each edge of the cutout canvas. A usable inset is nonnegative and leaves a positive inner square.

The inset applies only to cutout composition. If extraction fails, returns no image, or produces an image that cannot be composed with the requested inset, the processor retries with the original source, aspect fill, and zero inset. An invalid inset can therefore produce a valid `.fallback` instead of `nil`.

### `.room(pixelSize:)`

Skips foreground extraction and aspect-fills the source across the square. Content outside the centered square is cropped symmetrically. Source alpha is preserved because the processor does not add a background color.

## `SubjectThumbnailOutputKind`

```swift
public enum SubjectThumbnailOutputKind: Sendable, Equatable {
    case cutout
    case fallback
    case room
}
```

| Case | Processing path |
| --- | --- |
| `.cutout` | An injected or Vision extractor returned an image, and that image was successfully aspect-fitted. |
| `.fallback` | Extraction or cutout composition did not produce an output, so the original source was aspect-filled. |
| `.room` | The caller selected `.room(pixelSize:)`, and direct aspect-fill composition succeeded. |

The value identifies execution, not segmentation quality or semantic confidence. An injected extractor can return any `CGImage`, and the processor still reports `.cutout` when composition succeeds.

## `SubjectThumbnailOutput`

```swift
public struct SubjectThumbnailOutput: @unchecked Sendable {
    public let image: CGImage
    public let kind: SubjectThumbnailOutputKind

    public init(image: CGImage, kind: SubjectThumbnailOutputKind)
}
```

### `image`

The composed image. Processor-created values are square, use the requested pixel dimensions, and use device RGB with premultiplied-last alpha. The property retains the `CGImage` reference.

### `kind`

The processing path associated with `image`.

### `init(image:kind:)`

Stores the supplied image and kind without validation. It does not copy image pixels, enforce square geometry, or verify that the kind matches the image's origin.

In current SDKs, `CGImage` itself conforms to `@unchecked Sendable`. `SubjectThumbnailOutput` retains its explicit `@unchecked Sendable` declaration for compatibility with the original public API. The declaration applies to the complete structure, not only to `image`. Both stored properties are immutable. Callers creating images from custom mutable backing storage must keep that storage alive and must not mutate it concurrently while the image is in use.

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

The processor is stateless and stores no Vision foreground-mask operation, `CIContext`, cache, or shared mutable state. Processing is synchronous.

### `ForegroundExtractor`

Receives the exact source image passed to `process` and returns an image for cutout composition, or `nil` to request fallback.

Supplying an extractor completely replaces built-in Vision extraction for that call. If the extractor returns `nil`, the processor goes directly to `.fallback`; it does not try Vision afterward. The closure is not `@Sendable`, so the integrating app must choose an isolation context that is safe for captured state.

### `init()`

Creates a stateless processor. Initialization performs no image or framework work.

### `process(_:request:foregroundExtractor:)`

For `.room`, the method validates the canvas and aspect-fills the original source.

For `.subject`, the method uses the injected extractor when present. Otherwise it performs `VNGenerateForegroundInstanceMaskRequest`, takes the first result, includes all detected instances, generates a masked image cropped to their combined extent, converts the pixel buffer through Core Image, and aspect-fits the result inside the requested inset.

The method catches errors from the Vision foreground-mask operation and treats missing results, empty instance sets, masked-image generation errors, and Core Image conversion failures as extraction failure. None of these conditions is thrown to the caller. The processor then attempts the original-image fallback.

The return value is `nil` when no requested or fallback canvas can be created. Common causes are:

- a source image with unusable dimensions
- `pixelSize <= 0`
- failure to allocate or finalize the Core Graphics bitmap

For `.subject`, a negative or oversized inset can reject cutout composition while the zero-inset fallback still succeeds. Vision failure alone does not cause `nil` when fallback composition succeeds.

The method reads `source` synchronously and does not consume the caller's reference. It has no cancellation check. The integrating app owns scheduling, cancellation, deduplication, persistence, and cache policy.

## Rendering geometry

- Canvas: square, device RGB, premultiplied-last alpha
- Interpolation: high quality
- Alignment: centered
- Cutout: aspect fit inside `pixelSize - inset * 2`
- Room and fallback: aspect fill across the full square
- Crop: symmetric around the image center

## Example

```swift
let processor = SubjectThumbnailProcessor()
let output = processor.process(
    source,
    request: .subject(pixelSize: 320, inset: 20),
    foregroundExtractor: { image in
        customSegmenter.maskedForeground(from: image)
    }
)

guard let output else {
    throw ThumbnailError.invalidCanvas
}

if output.kind == .fallback {
    logger.info("Subject extraction unavailable; used source crop")
}
```
