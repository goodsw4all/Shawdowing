//
//  Playlist.swift
//  EnglishShadowing
//
//  Created by Myoungwoo Jang on 12/28/25.
//

import Foundation

struct Playlist: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var sessionIDs: [UUID]
    var color: String  // 파스텔 컬러 hex
    let createdAt: Date
    
    init(id: UUID = UUID(), name: String, color: String = "#A8DADC") {
        self.id = id
        self.name = name
        self.sessionIDs = []
        self.color = color
        self.createdAt = Date()
    }
}
