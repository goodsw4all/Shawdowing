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
    
    var currentSentence: SentenceItem? {
        guard currentSentenceIndex < session.sentences.count else { return nil }
        return session.sentences[currentSentenceIndex]
    }
    
    var isLastSentence: Bool {
        currentSentenceIndex >= session.sentences.count - 1
    }
    
    init(session: ShadowingSession, playerSettings: PlayerSettings = PlayerSettings()) {
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
        
        // 1. 현재 재생 시간에 맞는 자막 인덱스 찾기 (동기화)
        if let matchingIndex = session.sentences.firstIndex(where: { 
            time >= $0.startTime && time < $0.endTime 
        }) {
            // 인덱스가 변경되었을 때만 업데이트
            if matchingIndex != currentSentenceIndex {
                print("🔄 Auto-updating sentence index: \(currentSentenceIndex) → \(matchingIndex) at \(time)s")
                currentSentenceIndex = matchingIndex
                repeatCount = 0
            }
        }
        
        // 2. 문장 끝에서 자동 일시정지
        let isNearEnd = time >= (sentence.endTime - 0.5) && time <= (sentence.endTime + 0.5)
        
        if isNearEnd && isPlaying {
            print("⏸ Auto-pausing at \(time)s (sentence ends at \(sentence.endTime)s)")
            isPlaying = false
        }
    }
    
    // 플레이어 컨트롤 메서드들은 이제 단순히 상태만 변경
    // 실제 플레이어 제어는 CustomYouTubePlayer가 담당
    
    func play() {
        print("▶️ Play requested")
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
        currentTime = sentence.startTime
    }
    
    /// 자막 클릭 시: seek + 자동 재생
    func seekAndPlay() {
        guard let sentence = currentSentence else { return }
        print("🎬 Seek and play: \(sentence.text) at \(sentence.startTime)s")
        currentTime = sentence.startTime
        isPlaying = true
    }
    
    func nextSentence() {
        if currentSentenceIndex < session.sentences.count - 1 {
            currentSentenceIndex += 1
            repeatCount = 0
            seekToCurrentSentence()
        }
    }
    
    func previousSentence() {
        if currentSentenceIndex > 0 {
            currentSentenceIndex -= 1
            repeatCount = 0
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
