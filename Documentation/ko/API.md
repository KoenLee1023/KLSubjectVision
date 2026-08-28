# KLSubjectVision API 레퍼런스

> <span lang="ko">[English](../en/API.md) · [简体中文](../zh-Hans/API.md) · [繁體中文](../zh-Hant/API.md) · [日本語](../ja/API.md) · [한국어](API.md)</span>

이 문서는 KLSubjectVision 0.1.0의 모든 공개 선언을 설명합니다. 정확한 시그니처와 심볼 관계는 컴파일러가 생성한 Swift-DocC 페이지를 기준으로 합니다.

## `SubjectThumbnailRequest`

```swift
public enum SubjectThumbnailRequest: Sendable, Equatable {
    case subject(pixelSize: Int, inset: CGFloat)
    case room(pixelSize: Int)
}
```

정사각형 캔버스의 크기와 이미지 배치 방식을 나타내는 값 타입입니다.

### `.subject(pixelSize:inset:)`

전경을 분리한 뒤 분리된 이미지의 비율을 유지하면서 정사각형 중앙에 맞춥니다.

- `pixelSize`는 출력 이미지의 너비와 높이입니다. 단위는 픽셀입니다. 0 이하이면 결과를 만들 수 없습니다.
- `inset`은 분리된 이미지와 캔버스 각 변 사이에 둘 픽셀 수입니다. 0 이상이어야 하며 내부에 양수 크기의 영역이 남아야 합니다.

`inset`은 분리된 이미지를 배치할 때만 적용됩니다. 분리에 실패하거나 분리기가 `nil`을 반환하거나 지정한 `inset`으로 이미지를 배치할 수 없으면 원본 이미지를 여백 없이 정사각형에 가득 채웁니다. 따라서 잘못된 `inset`을 전달해도 유효한 `.fallback` 결과가 나올 수 있으며 항상 `nil`이 되는 것은 아닙니다.

### `.room(pixelSize:)`

전경 분리를 건너뛰고 원본 이미지를 정사각형에 가득 채웁니다. 정사각형 밖으로 나가는 부분은 이미지 중심을 기준으로 양쪽에서 대칭으로 잘립니다. 배경색을 추가하지 않으므로 원본 이미지의 투명 영역은 그대로 유지됩니다.

## `SubjectThumbnailOutputKind`

```swift
public enum SubjectThumbnailOutputKind: Sendable, Equatable {
    case cutout
    case fallback
    case room
}
```

| 값 | 실제 처리 경로 |
| --- | --- |
| `.cutout` | 주입된 분리기 또는 Vision이 이미지를 반환했고 해당 이미지를 정상적으로 배치했습니다. |
| `.fallback` | 전경 분리나 분리 이미지 배치가 결과를 만들지 못해 원본 이미지를 정사각형에 채웠습니다. |
| `.room` | 호출자가 `.room(pixelSize:)`을 선택했고 원본 이미지 배치에 성공했습니다. |

이 값은 실행된 경로만 나타냅니다. 분리 품질이나 의미적 신뢰도를 나타내지 않습니다. 주입된 분리기는 어떤 `CGImage`든 반환할 수 있으며 배치에 성공하면 `.cutout`으로 기록됩니다.

## `SubjectThumbnailOutput`

```swift
public struct SubjectThumbnailOutput: @unchecked Sendable {
    public let image: CGImage
    public let kind: SubjectThumbnailOutputKind

    public init(image: CGImage, kind: SubjectThumbnailOutputKind)
}
```

### `image`

합성된 이미지입니다. 프로세서가 생성한 값은 지정한 픽셀 크기의 정사각형이며 device RGB 색 공간과 premultiplied-last alpha를 사용합니다. 이 프로퍼티는 `CGImage` 참조를 유지합니다.

### `kind`

`image`를 만든 처리 경로입니다.

### `init(image:kind:)`

전달된 이미지와 처리 경로를 그대로 저장합니다. 픽셀을 복사하지 않고 이미지가 정사각형인지 검사하지 않으며 `kind`가 이미지 생성 방식과 일치하는지도 확인하지 않습니다.

현재 SDK에서 `CGImage` 자체는 `@unchecked Sendable`을 준수합니다. `SubjectThumbnailOutput`에도 `@unchecked Sendable`이 명시되어 있으며 이는 최초 공개 API와의 호환성을 유지하기 위한 선언입니다. 이 선언은 `image`만이 아니라 구조체 전체에 적용됩니다. 두 저장 프로퍼티는 모두 변경할 수 없습니다. 자체 가변 메모리를 이미지의 배경 저장소로 사용한다면 이미지가 사용되는 동안 메모리를 유효하게 유지하고 동시에 수정하지 않아야 합니다.

## `SubjectThumbnailProcessor`

```swift
public struct SubjectThumbnailProcessor: Sendable {
    public typealias ForegroundExtractor = (CGImage) -> CGImage?

    public init()

    public func process(
        _ source: CGImage,
        request: SubjectThumbnailRequest,
        foregroundExtractor: ForegroundExtractor? = nil
    ) -> SubjectThumbnailOutput?
}
```

상태를 저장하지 않는 프로세서입니다. Vision 요청, `CIContext`, 캐시, 공유 가변 데이터를 보관하지 않습니다. 처리는 동기 방식으로 실행됩니다.

### `ForegroundExtractor`

`process`에 전달된 원본 `CGImage`를 받아 배치할 전경 이미지 또는 `nil`을 반환하는 동기 클로저입니다. `nil`을 반환하면 원본 이미지로 대체합니다.

분리기를 전달한 호출에서는 내장 Vision 분리를 전혀 실행하지 않습니다. 분리기가 `nil`을 반환해도 Vision을 다시 시도하지 않습니다. 이 클로저는 `@Sendable`이 아닙니다. 캡처한 상태에 적합한 격리 컨텍스트를 통합 앱에서 선택해야 합니다.

### `init()`

상태가 없는 프로세서를 만듭니다. 초기화 과정에서는 이미지 처리나 프레임워크 요청을 실행하지 않습니다.

### `process(_:request:foregroundExtractor:)`

`.room` 요청은 캔버스를 검증한 뒤 원본 이미지를 정사각형에 가득 채웁니다.

`.subject` 요청은 전달된 분리기가 있으면 해당 분리기를 사용합니다. 분리기가 없으면 `VNGenerateForegroundInstanceMaskRequest`를 실행합니다. 첫 번째 결과에 포함된 모든 인스턴스를 대상으로 결합 영역에 맞춰 잘린 마스크 이미지를 만들고 Core Image로 변환한 뒤 지정한 여백 안에 배치합니다.

Vision 요청 오류, 결과 없음, 빈 인스턴스 집합, 마스크 이미지 생성 실패, Core Image 변환 실패는 호출자에게 던지지 않습니다. 모두 분리 실패로 처리한 뒤 원본 이미지 대체 경로를 시도합니다.

분리 이미지와 원본 이미지 어느 쪽으로도 캔버스를 만들 수 없으면 `nil`을 반환합니다. 주요 원인은 다음과 같습니다.

- 원본 이미지 크기를 사용할 수 없음
- `pixelSize <= 0`
- Core Graphics가 비트맵 컨텍스트 또는 최종 이미지를 만들 수 없음

`.subject`에서 `inset`이 음수이거나 너무 크면 분리 이미지를 배치할 수 없습니다. 그러나 여백이 없는 원본 이미지 대체 경로는 성공할 수 있습니다. 대체 경로가 성공하면 Vision 실패만으로 `nil`이 되지 않습니다.

이 메서드는 `source`를 동기 방식으로 읽으며 호출자의 이미지 소유권을 가져가지 않습니다. 취소 확인은 내장되어 있지 않습니다. 실행 예약, 취소, 중복 제거, 저장, 캐시는 통합 앱에서 관리합니다.

## 렌더링 규칙

- 캔버스는 정사각형이며 device RGB와 premultiplied-last alpha 사용
- 보간 품질은 high
- 이미지는 중앙에 배치
- 분리 이미지는 `pixelSize - inset * 2` 영역 안에 맞춤
- `.room`과 `.fallback`은 정사각형 전체를 채움
- 넘치는 부분은 이미지 중심을 기준으로 대칭으로 자름
