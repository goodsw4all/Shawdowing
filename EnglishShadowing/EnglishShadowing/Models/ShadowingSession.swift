//
//  ShadowingSession.swift
//  EnglishShadowing
//
//  Created by Myoungwoo Jang on 12/28/25.
//

import Foundation

enum SessionStatus: String, Codable {
    case active     // 학습 중
    case completed  // 완료
}

struct ShadowingSession: Identifiable, Codable, Hashable {
    let id: UUID
    let video: YouTubeVideo
    var sentences: [SentenceItem]
    var status: SessionStatus
    let createdAt: Date
    var updatedAt: Date
    var completedSentences: Set<UUID>
    
    var progress: Double {
        guard !sentences.isEmpty else { return 0.0 }
        return Double(completedSentences.count) / Double(sentences.count)
    }
    
    init(id: UUID = UUID(), video: YouTubeVideo, sentences: [SentenceItem], status: SessionStatus = .active) {
        self.id = id
        self.video = video
        self.sentences = sentences
        self.status = status
        self.createdAt = Date()
        self.updatedAt = Date()
        self.completedSentences = []
    }
}
