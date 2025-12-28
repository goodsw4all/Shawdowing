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
    
    init(session: ShadowingSession) {
        _viewModel = StateObject(wrappedValue: ShadowingViewModel(session: session))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // YouTube Player
            if let player = viewModel.player {
                YouTubePlayerView(player)
                    .frame(height: 450)
                    .cornerRadius(12)
                    .padding()
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
            ScrollViewReader { proxy in
                List(Array(viewModel.session.sentences.enumerated()), id: \.element.id) { index, sentence in
                    SentenceRow(
                        sentence: sentence,
                        isCurrentlyPlaying: index == viewModel.currentSentenceIndex,
                        onTap: {
                            viewModel.currentSentenceIndex = index
                            viewModel.seekToCurrentSentence()
                        }
                    )
                }
                .listStyle(.plain)
                .frame(maxHeight: 200)
                .onChange(of: viewModel.currentSentenceIndex) { _, newIndex in
                    if newIndex < viewModel.session.sentences.count {
                        withAnimation {
                            proxy.scrollTo(viewModel.session.sentences[newIndex].id, anchor: .center)
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
    
    var body: some View {
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
                    
                    Text("\(TimeFormatter.formatTime(sentence.startTime)) - \(TimeFormatter.formatTime(sentence.endTime))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if isCurrentlyPlaying {
                    Image(systemName: "waveform")
                        .foregroundStyle(.blue)
                        .symbolEffect(.pulse)
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(isCurrentlyPlaying ? Color.blue.opacity(0.1) : Color.clear)
    }
}

struct ControlPanelView: View {
    @ObservedObject var viewModel: ShadowingViewModel
    
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
                
                Button(action: viewModel.repeatCurrentSentence) {
                    Label("반복", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)
                
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
