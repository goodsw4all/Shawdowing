//
//  YouTubeMetadataService.swift
//  EnglishShadowing
//
//  Created by GitHub Copilot on 12/29/25.
//

import Foundation

@MainActor
class YouTubeMetadataService {
    static let shared = YouTubeMetadataService()
    
    private init() {}
    
    enum MetadataError: LocalizedError {
        case invalidURL
        case networkError(Error)
        case parsingError
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "잘못된 비디오 ID입니다"
            case .networkError(let error):
                return "네트워크 오류: \(error.localizedDescription)"
            case .parsingError:
                return "메타데이터 파싱 오류"
            }
        }
    }
    
    struct VideoMetadata {
        let title: String
        let thumbnailURL: URL?
        let duration: TimeInterval?
    }
    
    /// YouTube oEmbed API를 통해 비디오 메타데이터 가져오기
    func fetchMetadata(videoID: String) async throws -> VideoMetadata {
        let urlString = "https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=\(videoID)&format=json"
        
        guard let url = URL(string: urlString) else {
            throw MetadataError.invalidURL
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw MetadataError.parsingError
            }
            
            let title = json["title"] as? String ?? "YouTube Video"
            
            // 썸네일 URL 추출
            var thumbnailURL: URL?
            if let thumbnailURLString = json["thumbnail_url"] as? String {
                thumbnailURL = URL(string: thumbnailURLString)
            }
            
            return VideoMetadata(
                title: title,
                thumbnailURL: thumbnailURL,
                duration: nil  // oEmbed는 duration을 제공하지 않음
            )
            
        } catch {
            if let metadataError = error as? MetadataError {
                throw metadataError
            } else {
                throw MetadataError.networkError(error)
            }
        }
    }
    
    /// 기본 썸네일 URL 생성 (API 호출 없이)
    func generateThumbnailURL(videoID: String, quality: ThumbnailQuality = .medium) -> URL? {
        let urlString: String
        switch quality {
        case .default:
            urlString = "https://img.youtube.com/vi/\(videoID)/default.jpg"
        case .medium:
            urlString = "https://img.youtube.com/vi/\(videoID)/mqdefault.jpg"
        case .high:
            urlString = "https://img.youtube.com/vi/\(videoID)/hqdefault.jpg"
        case .standard:
            urlString = "https://img.youtube.com/vi/\(videoID)/sddefault.jpg"
        case .maxres:
            urlString = "https://img.youtube.com/vi/\(videoID)/maxresdefault.jpg"
        }
        return URL(string: urlString)
    }
    
    enum ThumbnailQuality {
        case `default`  // 120x90
        case medium     // 320x180
        case high       // 480x360
        case standard   // 640x480
        case maxres     // 1280x720
    }
}
