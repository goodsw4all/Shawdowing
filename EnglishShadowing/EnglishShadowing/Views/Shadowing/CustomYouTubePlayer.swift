//
//  CustomYouTubePlayer.swift
//  EnglishShadowing
//
//  Created by Myoungwoo Jang on 12/28/25.
//

import SwiftUI
import AVKit
import YouTubeKit
import Combine

/// YouTubeKit을 사용한 커스텀 YouTube 플레이어
/// 직접 비디오 스트림을 다운로드하여 AVPlayer로 재생
struct CustomYouTubePlayer: View {
    let videoID: String
    @Binding var currentTime: Double
    @Binding var isPlaying: Bool
    @Binding var playbackRate: Double
    
    @StateObject private var playerManager = YouTubePlayerManager()
    @State private var player: AVPlayer?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var isSeeking = false  // seek 무한루프 방지
    
    var body: some View {
        ZStack {
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("영상을 로딩 중...")
                        .foregroundColor(.secondary)
                }
            } else if let errorMessage = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else if let player = player {
                VideoPlayer(player: player)
                    .onAppear {
                        setupPlayerObservers()
                        if isPlaying {
                            player.play()
                        }
                    }
                    .onChange(of: isPlaying) { _, newValue in
                        if newValue {
                            player.rate = Float(playbackRate)  // 재생 속도 적용
                            player.play()
                        } else {
                            player.pause()
                        }
                    }
                    .onChange(of: playbackRate) { _, newRate in
                        // 재생 속도 변경
                        if isPlaying {
                            player.rate = Float(newRate)
                        }
                    }
                    .onChange(of: currentTime) { _, newTime in
                        guard !isSeeking else { return }  // seek 중 무시
                        
                        // 현재 시간과 요청된 시간이 1초 이상 차이나면 seek
                        let currentPlayerTime = player.currentTime().seconds
                        if abs(currentPlayerTime - newTime) > 1.0 {
                            isSeeking = true
                            player.seek(to: CMTime(seconds: newTime, preferredTimescale: 600)) { _ in
                                isSeeking = false
                            }
                        }
                    }
            }
        }
        .task {
            await loadVideo()
        }
    }
    
    /// 비디오 로드
    private func loadVideo() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let youtube = YouTube(videoID: videoID)
            
            // 스트림 가져오기
            let streams = try await youtube.streams
            
            // 최적의 스트림 선택
            // 비디오와 오디오가 함께 있고, 네이티브 재생 가능하며, 1080p 이하인 스트림 선택
            let stream = streams
                .filterVideoAndAudio()
                .filter { $0.isNativelyPlayable }
                .filter { stream in
                    if let resolution = stream.videoResolution {
                        return resolution <= 1080
                    }
                    return true
                }
                .highestResolutionStream()
            
            guard let stream = stream else {
                errorMessage = "재생 가능한 스트림을 찾을 수 없습니다."
                isLoading = false
                return
            }
            
            let streamURL = stream.url
            
            print("🎬 Selected stream:")
            print("   - Resolution: \(stream.videoResolution ?? 0)p")
            print("   - Extension: \(stream.fileExtension)")
            print("   - Natively playable: \(stream.isNativelyPlayable)")
            
            // AVPlayer 생성
            let avPlayer = AVPlayer(url: streamURL)
            await MainActor.run {
                self.player = avPlayer
                self.isLoading = false
                if isPlaying {
                    avPlayer.play()
                }
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "영상 로드 실패: \(error.localizedDescription)"
                isLoading = false
            }
            print("❌ Failed to load video: \(error)")
        }
    }
    
    /// 플레이어 상태 관찰 설정
    private func setupPlayerObservers() {
        guard let player = player else { return }
        
        // 재생 시간 업데이트
        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
        player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [self] time in
            let seconds = time.seconds
            if !seconds.isNaN && !seconds.isInfinite && !isSeeking {
                currentTime = seconds
            }
        }
        
        // 재생 상태 관찰
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [self] _ in
            isPlaying = false
        }
    }
}

/// YouTube 플레이어 관리자
@MainActor
class YouTubePlayerManager: ObservableObject {
    @Published var duration: Double = 0
    @Published var isReady = false
    
    init() {}
}

// MARK: - Preview
struct CustomYouTubePlayer_Previews: PreviewProvider {
    static var previews: some View {
        CustomYouTubePlayer(
            videoID: "dQw4w9WgXcQ",
            currentTime: .constant(0),
            isPlaying: .constant(false),
            playbackRate: .constant(1.0)
        )
        .frame(height: 400)
        .padding()
    }
}
