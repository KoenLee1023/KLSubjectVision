# Migrating to KLSubjectVision

## Preserve output contracts first

Record current pixel dimensions, crop mode, transparency expectations, file format, storage path, and cache key for each thumbnail role. Package adoption should not invalidate previously stored media accidentally.

## Map product requests

Translate product vocabulary at one adapter boundary:

```swift
func packageRequest(for role: ExistingRole) -> SubjectThumbnailRequest {
    switch role {
    case .person, .pet, .object:
        return .subject(pixelSize: role.pixelSize, inset: role.inset)
    case .room, .place:
        return .room(pixelSize: role.pixelSize)
    }
}
```

Do not move note IDs, attachment names, or storage policy into the package.

## Compare all three paths

Fixtures should force `.cutout`, `.fallback`, and `.room`. Inject a deterministic extractor for cutout geometry instead of making tests depend on Vision model behavior.

## Retain orchestration

Keep existing task cancellation, in-flight deduplication, persistence, and cache lookup around the package call. Replace only image transformation until output parity is established.

## Remove duplicate geometry

Once package tests and integrating-app regression tests pass, delete local aspect-fit/fill helpers so there is one owner for square composition.
