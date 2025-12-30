//
//  CurrentSentenceCard.swift
//  EnglishShadowing
//
//  Created by GitHub Copilot on 12/30/25.
//

import SwiftUI

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
                
                RepeatIndicator(current: repeatCount, total: totalRepeats)
            }
            
            Text(sentence.text)
                .font(.title3)
                .fontWeight(.medium)
                .lineLimit(3)
            
            TimeRangeLabel(
                startTime: sentence.startTime,
                endTime: sentence.endTime
            )
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Subcomponents

private struct RepeatIndicator: View {
    let current: Int
    let total: Int
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index < current ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

private struct TimeRangeLabel: View {
    let startTime: TimeInterval
    let endTime: TimeInterval
    
    var body: some View {
        HStack {
            Text(TimeFormatter.formatTime(startTime))
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("-")
                .foregroundStyle(.secondary)
            Text(TimeFormatter.formatTime(endTime))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
