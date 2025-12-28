//
//  PlayerSettings.swift
//  EnglishShadowing
//
//  Created by Myoungwoo Jang on 12/28/25.
//

import Foundation

struct PlayerSettings {
    var autoPlay: Bool = false
    var showCaptions: Bool = false
    var showControls: Bool = false  // 기본값 true로 복원 (YouTubePlayerKit 제약)
    var showFullscreenButton: Bool = false
    var showRelatedVideos: Bool = false  // rel=0 (같은 채널만)
    var loop: Bool = false
    
    // YouTube Player Quality 설정
    enum PlaybackQuality: String, CaseIterable {
        case auto = "auto"
        case small = "small"      // 240p
        case medium = "medium"    // 360p
        case large = "large"      // 480p
        case hd720 = "hd720"      // 720p
        case hd1080 = "hd1080"    // 1080p
        
        var displayName: String {
            switch self {
            case .auto: return "자동"
            case .small: return "240p"
            case .medium: return "360p"
            case .large: return "480p"
            case .hd720: return "720p"
            case .hd1080: return "1080p"
            }
        }
    }
    
    var quality: PlaybackQuality = .auto
}
