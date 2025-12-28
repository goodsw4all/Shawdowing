# 🎉 English Shadowing - 개발 진행 상황

## 현재 상태: MVP 완성 ✅

**날짜**: 2025-12-27

---

## ✅ 완성된 기능

### 1. 프로젝트 구조
- MVVM + Service Layer 아키텍처
- Models: `YouTubeVideo`, `Transcript`, `SubtitleLine`
- ViewModels: `PlayerViewModel`
- Services: `YouTubeService`, `RecordingService`

### 2. YouTube 통합
- YouTubePlayerKit 패키지 통합
- YouTube 영상 재생
- Video ID 추출 (URL 파싱)

### 3. 자막 기능
- 자막 리스트 표시
- 자막 터치로 구간 이동
- 현재 재생 자막 자동 하이라이팅
- 자동 스크롤

### 4. 컨트롤 패널
- 재생/일시정지 버튼
- 쉐도잉 모드 토글 (UI만)
- 녹음 버튼 (UI만)

### 5. 반응형 UI
- iOS, iPadOS 지원
- 로딩, 에러, 성공 상태 표시
- 다크 모드 지원

---

## ⏳ 미완성 기능 (TODO)

### 우선순위: High
1. **YouTube 자막 추출**
   - 현재: 더미 데이터 사용
   - 필요: YouTube Caption API 또는 yt-dlp 연동
   
2. **쉐도잉 모드 구현**
   - 문장 종료 시 자동 일시정지
   - 반복 재생 (3회, 5회 등)
   
3. **녹음 기능 완성**
   - 사용자 음성 녹음
   - 녹음 파일 재생
   - 원본과 비교 재생

### 우선순위: Medium
4. **재생 속도 조절** (0.5x ~ 2.0x)
5. **자막 캐싱** (반복 다운로드 방지)
6. **학습 기록** (완료한 영상, 시간 추적)

### 우선순위: Low
7. **다국어 자막 지원**
8. **단어장 기능**
9. **UI/UX 개선**
10. **단위 테스트 추가**

---

## 📁 프로젝트 구조

```
EnglishShadowing/
├── Models/
│   ├── YouTubeVideo.swift
│   └── Transcript.swift
├── Views/
│   ├── ContentView.swift
│   └── PlayerView.swift
├── ViewModels/
│   └── PlayerViewModel.swift
├── Services/
│   ├── YouTubeService.swift (TODO: 실제 자막 추출)
│   └── RecordingService.swift
└── Resources/
    └── Assets.xcassets
```

---

## 🚀 다음 단계

1. 쉐도잉 모드 구현 시작
2. YouTube 자막 추출 방법 조사
3. 녹음 재생 기능 테스트

---

## 📝 참고 사항

- **빌드 타겟**: iOS 17.0+, iPadOS 17.0+
- **의존성**: YouTubePlayerKit (SPM)
- **테스트 URL**: https://www.youtube.com/watch?v=dYCpuqbXjmg
