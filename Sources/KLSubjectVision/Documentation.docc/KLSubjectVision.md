# ``KLSubjectVision``

Compose predictable square thumbnails with Vision, Core Image, and Core Graphics.

## How the API fits together

``SubjectThumbnailRequest`` is the policy input. Use
``SubjectThumbnailRequest/subject(pixelSize:inset:)`` when the foreground
should be isolated, and ``SubjectThumbnailRequest/room(pixelSize:)`` when the
scene is the content. Pass the request to
``SubjectThumbnailProcessor/process(_:request:foregroundExtractor:)``. The
processor returns ``SubjectThumbnailOutput`` so the host can display the image
and inspect ``SubjectThumbnailOutput/kind`` without guessing which path ran.

The processor is synchronous and stateless. Move large images and batches to a
host-owned background task. If the built-in Vision path cannot produce a
cutout, the processor uses the original image as a square fallback. A custom
``SubjectThumbnailProcessor/ForegroundExtractor`` is useful for deterministic
tests or a host-provided segmentation model. Passing one replaces Vision for
that call; it does not change the processor globally.

## Output semantics

``SubjectThumbnailOutputKind/cutout`` means the extracted foreground was
composited successfully. ``SubjectThumbnailOutputKind/fallback`` means the
original image was used because extraction or compositing did not produce a
usable cutout. ``SubjectThumbnailOutputKind/room`` means the caller explicitly
requested scene preservation. These values describe the processing path, not a
confidence score. The result is `nil` only when neither the requested path nor
its fallback can create a valid bitmap.

## Topics

### Essentials

- <doc:GettingStarted>
- ``SubjectThumbnailProcessor``

### Requests

- ``SubjectThumbnailRequest``
- ``SubjectThumbnailRequest/subject(pixelSize:inset:)``
- ``SubjectThumbnailRequest/room(pixelSize:)``

### Results

- ``SubjectThumbnailOutput``
- ``SubjectThumbnailOutput/init(image:kind:)``
- ``SubjectThumbnailOutput/image``
- ``SubjectThumbnailOutput/kind``
- ``SubjectThumbnailOutputKind``
- ``SubjectThumbnailOutputKind/cutout``
- ``SubjectThumbnailOutputKind/fallback``
- ``SubjectThumbnailOutputKind/room``

### Processing

- ``SubjectThumbnailProcessor/init()``
- ``SubjectThumbnailProcessor/ForegroundExtractor``
- ``SubjectThumbnailProcessor/process(_:request:foregroundExtractor:)``
