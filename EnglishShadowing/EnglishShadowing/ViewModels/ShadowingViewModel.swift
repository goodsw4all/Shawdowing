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
    
    private var cancellables = Set<AnyCancellable>()
    private var timeObserverTask: Task<Void, Never>?
    
    var currentSentence: SentenceItem? {
        guard currentSentenceIndex < session.sentences.count else { return nil }
        return session.sentences[currentSentenceIndex]
    }
    
    var isLastSentence: Bool {
        currentSentenceIndex >= session.sentences.count - 1
    }
    
    init(session: ShadowingSession) {
        self.session = session
        setupPlayer()
    }
    
    private func setupPlayer() {
        print("🎬 Setting up YouTube Player with Video ID: \(session.video.id)")
        player = YouTubePlayer(
            source: .video(id: session.video.id)
        )
        
        startTimeObserver()
    }
    
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
        
        // 0.5초 버퍼로 정확한 감지 (currentTimePublisher 업데이트 주기 고려)
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
        }
    }
    
    func loopCurrentSentence(times: Int) {
        guard let sentence = currentSentence else { return }
        
        Task {
            for i in 0..<times {
                print("🔁 Loop \(i + 1)/\(times)")
                
                // Seek to start
                try? await player?.seek(
                    to: .init(value: sentence.startTime, unit: .seconds),
                    allowSeekAhead: true
                )
                
                // Play
                try? await player?.play()
                self.isPlaying = true
                
                // Wait for sentence duration
                let duration = sentence.duration
                try? await Task.sleep(for: .seconds(duration))
                
                // Pause at end
                try? await player?.pause()
                self.isPlaying = false
                
                // Wait 1 second before next loop
                if i < times - 1 {
                    try? await Task.sleep(for: .seconds(1))
                }
            }
            
            print("✅ Loop completed")
        }
    }
    
    func markCurrentSentenceCompleted() {
        guard let sentence = currentSentence else { return }
        session.completedSentences.insert(sentence.id)
        
        if let index = session.sentences.firstIndex(where: { $0.id == sentence.id }) {
            session.sentences[index].isCompleted = true
        }
    }
    
    func setPlaybackRate(_ rate: Double) {
        playbackRate = rate
        // YouTubePlayerKit playback rate는 플레이어 UI에서 직접 제어
        // 추후 필요시 구현
    }
    
    deinit {
        timeObserverTask?.cancel()
    }
}
