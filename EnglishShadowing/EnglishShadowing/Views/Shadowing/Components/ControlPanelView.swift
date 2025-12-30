//
//  ControlPanelView.swift
//  EnglishShadowing
//
//  Created by GitHub Copilot on 12/30/25.
//

import SwiftUI

struct ControlPanelView: View {
    @ObservedObject var viewModel: ShadowingViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            PlaybackControls(viewModel: viewModel)
            PlaybackRateSelector(
                currentRate: viewModel.playbackRate,
                onRateSelect: viewModel.setPlaybackRate
            )
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Subcomponents

private struct PlaybackControls: View {
    @ObservedObject var viewModel: ShadowingViewModel
    
    var body: some View {
        HStack(spacing: 24) {
            PreviousButton(
                action: viewModel.previousSentence,
                isDisabled: viewModel.currentSentenceIndex == 0
            )
            
            PlayPauseButton(
                isPlaying: viewModel.isPlaying,
                action: viewModel.togglePlayPause
            )
            
            NextButton(
                action: viewModel.nextSentence,
                isDisabled: viewModel.isLastSentence
            )
            
            Divider()
                .frame(height: 30)
            
            LoopControl(viewModel: viewModel)
            
            FavoriteButton(
                isFavorite: viewModel.currentSentence?.isFavorite == true,
                action: viewModel.toggleFavoriteSentence
            )
            
            CompleteButton(action: viewModel.markCurrentSentenceCompleted)
        }
    }
}

private struct PreviousButton: View {
    let action: () -> Void
    let isDisabled: Bool
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "backward.fill")
                .font(.title2)
        }
        .disabled(isDisabled)
    }
}

private struct PlayPauseButton: View {
    let isPlaying: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                .font(.system(size: 48))
        }
    }
}

private struct NextButton: View {
    let action: () -> Void
    let isDisabled: Bool
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "forward.fill")
                .font(.title2)
        }
        .disabled(isDisabled)
    }
}

private struct LoopControl: View {
    @ObservedObject var viewModel: ShadowingViewModel
    
    private let loopOptions = [1, 3, 5, 10]
    
    var body: some View {
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
                ForEach(loopOptions, id: \.self) { times in
                    Button("\(times)회 반복") {
                        viewModel.loopCurrentSentence(times: times)
                    }
                }
            } label: {
                Label("반복", systemImage: "repeat")
            }
            .buttonStyle(.bordered)
        }
    }
}

private struct FavoriteButton: View {
    let isFavorite: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label("저장", systemImage: isFavorite ? "star.fill" : "star")
        }
        .buttonStyle(.bordered)
        .foregroundStyle(isFavorite ? .yellow : .primary)
    }
}

private struct CompleteButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label("완료", systemImage: "checkmark")
        }
        .buttonStyle(.borderedProminent)
    }
}

private struct PlaybackRateSelector: View {
    let currentRate: Double
    let onRateSelect: (Double) -> Void
    
    private let rates: [Double] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
    
    var body: some View {
        HStack {
            Text("속도:")
                .font(.subheadline)
            
            ForEach(rates, id: \.self) { rate in
                RateButton(
                    rate: rate,
                    isSelected: currentRate == rate,
                    action: { onRateSelect(rate) }
                )
            }
        }
    }
}

private struct RateButton: View {
    let rate: Double
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("\(rate, specifier: "%.2g")x")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isSelected ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                .foregroundStyle(isSelected ? .white : .primary)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}
