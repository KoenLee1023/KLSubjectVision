# KLSubjectVision Demo Apps

> [English](../en/README.md) · [简体中文](../zh-Hans/README.md) · [繁體中文](../zh-Hant/README.md) · [日本語](../ja/README.md) · [한국어](../ko/README.md)

Two independent SwiftUI applications demonstrate processing without importing wondays assets. Both create synthetic source artwork locally so examples remain redistributable.

## Subject Studio

Subject Studio compares an injected foreground cutout, a forced fallback, and the original source. It is the fastest way to inspect inset and aspect-fit behavior without relying on Vision's model output.

## Thumbnail Matrix

Thumbnail Matrix renders several square sizes and both request modes together. Use it to review crop consistency, transparent margins, and how a single policy scales across UI roles.

Each example has its own `Package.swift` and app entry point. From the repository root, build either package with SwiftPM:

```bash
swift build --package-path Examples/SubjectStudio

swift build --package-path Examples/ThumbnailMatrix
```

The demos do not define persistence, cache, or source-image policy. Those remain responsibilities of the integrating app.
