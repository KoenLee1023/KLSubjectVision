import AppKit
import KLSubjectVision
import SwiftUI

@main
struct ThumbnailMatrixApp: App {
    var body: some Scene {
        WindowGroup("Thumbnail Matrix") {
            ThumbnailMatrixView()
                .frame(minWidth: 720, minHeight: 500)
        }
    }
}

private struct ThumbnailMatrixView: View {
    private let sizes = [96, 160, 250]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Thumbnail Matrix")
                    .font(.largeTitle.bold())
                Text("One synthetic source, several explicit output policies.")
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [.init(.adaptive(minimum: 190), spacing: 18)], spacing: 18) {
                    ForEach(sizes, id: \.self) { size in
                        tile(title: "Subject · \(size) px", request: .subject(pixelSize: size, inset: 10))
                        tile(title: "Room · \(size) px", request: .room(pixelSize: size))
                    }
                }
            }
            .padding(32)
        }
    }

    private func tile(title: String, request: SubjectThumbnailRequest) -> some View {
        let output = SubjectThumbnailProcessor().process(
            MatrixArtwork.source,
            request: request,
            foregroundExtractor: { _ in MatrixArtwork.subject }
        )
        return VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            if let output {
                Image(nsImage: NSImage(cgImage: output.image, size: .zero))
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 18))
            }
            Text(String(describing: output?.kind ?? .fallback).capitalized)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
    }
}

private enum MatrixArtwork {
    static let source = makeImage(width: 720, height: 420, subjectOnly: false)
    static let subject = makeImage(width: 280, height: 360, subjectOnly: true)

    private static func makeImage(width: Int, height: Int, subjectOnly: Bool) -> CGImage {
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        if !subjectOnly {
            context.setFillColor(CGColor(red: 0.94, green: 0.92, blue: 0.86, alpha: 1))
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
            context.setFillColor(CGColor(red: 0.3, green: 0.42, blue: 0.58, alpha: 1))
            context.fill(CGRect(x: 0, y: 0, width: width, height: height / 3))
        }
        context.setFillColor(CGColor(red: 0.95, green: 0.48, blue: 0.32, alpha: 1))
        context.fillEllipse(in: CGRect(x: width / 5, y: height / 10, width: width * 3 / 5, height: height * 4 / 5))
        return context.makeImage()!
    }
}
