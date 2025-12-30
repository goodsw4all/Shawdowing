//
//  ShadowingView.swift
//  EnglishShadowing
//
//  Created by Myoungwoo Jang on 12/28/25.
//
//  역할: 쉐도잉 학습 화면의 UI를 구성하는 메인 View
//  - YouTube 비디오 플레이어
//  - 현재 문장 카드
//  - 문장 목록 (필터링 가능)
//  - 재생 컨트롤 패널
//  - 프로소디 체크리스트
//

import SwiftUI

/// 쉐도잉 학습 화면
///
/// 이 화면은 다음 요소들로 구성됩니다:
/// - YouTube 비디오 플레이어
/// - 현재 재생 중인 문장 정보 카드
/// - 필터링 가능한 문장 목록
/// - 재생 컨트롤 버튼들
/// - 프로소디(발음) 체크리스트
struct ShadowingView: View {
    @EnvironmentObject var navigationVM: NavigationViewModel
    @StateObject private var viewModel: ShadowingViewModel
    
    /// 즐겨찾기한 문장만 보기 토글
    @State private var showFavoritesOnly: Bool = false
    
    /// 완료한 문장 숨기기 토글
    @State private var hideCompleted: Bool = false
    
    /// ViewModel 초기화
    /// - Parameters:
    ///   - session: 학습할 세션 정보
    ///   - playerSettings: 플레이어 설정
    init(session: ShadowingSession, playerSettings: PlayerSettings) {
        _viewModel = StateObject(wrappedValue: ShadowingViewModel(
            session: session,
            playerSettings: playerSettings
        ))
    }
    
    /// 필터링된 문장 목록
    ///
    /// ViewModel의 filteredSentences 메서드를 호출하여
    /// 현재 필터 설정에 맞는 문장들만 반환합니다.
    private var filteredSentences: [(index: Int, sentence: SentenceItem)] {
        viewModel.filteredSentences(
            showFavoritesOnly: showFavoritesOnly,
            hideCompleted: hideCompleted
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // YouTube 플레이어
            CustomYouTubePlayer(
                videoID: viewModel.session.video.id,
                currentTime: $viewModel.currentTime,
                isPlaying: $viewModel.isPlaying,
                playbackRate: $viewModel.playbackRate
            )
            .frame(height: 450)
            .cornerRadius(12)
            .padding()
            
            // Session Info Card
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    // 썸네일 또는 플레이스홀더
                    if let thumbnailURL = viewModel.session.video.thumbnailURL {
                        AsyncImage(url: thumbnailURL) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 80, height: 60)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 60)
                                    .clipped()
                                    .cornerRadius(8)
                            case .failure:
                                Image(systemName: "film")
                                    .font(.title)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 80, height: 60)
                                    .background(Color(nsColor: .controlBackgroundColor))
                                    .cornerRadius(8)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        Image(systemName: "film")
                            .font(.title)
                            .foregroundStyle(.secondary)
                            .frame(width: 80, height: 60)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        if let title = viewModel.session.video.title, !title.isEmpty {
                            Text(title)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .lineLimit(2)
                        } else {
                            Text("YouTube Video")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                        }
                        
                        Label("ID: \(viewModel.session.video.id)", systemImage: "link")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Progress")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(Int(viewModel.session.progress * 100))%")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading) {
                        Text("Sentences")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(viewModel.session.completedSentences.count)/\(viewModel.session.sentences.count)")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
                
                ProgressView(value: viewModel.session.progress)
                    .tint(Color(hex: "#A8DADC"))
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            .padding(.horizontal)
            
            // Current Sentence Card
            if let sentence = viewModel.currentSentence {
                CurrentSentenceCard(
                    sentence: sentence,
                    repeatCount: viewModel.repeatCount,
                    totalRepeats: sentence.repeatCount
                )
                .padding(.horizontal)
                
                ProsodyChecklistView(
                    assessment: sentence.prosodyAssessment,
                    onMetricTap: { metric in
                        viewModel.cycleProsodyScore(for: metric)
                    }
                )
                .padding(.horizontal)
            }
            
            // Sentence List
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("자막 리스트")
                        .font(.headline)
                    
                    Spacer()
                    
                    // 필터 상태 표시
                    if showFavoritesOnly || hideCompleted {
                        Text("\(filteredSentences.count)/\(viewModel.session.sentences.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Filter buttons
                    Button {
                        showFavoritesOnly = false
                        hideCompleted = false
                    } label: {
                        Text("전체")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .tint(!showFavoritesOnly && !hideCompleted ? .blue : .gray)
                    
                    Button {
                        showFavoritesOnly.toggle()
                    } label: {
                        Image(systemName: showFavoritesOnly ? "star.fill" : "star")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .tint(showFavoritesOnly ? .yellow : .gray)
                    
                    Button {
                        hideCompleted.toggle()
                    } label: {
                        Image(systemName: hideCompleted ? "eye.slash.fill" : "eye.slash")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .tint(hideCompleted ? .green : .gray)
                }
                .padding(.horizontal)
                
                ScrollViewReader { proxy in
                    if filteredSentences.isEmpty {
                        // 빈 상태 메시지
                        VStack(spacing: 12) {
                            Image(systemName: "tray")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            
                            Text("필터 조건에 맞는 문장이 없습니다")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            if showFavoritesOnly {
                                Text("⭐️를 눌러 문장을 즐겨찾기에 추가하세요")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Button("필터 초기화") {
                                showFavoritesOnly = false
                                hideCompleted = false
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxWidth: .infinity, maxHeight: 250)
                    } else {
                        List(filteredSentences, id: \.sentence.id) { item in
                            SentenceRow(
                                sentence: item.sentence,
                                isCurrentlyPlaying: item.index == viewModel.currentSentenceIndex,
                                onTap: {
                                    print("🔍 Clicked sentence:")
                                    print("   - Text: \(item.sentence.text)")
                                    print("   - Index: \(item.index)")
                                    print("   - Start time: \(item.sentence.startTime)")
                                    print("   - Current index before: \(viewModel.currentSentenceIndex)")
                                    
                                    viewModel.currentSentenceIndex = item.index
                                    
                                    print("   - Current index after: \(viewModel.currentSentenceIndex)")
                                    print("   - Current sentence: \(viewModel.currentSentence?.text ?? "nil")")
                                    
                                    viewModel.seekAndPlay()  // seek + 자동 재생
                                },
                                onFavorite: {
                                    viewModel.currentSentenceIndex = item.index
                                    viewModel.toggleFavoriteSentence()
                                },
                                onLoop: { times in
                                    viewModel.currentSentenceIndex = item.index
                                    viewModel.loopCurrentSentence(times: times)
                                }
                            )
                        }
                        .listStyle(.plain)
                        .frame(maxHeight: 250)
                        .onChange(of: viewModel.currentSentenceIndex) { _, newIndex in
                            if newIndex < viewModel.session.sentences.count {
                                withAnimation {
                                    proxy.scrollTo(viewModel.session.sentences[newIndex].id, anchor: .center)
                                }
                            }
                        }
                    }
                }
            }
            
            // Control Panel
            ControlPanelView(viewModel: viewModel)
                .padding()
        }
        .navigationTitle(viewModel.session.video.title ?? "Shadowing")
        .navigationSubtitle("\(viewModel.currentSentenceIndex + 1) / \(viewModel.session.sentences.count)")
    }
}

#Preview {
    let video = YouTubeVideo(id: "dQw4w9WgXcQ", title: "Sample Video")
    let sentences = [
        SentenceItem(text: "Hello, welcome to this video.", startTime: 0, endTime: 5),
        SentenceItem(text: "This is a sample sentence.", startTime: 10, endTime: 15)
    ]
    let session = ShadowingSession(video: video, sentences: sentences)
    let settings = PlayerSettings()
    
    NavigationStack {
        ShadowingView(session: session, playerSettings: settings)
    }
}
