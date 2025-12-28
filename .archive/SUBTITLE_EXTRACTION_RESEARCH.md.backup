# 🔍 YouTube 자막 추출 방법 조사

**작성일**: 2025-12-28  
**목적**: English Shadowing 앱에 자막 자동 추출 기능 추가

---

## 목차

1. [조사 개요](#1-조사-개요)
2. [방법 비교](#2-방법-비교)
3. [추천 솔루션](#3-추천-솔루션)
4. [구현 방법](#4-구현-방법)
5. [법적 고려사항](#5-법적-고려사항)

---

## 1. 조사 개요

### 1.1 현재 상황
- ✅ **구현됨**: 사용자가 문장을 수동으로 입력
- ❌ **미구현**: YouTube 자막 자동 추출
- 🎯 **목표**: 사용자 편의성 향상을 위한 자동 자막 추출

### 1.2 요구사항
- macOS 15.0+ Swift 앱에서 작동
- App Store 정책 준수
- 신뢰성 및 유지보수성
- 최소한의 외부 의존성

---

## 2. 방법 비교

### 2.1 방법론 개요

```mermaid
graph TB
    A[YouTube 자막 추출 방법]
    
    A --> B[1. Swift Native Library]
    A --> C[2. REST API Services]
    A --> D[3. YouTube Data API v3]
    A --> E[4. Web Scraping]
    A --> F[5. 사용자 수동 입력]
    
    B --> B1[swift-youtube-transcript]
    C --> C1[TranscriptAPI.com]
    C --> C2[ScrapeCreators API]
    D --> D1[OAuth 2.0 필요]
    E --> E1[URLSession + HTML 파싱]
    F --> F1[현재 구현 방식]
    
    style B fill:#C8E6C9
    style C fill:#B3E5FC
    style D fill:#FFE0B2
    style E fill:#FFCDD2
    style F fill:#E0E0E0
```

---

### 2.2 방법별 상세 분석

| 방법 | 난이도 | 신뢰성 | 비용 | App Store 안전성 | 추천도 |
|------|--------|--------|------|------------------|--------|
| **swift-youtube-transcript** | ⭐⭐ | ⭐⭐⭐ | 무료 | ✅ | ⭐⭐⭐⭐⭐ |
| **REST API (TranscriptAPI)** | ⭐ | ⭐⭐⭐⭐⭐ | 유료 | ✅ | ⭐⭐⭐⭐ |
| **YouTube Data API v3** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 무료* | ✅ | ⭐⭐ |
| **Web Scraping (Manual)** | ⭐⭐⭐ | ⭐⭐ | 무료 | ⚠️ | ⭐⭐ |
| **사용자 수동 입력 (현재)** | - | ⭐⭐⭐⭐⭐ | 무료 | ✅ | ⭐⭐⭐ |

*YouTube Data API v3는 할당량 제한 있음 (일 10,000 units)

---

### 2.3 각 방법 세부 설명

#### 방법 1: swift-youtube-transcript (네이티브 Swift 라이브러리)

**GitHub**: [spaceman1412/swift-youtube-transcript](https://github.com/spaceman1412/swift-youtube-transcript)

**장점**:
- ✅ 순수 Swift 패키지 (SPM 지원)
- ✅ async/await 지원
- ✅ iOS, macOS, tvOS, watchOS 호환
- ✅ 언어 선택 가능
- ✅ 무료 & 오픈소스
- ✅ 외부 서버 불필요

**단점**:
- ⚠️ 비공식 API (YouTube 변경 시 깨질 수 있음)
- ⚠️ Rate limiting 위험
- ⚠️ 자막이 없는 영상은 실패

**적합성**: ⭐⭐⭐⭐⭐ (최고 추천)

**예시 코드**:
```swift
import YoutubeTranscript

Task {
    do {
        let transcript = try await YoutubeTranscript.fetchTranscript(for: "dQw4w9WgXcQ")
        for entry in transcript {
            print("\(entry.offset)s: \(entry.text)")
        }
    } catch {
        print("Failed to fetch transcript: \(error)")
    }
}
```

**출력 형식**:
```swift
struct TranscriptEntry {
    let offset: TimeInterval  // 시작 시간 (초)
    let duration: TimeInterval  // 길이
    let text: String  // 자막 텍스트
}
```

---

#### 방법 2: REST API Services (TranscriptAPI, ScrapeCreators)

**서비스 비교**:

| 서비스 | 가격 | 무료 한도 | 특징 |
|--------|------|-----------|------|
| [TranscriptAPI.com](https://transcriptapi.com) | $0.01/request | 100 req/월 | 안정적, 다양한 형식 |
| [ScrapeCreators](https://scrapecreators.com) | 유료 | 제한적 | Swift 튜토리얼 제공 |
| [Apify](https://apify.com) | 사용량 기반 | Free tier | 배치 처리 강력 |

**장점**:
- ✅ 매우 안정적
- ✅ 프로덕션 레벨 신뢰성
- ✅ YouTube 변경 시 서비스 측에서 대응
- ✅ 다양한 출력 형식 (SRT, VTT, JSON)
- ✅ Rate limiting 처리됨

**단점**:
- ❌ 비용 발생 (무료 한도 초과 시)
- ❌ 인터넷 연결 필수
- ❌ 외부 서비스 의존성

**적합성**: ⭐⭐⭐⭐ (상업용 앱에 적합)

**예시 코드**:
```swift
struct TranscriptAPIService {
    let apiKey: String = "YOUR_API_KEY"
    let baseURL = "https://api.transcriptapi.com/v1/transcript"
    
    func fetchTranscript(videoID: String) async throws -> [TranscriptEntry] {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "video_id", value: videoID),
            URLQueryItem(name: "format", value: "json")
        ]
        
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(TranscriptResponse.self, from: data)
        
        return response.transcript
    }
}
```

---

#### 방법 3: YouTube Data API v3 (공식 API)

**API 문서**: [Captions: download](https://developers.google.com/youtube/v3/docs/captions/download)

**장점**:
- ✅ YouTube 공식 API
- ✅ 법적으로 안전
- ✅ 신뢰성 최고

**단점**:
- ❌ OAuth 2.0 인증 필수 (복잡함)
- ❌ **자신이 소유한 영상만 가능** (치명적 제약)
- ❌ 일일 할당량 제한 (10,000 units)
- ❌ 사용자가 Google 계정 로그인 필요

**적합성**: ⭐⭐ (우리 앱에는 부적합)

**이유**: 
> **⚠️ 치명적 제한**: YouTube Data API의 `captions.download` 엔드포인트는 **본인이 업로드한 영상의 자막만** 다운로드 가능합니다. 즉, 다른 사람의 YouTube 영상에서는 자막을 가져올 수 없어 우리 앱의 목적과 맞지 않습니다.

---

#### 방법 4: Web Scraping (수동 구현)

**원리**: YouTube의 Transcript 페이지를 HTML 파싱

**장점**:
- ✅ 무료
- ✅ 외부 라이브러리 최소화

**단점**:
- ❌ YouTube UI 변경 시 깨짐 (높은 유지보수 비용)
- ❌ Rate limiting 위험
- ❌ 법적 회색지대
- ❌ App Store 거부 가능성 (스크래핑 정책)

**적합성**: ⭐⭐ (비추천)

**예시 구조**:
```swift
// SwiftSoup 사용 (HTML 파싱)
import SwiftSoup

func scrapeTranscript(url: String) async throws -> String {
    let (data, _) = try await URLSession.shared.data(from: URL(string: url)!)
    let html = String(data: data, encoding: .utf8)!
    let doc = try SwiftSoup.parse(html)
    
    // YouTube의 transcript 버튼 클릭 시뮬레이션 필요
    // → 복잡하고 불안정함
}
```

---

#### 방법 5: 사용자 수동 입력 (현재 방식)

**현재 구현**:
- 사용자가 `NewSessionView`에서 텍스트 직접 입력
- 타이밍 자동 계산

**장점**:
- ✅ 100% 신뢰성
- ✅ 법적으로 안전
- ✅ 추가 의존성 없음
- ✅ App Store 정책 준수

**단점**:
- ❌ 사용자 불편함
- ❌ 진입 장벽

**적합성**: ⭐⭐⭐ (현재 유지, 추후 자동화 추가)

---

## 3. 추천 솔루션

### 3.1 최종 추천: swift-youtube-transcript

**이유**:
1. ✅ **Swift 네이티브**: 별도 서버/API 불필요
2. ✅ **무료**: 비용 부담 없음
3. ✅ **간단한 통합**: SPM으로 1분 내 추가
4. ✅ **App Store 안전**: 공식 정책 위반 없음
5. ✅ **async/await**: 최신 Swift 문법 지원

**구현 전략**:
```
사용자 수동 입력 (Fallback) + swift-youtube-transcript (자동)
```

즉, 자동 추출 실패 시 사용자가 직접 입력할 수 있도록 하이브리드 방식 채택.

---

### 3.2 대안: TranscriptAPI (상업용 앱)

**App Store 출시 후 수익화 시 고려**:
- 월 $10 ~ $50 정도로 안정적인 서비스 이용
- 프로덕션 레벨 신뢰성
- YouTube 변경에도 안정적

---

## 4. 구현 방법

### 4.1 swift-youtube-transcript 통합

#### Step 1: SPM 추가

**Package.swift**:
```swift
dependencies: [
    .package(url: "https://github.com/spaceman1412/swift-youtube-transcript", from: "1.0.0")
]
```

**Xcode**:
1. File → Add Package Dependencies...
2. URL 입력: `https://github.com/spaceman1412/swift-youtube-transcript`
3. Add to Target: EnglishShadowing

---

#### Step 2: Service 클래스 생성

**파일 위치**: `Services/TranscriptService.swift`

```swift
import Foundation
import YoutubeTranscript

@MainActor
class TranscriptService {
    static let shared = TranscriptService()
    
    enum TranscriptError: LocalizedError {
        case notAvailable
        case networkError(Error)
        case parsingError
        
        var errorDescription: String? {
            switch self {
            case .notAvailable:
                return "이 영상은 자막을 제공하지 않습니다"
            case .networkError(let error):
                return "네트워크 오류: \(error.localizedDescription)"
            case .parsingError:
                return "자막 파싱 중 오류가 발생했습니다"
            }
        }
    }
    
    /// YouTube Video ID로 자막 추출
    func fetchTranscript(videoID: String, language: String = "en") async throws -> [SentenceItem] {
        do {
            // 1. YoutubeTranscript로 자막 가져오기
            let transcript = try await YoutubeTranscript.fetchTranscript(
                for: videoID,
                language: language
            )
            
            // 2. TranscriptEntry → SentenceItem 변환
            let sentences = transcript.map { entry in
                SentenceItem(
                    text: entry.text.trimmingCharacters(in: .whitespacesAndNewlines),
                    startTime: entry.offset,
                    endTime: entry.offset + entry.duration
                )
            }
            
            // 3. 빈 문장 제거
            return sentences.filter { !$0.text.isEmpty }
            
        } catch let error as YoutubeTranscriptError {
            switch error {
            case .transcriptNotAvailable:
                throw TranscriptError.notAvailable
            default:
                throw TranscriptError.networkError(error)
            }
        } catch {
            throw TranscriptError.networkError(error)
        }
    }
    
    /// 자막 병합 (짧은 자막들을 문장 단위로 합치기)
    func mergeSentences(_ sentences: [SentenceItem], maxDuration: TimeInterval = 10.0) -> [SentenceItem] {
        var merged: [SentenceItem] = []
        var currentText = ""
        var currentStart: TimeInterval = 0
        var currentEnd: TimeInterval = 0
        
        for sentence in sentences {
            // 첫 문장
            if currentText.isEmpty {
                currentText = sentence.text
                currentStart = sentence.startTime
                currentEnd = sentence.endTime
                continue
            }
            
            // 문장 종결 부호로 끝나거나 최대 길이 초과 시 분리
            if currentText.hasSuffix(".") || currentText.hasSuffix("!") || currentText.hasSuffix("?") ||
               (currentEnd - currentStart) >= maxDuration {
                
                merged.append(SentenceItem(
                    text: currentText,
                    startTime: currentStart,
                    endTime: currentEnd
                ))
                
                currentText = sentence.text
                currentStart = sentence.startTime
                currentEnd = sentence.endTime
            } else {
                // 계속 이어붙이기
                currentText += " " + sentence.text
                currentEnd = sentence.endTime
            }
        }
        
        // 마지막 문장 추가
        if !currentText.isEmpty {
            merged.append(SentenceItem(
                text: currentText,
                startTime: currentStart,
                endTime: currentEnd
            ))
        }
        
        return merged
    }
}
```

---

#### Step 3: NewSessionView 수정

**하이브리드 방식: 자동 추출 + 수동 입력**

```swift
struct NewSessionView: View {
    @State private var isLoadingTranscript = false
    @State private var transcriptError: String?
    @State private var autoExtractEnabled = true
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // YouTube URL 입력
                    VStack(alignment: .leading, spacing: 8) {
                        Label("YouTube URL", systemImage: "link")
                            .font(.headline)
                        
                        HStack {
                            TextField("https://www.youtube.com/watch?v=...", text: $youtubeURL)
                                .textFieldStyle(.roundedBorder)
                            
                            // 자동 추출 버튼
                            if let videoID = VideoIDExtractor.extractVideoID(from: youtubeURL) {
                                Button {
                                    Task {
                                        await autoExtractTranscript(videoID: videoID)
                                    }
                                } label: {
                                    if isLoadingTranscript {
                                        ProgressView()
                                            .controlSize(.small)
                                    } else {
                                        Label("자막 추출", systemImage: "text.bubble")
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(isLoadingTranscript)
                            }
                        }
                        
                        // 에러 메시지
                        if let error = transcriptError {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(12)
                    
                    // 문장 입력 (자동 추출 또는 수동)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("학습할 문장", systemImage: "text.quote")
                                .font(.headline)
                            
                            Spacer()
                            
                            if !sentencesText.isEmpty {
                                Text("\(sentencesCount) 문장")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        TextEditor(text: $sentencesText)
                            .frame(minHeight: 200)
                            .font(.body)
                            .padding(8)
                            .background(Color(nsColor: .textBackgroundColor))
                            .cornerRadius(8)
                    }
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(12)
                    
                    // ... 나머지 UI
                }
            }
        }
    }
    
    // 자동 자막 추출
    private func autoExtractTranscript(videoID: String) async {
        isLoadingTranscript = true
        transcriptError = nil
        
        do {
            let sentences = try await TranscriptService.shared.fetchTranscript(videoID: videoID)
            
            // 문장 병합 (짧은 자막들을 합침)
            let merged = TranscriptService.shared.mergeSentences(sentences)
            
            // TextEditor에 표시
            await MainActor.run {
                sentencesText = merged.map { $0.text }.joined(separator: "\n")
                isLoadingTranscript = false
            }
            
        } catch let error as TranscriptService.TranscriptError {
            await MainActor.run {
                transcriptError = error.localizedDescription
                isLoadingTranscript = false
            }
        } catch {
            await MainActor.run {
                transcriptError = "알 수 없는 오류가 발생했습니다"
                isLoadingTranscript = false
            }
        }
    }
}
```

---

### 4.2 UI 플로우

```mermaid
sequenceDiagram
    participant User
    participant NewSessionView
    participant TranscriptService
    participant YoutubeTranscript
    participant YouTube
    
    User->>NewSessionView: YouTube URL 입력
    NewSessionView->>NewSessionView: Video ID 추출
    User->>NewSessionView: "자막 추출" 버튼 클릭
    
    NewSessionView->>TranscriptService: fetchTranscript(videoID)
    TranscriptService->>YoutubeTranscript: fetchTranscript(for:)
    YoutubeTranscript->>YouTube: HTTP Request
    
    alt 자막 있음
        YouTube-->>YoutubeTranscript: Transcript Data
        YoutubeTranscript-->>TranscriptService: [TranscriptEntry]
        TranscriptService->>TranscriptService: mergeSentences()
        TranscriptService-->>NewSessionView: [SentenceItem]
        NewSessionView->>User: 자막 표시 ✅
    else 자막 없음
        YouTube-->>YoutubeTranscript: 404 / No Transcript
        YoutubeTranscript-->>TranscriptService: Error
        TranscriptService-->>NewSessionView: TranscriptError
        NewSessionView->>User: 에러 메시지 + 수동 입력 안내
    end
    
    User->>NewSessionView: 필요시 수정
    User->>NewSessionView: "생성" 버튼
    NewSessionView->>NavigationViewModel: createNewSession()
```

---

### 4.3 에러 처리

**사용자에게 친화적인 메시지**:

```swift
extension TranscriptService.TranscriptError {
    var userFriendlyMessage: String {
        switch self {
        case .notAvailable:
            return """
            이 영상은 자막을 제공하지 않습니다.
            아래 텍스트 영역에 직접 문장을 입력해주세요.
            """
        case .networkError:
            return """
            네트워크 연결을 확인해주세요.
            인터넷 연결 후 다시 시도하거나 수동으로 입력할 수 있습니다.
            """
        case .parsingError:
            return """
            자막 형식을 인식할 수 없습니다.
            수동으로 문장을 입력해주세요.
            """
        }
    }
}
```

---

### 4.4 테스트 케이스

**파일 위치**: `Tests/TranscriptServiceTests.swift`

```swift
import XCTest
@testable import EnglishShadowing

final class TranscriptServiceTests: XCTestCase {
    let service = TranscriptService.shared
    
    // 실제 YouTube 영상으로 테스트
    func testFetchTranscript() async throws {
        let videoID = "dQw4w9WgXcQ"  // Rick Astley - Never Gonna Give You Up
        
        let sentences = try await service.fetchTranscript(videoID: videoID)
        
        XCTAssertFalse(sentences.isEmpty, "자막이 비어있으면 안됩니다")
        XCTAssertTrue(sentences.first!.text.count > 0, "첫 문장이 있어야 합니다")
        XCTAssertTrue(sentences.first!.startTime >= 0, "시작 시간은 0 이상이어야 합니다")
    }
    
    func testMergeSentences() {
        let shortSentences = [
            SentenceItem(text: "Hello", startTime: 0, endTime: 1),
            SentenceItem(text: "world", startTime: 1, endTime: 2),
            SentenceItem(text: "this is", startTime: 2, endTime: 3),
            SentenceItem(text: "a test.", startTime: 3, endTime: 4)
        ]
        
        let merged = service.mergeSentences(shortSentences)
        
        XCTAssertEqual(merged.count, 1, "짧은 문장들이 하나로 합쳐져야 합니다")
        XCTAssertEqual(merged.first!.text, "Hello world this is a test.")
    }
    
    func testInvalidVideoID() async {
        let invalidID = "INVALID_VIDEO_ID_12345"
        
        do {
            _ = try await service.fetchTranscript(videoID: invalidID)
            XCTFail("유효하지 않은 Video ID는 에러를 던져야 합니다")
        } catch {
            // 에러 발생 예상
            XCTAssertTrue(true)
        }
    }
}
```

---

## 5. 법적 고려사항

### 5.1 YouTube 서비스 약관

**허용되는 사용**:
- ✅ 개인적 학습 목적
- ✅ 접근성 향상 (자막 활용)
- ✅ 비상업적 교육 목적

**금지되는 사용**:
- ❌ 영상 다운로드 및 재배포
- ❌ 자막 상업적 재판매
- ❌ YouTube 서비스 우회

**우리 앱의 경우**:
✅ **안전**: YouTube 영상을 직접 스트리밍하며, 자막은 학습 보조 목적으로만 사용

---

### 5.2 App Store 정책

**App Store Review Guidelines 5.2.3**:
> Apps may not use third-party services to download content in a manner that violates YouTube's terms of service.

**우리 앱의 준수 사항**:
- ✅ 영상 다운로드 없음 (YouTubePlayerKit 사용)
- ✅ 자막 추출은 공개된 데이터 활용
- ✅ 교육 목적 명시
- ✅ 저작권 존중

---

### 5.3 라이센스 표시

**About 창에 추가**:

```
이 앱은 다음 오픈소스 라이브러리를 사용합니다:

• swift-youtube-transcript (MIT License)
  by spaceman1412
  https://github.com/spaceman1412/swift-youtube-transcript
  
자막 추출 기능은 YouTube의 공개 자막 데이터를 활용하며,
개인 학습 목적으로만 사용됩니다. 영상 저작권은 원 제작자에게 있습니다.
```

---

## 6. 구현 일정

### Phase 1: 기본 통합 (1-2일)
- [ ] swift-youtube-transcript SPM 추가
- [ ] TranscriptService 클래스 생성
- [ ] 기본 자막 추출 테스트

### Phase 2: UI 통합 (2-3일)
- [ ] NewSessionView에 "자막 추출" 버튼 추가
- [ ] 로딩 상태 표시
- [ ] 에러 처리 UI

### Phase 3: UX 개선 (1-2일)
- [ ] 문장 병합 로직 최적화
- [ ] 자동/수동 전환 UX
- [ ] 언어 선택 기능

### Phase 4: 테스트 & 문서화 (1일)
- [ ] 다양한 영상으로 테스트
- [ ] 사용자 가이드 작성
- [ ] 에러 케이스 처리

**총 예상 기간**: 5-8일

---

## 7. 대안 시나리오

### 7.1 swift-youtube-transcript 실패 시

**백업 플랜**:
1. **TranscriptAPI.com 유료 플랜**
   - 월 $10 (1,000 requests)
   - 안정적인 프로덕션 레벨 서비스

2. **사용자 수동 입력 유지**
   - 현재 방식 계속 사용
   - 자막 붙여넣기 가이드 제공

---

### 7.2 App Store 거부 시

**대응 방안**:
1. **교육 목적 강조**
   - App 설명에 학습 도구임을 명시
   - 스크린샷에 교육 콘텐츠 사용

2. **자막 사용 동의**
   - 첫 실행 시 "자막 사용 동의" 팝업
   - 개인 학습 목적임을 사용자가 확인

---

## 8. 결론

### 8.1 최종 결정

**✅ swift-youtube-transcript 채택**

**이유**:
1. Swift 네이티브 솔루션
2. 무료 & 오픈소스
3. 간단한 통합
4. App Store 정책 준수
5. Fallback 전략 (수동 입력) 병행

---

### 8.2 예상 효과

**사용자 경험 개선**:
- ⚡ 빠른 세션 생성 (1분 → 10초)
- 🎯 정확한 타이밍 (자동 추출)
- 😊 사용자 만족도 ↑

**앱 경쟁력**:
- 🚀 차별화된 기능
- 📈 App Store 평가 개선 예상
- 💡 향후 기능 확장 기반

---

**다음 단계**: 
1. swift-youtube-transcript 테스트
2. TranscriptService 구현
3. NewSessionView UI 업데이트

---

**작성자**: GitHub Copilot CLI  
**참고 자료**:
- [swift-youtube-transcript GitHub](https://github.com/spaceman1412/swift-youtube-transcript)
- [YouTube Data API v3 Documentation](https://developers.google.com/youtube/v3)
- [TranscriptAPI.com](https://transcriptapi.com)
