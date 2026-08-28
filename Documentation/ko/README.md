# KLSubjectVision

> <span lang="ko">[English](../../README.md) · [简体中文](../zh-Hans/README.md) · [繁體中文](../zh-Hant/README.md) · [日本語](../ja/README.md) · [한국어](../ko/README.md)</span>

이미지에서 정사각형 썸네일을 만듭니다. Apple Vision으로 피사체를 분리할 수 없으면 원본 이미지를 사용하는 방식으로 자동 전환합니다.

KLSubjectVision은 피사체 분리와 정사각형 배치를 하나로 묶은 Swift 패키지입니다. `.subject`는 분리한 피사체 전체가 투명한 정사각형 안에 보이도록 배치하고, 분리에 실패하면 원본 이미지로 정사각형을 채웁니다. `.room`은 장소나 실내 사진처럼 장면 전체를 유지해야 하는 이미지에 사용합니다.

## 개요

- Apple Vision을 이용한 전경 분리
- 여백을 지정할 수 있는 피사체 전체 맞춤 배치
- 장소 사진과 대체 처리에서는 정사각형을 가득 채워 배치
- 테스트용 전경 분리기 교체 가능
- cutout, fallback, room 중 실제 사용한 처리 경로 확인 가능

## 요구 사항

- Swift 6.0 이상
- iOS 17 이상
- macOS 14 이상
- 서드파티 런타임 의존성 없음
- Vision · Core Image · Core Graphics

## 설치

Xcode의 Add Package Dependencies에서 저장소를 추가하거나 `Package.swift`에 다음을 선언합니다.

```swift
dependencies: [
    .package(
        url: "https://github.com/KoenLee1023/KLSubjectVision.git",
        from: "0.1.0"
    )
]
```

```swift
import KLSubjectVision
```

## 시작하기

1. 앱 경계에서 이미지 방향을 보정한 뒤 `CGImage`로 변환합니다.
2. 사람, 동물, 제품에는 `.subject`를, 장소, 문서, 스크린샷에는 `.room`을 지정합니다.
3. 큰 이미지나 여러 이미지는 메인 액터 밖에서 처리합니다.
4. `output.kind`를 진단에 사용하고 인코딩, 저장, 캐시는 앱에서 관리합니다.

```swift
let processor = SubjectThumbnailProcessor()

let output = processor.process(
    sourceImage,
    request: .subject(pixelSize: 512, inset: 28)
)

guard let output else { return }

switch output.kind {
case .cutout:
    print("Vision produced a foreground cutout")
case .fallback:
    print("The original image was aspect-filled")
case .room:
    print("Room treatment was used")
}

display(output.image)
```

```swift
let output = processor.process(
    sourceImage,
    request: .room(pixelSize: 384)
)
```

## 동작 보장

- `SubjectThumbnailRequest`: 피사체를 분리하는 `.subject(pixelSize:inset:)`와 전체 이미지를 사용하는 `.room(pixelSize:)`를 제공합니다.
- `SubjectThumbnailOutputKind`: 결과가 `.cutout`, `.fallback`, `.room` 중 어느 경로에서 생성되었는지 나타냅니다.
- `SubjectThumbnailOutput`: 프로세서가 생성한 값에는 지정한 픽셀 크기의 정사각형 `CGImage`와 처리 경로가 포함됩니다. 공개 이니셜라이저는 이미지 크기를 검증하지 않습니다.
- `SubjectThumbnailProcessor`: 공유 가변 상태가 없는 동기 처리기입니다. 테스트에서는 `ForegroundExtractor`를 교체할 수 있습니다.
- `pixelSize`가 0 이하이거나 원본 이미지 크기를 사용할 수 없거나 캔버스를 만들 수 없으면 `nil`을 반환합니다. 잘못된 `inset`은 분리 이미지 배치를 막지만 원본 이미지 대체 경로는 성공할 수 있습니다. Vision 분리에 실패해도 대체 경로가 성공하면 `nil`이 되지 않습니다.

## 책임 경계

이 패키지는 `CGImage` 변환만 담당합니다. UIImage 또는 NSImage 로딩, 이미지 방향 보정, 작업 실행과 취소, 인코딩, 저장 위치, 캐시 키, 첨부 파일 관리는 앱에서 처리해야 합니다.

## 문서

- [시작하기](GettingStarted.md)
- [API 레퍼런스](API.md)
- [아키텍처](Architecture.md)
- [마이그레이션](Migration.md)
- [데모 앱](../../Examples/Documentation/ko/README.md)
- [보안 정책](SECURITY.md)
- [행동 강령](CODE_OF_CONDUCT.md)
- [변경 기록](CHANGELOG.md)

## 상태

현재 API 버전은 1.0 미만입니다. wondays에서 실제로 사용하고 있지만 안정 버전을 발표하기 전까지는 마이너 업데이트에서 이름이나 설정 방식을 변경할 수 있습니다.

## 라이선스

MIT. [LICENSE](../../LICENSE)
