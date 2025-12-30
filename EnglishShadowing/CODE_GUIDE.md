# EnglishShadowing 코드 가이드

> 초보 Swift 개발자를 위한 코드 설명서

## 📚 목차

1. [프로젝트 구조](#프로젝트-구조)
2. [MVVM 아키텍처](#mvvm-아키텍처)
3. [주요 컴포넌트 설명](#주요-컴포넌트-설명)
4. [코드 읽는 순서](#코드-읽는-순서)
5. [자주 사용하는 패턴](#자주-사용하는-패턴)

## 프로젝트 구조

```
EnglishShadowing/
├── Models/              # 데이터 구조 정의
│   ├── ShadowingSession.swift    # 학습 세션 데이터
│   ├── SentenceItem.swift        # 문장 데이터
│   └── YouTubeVideo.swift        # 비디오 정보
│
├── ViewModels/          # 비즈니스 로직 (MVVM의 ViewModel)
│   └── ShadowingViewModel.swift  # 쉐도잉 화면 로직
│
├── Views/               # 화면 UI (MVVM의 View)
│   ├── Shadowing/
│   │   ├── ShadowingView.swift         # 메인 화면
│   │   └── Components/                  # 재사용 가능한 UI 조각들
│   │       ├── CurrentSentenceCard.swift
│   │       ├── SentenceRow.swift
│   │       ├── ControlPanelView.swift
│   │       └── ProsodyChecklistView.swift
│   └── Session/
│       └── NewSessionView.swift        # 세션 생성 화면
│
├── Services/            # 외부 기능 (네트워크, 저장소)
│   ├── StorageService.swift      # 파일 저장/로드
│   ├── TranscriptService.swift   # YouTube 자막 추출
│   └── YouTubeMetadataService.swift  # 비디오 정보 가져오기
│
└── Utilities/           # 공통 도구
    └── Color+Hex.swift          # Hex 컬러 확장
```

## MVVM 아키텍처

이 앱은 MVVM (Model-View-ViewModel) 패턴을 사용합니다.

### 🎯 Model (데이터)
**역할**: 앱에서 사용하는 데이터의 구조를 정의합니다.

```swift
// 예: SentenceItem.swift
struct SentenceItem {
    let text: String          // 문장 텍스트
    let startTime: Double     // 시작 시간
    let endTime: Double       // 종료 시간
    var isCompleted: Bool     // 완료 여부
    var isFavorite: Bool      // 즐겨찾기 여부
}
```

**특징**:
- ✅ 순수한 데이터만 포함
- ✅ 로직이 없음
- ✅ `struct`로 정의 (값 타입)

### 🧠 ViewModel (비즈니스 로직)
**역할**: 데이터를 처리하고 View에게 표시할 정보를 제공합니다.

```swift
// 예: ShadowingViewModel.swift
class ShadowingViewModel: ObservableObject {
    @Published var isPlaying: Bool = false     // View가 관찰하는 속성
    @Published var currentTime: Double = 0
    
    func play() {                              // View가 호출하는 메서드
        isPlaying = true
    }
    
    func pause() {
        isPlaying = false
    }
}
```

**특징**:
- ✅ `@Published`: 값이 변경되면 View가 자동으로 업데이트
- ✅ 비즈니스 로직 포함 (재생, 일시정지 등)
- ✅ `class`로 정의 (참조 타입)

### 🎨 View (UI)
**역할**: 사용자에게 보이는 화면을 그립니다.

```swift
// 예: ShadowingView.swift
struct ShadowingView: View {
    @StateObject var viewModel: ShadowingViewModel  // ViewModel 연결
    
    var body: some View {
        VStack {
            // UI 구성
            Button(action: viewModel.play) {
                Text(viewModel.isPlaying ? "일시정지" : "재생")
            }
        }
    }
}
```

**특징**:
- ✅ UI만 담당
- ✅ 비즈니스 로직은 ViewModel에 위임
- ✅ `@StateObject`, `@ObservedObject`로 ViewModel 관찰

## 주요 컴포넌트 설명

### 1. ShadowingViewModel.swift

앱의 핵심 비즈니스 로직을 담당합니다.

#### 주요 속성 (Properties)

```swift
// 📢 View가 관찰하는 속성들 (@Published)
@Published var isPlaying: Bool              // 재생 중인지 여부
@Published var currentTime: TimeInterval    // 현재 재생 시간 (초)
@Published var currentSentenceIndex: Int    // 현재 문장 번호 (0부터 시작)

// 🔒 내부에서만 사용하는 속성들 (private)
private var hasAutoPaused: Bool            // 자동 일시정지 완료 여부
private var isManualSeeking: Bool          // 수동으로 시간 이동 중인지
```

#### 주요 메서드 (Methods)

```swift
// ▶️ 재생 제어
func play()                    // 재생 시작
func pause()                   // 일시정지
func togglePlayPause()         // 재생/일시정지 토글

// ⏭ 문장 이동
func nextSentence()            // 다음 문장으로
func previousSentence()        // 이전 문장으로
func seekAndPlay()             // 현재 문장 처음부터 재생

// 🔄 반복 재생
func loopCurrentSentence(times: Int)  // N회 반복 재생
func cancelLoop()                     // 반복 중지

// ⭐️ 문장 관리
func toggleFavoriteSentence()        // 즐겨찾기 토글
func markCurrentSentenceCompleted()  // 완료 표시
```

### 2. ShadowingView.swift

메인 화면의 UI를 구성합니다.

#### 화면 구성 요소

```swift
VStack {
    // 1. YouTube 플레이어
    CustomYouTubePlayer(...)
    
    // 2. 세션 정보 (제목, 진행률)
    SessionInfoCard(...)
    
    // 3. 현재 문장 카드
    CurrentSentenceCard(...)
    
    // 4. 프로소디 체크리스트
    ProsodyChecklistView(...)
    
    // 5. 문장 목록
    List(filteredSentences) { sentence in
        SentenceRow(...)
    }
    
    // 6. 재생 컨트롤
    ControlPanelView(...)
}
```

#### 필터링 기능

```swift
// View에서 필터 상태 관리
@State private var showFavoritesOnly: Bool = false
@State private var hideCompleted: Bool = false

// ViewModel에서 필터링 수행
private var filteredSentences: [(index: Int, sentence: SentenceItem)] {
    viewModel.filteredSentences(
        showFavoritesOnly: showFavoritesOnly,
        hideCompleted: hideCompleted
    )
}
```

### 3. Components (재사용 가능한 UI 조각들)

#### CurrentSentenceCard.swift
현재 재생 중인 문장 정보를 카드로 표시

```swift
CurrentSentenceCard(
    sentence: currentSentence,    // 문장 객체
    repeatCount: 2,                // 현재 반복 횟수
    totalRepeats: 5                // 총 반복 목표
)
```

#### SentenceRow.swift
문장 목록의 각 행을 표시

```swift
SentenceRow(
    sentence: sentence,           // 문장 객체
    isCurrentlyPlaying: true,     // 현재 재생 중인지
    onTap: { /* 클릭 시 동작 */ },
    onFavorite: { /* 즐겨찾기 */ },
    onLoop: { times in /* 반복 */ }
)
```

#### ControlPanelView.swift
재생 컨트롤 버튼들 (재생, 일시정지, 이전, 다음 등)

#### ProsodyChecklistView.swift
발음 체크리스트 (강세, 리듬, 연음)

## 코드 읽는 순서

처음 코드를 읽을 때는 다음 순서를 추천합니다:

1. **Models 먼저** 📦
   - `ShadowingSession.swift` - 어떤 데이터를 다루는지 파악
   - `SentenceItem.swift`
   - `YouTubeVideo.swift`

2. **ViewModel** 🧠
   - `ShadowingViewModel.swift` - 어떤 기능이 있는지 파악
   - `@Published` 속성들 확인
   - `public` 메서드들 확인

3. **View** 🎨
   - `ShadowingView.swift` - 화면 구성 파악
   - 어떤 Component들을 사용하는지 확인

4. **Components** 🧩
   - 각 Component가 어떤 역할인지 확인
   - 재사용 가능한 단위 파악

5. **Services** 🛠
   - 외부 기능들 확인 (저장, 네트워크 등)

## 자주 사용하는 패턴

### 1. @Published와 @StateObject

```swift
// ViewModel에서
class MyViewModel: ObservableObject {
    @Published var count: Int = 0    // 변경되면 View에 알림
}

// View에서
struct MyView: View {
    @StateObject var viewModel = MyViewModel()  // ViewModel 소유
    
    var body: some View {
        Text("\(viewModel.count)")    // count가 변경되면 자동 업데이트
    }
}
```

### 2. Computed Property (계산된 속성)

```swift
var currentSentence: SentenceItem? {
    // getter만 있는 속성 (set 불가, get만 가능)
    guard currentSentenceIndex < sentences.count else { return nil }
    return sentences[currentSentenceIndex]
}

// 사용
let sentence = viewModel.currentSentence  // 매번 계산됨
```

### 3. @MainActor

```swift
@MainActor  // 이 클래스의 모든 작업은 메인 스레드에서 실행
class ShadowingViewModel: ObservableObject {
    // UI 업데이트는 반드시 메인 스레드에서!
}
```

### 4. weak self (메모리 누수 방지)

```swift
$currentTime
    .sink { [weak self] time in
        // self를 약하게 참조 → 순환 참조 방지
        self?.checkSentenceProgress(time: time)
    }
    .store(in: &cancellables)
```

### 5. Task (비동기 작업)

```swift
func seekAndPlay() {
    Task {
        // 비동기 작업
        try? await Task.sleep(for: .milliseconds(100))
        
        await MainActor.run {
            // 메인 스레드에서 실행
            self.currentTime = newTime
        }
    }
}
```

## 🎓 학습 팁

### 초보자를 위한 조언

1. **한 번에 하나씩**: 전체 코드를 이해하려고 하지 말고, 한 기능씩 따라가세요.

2. **디버깅 로그 활용**: 코드에 `print()` 문이 많이 있습니다. 실행해보면서 흐름을 파악하세요.

3. **Xcode 도움말**: 코드를 Option+클릭하면 문서를 볼 수 있습니다.

4. **작은 변경부터**: 코드를 수정하려면 작은 부분부터 시작하세요.

### 자주 보는 에러

#### 1. "Cannot find ... in scope"
→ import 문이 누락되었거나 파일이 프로젝트에 추가되지 않았습니다.

#### 2. "Type '...' has no member '...'"
→ 해당 타입에 그 속성/메서드가 없습니다. 철자를 확인하세요.

#### 3. "Value of type '...' has no subscripts"
→ 배열이나 딕셔너리가 아닌데 `[]`를 사용했습니다.

## 📞 도움이 필요하면

1. **코드 주석 읽기**: 대부분의 복잡한 로직에는 주석이 있습니다.
2. **Xcode 문서**: Option+클릭으로 Swift 공식 문서 확인
3. **Git 히스토리**: 코드가 왜 이렇게 작성되었는지 커밋 메시지 확인

---

**마지막 업데이트**: 2025-12-30  
**작성자**: GitHub Copilot
