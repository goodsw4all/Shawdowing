//
//  CurrentSentenceCard.swift
//  EnglishShadowing
//
//  Created by GitHub Copilot on 12/30/25.
//
//  역할: 현재 재생 중인 문장 정보를 카드 형태로 표시
//  - 문장 텍스트
//  - 반복 횟수 인디케이터
//  - 시작/종료 시간
//

import SwiftUI

/// 현재 재생 중인 문장을 표시하는 카드 컴포넌트
///
/// 다음 정보를 표시합니다:
/// - 문장 텍스트 (최대 3줄)
/// - 반복 횟수 (원형 인디케이터)
/// - 문장의 시작/종료 시간
///
/// 사용 예시:
/// ```swift
/// CurrentSentenceCard(
///     sentence: currentSentence,
///     repeatCount: 2,
///     totalRepeats: 5
/// )
/// ```
struct CurrentSentenceCard: View {
    /// 표시할 문장 객체
    let sentence: SentenceItem
    
    /// 현재까지 반복한 횟수
    let repeatCount: Int
    
    /// 총 반복 예정 횟수
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
