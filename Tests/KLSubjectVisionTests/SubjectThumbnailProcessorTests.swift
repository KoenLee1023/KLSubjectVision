import CoreGraphics
import Testing
@testable import KLSubjectVision

@Suite("Subject thumbnail processor")
struct SubjectThumbnailProcessorTests {
    @Test("A failed extraction falls back to an aspect-fill square")
    func extractionFailureFallsBack() throws {
        let source = try #require(makeImage(width: 800, height: 400))
        let output = try #require(
            SubjectThumbnailProcessor().process(
                source,
                request: .subject(pixelSize: 250, inset: 6),
                foregroundExtractor: { _ in nil }
            )
        )

        #expect(output.kind == .fallback)
        #expect(output.image.width == 250)
        #expect(output.image.height == 250)
    }

    @Test("A room thumbnail is an exact aspect-fill square")
    func roomOutputUsesRequestedSize() throws {
        let source = try #require(makeImage(width: 400, height: 800))
        let output = try #require(
            SubjectThumbnailProcessor().process(
                source,
                request: .room(pixelSize: 500)
            )
        )

        #expect(output.kind == .room)
        #expect(output.image.width == 500)
        #expect(output.image.height == 500)
    }

    @Test("An extracted subject is fitted onto a transparent square")
    func extractedSubjectUsesTransparentCanvas() throws {
        let source = try #require(makeImage(width: 800, height: 400))
        let cutout = try #require(makeImage(width: 200, height: 100))
        let output = try #require(
            SubjectThumbnailProcessor().process(
                source,
                request: .subject(pixelSize: 250, inset: 6),
                foregroundExtractor: { _ in cutout }
            )
        )

        #expect(output.kind == .cutout)
        #expect(output.image.width == 250)
        #expect(output.image.height == 250)
        #expect(output.image.alphaInfo != .none)
    }

    @Test("Invalid request dimensions fail safely", arguments: [0, -1])
    func invalidDimensionsFail(pixelSize: Int) throws {
        let source = try #require(makeImage(width: 20, height: 20))
        let output = SubjectThumbnailProcessor().process(
            source,
            request: .room(pixelSize: pixelSize)
        )

        #expect(output == nil)
    }

    private func makeImage(width: Int, height: Int) -> CGImage? {
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.setFillColor(CGColor(red: 0.1, green: 0.7, blue: 0.6, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()
    }
}
