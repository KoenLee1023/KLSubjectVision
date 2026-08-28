# KLSubjectVision 시작하기

KLSubjectVision을 앱에 추가하고 썸네일 생성 방식과 각 출력 결과의 처리 방법을 설정합니다.

## 개요

### 패키지 추가

패키지 저장소를 추가하고 최소 버전을 `0.1.0`으로 지정한 뒤 `KLSubjectVision` 라이브러리를 연결합니다.

```swift
dependencies: [
    .package(
        url: "https://github.com/KoenLee1023/KLSubjectVision.git",
        from: "0.1.0"
    )
]
```

방향이 보정된 `CGImage`를 사용할 수 있는 파일에서 모듈을 가져옵니다.

```swift
import KLSubjectVision
```

KLSubjectVision은 서드파티 런타임 의존성이 없습니다. 패키지에 선언된 Swift-DocC 플러그인은 문서 생성에만 사용되며 통합 앱에는 연결되지 않습니다.

### 요청 선택

전경 피사체를 분리할 때는 ``SubjectThumbnailRequest/subject(pixelSize:inset:)``를 사용합니다. 장면 전체를 유지할 때는 ``SubjectThumbnailRequest/room(pixelSize:)``을 사용합니다.

```swift
let request: SubjectThumbnailRequest = keepsSceneContext
    ? .room(pixelSize: 512)
    : .subject(pixelSize: 512, inset: 24)
```

`pixelSize`는 출력 이미지의 너비와 높이이며 단위는 픽셀입니다. `.subject`의 `inset`도 출력 픽셀 단위이며 분리된 이미지를 정상적으로 배치했을 때만 적용됩니다.

### 이미지 처리

``SubjectThumbnailProcessor``를 만들고 ``SubjectThumbnailProcessor/process(_:request:foregroundExtractor:)``를 호출합니다.

```swift
let processor = SubjectThumbnailProcessor()

guard let output = processor.process(sourceImage, request: request) else {
    throw ThumbnailError.couldNotCreateCanvas
}
```

처리는 동기 방식으로 실행되며 Vision, Core Image, Core Graphics를 사용할 수 있습니다. 큰 이미지나 여러 이미지는 통합 앱이 관리하는 백그라운드 실행 환경에서 처리합니다. 작업 우선순위, 취소, 저장, 캐시도 앱에서 관리합니다.

### 결과 확인

``SubjectThumbnailOutput/kind``는 ``SubjectThumbnailOutput/image``를 만든 처리 경로를 나타냅니다.

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

``SubjectThumbnailOutputKind/cutout``은 분리된 이미지를 정상적으로 배치했다는 뜻입니다. ``SubjectThumbnailOutputKind/fallback``은 전경 분리 또는 분리 이미지 배치가 결과를 만들지 못해 원본 이미지를 정사각형에 채웠다는 뜻입니다. ``SubjectThumbnailOutputKind/room``은 호출자가 장면 전체 배치를 선택했다는 뜻입니다. 이 값들은 처리 경로를 나타내며 분리 품질의 신뢰도가 아닙니다.

### 대체 처리와 `nil`

Vision 실행 실패, 전경 인스턴스 없음, 마스크 이미지 생성 실패, 지정한 `inset`으로 분리 이미지를 배치할 수 없는 경우에는 원본 이미지로 대체합니다. 주입한 분리기가 `nil`을 반환할 때도 같습니다. 대체 처리에서는 여백을 사용하지 않습니다.

요청한 방식과 대체 처리 모두 캔버스를 만들 수 없을 때만 메서드가 `nil`을 반환합니다. 주요 원인은 `pixelSize`가 0 이하이거나 원본 이미지 크기를 사용할 수 없거나 Core Graphics가 필요한 영역 또는 최종 이미지를 만들 수 없는 경우입니다. 잘못된 `inset` 때문에 분리 이미지를 배치하지 못해도 대체 처리는 성공할 수 있습니다.

### 전경 분리기 주입

재현 가능한 테스트를 만들거나 다른 분할 구현을 연결할 때 ``SubjectThumbnailProcessor/ForegroundExtractor``를 전달합니다.

```swift
let output = processor.process(
    sourceImage,
    request: .subject(pixelSize: 256, inset: 16),
    foregroundExtractor: { image in
        customSegmenter.maskedForeground(from: image)
    }
)
```

분리기를 전달하면 해당 호출에서는 내장 Vision 분리를 실행하지 않습니다. 분리기는 동기 방식으로 실행되며 `@Sendable`이 아닙니다. 분리기가 참조하는 상태를 안전하게 다룰 수 있는 격리 컨텍스트에서 `process`를 호출해야 합니다.

현재 SDK에서 `CGImage` 자체는 `@unchecked Sendable`을 준수합니다. ``SubjectThumbnailOutput``에도 최초 공개 API와의 호환성을 유지하기 위해 `@unchecked Sendable`을 명시합니다. 이 선언은 출력 구조체 전체에 적용됩니다. 자체 가변 메모리를 이미지의 배경 저장소로 사용한다면 이미지가 사용되는 동안 메모리를 유효하게 유지하고 동시에 수정하지 않아야 합니다.

### 다른 언어

- <doc:GettingStarted>
- <doc:GettingStarted-zh-Hans>
- <doc:GettingStarted-zh-Hant>
- <doc:GettingStarted-ja>
