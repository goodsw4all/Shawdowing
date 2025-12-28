//
//  VideoIDExtractor.swift
//  EnglishShadowing
//
//  Created by Myoungwoo Jang on 12/28/25.
//

import Foundation

struct VideoIDExtractor {
    static func extractVideoID(from url: String) -> String? {
        let patterns = [
            "(?:youtube\\.com\\/watch\\?v=|youtu\\.be\\/)([\\w-]+)",
            "youtube\\.com\\/embed\\/([\\w-]+)",
            "youtube\\.com\\/v\\/([\\w-]+)"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(url.startIndex..., in: url)
                if let match = regex.firstMatch(in: url, options: [], range: range) {
                    if let range = Range(match.range(at: 1), in: url) {
                        return String(url[range])
                    }
                }
            }
        }
        return nil
    }
    
    static func isValidVideoID(_ videoID: String) -> Bool {
        let pattern = "^[\\w-]{11}$"
        return videoID.range(of: pattern, options: .regularExpression) != nil
    }
}
