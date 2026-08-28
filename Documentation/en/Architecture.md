# KLSubjectVision Architecture

The package separates image transformation from product orchestration.

## Processing boundary

Input is a `CGImage` plus an explicit request. Output is a square `CGImage` plus a path identifier. This keeps UIKit/AppKit conversion, storage, task scheduling, caching, and UI outside the module.

## Subject path

The default path runs `VNGenerateForegroundInstanceMaskRequest`, requests a masked image for all detected instances, crops to their combined extent, converts the pixel buffer through Core Image, and aspect-fits the result onto a cleared square canvas.

An injected extractor replaces the Vision step completely. That makes geometry tests deterministic and allows alternate segmentation engines without changing the public result model.

## Fallback path

Foreground segmentation is opportunistic rather than required. Errors and empty masks fall through to the same aspect-fill canvas used by room treatment. The path is explicit in `.fallback`, preventing silent quality assumptions.

## Statelessness

The processor retains no `CIContext`, Vision foreground-mask operation, cache, or mutable singleton. Calls cannot invalidate one another and hosts choose their own reuse and memory-pressure strategy.

## Exclusions

Source acquisition, EXIF orientation, background colors, file encoding, persistence, cache invalidation, cancellation policy, and product taxonomy are application concerns.
