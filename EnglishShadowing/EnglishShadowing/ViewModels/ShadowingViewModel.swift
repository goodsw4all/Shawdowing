//
//  ShadowingViewModel.swift
//  EnglishShadowing
//
//  Created by Myoungwoo Jang on 12/28/25.
//

import Foundation
import Combine
import YouTubePlayerKit

@MainActor
class ShadowingViewModel: ObservableObject {
    @Published var session: ShadowingSession
    @Published var player: YouTubePlayer?
    @Published var currentSentenceIndex: Int = 0
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var playbackRate: Double = 1.0
    @Published var repeatCount: Int = 0
    @Published var isLooping: Bool = false  // 반복 중인지 표시
    
    private let playerSettings: PlayerSettings  // 전역 설정
    private var cancellables = Set<AnyCancellable>()
    private var timeObserverTask: Task<Void, Never>?
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
        setupPlayer()
    }
    
    private func setupPlayer() {
        print("🎬 Setting up YouTube Player with Video ID: \(session.video.id)")
        
        // Configuration - 기본 설정만 사용
        // YouTubePlayerKit는 Configuration 초기화 시 playerVars를 직접 지원하지 않음
        // 대신 기본 Configuration 사용
        let configuration = YouTubePlayer.Configuration()
        
        player = YouTubePlayer(
            source: .video(id: session.video.id),
            configuration: configuration
        )
        
        print("⚙️ Player configured")
        print("   - Video ID: \(session.video.id)")
        print("   ⚠️  Note: YouTube pause overlay는 YouTube 정책상 제거 불가")
        print("   ⚠️  controls, rel 등의 파라미터는 YouTubePlayerKit 제약으로 설정 제한됨")
        startTimeObserver()
    }
    
    /// Player 재생성은 이제 필요 없음 (전역 설정 사용)
    
    private func startTimeObserver() {
        timeObserverTask?.cancel()
        
        timeObserverTask = Task { @MainActor in
            guard let player = player else { return }
            
            var lastState: YouTubePlayer.PlaybackState?
            var hasAutoSeeked = false
            
            // 250ms마다 폴링
            while !Task.isCancelled {
                do {
                    // 현재 시간 가져오기
                    let time = try await player.getCurrentTime()
                    let seconds = time.converted(to: .seconds).value
                    self.currentTime = seconds
                    self.checkSentenceProgress(time: seconds)
                    
                    // 현재 상태 가져오기
                    let state = try await player.getPlaybackState()
                    
                    // 상태 변경 감지
                    if lastState != state {
                        print("🎥 Playback State Changed: \(state)")
                        lastState = state
                        
                        switch state {
                        case .unstarted:
                            print("🔄 State: UNSTARTED")
                            self.isPlaying = false
                            
                            // 최초 한 번만 자동 seek
                            if !hasAutoSeeked {
                                hasAutoSeeked = true
                                try? await Task.sleep(for: .seconds(1))
                                print("⏩ Auto-seeking to first sentence")
                                self.seekToCurrentSentence()
                            }
                            
                        case .ended:
                            print("🏁 State: ENDED")
                            self.isPlaying = false
                            
                        case .playing:
                            print("✅ State: PLAYING")
                            self.isPlaying = true
                            
                        case .paused:
                            print("⏸ State: PAUSED")
                            self.isPlaying = false
                            
                        case .buffering:
                            print("⏳ State: BUFFERING")
                            
                        case .cued:
                            print("📌 State: CUED")
                            
                        default:
                            print("❓ State: UNKNOWN")
                        }
                    }
                    
                    // 250ms 대기
                    try await Task.sleep(for: .milliseconds(250))
                } catch {
                    if !Task.isCancelled {
                        print("⚠️ Observer error: \(error)")
                        try? await Task.sleep(for: .seconds(1))
                    }
                }
            }
        }
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
            Task {
                try? await player?.pause()
                self.isPlaying = false
            }
        }
    }
    
    func play() {
        print("▶️ Play requested")
        Task {
            do {
                try await player?.play()
                self.isPlaying = true
                print("✅ Playing")
            } catch {
                print("❌ Play error: \(error)")
            }
        }
    }
    
    func pause() {
        print("⏸ Pause requested")
        Task {
            do {
                try await player?.pause()
                self.isPlaying = false
                print("✅ Paused")
            } catch {
                print("❌ Pause error: \(error)")
            }
        }
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
        Task {
            do {
                try await player?.seek(
                    to: .init(value: sentence.startTime, unit: .seconds),
                    allowSeekAhead: true
                )
                print("✅ Seek completed")
            } catch {
                print("❌ Seek error: \(error)")
            }
        }
    }
    
    /// 자막 클릭 시: seek + 자동 재생
    func seekAndPlay() {
        guard let sentence = currentSentence else { return }
        print("🎬 Seek and play: \(sentence.text) at \(sentence.startTime)s")
        
        Task {
            do {
                // 1. Seek to start
                try await player?.seek(
                    to: .init(value: sentence.startTime, unit: .seconds),
                    allowSeekAhead: true
                )
                print("⏭️ Seeked to: \(sentence.startTime)s")
                
                // 2. Start playing
                try await player?.play()
                await MainActor.run {
                    self.isPlaying = true
                }
                print("▶️ Auto-playing")
            } catch {
                print("❌ Seek and play failed: \(error)")
            }
        }
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
                try? await player?.seek(
                    to: .init(value: sentence.startTime, unit: .seconds),
                    allowSeekAhead: true
                )
                
                // Play
                try? await player?.play()
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
                try? await player?.pause()
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
        timeObserverTask?.cancel()
        loopTask?.cancel()
    }
}
