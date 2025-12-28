//
//  SentenceItem.swift
//  EnglishShadowing
//
//  Created by Myoungwoo Jang on 12/28/25.
//

import Foundation

struct SentenceItem: Identifiable, Codable, Hashable {
    let id: UUID
    let text: String
    var startTime: TimeInterval
    var endTime: TimeInterval
    var repeatCount: Int = 3
    var recordings: [URL] = []
    var isCompleted: Bool = false
    var isFavorite: Bool = false  // 즐겨찾기 (저장된 문장)
    var currentRepeat: Int = 0    // 현재 반복 횟수
    var notes: String = ""        // 메모
    
    var duration: TimeInterval {
        endTime - startTime
    }
    
    init(id: UUID = UUID(), text: String, startTime: TimeInterval, endTime: TimeInterval, repeatCount: Int = 3) {
        self.id = id
        self.text = text
        self.startTime = startTime
        self.endTime = endTime
        self.repeatCount = repeatCount
    }
}
