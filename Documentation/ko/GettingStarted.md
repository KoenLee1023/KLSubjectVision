# KLSubjectVision 시작하기

> <span lang="ko">[English](../en/GettingStarted.md) · [简体中文](../zh-Hans/GettingStarted.md) · [繁體中文](../zh-Hant/GettingStarted.md) · [日本語](../ja/GettingStarted.md) · [한국어](GettingStarted.md)</span>

## 패키지 추가

Xcode의 Add Package Dependencies에서 `https://github.com/KoenLee1023/KLSubjectVision.git`을 추가하고 최소 버전을 `0.1.0`으로 지정합니다. `Package.swift`에 직접 선언하려면 다음과 같이 작성합니다.

```swift
dependencies: [
    .package(
        url: "https://github.com/KoenLee1023/KLSubjectVision.git",
        from: "0.1.0"
    )
]
```

`CGImage`를 처리하는 파일에서 `KLSubjectVision`을 가져옵니다.

## 원본 이미지 준비

플랫폼 이미지 타입 변환은 앱 경계에서 수행합니다. 로더가 방향 정보를 반영하지 않았다면 방향을 보정한 뒤 `CGImage`를 가져옵니다.

```swift
guard let source = uiImage.cgImage else { return }
```

KLSubjectVision은 픽셀 단위로 처리합니다. `UIImage.scale`, EXIF 방향, 화면 포인트, 색상 프로파일 정책은 통합 앱에서 결정해야 합니다.

## 요청 선택

피사체를 배경에서 분리해야 할 때는 `.subject`를 사용합니다. 장면 전체를 유지해야 할 때는 `.room`을 사용합니다.

```swift
let request: SubjectThumbnailRequest = isContextualScene
    ? .room(pixelSize: 512)
    : .subject(pixelSize: 512, inset: 24)
```

`.subject`의 `inset`은 출력 픽셀 단위이며 분리된 이미지를 정상적으로 배치했을 때만 적용됩니다. 분리에 실패하면 원본 이미지를 여백 없이 배치합니다. 장소, 실내, 문서, 스크린샷처럼 주변 정보를 유지해야 하는 이미지에는 `.room`이 적합합니다.

## 이미지 처리

```swift
let processor = SubjectThumbnailProcessor()

guard let output = processor.process(source, request: request) else {
    throw ThumbnailError.couldNotCreateCanvas
}
```

`process`는 동기 메서드이며 Vision, Core Image, Core Graphics 작업을 실행할 수 있습니다. 큰 이미지나 여러 이미지를 처리할 때는 통합 앱이 관리하는 백그라운드 실행 환경에서 이미지 디코딩부터 처리까지 수행합니다. 전용 액터, `OperationQueue`, DispatchQueue 등을 사용할 수 있습니다. 작업 우선순위, 취소, 자체 이미지 배경 저장소의 수명은 앱에서 관리합니다.

## 처리 경로 확인

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

`kind`는 실제로 실행된 경로를 나타냅니다. 신뢰도 점수가 아닙니다. 제품에서 분리 품질을 확인해야 한다면 별도의 검사나 미리보기를 제공해야 합니다.

## 전경 분리기 주입

재현 가능한 테스트를 만들거나 다른 분할 엔진을 연결할 때 `ForegroundExtractor`를 전달합니다.

```swift
let output = processor.process(
    source,
    request: .subject(pixelSize: 256, inset: 16),
    foregroundExtractor: { image in
        customSegmenter.maskedForeground(from: image)
    }
)
```

분리기를 전달하면 해당 호출에서는 Vision을 사용하지 않습니다. 클로저가 `nil`을 반환하면 즉시 원본 이미지로 대체합니다.

## 결과 저장

`output.image`의 이미지 형식과 저장 방식은 통합 앱에서 결정합니다. 이 패키지는 PNG, HEIF, JPEG 선택, 파일 경로, 캐시 키, 첨부 파일 식별자, 무효화 규칙을 정의하지 않습니다.

출력은 `CGImage` 참조를 유지하지만 픽셀은 복사하지 않습니다. 자체 가변 메모리를 이미지 배경 저장소로 사용한다면 이미지가 사용되는 동안 메모리를 유효하게 유지하고 동시에 수정하지 않아야 합니다.

## 통합 확인 항목

- 원본 `CGImage`를 만들기 전에 이미지 방향 보정
- UI 용도마다 픽셀 크기 정책 고정
- 가장 작은 크기에서도 `inset` 안쪽에 양수 크기 영역이 남는지 확인
- `.cutout`, `.fallback`, `.room`, 캔버스 생성 실패 테스트
- 실행 예약, 취소, 저장, 캐시를 통합 앱에서 관리
- 마이그레이션 중 기존 미디어 식별자와 캐시 키 유지
