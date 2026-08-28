# Getting Started with KLSubjectVision

## Add the package

Add `https://github.com/KoenLee1023/KLSubjectVision.git` from version `0.1.0`, link the `KLSubjectVision` product, and import the module where a `CGImage` is available.

```swift
dependencies: [
    .package(
        url: "https://github.com/KoenLee1023/KLSubjectVision.git",
        from: "0.1.0"
    )
]
```

## Prepare the source image

Convert platform images at the application boundary. Normalize orientation before processing when the loader has not already done so.

```swift
guard let source = uiImage.cgImage else { return }
```

KLSubjectVision works in pixels. It does not interpret `UIImage.scale`, EXIF orientation, display points, or color-profile policy for the integrating app.

## Choose a request

Use `.subject` when foreground isolation is appropriate. Use `.room` when the complete scene carries meaning.

```swift
let request: SubjectThumbnailRequest = isContextualScene
    ? .room(pixelSize: 512)
    : .subject(pixelSize: 512, inset: 24)
```

For `.subject`, `inset` is measured in output pixels and applies only when a cutout is composed. Extraction failure uses the original image with zero inset. Use `.room` for places, interiors, documents, screenshots, or other images where foreground extraction would remove useful context.

## Process the image

```swift
let processor = SubjectThumbnailProcessor()

guard let output = processor.process(source, request: request) else {
    throw ThumbnailError.couldNotCreateCanvas
}
```

The method is synchronous and may run Vision, Core Image, and Core Graphics work. For large images or batches, decode and process the image in a background execution context managed by the integrating app, such as a dedicated actor, `OperationQueue`, or dispatch queue. The integrating app remains responsible for task priority, cancellation, and the lifetime of any custom image backing storage.

## Handle the processing path

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

`kind` reports which path ran. It is not a confidence score. Review segmentation quality separately if the product requires it.

## Inject an extractor

Use `ForegroundExtractor` for deterministic tests or another segmentation engine.

```swift
let output = processor.process(
    source,
    request: .subject(pixelSize: 256, inset: 16),
    foregroundExtractor: { image in
        customSegmenter.maskedForeground(from: image)
    }
)
```

An injected extractor replaces Vision completely. Returning `nil` selects the original-image fallback immediately.

## Store the result

Encode `output.image` using the integrating app's format and persistence policy. The package does not select PNG, HEIF, or JPEG, and it does not define paths, cache keys, attachment identity, or invalidation rules.

The output retains its `CGImage` without copying pixels. If the integrating app creates images from custom mutable backing storage, that storage must remain valid and must not be mutated concurrently.

## Integration checklist

- Normalize image orientation before creating the source `CGImage`.
- Use one pixel-size policy for each UI role.
- Verify the smallest subject inset leaves a positive inner square.
- Exercise `.cutout`, `.fallback`, `.room`, and allocation failure paths.
- Keep scheduling, cancellation, storage, and caching in the integrating app.
- Preserve existing media identity and cache keys during migration.
