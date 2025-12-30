# 아키텍처 및 데이터 흐름 가이드

> 시스템 구조와 데이터 흐름을 이해하기 위한 상세 가이드

## 📐 전체 아키텍처

### MVVM 레이어 구조

```
┌─────────────────────────────────────────────────────┐
│                      View Layer                      │
│  (사용자 인터페이스 - SwiftUI)                      │
│                                                       │
│  ShadowingView                                       │
│  ├─ CustomYouTubePlayer                             │
│  ├─ CurrentSentenceCard                             │
│  ├─ SentenceRow                                     │
│  ├─ ControlPanelView                                │
│  └─ ProsodyChecklistView                            │
└─────────────────────────────────────────────────────┘
                         ↕ @Published / @Binding
┌─────────────────────────────────────────────────────┐
│                   ViewModel Layer                    │
│  (비즈니스 로직 - Swift Class)                      │
│                                                       │
│  ShadowingViewModel                                  │
│  ├─ 재생 제어 로직                                  │
│  ├─ 상태 관리                                       │
│  ├─ 자동 일시정지                                   │
│  └─ 데이터 변환                                     │
└─────────────────────────────────────────────────────┘
                         ↕ 메서드 호출
┌─────────────────────────────────────────────────────┐
│                    Service Layer                     │
│  (외부 의존성 - Swift Class)                        │
│                                                       │
│  StorageService         TranscriptService            │
│  YouTubeMetadataService                              │
└─────────────────────────────────────────────────────┘
                         ↕ API / File I/O
┌─────────────────────────────────────────────────────┐
│                     Model Layer                      │
│  (데이터 구조 - Swift Struct)                       │
│                                                       │
│  ShadowingSession, SentenceItem                      │
│  YouTubeVideo, ProsodyAssessment                     │
└─────────────────────────────────────────────────────┘
```

## 🔄 데이터 흐름

### 1. 세션 생성 플로우

```
사용자 입력 (YouTube URL)
         ↓
NewSessionView
         ↓
[1] TranscriptService.fetchTranscript(videoID)
         ↓ YouTube API 호출
    자막 데이터 (JSON)
         ↓
[2] SentenceItem 배열 생성
         ↓
[3] ShadowingSession 생성
         ↓
[4] StorageService.saveSession()
         ↓
    파일 시스템에 저장
         ↓
ShadowingView로 이동
```

**코드 예시**:
```swift
// 1. 자막 가져오기
let transcript = try await TranscriptService.shared.fetchTranscript(videoID: videoID)

// 2. 문장 생성
let sentences = transcript.map { item in
    SentenceItem(
        text: item.text,
        startTime: item.start,
        endTime: item.start + item.duration
    )
}

// 3. 세션 생성
let session = ShadowingSession(video: video, sentences: sentences)

// 4. 저장
try StorageService.shared.saveSession(session)
```

### 2. 비디오 재생 플로우

```
CustomYouTubePlayer (View)
         ↓
[1] loadVideo() 시작
         ↓
YouTubeKit.streams 요청
         ↓
    비디오 스트림 URL 수신
         ↓
[2] AVPlayer 생성 및 로드
         ↓
[3] setupPlayerObservers() 호출
         ├─ 시간 관찰자 등록 (0.1초마다)
         └─ 재생 완료 관찰자 등록
         ↓
[4] currentTime 바인딩 업데이트 (0.1초마다)
         ↓
ShadowingViewModel.$currentTime 변경
         ↓
[5] checkSentenceProgress() 호출
         ↓
    문장 끝 감지 시 isPlaying = false
         ↓
[6] CustomYouTubePlayer.onChange(isPlaying)
         ↓
    AVPlayer.pause() 호출
```

**코드 흐름**:
```swift
// CustomYouTubePlayer.swift
func loadVideo() async {
    // 1. 스트림 URL 가져오기
    let youtube = YouTube(videoID: videoID)
    let streams = try await youtube.streams
    let stream = streams.highestResolutionStream()
    
    // 2. AVPlayer 생성
    let avPlayer = AVPlayer(url: stream.url)
    self.player = avPlayer
    
    // 3. 관찰자 설정
    setupPlayerObservers()
}

func setupPlayerObservers() {
    // 4. 시간 업데이트 (0.1초마다)
    player.addPeriodicTimeObserver(forInterval: 0.1) { time in
        currentTime = time.seconds  // ViewModel에 알림
    }
}

// ShadowingViewModel.swift
private func checkSentenceProgress(time: TimeInterval) {
    // 5. 문장 끝 감지
    if time >= sentence.endTime && isPlaying {
        isPlaying = false  // 6. 일시정지
    }
}
```

### 3. 자막 클릭 플로우

```
사용자가 자막 클릭
         ↓
SentenceRow.onTap 호출
         ↓
viewModel.currentSentenceIndex = 클릭한 인덱스
viewModel.seekAndPlay() 호출
         ↓
[1] hasAutoPaused = false (플래그 초기화)
[2] isPlaying = false (일시정지)
         ↓
Task 시작 (비동기)
         ↓
[3] 100ms 대기
[4] currentTime = sentence.startTime (seek)
         ↓
CustomYouTubePlayer.onChange(currentTime)
         ↓
[5] AVPlayer.seek() 호출
         ↓
[6] 100ms 대기
[7] isPlaying = true (재생 시작)
         ↓
CustomYouTubePlayer.onChange(isPlaying)
         ↓
[8] AVPlayer.play() 호출
```

## 🎯 상태 동기화 메커니즘

### Binding을 통한 양방향 동기화

```
┌──────────────────┐         @Binding         ┌──────────────────┐
│  ViewModel       │ ←─────────────────────→  │  CustomYouTube   │
│                  │                           │  Player          │
│  @Published      │                           │                  │
│  isPlaying       │ ←───── onChange ────────→ │  AVPlayer        │
│  currentTime     │                           │  .play()         │
│  playbackRate    │                           │  .pause()        │
└──────────────────┘                           │  .seek()         │
         ↕                                      └──────────────────┘
    @StateObject                                        ↕
         ↕                                         AVPlayer API
┌──────────────────┐
│  ShadowingView   │
│                  │
│  UI 업데이트     │
│  (SwiftUI)       │
└──────────────────┘
```

**코드 예시**:
```swift
// ViewModel → Player (명령)
viewModel.isPlaying = true

// Player → ViewModel (상태 보고)
.onChange(of: isPlaying) { newValue in
    if newValue {
        player.play()
    }
}

// Player → ViewModel (시간 업데이트)
player.addPeriodicTimeObserver { time in
    currentTime = time.seconds  // Binding 업데이트
}
```

## 🔐 안전 장치 (Safety Mechanisms)

### 1. Seek 무한 루프 방지

**문제**: currentTime 변경 → seek → currentTime 변경 → 무한 반복

**해결**:
```swift
@State private var isSeeking = false

.onChange(of: currentTime) { newTime in
    guard !isSeeking else { return }  // seek 중이면 무시
    
    if abs(player.currentTime - newTime) > 1.0 {
        isSeeking = true
        player.seek(to: newTime) { _ in
            isSeeking = false  // 완료 후 플래그 해제
        }
    }
}
```

### 2. 자동 일시정지 중복 실행 방지

**문제**: 문장 끝에서 매 0.1초마다 일시정지 시도

**해결**:
```swift
private var hasAutoPaused: Bool = false

private func checkSentenceProgress(time: TimeInterval) {
    if time >= endTime && isPlaying && !hasAutoPaused {
        isPlaying = false
        hasAutoPaused = true  // 한 번만 실행되도록
    }
}

func seekAndPlay() {
    hasAutoPaused = false  // 새 재생 시 초기화
}
```

### 3. Seek 중 일시정지 체크 건너뛰기

**문제**: Seek 직후 이전 시간으로 잘못된 일시정지

**해결**:
```swift
private var isManualSeeking: Bool = false

private func checkSentenceProgress(time: TimeInterval) {
    // Seek 직후 안정화 대기
    if time < sentence.startTime + 0.3 {
        return  // 0.3초간 체크 안 함
    }
    
    // 이후 정상 체크...
}
```

## 📊 성능 최적화

### 1. 시간 관찰 주기

```swift
// 0.1초마다 체크 (10 FPS)
let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
player.addPeriodicTimeObserver(forInterval: interval)
```

**선택 이유**:
- ✅ 충분히 정확함 (사람이 인지하기 어려움)
- ✅ CPU 사용량 적절
- ⚠️ 0.05초: 더 정확하지만 CPU 2배 사용
- ⚠️ 0.5초: CPU 절약하지만 반응 느림

### 2. 필터링 최적화

```swift
// ViewModel에서 한 번만 계산
func filteredSentences(...) -> [(index: Int, sentence: SentenceItem)] {
    return session.sentences.enumerated().compactMap { ... }
}

// View에서 재사용
private var filteredSentences: [...] {
    viewModel.filteredSentences(
        showFavoritesOnly: showFavoritesOnly,
        hideCompleted: hideCompleted
    )
}
```

## 🐛 디버깅 가이드

### 로그 패턴

프로젝트 전체에서 사용하는 로그 이모지:

```swift
print("🎬 ...")  // 초기화/시작
print("▶️ ...")  // 재생 시작
print("⏸ ...")  // 일시정지
print("⏩ ...")  // Seek
print("🔁 ...")  // 반복
print("⭐️ ...")  // 즐겨찾기
print("✅ ...")  // 성공
print("❌ ...")  // 에러
print("⚠️ ...")  // 경고
print("🔍 ...")  // 디버깅 정보
```

### 흔한 디버깅 시나리오

#### 1. 자막 클릭했는데 재생 안 됨
```
확인 사항:
1. 로그에 "🎬 Seek and play" 있는지?
2. "⏸ Auto-pausing" 로그가 너무 빨리 나오는지?
3. hasAutoPaused 플래그 상태는?
```

#### 2. 문장 끝에서 멈추지 않음
```
확인 사항:
1. checkSentenceProgress() 호출되는지?
2. time과 endTime 값 비교
3. hasAutoPaused 플래그가 이미 true인지?
```

#### 3. Seek가 작동 안 함
```
확인 사항:
1. isSeeking 플래그 상태
2. currentTime Binding 연결 확인
3. AVPlayer의 seek completion 호출되는지?
```

## 📚 추가 학습 자료

### SwiftUI 공식 문서
- [@Published](https://developer.apple.com/documentation/combine/published)
- [@StateObject](https://developer.apple.com/documentation/swiftui/stateobject)
- [@Binding](https://developer.apple.com/documentation/swiftui/binding)

### AVFoundation
- [AVPlayer](https://developer.apple.com/documentation/avfoundation/avplayer)
- [CMTime](https://developer.apple.com/documentation/coremedia/cmtime)

### Combine
- [Publishers](https://developer.apple.com/documentation/combine/publishers)
- [Cancellable](https://developer.apple.com/documentation/combine/cancellable)

---

**마지막 업데이트**: 2025-12-30  
**작성자**: GitHub Copilot
