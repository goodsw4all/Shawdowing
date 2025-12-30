# API 레퍼런스

> 모든 public API의 상세 문서

## 📱 ShadowingViewModel

### Properties (속성)

#### @Published 속성 (View가 관찰 가능)

##### `session: ShadowingSession`
현재 학습 중인 세션 정보

**타입**: `ShadowingSession`  
**초기값**: init 시 전달받음  
**용도**: 비디오 정보, 문장 목록, 학습 진행 상태 포함

```swift
// 사용 예시
Text(viewModel.session.video.title ?? "제목 없음")
Text("문장 수: \(viewModel.session.sentences.count)")
```

##### `currentSentenceIndex: Int`
현재 재생 중인 문장의 인덱스

**타입**: `Int`  
**초기값**: `0`  
**범위**: `0 ..< session.sentences.count`  
**용도**: 현재 문장 추적, UI 하이라이트

```swift
// 사용 예시
if viewModel.currentSentenceIndex == index {
    // 현재 재생 중인 문장 스타일 적용
}
```

##### `isPlaying: Bool`
비디오 재생 상태

**타입**: `Bool`  
**초기값**: `false`  
**용도**: 재생/일시정지 UI 표시, AVPlayer 제어

```swift
// 사용 예시
Button {
    viewModel.togglePlayPause()
} label: {
    Image(systemName: viewModel.isPlaying ? "pause" : "play")
}
```

##### `currentTime: TimeInterval`
현재 비디오 재생 시간 (초 단위)

**타입**: `TimeInterval` (= `Double`)  
**초기값**: `0.0`  
**단위**: 초 (seconds)  
**업데이트**: 0.1초마다 AVPlayer에서 자동 업데이트  
**용도**: 진행 표시, 문장 동기화

```swift
// 사용 예시
Text("재생 시간: \(Int(viewModel.currentTime))초")
```

##### `playbackRate: Double`
재생 속도 배율

**타입**: `Double`  
**초기값**: `1.0`  
**범위**: `0.5 ... 2.0` (권장)  
**용도**: 재생 속도 조절

```swift
// 사용 예시
ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { rate in
    Button("\(rate)x") {
        viewModel.setPlaybackRate(rate)
    }
}
```

##### `repeatCount: Int`
현재 문장의 반복 재생 횟수

**타입**: `Int`  
**초기값**: `0`  
**용도**: 반복 재생 진행 상태 표시

```swift
// 사용 예시
Text("반복: \(viewModel.repeatCount)/5")
```

##### `isLooping: Bool`
반복 재생 모드 활성화 여부

**타입**: `Bool`  
**초기값**: `false`  
**용도**: 반복 중 UI 변경, 중지 버튼 표시

```swift
// 사용 예시
if viewModel.isLooping {
    Button("중지") {
        viewModel.cancelLoop()
    }
}
```

#### Computed Properties (계산된 속성)

##### `currentSentence: SentenceItem?`
현재 재생 중인 문장 객체

**타입**: `SentenceItem?`  
**읽기 전용**: get only  
**nil 조건**: `currentSentenceIndex`가 범위 벗어남  
**용도**: 현재 문장 정보 표시

```swift
// 사용 예시
if let sentence = viewModel.currentSentence {
    Text(sentence.text)
    Text("\(sentence.startTime) - \(sentence.endTime)")
}
```

##### `isLastSentence: Bool`
마지막 문장인지 여부

**타입**: `Bool`  
**읽기 전용**: get only  
**용도**: "다음" 버튼 비활성화

```swift
// 사용 예시
Button("다음") {
    viewModel.nextSentence()
}
.disabled(viewModel.isLastSentence)
```

##### `completedCount: Int`
완료된 문장 개수

**타입**: `Int`  
**읽기 전용**: get only  
**계산**: `session.completedSentences.count`

```swift
// 사용 예시
Text("완료: \(viewModel.completedCount)/\(viewModel.totalCount)")
```

##### `totalCount: Int`
전체 문장 개수

**타입**: `Int`  
**읽기 전용**: get only  
**계산**: `session.sentences.count`

##### `progressPercentage: Int`
학습 진행률 (백분율)

**타입**: `Int`  
**읽기 전용**: get only  
**범위**: `0 ... 100`  
**계산**: `Int(session.progress * 100)`

```swift
// 사용 예시
Text("진행률: \(viewModel.progressPercentage)%")
ProgressView(value: Double(viewModel.progressPercentage) / 100.0)
```

### Methods (메서드)

#### Filtering (필터링)

##### `filteredSentences(showFavoritesOnly:hideCompleted:)`
문장 목록을 필터링하여 반환

```swift
func filteredSentences(
    showFavoritesOnly: Bool,
    hideCompleted: Bool
) -> [(index: Int, sentence: SentenceItem)]
```

**파라미터**:
- `showFavoritesOnly`: `true`면 즐겨찾기한 문장만 표시
- `hideCompleted`: `true`면 완료한 문장 숨기기

**반환값**: 튜플 배열
- `index`: 원본 배열에서의 인덱스 (0부터 시작)
- `sentence`: 문장 객체

**용도**: 문장 목록 UI에서 필터링된 결과 표시

**예시**:
```swift
let filtered = viewModel.filteredSentences(
    showFavoritesOnly: showFavoritesOnly,
    hideCompleted: hideCompleted
)

List(filtered, id: \.sentence.id) { item in
    SentenceRow(
        sentence: item.sentence,
        onTap: {
            viewModel.currentSentenceIndex = item.index
            viewModel.seekAndPlay()
        }
    )
}
```

#### Playback Controls (재생 제어)

##### `play()`
비디오 재생 시작

```swift
func play()
```

**동작**:
1. `hasAutoPaused` 플래그 초기화
2. `isPlaying = true` (View가 관찰)
3. CustomYouTubePlayer가 AVPlayer.play() 호출

**용도**: Play 버튼 동작

**예시**:
```swift
Button("재생") {
    viewModel.play()
}
```

##### `pause()`
비디오 일시정지

```swift
func pause()
```

**동작**:
1. `isPlaying = false`
2. CustomYouTubePlayer가 AVPlayer.pause() 호출

**용도**: Pause 버튼 동작

##### `togglePlayPause()`
재생/일시정지 토글

```swift
func togglePlayPause()
```

**동작**:
- `isPlaying == true` → `pause()` 호출
- `isPlaying == false` → `play()` 호출

**용도**: 단일 버튼으로 재생/일시정지 전환

**예시**:
```swift
Button {
    viewModel.togglePlayPause()
} label: {
    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
}
```

#### Sentence Navigation (문장 이동)

##### `nextSentence()`
다음 문장으로 이동

```swift
func nextSentence()
```

**전제 조건**: `currentSentenceIndex < sentences.count - 1`

**동작**:
1. `currentSentenceIndex += 1`
2. `repeatCount = 0` 초기화
3. `hasAutoPaused = false`
4. `seekToCurrentSentence()` 호출

**용도**: "다음" 버튼

**예시**:
```swift
Button("다음") {
    viewModel.nextSentence()
}
.disabled(viewModel.isLastSentence)
```

##### `previousSentence()`
이전 문장으로 이동

```swift
func previousSentence()
```

**전제 조건**: `currentSentenceIndex > 0`

**동작**:
1. `currentSentenceIndex -= 1`
2. `repeatCount = 0` 초기화
3. `hasAutoPaused = false`
4. `seekToCurrentSentence()` 호출

**용도**: "이전" 버튼

##### `seekAndPlay()`
현재 문장 처음부터 재생

```swift
func seekAndPlay()
```

**동작** (비동기):
1. `isManualSeeking = true`
2. `hasAutoPaused = false`
3. `isPlaying = false` (일시정지)
4. 100ms 대기
5. `currentTime = sentence.startTime` (seek)
6. 100ms 대기
7. `isPlaying = true` (재생)
8. 500ms 후 `isManualSeeking = false`

**용도**: 자막 클릭 시, 반복 버튼

**예시**:
```swift
Button(action: viewModel.seekAndPlay) {
    Text(sentence.text)
}
```

#### Loop Control (반복 재생)

##### `loopCurrentSentence(times:)`
현재 문장을 N회 반복 재생

```swift
func loopCurrentSentence(times: Int)
```

**파라미터**:
- `times`: 반복 횟수 (1, 3, 5, 10 등)

**동작** (비동기):
1. 기존 반복 취소 (`cancelLoop()`)
2. `isLooping = true`
3. `hasAutoPaused = false`
4. N회 반복:
   - Seek to start
   - Play
   - 문장 길이만큼 대기
   - Pause
   - 1초 대기
5. 완료 후 `isLooping = false`

**예시**:
```swift
Menu {
    Button("3회 반복") {
        viewModel.loopCurrentSentence(times: 3)
    }
    Button("5회 반복") {
        viewModel.loopCurrentSentence(times: 5)
    }
} label: {
    Label("반복", systemImage: "repeat")
}
```

##### `cancelLoop()`
반복 재생 중지

```swift
func cancelLoop()
```

**동작**:
1. `loopTask?.cancel()` (Task 취소)
2. `loopTask = nil`
3. `isLooping = false`

**용도**: 반복 중 "중지" 버튼

#### Sentence Management (문장 관리)

##### `toggleFavoriteSentence()`
현재 문장 즐겨찾기 토글

```swift
func toggleFavoriteSentence()
```

**동작**:
1. `sentence.isFavorite.toggle()`
2. `saveSession()` 호출 (자동 저장)
3. `objectWillChange.send()` (UI 업데이트)

**예시**:
```swift
Button(action: viewModel.toggleFavoriteSentence) {
    Image(systemName: viewModel.currentSentence?.isFavorite == true ? "star.fill" : "star")
}
```

##### `markCurrentSentenceCompleted()`
현재 문장 완료 표시

```swift
func markCurrentSentenceCompleted()
```

**동작**:
1. `session.completedSentences.insert(sentence.id)`
2. `sentence.isCompleted = true`
3. `saveSession()` 호출
4. `objectWillChange.send()`

**예시**:
```swift
Button(action: viewModel.markCurrentSentenceCompleted) {
    Label("완료", systemImage: "checkmark")
}
```

##### `cycleProsodyScore(for:)`
프로소디 평가 점수 순환

```swift
func cycleProsodyScore(for metric: ProsodyMetric)
```

**파라미터**:
- `metric`: `.stress`, `.rhythm`, `.liaison` 중 하나

**동작**:
- `notEvaluated` → `needsPractice` → `confident` → `notEvaluated` 순환
- 자동 저장

**예시**:
```swift
Button {
    viewModel.cycleProsodyScore(for: .stress)
} label: {
    Text("강세: \(assessment.stress.rawValue)")
}
```

##### `setPlaybackRate(_:)`
재생 속도 설정

```swift
func setPlaybackRate(_ rate: Double)
```

**파라미터**:
- `rate`: 재생 속도 배율 (0.5 ~ 2.0 권장)

**동작**:
1. `playbackRate = rate`
2. CustomYouTubePlayer가 AVPlayer.rate 설정

**예시**:
```swift
Picker("속도", selection: $speed) {
    ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { rate in
        Text("\(rate)x").tag(rate)
    }
}
.onChange(of: speed) { newRate in
    viewModel.setPlaybackRate(newRate)
}
```

---

## 📦 Models

### SentenceItem

```swift
struct SentenceItem: Identifiable, Codable {
    let id: UUID
    let text: String
    let startTime: TimeInterval
    let endTime: TimeInterval
    var isCompleted: Bool
    var isFavorite: Bool
    var prosodyAssessment: ProsodyAssessment
}
```

### ShadowingSession

```swift
struct ShadowingSession: Identifiable, Codable {
    let id: UUID
    let video: YouTubeVideo
    var sentences: [SentenceItem]
    var completedSentences: Set<UUID>
    let createdAt: Date
    var lastAccessedAt: Date
    
    var progress: Double { 
        Double(completedSentences.count) / Double(sentences.count) 
    }
}
```

---

**마지막 업데이트**: 2025-12-30  
**작성자**: GitHub Copilot
