import AppKit
import KLSubjectVision
import SwiftUI

@main
struct SubjectStudioApp: App {
    var body: some Scene {
        WindowGroup("Subject Studio") {
            SubjectStudioView()
                .frame(minWidth: 680, minHeight: 460)
        }
    }
}

private struct SubjectStudioView: View {
    @State private var usesCutout = true

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Subject Studio")
                    .font(.largeTitle.bold())
                Text("Compare a supplied foreground mask with KLSubjectVision’s safe fallback.")
                    .foregroundStyle(.secondary)
            }

            Toggle("Foreground extractor succeeds", isOn: $usesCutout)
                .toggleStyle(.switch)

            HStack(spacing: 28) {
                PreviewCard(title: "Source", image: DemoArtwork.source)
                Image(systemName: "arrow.right")
                    .font(.title2)
                    .foregroundStyle(.tertiary)
                PreviewCard(title: output.kind == .cutout ? "Cutout" : "Fallback", image: output.image)
            }
        }
        .padding(32)
    }

    private var output: SubjectThumbnailOutput {
        let result = SubjectThumbnailProcessor().process(
            DemoArtwork.source,
            request: .subject(pixelSize: 250, inset: 18),
            foregroundExtractor: { _ in usesCutout ? DemoArtwork.subject : nil }
        )
        return result ?? SubjectThumbnailOutput(image: DemoArtwork.source, kind: .fallback)
    }
}

private struct PreviewCard: View {
    let title: String
    let image: CGImage

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            Image(nsImage: NSImage(cgImage: image, size: .zero))
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 250, height: 250)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 24))
                .clipShape(RoundedRectangle(cornerRadius: 24))
        }
    }
}

private enum DemoArtwork {
    static let source = makeImage(width: 640, height: 360, transparent: false)
    static let subject = makeImage(width: 240, height: 320, transparent: true)

    private static func makeImage(width: Int, height: Int, transparent: Bool) -> CGImage {
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        if !transparent {
            context.setFillColor(CGColor(red: 0.07, green: 0.1, blue: 0.18, alpha: 1))
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
        context.setFillColor(CGColor(red: 0.22, green: 0.86, blue: 0.78, alpha: 1))
        context.fillEllipse(in: CGRect(x: width / 4, y: height / 8, width: width / 2, height: height * 3 / 4))
        return context.makeImage()!
    }
}
