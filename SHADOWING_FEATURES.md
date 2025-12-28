# 🎯 Shadowing 기능 구현 완료

**구현일**: 2025-12-28  
**버전**: 1.1.0

---

## 📋 구현된 기능

### 1. ✅ 자막 시간별 리스트 표시

**위치**: `ShadowingView.swift`

```swift
// 자막 리스트 섹션
VStack(alignment: .leading, spacing: 8) {
    HStack {
        Text("자막 리스트")
            .font(.headline)
        Spacer()
        // 필터 버튼들
    }
    
    ScrollViewReader { proxy in
        List(sentences) { sentence in
            SentenceRow(...)
        }
    }
}
```

**특징**:
- ✅ 시간 순서대로 정렬된 자막 리스트
- ✅ 현재 재생 중인 자막 하이라이트 (파란색 배경)
- ✅ 자동 스크롤 (재생 중인 자막으로)
- ✅ 타임스탬프 표시 (00:00 - 00:05)

---

### 2. ✅ 자막 클릭 시 이동 기능

**코드**:
```swift
SentenceRow(
    sentence: sentence,
    isCurrentlyPlaying: index == viewModel.currentSentenceIndex,
    onTap: {
        viewModel.currentSentenceIndex = index
        viewModel.seekToCurrentSentence()
    }
)
```

**동작**:
1. 사용자가 리스트에서 자막 클릭
2. `currentSentenceIndex` 업데이트
3. YouTube Player가 해당 시간으로 Seek
4. 자동으로 해당 문장 하이라이트

---

### 3. ✅ 자막 시간별 반복 기능

#### 3.1 단일 반복 (repeatCurrentSentence)
```swift
func repeatCurrentSentence() {
    repeatCount += 1
    Task {
        seekToCurrentSentence()
        try? await Task.sleep(for: .seconds(0.5))
        play()
    }
}
```

#### 3.2 다중 반복 (loopCurrentSentence)
```swift
func loopCurrentSentence(times: Int) {
    Task {
        for i in 0..<times {
            // 1. 시작 지점으로 Seek
            try? await player?.seek(to: .init(value: startTime, unit: .seconds))
            
            // 2. 재생
            try? await player?.play()
            
            // 3. 문장 길이만큼 대기
            try? await Task.sleep(for: .seconds(duration))
            
            // 4. 일시정지
            try? await player?.pause()
            
            // 5. 1초 대기 후 다음 반복
            if i < times - 1 {
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }
}
```

**사용 방법**:
- **컨트롤 패널**: "반복" 버튼 클릭 → 1/3/5/10회 선택
- **자막 리스트**: 각 자막 옆 반복 아이콘 클릭

**흐름도**:
```mermaid
sequenceDiagram
    participant User
    participant ViewModel
    participant YouTubePlayer
    
    User->>ViewModel: "3회 반복" 클릭
    loop 3번 반복
        ViewModel->>YouTubePlayer: seek(startTime)
        ViewModel->>YouTubePlayer: play()
        Note over ViewModel: 문장 길이만큼 대기
        ViewModel->>YouTubePlayer: pause()
        Note over ViewModel: 1초 대기
    end
    ViewModel->>User: 반복 완료 ✅
```

---

### 4. ✅ 특정 자막 문장 저장 (즐겨찾기)

#### 4.1 데이터 모델 확장
```swift
struct SentenceItem: Identifiable, Codable, Hashable {
    let id: UUID
    let text: String
    var startTime: TimeInterval
    var endTime: TimeInterval
    var isFavorite: Bool = false  // ⭐️ 즐겨찾기
    var notes: String = ""        // 메모 (향후 확장)
}
```

#### 4.2 즐겨찾기 토글
```swift
func toggleFavoriteSentence() {
    guard let sentence = currentSentence else { return }
    
    if let index = session.sentences.firstIndex(where: { $0.id == sentence.id }) {
        session.sentences[index].isFavorite.toggle()
        print("⭐️ Favorite toggled: \(session.sentences[index].isFavorite)")
    }
}
```

#### 4.3 즐겨찾기 리스트 (Sidebar)
```swift
var favoriteSentences: [(session: ShadowingSession, sentence: SentenceItem)] {
    let allSessions = activeSessions + history
    var favorites: [(ShadowingSession, SentenceItem)] = []
    
    for session in allSessions {
        let favs = session.sentences.filter { $0.isFavorite }
        for sentence in favs {
            favorites.append((session, sentence))
        }
    }
    
    return favorites
}
```

**Sidebar UI**:
```
📚 Library
├─ ✅ Active Sessions
├─ ⭐️ Favorites       ← 새로 추가!
│  ├─ "Hello, welcome..." (Video 1)
│  ├─ "This is amazing!" (Video 2)
│  └─ "Let's practice." (Video 3)
├─ ✅ History
└─ 📂 Playlists
```

---

## 🎨 UI/UX 개선사항

### 1. SentenceRow 컴포넌트 강화

**이전**:
```
[✓] Hello, welcome to this video.
    00:00 - 00:05
```

**현재**:
```
[⭐️] [✓] Hello, welcome to this video.  [🔁]
         00:00 - 00:05 ⭐️
```

**구성 요소**:
- ⭐️ **즐겨찾기 버튼**: 클릭 시 즐겨찾기 토글
- ✓ **완료 표시**: 학습 완료된 문장 체크
- 🔁 **반복 메뉴**: 1/3/5/10회 반복 선택
- 📍 **현재 재생 표시**: 파란색 배경 + 파형 아이콘

---

### 2. ControlPanelView 업데이트

**추가된 버튼**:
```
[◀◀] [▶/⏸] [▶▶] | [반복 ▼] [⭐️ 저장] [✓ 완료]
```

**반복 메뉴**:
- 1회 반복
- 3회 반복
- 5회 반복
- 10회 반복

---

### 3. 자막 리스트 헤더

**추가 기능**:
```
자막 리스트          [전체] [⭐️]
```

- **전체**: 모든 자막 표시
- **⭐️**: 즐겨찾기된 자막만 필터링 (향후 구현)

---

## 📊 기능 비교표

| 기능 | 이전 | 현재 | 개선점 |
|------|------|------|--------|
| **자막 리스트** | 기본 | 시간별 정렬 + 하이라이트 | ✅ 가독성 향상 |
| **클릭 이동** | ✅ | ✅ | 동일 |
| **반복 재생** | 1회만 | 1/3/5/10회 선택 | ✅ 유연성 향상 |
| **즐겨찾기** | ❌ | ⭐️ 저장 + Sidebar | ✅ 복습 용이 |
| **자동 스크롤** | ❌ | ✅ | ✅ UX 향상 |
| **재생 중 표시** | 텍스트만 | 배경 + 아이콘 | ✅ 시각적 피드백 |

---

## 🔄 데이터 흐름

### 즐겨찾기 저장 흐름
```mermaid
sequenceDiagram
    participant User
    participant ShadowingView
    participant ViewModel
    participant SentenceItem
    participant StorageService
    participant Sidebar
    
    User->>ShadowingView: "저장" 버튼 클릭
    ShadowingView->>ViewModel: toggleFavoriteSentence()
    ViewModel->>SentenceItem: isFavorite = true
    ViewModel->>StorageService: saveSession(session)
    StorageService-->>Sidebar: 데이터 업데이트
    Sidebar->>User: ⭐️ Favorites 섹션 업데이트
```

---

### 반복 재생 흐름
```mermaid
stateDiagram-v2
    [*] --> Idle: 사용자가 "3회 반복" 선택
    Idle --> SeekStart: Loop 1 시작
    SeekStart --> Playing: play()
    Playing --> Waiting: 문장 종료 대기
    Waiting --> Paused: pause()
    
    Paused --> SeekStart: Loop 2 (1초 후)
    Paused --> Complete: 3회 완료
    Complete --> [*]
```

---

## 🎯 사용자 시나리오

### 시나리오 1: 어려운 문장 집중 연습

1. **자막 리스트 탐색**
   - 스크롤하며 어려운 문장 찾기
   
2. **문장 클릭**
   - 해당 시간으로 즉시 이동
   
3. **반복 재생**
   - "5회 반복" 선택
   - 자동으로 5번 재생됨
   
4. **즐겨찾기 저장**
   - "저장" 버튼 클릭
   - 나중에 Sidebar에서 빠르게 접근

---

### 시나리오 2: 저장된 문장 복습

1. **Sidebar 열기**
   - ⭐️ Favorites 섹션 확인
   
2. **저장된 문장 클릭**
   - 원본 세션으로 이동
   - 해당 문장으로 자동 seek
   
3. **반복 학습**
   - 저장된 문장들을 순차적으로 복습

---

## 💡 향후 개선 사항

### Phase 2: 필터링 & 검색
- [ ] 즐겨찾기만 표시 필터
- [ ] 완료된 문장 숨기기
- [ ] 자막 텍스트 검색

### Phase 3: 고급 반복
- [ ] AB 구간 반복 (시작~끝 지점 설정)
- [ ] 반복 간격 조절 (1초 → 사용자 설정)
- [ ] 자동 진행 모드 (모든 문장 순차 반복)

### Phase 4: 메모 & 통계
- [ ] 문장별 메모 작성
- [ ] 반복 횟수 통계
- [ ] 학습 시간 추적

---

## 🐛 알려진 제약사항

1. **YouTube Player 제약**
   - Seek 정확도: ±0.5초 오차 가능
   - 버퍼링 시간 고려 필요

2. **반복 재생 중단**
   - 사용자가 수동으로 일시정지 시 반복 중단됨
   - → 향후 "반복 중단" 버튼 추가 예정

3. **즐겨찾기 동기화**
   - 현재 로컬 저장만 지원
   - iCloud 동기화는 Phase 3에서 구현 예정

---

## 📝 코드 변경 요약

### 수정된 파일
1. ✅ `SentenceItem.swift` - 즐겨찾기 필드 추가
2. ✅ `ShadowingViewModel.swift` - 반복/즐겨찾기 로직 추가
3. ✅ `ShadowingView.swift` - UI 컴포넌트 개선
4. ✅ `NavigationViewModel.swift` - 즐겨찾기 computed property
5. ✅ `SidebarView.swift` - Favorites 섹션 추가

### 새로 추가된 함수
```swift
// ShadowingViewModel.swift
func toggleFavoriteSentence()
func loopCurrentSentence(times: Int)

// NavigationViewModel.swift
var favoriteSentences: [(session, sentence)]
```

### 새로운 UI 컴포넌트
```swift
// SidebarView.swift
struct FavoriteSentenceRow: View
```

---

## ✅ 테스트 체크리스트

- [x] 자막 클릭 시 영상 이동
- [x] 1회 반복 재생
- [x] 3회 반복 재생 (자동)
- [x] 즐겨찾기 토글 동작
- [x] Sidebar에 즐겨찾기 표시
- [x] 현재 재생 중인 자막 하이라이트
- [x] 자동 스크롤 동작
- [ ] 즐겨찾기 필터링 (Phase 2)
- [ ] AB 구간 반복 (Phase 3)

---

**구현 완료일**: 2025-12-28  
**다음 단계**: 자막 자동 추출 기능 통합 (TranscriptService)
