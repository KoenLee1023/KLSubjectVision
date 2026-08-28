# KLSubjectVision 데모 앱

> <span lang="ko">[English](../en/README.md) · [简体中文](../zh-Hans/README.md) · [繁體中文](../zh-Hant/README.md) · [日本語](../ja/README.md) · [한국어](../ko/README.md)</span>

KLSubjectVision은 피사체 분리와 정사각형 배치를 하나로 묶은 Swift 패키지입니다. `.subject`는 분리한 피사체 전체가 투명한 정사각형 안에 보이도록 배치하고, 분리에 실패하면 원본 이미지로 정사각형을 채웁니다. `.room`은 장소나 실내 사진처럼 장면 전체를 유지해야 하는 이미지에 사용합니다.

## Subject Studio

Apple Vision을 이용한 전경 분리 · 여백을 지정할 수 있는 피사체 전체 맞춤 배치 · 장소 사진과 대체 처리에서는 정사각형을 가득 채워 배치

## Thumbnail Matrix

장소 사진과 대체 처리에서는 정사각형을 가득 채워 배치 · 테스트용 전경 분리기 교체 가능 · cutout, fallback, room 중 실제 사용한 처리 경로 확인 가능

두 데모 앱에는 각각 전용 `Package.swift`와 앱 진입점이 있습니다. 저장소 루트의 패키지만 사용하며 wondays 코드나 리소스를 가져오지 않습니다.

이 패키지는 `CGImage` 변환만 담당합니다. UIImage 또는 NSImage 로딩, 이미지 방향 보정, 작업 실행과 취소, 인코딩, 저장 위치, 캐시 키, 첨부 파일 관리는 앱에서 처리해야 합니다.
