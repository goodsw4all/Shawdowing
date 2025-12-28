//
//  YouTubeVideo.swift
//  EnglishShadowing
//
//  Created by Myoungwoo Jang on 12/28/25.
//

import Foundation

struct YouTubeVideo: Identifiable, Codable, Hashable {
    let id: String  // YouTube Video ID
    var title: String?
    var thumbnailURL: URL?
    var duration: TimeInterval?
    
    init(id: String, title: String? = nil, thumbnailURL: URL? = nil, duration: TimeInterval? = nil) {
        self.id = id
        self.title = title
        self.thumbnailURL = thumbnailURL
        self.duration = duration
    }
}
