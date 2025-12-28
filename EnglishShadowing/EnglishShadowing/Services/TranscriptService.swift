//
//  TranscriptService.swift
//  EnglishShadowing
//
//  Created by GitHub Copilot on 12/28/25.
//

import Foundation
import YoutubeTranscript

/// YouTube 자막 추출 서비스
@MainActor
class TranscriptService {
    static let shared = TranscriptService()
    
    private init() {}
    
    /// 자막 추출 에러
    enum TranscriptError: LocalizedError {
        case notAvailable
        case networkError(Error)
        case parsingError
        
        var errorDescription: String? {
            switch self {
            case .notAvailable:
                return "이 영상은 자막을 제공하지 않습니다"
            case .networkError(let error):
                return "네트워크 오류: \(error.localizedDescription)"
            case .parsingError:
                return "자막 파싱 중 오류가 발생했습니다"
            }
        }
        
        var userFriendlyMessage: String {
            switch self {
            case .notAvailable:
                return """
                이 영상은 자막을 제공하지 않습니다.
                아래 텍스트 영역에 직접 문장을 입력해주세요.
                """
            case .networkError:
                return """
                네트워크 연결을 확인해주세요.
                인터넷 연결 후 다시 시도하거나 수동으로 입력할 수 있습니다.
                """
            case .parsingError:
                return """
                자막 형식을 인식할 수 없습니다.
                수동으로 문장을 입력해주세요.
                """
            }
        }
    }
    
    /// YouTube Video ID로 자막 추출
    /// - Parameters:
    ///   - videoID: YouTube Video ID
    /// - Returns: 추출된 문장 배열
    func fetchTranscript(videoID: String) async throws -> [SentenceItem] {
        print("🎬 Fetching transcript for video: \(videoID)")
        
        do {
            // 1. YoutubeTranscript로 자막 가져오기
            let transcript = try await YoutubeTranscript.fetchTranscript(for: videoID)
            
            print("✅ Fetched \(transcript.count) subtitle entries")
            
            // 2. TranscriptEntry → SentenceItem 변환
            let sentences = transcript.map { entry in
                SentenceItem(
                    text: entry.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
                    startTime: entry.offset,
                    endTime: entry.offset + entry.duration
                )
            }
            
            // 3. 빈 문장 제거
            let filtered = sentences.filter { !$0.text.isEmpty }
            
            print("📝 Converted to \(filtered.count) sentences")
            
            return filtered
            
        } catch {
            print("❌ Transcript fetch error: \(error)")
            // swift-youtube-transcript의 에러를 우리 에러로 변환
            if error.localizedDescription.contains("not available") || 
               error.localizedDescription.contains("No transcript") {
                throw TranscriptError.notAvailable
            } else {
                throw TranscriptError.networkError(error)
            }
        }
    }
    
    /// 짧은 자막들을 문장 단위로 병합
    /// - Parameters:
    ///   - sentences: 원본 문장 배열
    ///   - maxDuration: 최대 문장 길이 (초)
    /// - Returns: 병합된 문장 배열
    func mergeSentences(_ sentences: [SentenceItem], maxDuration: TimeInterval = 10.0) -> [SentenceItem] {
        guard !sentences.isEmpty else { return [] }
        
        print("🔀 Merging \(sentences.count) sentences...")
        
        var merged: [SentenceItem] = []
        var currentText = ""
        var currentStart: TimeInterval = 0
        var currentEnd: TimeInterval = 0
        
        for (index, sentence) in sentences.enumerated() {
            // 첫 문장
            if currentText.isEmpty {
                currentText = sentence.text
                currentStart = sentence.startTime
                currentEnd = sentence.endTime
                continue
            }
            
            let duration = currentEnd - currentStart
            let endsWithPunctuation = currentText.hasSuffix(".") || 
                                     currentText.hasSuffix("!") || 
                                     currentText.hasSuffix("?")
            
            // 문장 분리 조건:
            // 1. 문장 종결 부호로 끝남
            // 2. 최대 길이 초과
            // 3. 마지막 문장
            if endsWithPunctuation || duration >= maxDuration || index == sentences.count - 1 {
                // 마지막이지만 이어붙일 수 있으면 붙이기
                if index == sentences.count - 1 && !endsWithPunctuation && duration < maxDuration {
                    currentText += " " + sentence.text
                    currentEnd = sentence.endTime
                }
                
                merged.append(SentenceItem(
                    text: currentText,
                    startTime: currentStart,
                    endTime: currentEnd
                ))
                
                // 다음 문장 시작 (마지막이 아닐 때만)
                if index < sentences.count - 1 {
                    currentText = sentence.text
                    currentStart = sentence.startTime
                    currentEnd = sentence.endTime
                } else {
                    currentText = ""
                }
            } else {
                // 계속 이어붙이기
                currentText += " " + sentence.text
                currentEnd = sentence.endTime
            }
        }
        
        // 마지막 남은 문장 추가
        if !currentText.isEmpty {
            merged.append(SentenceItem(
                text: currentText,
                startTime: currentStart,
                endTime: currentEnd
            ))
        }
        
        print("✅ Merged into \(merged.count) sentences")
        
        return merged
    }
}
