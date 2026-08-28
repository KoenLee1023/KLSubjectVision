import CoreGraphics
import CoreImage
import Vision

/// A square-thumbnail composition request.
///
/// A request chooses between foreground extraction and direct scene cropping.
/// Both cases express the output width and height in pixels.
public enum SubjectThumbnailRequest: Sendable, Equatable {
    /// Extracts foreground instances and aspect-fits the result inside a transparent square.
    ///
    /// The processor centers a successful extraction in the square, preserving its aspect
    /// ratio and leaving `inset` pixels available at each edge. When extraction or cutout
    /// composition fails, it aspect-fills the original image across the complete square and
    /// reports ``SubjectThumbnailOutputKind/fallback``.
    ///
    /// An inset is usable for cutout composition when it is nonnegative and leaves a positive
    /// inner square. An unusable inset does not prevent the zero-inset fallback path from
    /// succeeding.
    ///
    /// - Parameters:
    ///   - pixelSize: The requested output width and height in pixels. Values less than or
    ///     equal to zero cannot produce an output.
    ///   - inset: The number of pixels reserved between each canvas edge and the fitted
    ///     foreground. The value applies only to a successful cutout composition.
    case subject(pixelSize: Int, inset: CGFloat)

    /// Aspect-fills the complete source image into a square without foreground extraction.
    ///
    /// Content outside the centered square is cropped symmetrically. Existing source alpha is
    /// preserved; the processor does not add an opaque background.
    ///
    /// - Parameter pixelSize: The requested output width and height in pixels. Values less
    ///   than or equal to zero cannot produce an output.
    case room(pixelSize: Int)
}

/// The processing path that produced a thumbnail.
///
/// The value describes execution, not segmentation quality or semantic confidence.
public enum SubjectThumbnailOutputKind: Sendable, Equatable {
    /// A foreground extractor returned an image that was successfully aspect-fitted.
    case cutout

    /// Foreground extraction or cutout composition did not produce an image, so the original
    /// source was aspect-filled instead.
    case fallback

    /// The request explicitly selected direct scene composition with
    /// ``SubjectThumbnailRequest/room(pixelSize:)``.
    case room
}

/// A thumbnail image paired with the processing path that produced it.
///
/// Processor-created values contain a square bitmap with the requested pixel dimensions. The
/// public initializer does not validate geometry and can also represent caller-created images.
///
/// In current SDKs, `CGImage` itself conforms to `@unchecked Sendable`. This type keeps its own
/// explicit `@unchecked Sendable` declaration for compatibility with the original public API.
/// The declaration applies to the complete structure rather than to one stored property. The
/// structure retains the `CGImage` reference and does not copy its pixels. Callers that construct
/// an image from custom mutable backing storage must keep that storage valid and must not mutate
/// it concurrently while the image is in use.
public struct SubjectThumbnailOutput: @unchecked Sendable {
    /// The composed image.
    ///
    /// The property holds a retained `CGImage` reference. Values returned by
    /// ``SubjectThumbnailProcessor/process(_:request:foregroundExtractor:)`` are square and use
    /// premultiplied-last alpha in device RGB. Values made with the public initializer are not
    /// validated or copied.
    public let image: CGImage

    /// The path that produced ``image``.
    public let kind: SubjectThumbnailOutputKind

    /// Creates an output from an existing image and path marker.
    ///
    /// This initializer stores and retains `image` without copying pixels or validating that it
    /// is square. It also does not verify that `kind` matches how the image was created.
    ///
    /// - Parameters:
    ///   - image: The image to retain in the output.
    ///   - kind: The processing-path marker to associate with the image.
    public init(image: CGImage, kind: SubjectThumbnailOutputKind) {
        self.image = image
        self.kind = kind
    }
}

/// Produces square thumbnails with optional foreground extraction.
///
/// The processor is a stateless `Sendable` value. Calls are synchronous and may perform Vision,
/// Core Image, and Core Graphics work. The integrating app chooses the execution context,
/// priority, cancellation policy, persistence, and caching strategy.
public struct SubjectThumbnailProcessor: Sendable {
    /// A synchronous foreground-extraction function.
    ///
    /// The closure receives the exact source `CGImage` passed to ``process(_:request:foregroundExtractor:)``
    /// and returns an image to aspect-fit, or `nil` to request fallback composition. Supplying a
    /// closure completely replaces built-in Vision extraction for that call, even when the
    /// closure returns `nil`.
    ///
    /// The closure is not `@Sendable`. The caller is responsible for invoking `process` in an
    /// isolation context that is safe for any state captured by the closure.
    public typealias ForegroundExtractor = (CGImage) -> CGImage?

    /// Creates a stateless thumbnail processor.
    public init() {}

    /// Produces a square thumbnail from a source image.
    ///
    /// A room request skips extraction and aspect-fills the original source. A subject request
    /// invokes `foregroundExtractor` when supplied. Otherwise it runs
    /// `VNGenerateForegroundInstanceMaskRequest`, combines all instances from the first result,
    /// crops the masked pixel buffer to their combined extent, converts it through Core Image,
    /// and aspect-fits that image using the request inset.
    ///
    /// Vision errors, missing results, empty instance sets, masked-image generation failures,
    /// conversion failures, and unusable cutout geometry are not thrown. They continue through
    /// the original-image fallback path. A supplied extractor returning `nil` also goes directly
    /// to fallback without a Vision attempt.
    ///
    /// - Parameters:
    ///   - source: The source image. The method reads the image synchronously and does not take
    ///     ownership away from the caller.
    ///   - request: The output size and composition policy.
    ///   - foregroundExtractor: An optional synchronous replacement for built-in Vision
    ///     extraction. The default value is `nil`.
    /// - Returns: A square output when the selected or fallback canvas can be created. Returns
    ///   `nil` when the source has unusable dimensions, `pixelSize` is nonpositive, or Core
    ///   Graphics cannot create the required fallback or room bitmap. For a subject request, an
    ///   invalid inset can prevent a cutout but does not prevent a valid zero-inset fallback.
    public func process(
        _ source: CGImage,
        request: SubjectThumbnailRequest,
        foregroundExtractor: ForegroundExtractor? = nil
    ) -> SubjectThumbnailOutput? {
        switch request {
        case let .room(pixelSize):
            return canvas(
                source,
                pixelSize: pixelSize,
                contentMode: .fill,
                inset: 0
            ).map { SubjectThumbnailOutput(image: $0, kind: .room) }

        case let .subject(pixelSize, inset):
            let extracted = foregroundExtractor?(source)
                ?? (foregroundExtractor == nil ? Self.extractForeground(from: source) : nil)

            if let extracted,
               let image = canvas(
                   extracted,
                   pixelSize: pixelSize,
                   contentMode: .fit,
                   inset: inset
               ) {
                return SubjectThumbnailOutput(image: image, kind: .cutout)
            }

            return canvas(
                source,
                pixelSize: pixelSize,
                contentMode: .fill,
                inset: 0
            ).map { SubjectThumbnailOutput(image: $0, kind: .fallback) }
        }
    }

    private enum ContentMode {
        case fit
        case fill
    }

    private func canvas(
        _ image: CGImage,
        pixelSize: Int,
        contentMode: ContentMode,
        inset: CGFloat
    ) -> CGImage? {
        guard image.width > 0,
              image.height > 0,
              pixelSize > 0,
              inset >= 0,
              CGFloat(pixelSize) > inset * 2,
              let context = CGContext(
                  data: nil,
                  width: pixelSize,
                  height: pixelSize,
                  bitsPerComponent: 8,
                  bytesPerRow: 0,
                  space: CGColorSpaceCreateDeviceRGB(),
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else { return nil }

        context.clear(CGRect(x: 0, y: 0, width: pixelSize, height: pixelSize))
        context.interpolationQuality = .high

        let availableSize = CGFloat(pixelSize) - inset * 2
        let widthRatio = availableSize / CGFloat(image.width)
        let heightRatio = availableSize / CGFloat(image.height)
        let scale = contentMode == .fit
            ? min(widthRatio, heightRatio)
            : max(widthRatio, heightRatio)
        let width = CGFloat(image.width) * scale
        let height = CGFloat(image.height) * scale

        context.draw(
            image,
            in: CGRect(
                x: (CGFloat(pixelSize) - width) / 2,
                y: (CGFloat(pixelSize) - height) / 2,
                width: width,
                height: height
            )
        )
        return context.makeImage()
    }

    private static func extractForeground(from image: CGImage) -> CGImage? {
        guard #available(iOS 17.0, macOS 14.0, *) else { return nil }

        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: image)
        do {
            try handler.perform([request])
            guard let result = request.results?.first,
                  !result.allInstances.isEmpty,
                  let buffer = try? result.generateMaskedImage(
                      ofInstances: result.allInstances,
                      from: handler,
                      croppedToInstancesExtent: true
                  ) else { return nil }
            let image = CIImage(cvPixelBuffer: buffer)
            return CIContext().createCGImage(image, from: image.extent)
        } catch {
            return nil
        }
    }
}
