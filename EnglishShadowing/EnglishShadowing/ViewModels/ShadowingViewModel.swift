//
//  ShadowingViewModel.swift
//  EnglishShadowing
//
//  Created by Myoungwoo Jang on 12/28/25.
//
//  역할: 쉐도잉 화면의 비즈니스 로직을 담당하는 ViewModel
//  - 비디오 재생 제어 (재생, 일시정지, 이동)
//  - 문장별 학습 진행 상태 관리
//  - 자동 일시정지 및 반복 재생 기능
//  - 즐겨찾기 및 완료 표시 관리
//

import Foundation
import Combine

/// 쉐도잉 학습 화면의 상태와 동작을 관리하는 ViewModel
///
/// 이 클래스는 다음 기능을 제공합니다:
/// - 비디오 재생 제어 (play, pause, seek)
/// - 문장 단위 학습 진행 추적
/// - 문장 끝에서 자동 일시정지
/// - N회 반복 재생
/// - 즐겨찾기 및 완료 상태 관리
@MainActor
class ShadowingViewModel: ObservableObject {
    
    // MARK: - Published Properties (View가 관찰하는 속성들)
    
    /// 현재 학습 중인 세션 정보
    @Published var session: ShadowingSession
    
    /// 현재 재생 중인 문장의 인덱스 (0부터 시작)
    @Published var currentSentenceIndex: Int = 0
    
    /// 비디오 재생 상태 (true: 재생 중, false: 일시정지)
    @Published var isPlaying: Bool = false
    
    /// 현재 비디오 재생 시간 (초 단위)
    @Published var currentTime: TimeInterval = 0
    
    /// 재생 속도 배율 (1.0 = 정상 속도, 0.5 = 느리게, 2.0 = 빠르게)
    @Published var playbackRate: Double = 1.0
    
    /// 현재 문장의 반복 재생 횟수 (루프 모드에서 사용)
    @Published var repeatCount: Int = 0
    
    /// 반복 재생 모드 활성화 여부
    @Published var isLooping: Bool = false
    
    // MARK: - Private Properties (내부에서만 사용하는 속성들)
    
    /// 플레이어 전역 설정
    private let playerSettings: PlayerSettings
    
    /// Combine 구독 관리를 위한 컬렉션
    private var cancellables = Set<AnyCancellable>()
    
    /// 반복 재생을 위한 비동기 Task
    private var loopTask: Task<Void, Never>?
    
    /// 수동 seek 작업 중인지 표시 (자동 동기화 방지용)
    private var isManualSeeking: Bool = false
    
    /// 자동 일시정지가 실행되었는지 표시 (중복 실행 방지용)
    private var hasAutoPaused: Bool = false
    
    // MARK: - Computed Properties (계산된 속성들)
    
    /// 현재 재생 중인 문장 객체
    /// - Returns: 현재 인덱스의 문장, 범위를 벗어나면 nil
    var currentSentence: SentenceItem? {
        guard currentSentenceIndex < session.sentences.count else { return nil }
        return session.sentences[currentSentenceIndex]
    }
    
    /// 마지막 문장인지 여부
    var isLastSentence: Bool {
        currentSentenceIndex >= session.sentences.count - 1
    }
    
    /// 완료된 문장 개수
    var completedCount: Int {
        session.completedSentences.count
    }
    
    /// 전체 문장 개수
    var totalCount: Int {
        session.sentences.count
    }
    
    /// 학습 진행률 (백분율)
    var progressPercentage: Int {
        Int(session.progress * 100)
    }
    
    // MARK: - Public Methods (View에서 호출하는 메서드들)
    
    /// 문장 목록을 필터링하여 반환
    ///
    /// - Parameters:
    ///   - showFavoritesOnly: true면 즐겨찾기한 문장만 표시
    ///   - hideCompleted: true면 완료한 문장 숨기기
    /// - Returns: 필터링된 문장 배열 (인덱스와 문장 객체 포함)
    ///
    /// 사용 예시:
    /// ```swift
    /// let filtered = viewModel.filteredSentences(
    ///     showFavoritesOnly: true,
    ///     hideCompleted: false
    /// )
    /// ```
    func filteredSentences(
        showFavoritesOnly: Bool,
        hideCompleted: Bool
    ) -> [(index: Int, sentence: SentenceItem)] {
        let indexed = Array(session.sentences.enumerated())
        
        return indexed.compactMap { (offset, element) -> (index: Int, sentence: SentenceItem)? in
            // 즐겨찾기 필터 적용
            if showFavoritesOnly && !element.isFavorite {
                return nil
            }
            
            // 완료 문장 필터 적용
            if hideCompleted && element.isCompleted {
                return nil
            }
            
            // 필터를 통과한 문장 반환
            return (index: offset, sentence: element)
        }
    }
    
    // MARK: - Initialization (초기화)
    
    /// ViewModel 초기화
    /// - Parameters:
    ///   - session: 학습할 세션 정보
    ///   - playerSettings: 플레이어 설정
    init(session: ShadowingSession, playerSettings: PlayerSettings) {
        self.session = session
        self.playerSettings = playerSettings
        print("🎬 Initialized ShadowingViewModel with Video ID: \(session.video.id)")
        
        // currentTime과 isPlaying 관찰 설정
        setupObservers()
    }
    
    private func setupObservers() {
        // currentTime 변경 시 문장 진행 상태 체크
        $currentTime
            .sink { [weak self] time in
                self?.checkSentenceProgress(time: time)
            }
            .store(in: &cancellables)
    }
    
    private func checkSentenceProgress(time: TimeInterval) {
        guard let sentence = currentSentence else { return }
        
        // seek 직후 안정화 대기: 문장 시작 후 0.3초까지는 체크 건너뛰기
        if time < sentence.startTime + 0.3 {
            return
        }
        
        // 문장 끝에서 자동 일시정지 체크
        // endTime 0.05초 전부터 체크 (자연스러운 일시정지)
        if time >= sentence.endTime - 0.05 && isPlaying && !hasAutoPaused {
            let overrun = time - sentence.endTime
            print("⏸ Auto-pausing:")
            print("   - Current: \(String(format: "%.3f", time))s")
            print("   - End: \(String(format: "%.3f", sentence.endTime))s")
            print("   - Overrun: \(String(format: "%.3f", overrun))s")
            print("   - Text: \(sentence.text.prefix(50))...")
            
            isPlaying = false
            hasAutoPaused = true
            return
        }
        
        // 안전장치: 0.5초 이상 오버런 시 강제 일시정지
        if time >= sentence.endTime + 0.5 && isPlaying {
            print("⚠️ Emergency pause (overrun: \(String(format: "%.3f", time - sentence.endTime))s)")
            isPlaying = false
            hasAutoPaused = true
            return
        }
        
        // 수동 seek 중에는 아래 로직 비활성화
        if isManualSeeking {
            return
        }
    }
    
    // MARK: - Playback Controls (재생 제어)
    
    /// 비디오 재생 시작
    ///
    /// Play 버튼을 눌렀을 때 호출됩니다.
    /// 일시정지 상태를 해제하고 자동 일시정지 플래그를 초기화합니다.
    func play() {
        print("▶️ Play requested")
        hasAutoPaused = false  // 플래그 초기화 - 문장 끝에서 다시 일시정지 가능하도록
        isPlaying = true
    }
    
    /// 비디오 일시정지
    ///
    /// Pause 버튼을 눌렀을 때 호출됩니다.
    func pause() {
        print("⏸ Pause requested")
        isPlaying = false
    }
    
    /// 재생/일시정지 토글
    ///
    /// Play/Pause 버튼을 눌렀을 때 호출됩니다.
    /// 현재 상태에 따라 재생 또는 일시정지를 실행합니다.
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func seekToCurrentSentence() {
        guard let sentence = currentSentence else { return }
        print("⏩ Seeking to sentence: \(sentence.text) at \(sentence.startTime)s")
        isManualSeeking = true
        currentTime = sentence.startTime
        
        // seek 완료 후 플래그 해제 (1초 후)
        Task {
            try? await Task.sleep(for: .seconds(1))
            await MainActor.run {
                self.isManualSeeking = false
            }
        }
    }
    
    /// 자막 클릭 시: seek + 자동 재생
    func seekAndPlay() {
        guard let sentence = currentSentence else { return }
        print("🎬 Seek and play: \(sentence.text) at \(sentence.startTime)s")
        isManualSeeking = true
        hasAutoPaused = false  // 플래그 초기화
        
        // 같은 문장을 다시 클릭해도 재생되도록 처리
        // 1. 먼저 일시정지
        isPlaying = false
        
        // 2. seek 실행 (약간의 딜레이를 두어 확실하게 처리)
        Task {
            try? await Task.sleep(for: .milliseconds(100))
            await MainActor.run {
                self.currentTime = sentence.startTime
            }
            
            // 3. 재생 시작
            try? await Task.sleep(for: .milliseconds(100))
            await MainActor.run {
                self.isPlaying = true
            }
            
            // 4. seek 플래그 해제
            try? await Task.sleep(for: .milliseconds(500))
            await MainActor.run {
                self.isManualSeeking = false
            }
        }
    }
    
    func nextSentence() {
        if currentSentenceIndex < session.sentences.count - 1 {
            currentSentenceIndex += 1
            repeatCount = 0
            hasAutoPaused = false  // 플래그 초기화
            seekToCurrentSentence()
        }
    }
    
    func previousSentence() {
        if currentSentenceIndex > 0 {
            currentSentenceIndex -= 1
            repeatCount = 0
            hasAutoPaused = false  // 플래그 초기화
            seekToCurrentSentence()
        }
    }
    
    func repeatCurrentSentence() {
        repeatCount += 1
        Task {
            seekToCurrentSentence()
            try? await Task.sleep(for: .seconds(0.5))
            play()
        }
    }
    
    func toggleFavoriteSentence() {
        guard let sentence = currentSentence else { return }
        
        if let index = session.sentences.firstIndex(where: { $0.id == sentence.id }) {
            session.sentences[index].isFavorite.toggle()
            print("⭐️ Favorite toggled: \(session.sentences[index].isFavorite)")
            
            // 데이터 영속성: 변경사항 저장
            saveSession()
            objectWillChange.send()  // UI 업데이트 트리거
        }
    }
    
    func loopCurrentSentence(times: Int) {
        guard let sentence = currentSentence else { return }
        
        // 기존 반복 취소
        cancelLoop()
        
        isLooping = true
        hasAutoPaused = false  // 플래그 초기화
        loopTask = Task {
            defer { 
                Task { @MainActor in
                    self.isLooping = false
                }
            }
            
            for i in 0..<times {
                // Task 취소 확인
                if Task.isCancelled {
                    print("⏹️ Loop cancelled")
                    return
                }
                
                print("🔁 Loop \(i + 1)/\(times)")
                
                // Seek to start
                await MainActor.run {
                    self.currentTime = sentence.startTime
                }
                
                // Play
                await MainActor.run {
                    self.isPlaying = true
                }
                
                // Wait for sentence duration
                let duration = sentence.duration
                try? await Task.sleep(for: .seconds(duration))
                
                // Task 취소 확인
                if Task.isCancelled {
                    print("⏹️ Loop cancelled during playback")
                    return
                }
                
                // Pause at end
                await MainActor.run {
                    self.isPlaying = false
                }
                
                // Wait 1 second before next loop
                if i < times - 1 {
                    try? await Task.sleep(for: .seconds(1))
                }
            }
            
            print("✅ Loop completed")
        }
    }
    
    func cancelLoop() {
        loopTask?.cancel()
        loopTask = nil
        isLooping = false
        print("🛑 Loop task cancelled")
    }
    
    func markCurrentSentenceCompleted() {
        guard let sentence = currentSentence else { return }
        session.completedSentences.insert(sentence.id)
        
        if let index = session.sentences.firstIndex(where: { $0.id == sentence.id }) {
            session.sentences[index].isCompleted = true
            print("✅ Sentence marked as completed")
            
            // 데이터 영속성: 변경사항 저장
            saveSession()
            objectWillChange.send()  // UI 업데이트 트리거
        }
    }
    
    /// 문장별 프로소디 체크리스트 버튼을 클릭할 때 호출하여 현재 강세·리듬·연음 평가를 순환시켜 사용자가 즉시 자기 피드백을 적재할 수 있게 한다.
    func cycleProsodyScore(for metric: ProsodyMetric) {
        guard let sentence = currentSentence else { return }
        
        guard let index = session.sentences.firstIndex(where: { $0.id == sentence.id }) else {
            return
        }
        
        session.sentences[index].prosodyAssessment.cycle(metric: metric)
        saveSession()
        objectWillChange.send()
    }
    
    func setPlaybackRate(_ rate: Double) {
        playbackRate = rate
        print("🎚️ Playback rate updated to \(rate)x (UI only)")
        
        // TODO: YouTubePlayerKit doesn't support setPlaybackRate directly
        // User must use YouTube player's built-in speed control
        // Future: Investigate YouTube iframe API postMessage
    }
    
    // 데이터 저장 헬퍼 함수
    private func saveSession() {
        Task {
            do {
                try StorageService.shared.saveSession(session)
                print("💾 Session saved successfully")
            } catch {
                print("❌ Failed to save session: \(error)")
            }
        }
    }
    
    deinit {
        loopTask?.cancel()
    }
}
