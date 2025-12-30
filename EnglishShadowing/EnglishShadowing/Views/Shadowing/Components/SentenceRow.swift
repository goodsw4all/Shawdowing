//
//  SentenceRow.swift
//  EnglishShadowing
//
//  Created by GitHub Copilot on 12/30/25.
//

import SwiftUI

struct SentenceRow: View {
    let sentence: SentenceItem
    let isCurrentlyPlaying: Bool
    let onTap: () -> Void
    let onFavorite: () -> Void
    let onLoop: (Int) -> Void
    
    private let loopOptions = [1, 3, 5, 10]
    
    var body: some View {
        HStack(spacing: 12) {
            FavoriteButton(
                isFavorite: sentence.isFavorite,
                action: onFavorite
            )
            
            MainContentButton(
                sentence: sentence,
                isCurrentlyPlaying: isCurrentlyPlaying,
                action: onTap
            )
            
            LoopMenu(
                options: loopOptions,
                onSelect: onLoop
            )
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .background(isCurrentlyPlaying ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
    }
}

// MARK: - Subcomponents

private struct FavoriteButton: View {
    let isFavorite: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .foregroundStyle(isFavorite ? .yellow : .secondary)
                .font(.title3)
        }
        .buttonStyle(.plain)
    }
}

private struct MainContentButton: View {
    let sentence: SentenceItem
    let isCurrentlyPlaying: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                CompletionIcon(isCompleted: sentence.isCompleted)
                
                SentenceInfo(
                    text: sentence.text,
                    startTime: sentence.startTime,
                    endTime: sentence.endTime,
                    isFavorite: sentence.isFavorite,
                    isCurrentlyPlaying: isCurrentlyPlaying
                )
                
                Spacer()
                
                if isCurrentlyPlaying {
                    PlayingIndicator()
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private struct CompletionIcon: View {
    let isCompleted: Bool
    
    var body: some View {
        Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
            .foregroundStyle(isCompleted ? .green : .secondary)
            .font(.title3)
    }
}

private struct SentenceInfo: View {
    let text: String
    let startTime: TimeInterval
    let endTime: TimeInterval
    let isFavorite: Bool
    let isCurrentlyPlaying: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(text)
                .font(.body)
                .lineLimit(2)
                .foregroundStyle(isCurrentlyPlaying ? .primary : .secondary)
            
            HStack {
                Text("\(TimeFormatter.formatTime(startTime)) - \(TimeFormatter.formatTime(endTime))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if isFavorite {
                    Text("⭐️")
                        .font(.caption2)
                }
            }
        }
    }
}

private struct PlayingIndicator: View {
    var body: some View {
        Image(systemName: "waveform")
            .foregroundStyle(.blue)
            .symbolEffect(.pulse)
    }
}

private struct LoopMenu: View {
    let options: [Int]
    let onSelect: (Int) -> Void
    
    var body: some View {
        Menu {
            ForEach(options, id: \.self) { count in
                Button("\(count)회 반복") {
                    onSelect(count)
                }
            }
        } label: {
            Image(systemName: "repeat")
                .foregroundStyle(.secondary)
        }
        .menuStyle(.borderlessButton)
        .frame(width: 30)
    }
}
