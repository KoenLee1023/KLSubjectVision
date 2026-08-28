# KLSubjectVision 아키텍처

> <span lang="ko">[English](../../README.md) · [简体中文](../zh-Hans/README.md) · [繁體中文](../zh-Hant/README.md) · [日本語](../ja/README.md) · [한국어](../ko/README.md)</span>

## 개요

입력은 `CGImage`와 명시적인 요청, 출력은 정사각형 이미지와 처리 경로로 제한합니다. `.subject`는 Vision으로 전경 마스크를 만들고 모든 피사체가 포함된 영역을 자른 뒤 Core Image를 거쳐 투명한 RGBA 이미지에 배치합니다. 전경 분리기를 주입한 경우에는 Vision을 호출하지 않습니다. 분리에 실패하면 `.room`과 같은 이미지 배치 방식을 사용합니다.

## 동작 보장

- Apple Vision을 이용한 전경 분리
- 여백을 지정할 수 있는 피사체 전체 맞춤 배치
- 장소 사진과 대체 처리에서는 정사각형을 가득 채워 배치
- 테스트용 전경 분리기 교체 가능
- cutout, fallback, room 중 실제 사용한 처리 경로 확인 가능

## 책임 경계

이 패키지는 `CGImage` 변환만 담당합니다. UIImage 또는 NSImage 로딩, 이미지 방향 보정, 작업 실행과 취소, 인코딩, 저장 위치, 캐시 키, 첨부 파일 관리는 앱에서 처리해야 합니다.

이 API는 계산 결과만 반환하며 앱의 상태를 변경하지 않습니다. 입력, 설정, 시스템 프레임워크의 동작이 같으면 동일한 결과를 반환합니다.
