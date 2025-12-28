//
//  ShadowingView.swift
//  EnglishShadowing
//
//  Created by Myoungwoo Jang on 12/28/25.
//

import SwiftUI
import YouTubePlayerKit

struct ShadowingView: View {
    @StateObject private var viewModel: ShadowingViewModel
    @State private var showFavoritesOnly: Bool = false
    @State private var hideCompleted: Bool = false
    @State private var showPlayerSettings: Bool = false  // Settings Sheet
    
    init(session: ShadowingSession) {
        _viewModel = StateObject(wrappedValue: ShadowingViewModel(session: session))
    }
    
    // 필터링된 문장 리스트
    private var filteredSentences: [(index: Int, sentence: SentenceItem)] {
        let indexed = Array(viewModel.session.sentences.enumerated())
        
        return indexed.compactMap { (offset, element) -> (index: Int, sentence: SentenceItem)? in
            // 즐겨찾기 필터
            if showFavoritesOnly && !element.isFavorite {
                return nil
            }
            
            // 완료된 문장 숨기기 필터
            if hideCompleted && element.isCompleted {
                return nil
            }
            
            return (index: offset, sentence: element)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // YouTube Player with Settings Button
            ZStack(alignment: .topTrailing) {
                if let player = viewModel.player {
                    YouTubePlayerView(player)
                        .frame(height: 450)
                        .cornerRadius(12)
                        .onAppear {
                            print("📱 YouTubePlayerView appeared")
                            print("📹 Video source: \(player.source)")
                        }
                } else {
                    VStack {
                        ProgressView()
                        Text("Loading player...")
                            .foregroundStyle(.secondary)
                    }
                    .frame(height: 450)
                }
                
                // Settings Button (Overlay)
                Button {
                    showPlayerSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding()
            }
            .padding()
            
            // Current Sentence Card
            if let sentence = viewModel.currentSentence {
                CurrentSentenceCard(
                    sentence: sentence,
                    repeatCount: viewModel.repeatCount,
                    totalRepeats: sentence.repeatCount
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
                                    viewModel.currentSentenceIndex = item.index
                                    viewModel.seekAndPlay()  // seek + 자동 재생
                                },
                                onFavorite: {
                                    viewModel.currentSentenceIndex = item.index
                                    viewModel.toggleFavoriteSentence()
                                },
                                onLoop: {
                                    viewModel.currentSentenceIndex = item.index
                                    viewModel.loopCurrentSentence(times: 3)
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
        .sheet(isPresented: $showPlayerSettings) {
            PlayerSettingsSheet(settings: $viewModel.playerSettings) {
                viewModel.reloadPlayer()
            }
        }
    }
}

struct CurrentSentenceCard: View {
    let sentence: SentenceItem
    let repeatCount: Int
    let totalRepeats: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("현재 문장")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    ForEach(0..<totalRepeats, id: \.self) { index in
                        Circle()
                            .fill(index < repeatCount ? Color.green : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
            }
            
            Text(sentence.text)
                .font(.title3)
                .fontWeight(.medium)
                .lineLimit(3)
            
            HStack {
                Text(TimeFormatter.formatTime(sentence.startTime))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("-")
                    .foregroundStyle(.secondary)
                Text(TimeFormatter.formatTime(sentence.endTime))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct SentenceRow: View {
    let sentence: SentenceItem
    let isCurrentlyPlaying: Bool
    let onTap: () -> Void
    let onFavorite: () -> Void
    let onLoop: () -> Void
    
    @State private var showLoopMenu = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Favorite button
            Button(action: onFavorite) {
                Image(systemName: sentence.isFavorite ? "star.fill" : "star")
                    .foregroundStyle(sentence.isFavorite ? .yellow : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            
            // Main content (clickable)
            Button(action: onTap) {
                HStack(spacing: 12) {
                    Image(systemName: sentence.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(sentence.isCompleted ? .green : .secondary)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(sentence.text)
                            .font(.body)
                            .lineLimit(2)
                            .foregroundStyle(isCurrentlyPlaying ? .primary : .secondary)
                        
                        HStack {
                            Text("\(TimeFormatter.formatTime(sentence.startTime)) - \(TimeFormatter.formatTime(sentence.endTime))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            if sentence.isFavorite {
                                Text("⭐️")
                                    .font(.caption2)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    if isCurrentlyPlaying {
                        Image(systemName: "waveform")
                            .foregroundStyle(.blue)
                            .symbolEffect(.pulse)
                    }
                }
            }
            .buttonStyle(.plain)
            
            // Loop button with menu
            Menu {
                Button("1회 반복") { 
                    // Loop 1 time - handled by onLoop
                }
                Button("3회 반복") { 
                    // Loop 3 times
                }
                Button("5회 반복") { 
                    // Loop 5 times
                }
                Button("10회 반복") { 
                    // Loop 10 times
                }
            } label: {
                Image(systemName: "repeat")
                    .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 30)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .background(isCurrentlyPlaying ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
    }
}

struct ControlPanelView: View {
    @ObservedObject var viewModel: ShadowingViewModel
    @State private var showLoopOptions = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Playback Controls
            HStack(spacing: 24) {
                Button(action: viewModel.previousSentence) {
                    Image(systemName: "backward.fill")
                        .font(.title2)
                }
                .disabled(viewModel.currentSentenceIndex == 0)
                
                Button(action: viewModel.togglePlayPause) {
                    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 48))
                }
                
                Button(action: viewModel.nextSentence) {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                }
                .disabled(viewModel.isLastSentence)
                
                Divider()
                    .frame(height: 30)
                
                // Loop menu or Cancel button
                if viewModel.isLooping {
                    Button(action: viewModel.cancelLoop) {
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                            Text("중지")
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                } else {
                    Menu {
                        Button("1회 반복") {
                            viewModel.loopCurrentSentence(times: 1)
                        }
                        Button("3회 반복") {
                            viewModel.loopCurrentSentence(times: 3)
                        }
                        Button("5회 반복") {
                            viewModel.loopCurrentSentence(times: 5)
                        }
                        Button("10회 반복") {
                            viewModel.loopCurrentSentence(times: 10)
                        }
                    } label: {
                        Label("반복", systemImage: "repeat")
                    }
                    .buttonStyle(.bordered)
                }
                
                Button(action: viewModel.toggleFavoriteSentence) {
                    Label("저장", systemImage: viewModel.currentSentence?.isFavorite == true ? "star.fill" : "star")
                }
                .buttonStyle(.bordered)
                .foregroundStyle(viewModel.currentSentence?.isFavorite == true ? .yellow : .primary)
                
                Button(action: viewModel.markCurrentSentenceCompleted) {
                    Label("완료", systemImage: "checkmark")
                }
                .buttonStyle(.borderedProminent)
            }
            
            // Playback Rate
            HStack {
                Text("속도:")
                    .font(.subheadline)
                
                ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { rate in
                    Button {
                        viewModel.setPlaybackRate(rate)
                    } label: {
                        Text("\(rate, specifier: "%.2g")x")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                viewModel.playbackRate == rate 
                                    ? Color.accentColor 
                                    : Color(nsColor: .controlBackgroundColor)
                            )
                            .foregroundStyle(viewModel.playbackRate == rate ? .white : .primary)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    let video = YouTubeVideo(id: "dQw4w9WgXcQ", title: "Sample Video")
    let sentences = [
        SentenceItem(text: "Hello, welcome to this video.", startTime: 0, endTime: 5),
        SentenceItem(text: "This is a sample sentence.", startTime: 10, endTime: 15)
    ]
    let session = ShadowingSession(video: video, sentences: sentences)
    
    return NavigationStack {
        ShadowingView(session: session)
    }
}
