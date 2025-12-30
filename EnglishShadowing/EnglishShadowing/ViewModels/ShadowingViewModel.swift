//
//  ShadowingViewModel.swift
//  EnglishShadowing
//
//  Created by Myoungwoo Jang on 12/28/25.
//

import Foundation
import Combine

@MainActor
class ShadowingViewModel: ObservableObject {
    @Published var session: ShadowingSession
    @Published var currentSentenceIndex: Int = 0
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var playbackRate: Double = 1.0
    @Published var repeatCount: Int = 0
    @Published var isLooping: Bool = false  // 반복 중인지 표시
    
    private let playerSettings: PlayerSettings  // 전역 설정
    private var cancellables = Set<AnyCancellable>()
    private var loopTask: Task<Void, Never>?  // 반복 재생 Task
    private var isManualSeeking: Bool = false  // 수동 seek 중인지 표시
    private var hasAutoPaused: Bool = false  // 자동 일시정지 완료 플래그
    
    var currentSentence: SentenceItem? {
        guard currentSentenceIndex < session.sentences.count else { return nil }
        return session.sentences[currentSentenceIndex]
    }
    
    var isLastSentence: Bool {
        currentSentenceIndex >= session.sentences.count - 1
    }
    
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
    
    // 플레이어 컨트롤 메서드들은 이제 단순히 상태만 변경
    // 실제 플레이어 제어는 CustomYouTubePlayer가 담당
    
    func play() {
        print("▶️ Play requested")
        hasAutoPaused = false  // 플래그 초기화 - Play 버튼으로 재개 시
        isPlaying = true
    }
    
    func pause() {
        print("⏸ Pause requested")
        isPlaying = false
    }
    
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
