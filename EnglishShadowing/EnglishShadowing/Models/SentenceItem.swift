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
