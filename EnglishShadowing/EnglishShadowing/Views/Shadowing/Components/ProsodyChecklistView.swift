//
//  ProsodyChecklistView.swift
//  EnglishShadowing
//
//  Created by GitHub Copilot on 12/30/25.
//

import SwiftUI

struct ProsodyChecklistView: View {
    let assessment: ProsodyAssessment
    let onMetricTap: (ProsodyMetric) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Header()
            
            HStack(spacing: 12) {
                ForEach(ProsodyMetric.allCases, id: \.self) { metric in
                    MetricButton(
                        metric: metric,
                        score: assessment.score(for: metric),
                        onTap: { onMetricTap(metric) }
                    )
                }
            }
        }
        .padding()
        .background(Color(nsColor: .underPageBackgroundColor))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 1)
    }
}

// MARK: - Subcomponents

private struct Header: View {
    var body: some View {
        HStack {
            Label("프로소디 체크리스트", systemImage: "waveform.path.ecg")
                .font(.subheadline.weight(.semibold))
            Spacer()
            Text("버튼을 눌러 상태를 순환하세요")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct MetricButton: View {
    let metric: ProsodyMetric
    let score: ProsodyScore
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Text(metric.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                ScoreBadge(score: score)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(score.tintColor.opacity(0.5), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(score.tintColor.opacity(0.08))
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(metric.displayName) \(score.accessibilityLabel)")
    }
}

private struct ScoreBadge: View {
    let score: ProsodyScore
    
    var body: some View {
        Text(score.shortLabel)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(score.tintColor.opacity(0.2))
            .foregroundStyle(score.tintColorText)
            .cornerRadius(6)
    }
}

// MARK: - ProsodyScore Extensions

extension ProsodyScore {
    var shortLabel: String {
        switch self {
        case .notEvaluated: return "미평가"
        case .needsPractice: return "보완 필요"
        case .confident: return "완벽"
        }
    }
    
    var accessibilityLabel: String {
        switch self {
        case .notEvaluated: return "아직 평가하지 않음"
        case .needsPractice: return "추가 연습 필요"
        case .confident: return "확신 있음"
        }
    }
    
    var tintColor: Color {
        switch self {
        case .notEvaluated: return .gray
        case .needsPractice: return .orange
        case .confident: return .green
        }
    }
    
    var tintColorText: Color {
        switch self {
        case .notEvaluated: return .primary
        default: return .white
        }
    }
}
