//
//  StringExtensions.swift
//  EnglishShadowing
//
//  Created by GitHub Copilot on 12/29/25.
//

import Foundation
import AppKit

extension String {
    /// HTML entities를 디코딩
    /// - Returns: 디코딩된 문자열
    func decodingHTMLEntities() -> String {
        guard let data = self.data(using: .utf8) else {
            return self
        }
        
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        
        guard let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) else {
            // Fallback: 일반적인 HTML entities 수동 치환
            return self
                .replacingOccurrences(of: "&#39;", with: "'")
                .replacingOccurrences(of: "&quot;", with: "\"")
                .replacingOccurrences(of: "&amp;", with: "&")
                .replacingOccurrences(of: "&lt;", with: "<")
                .replacingOccurrences(of: "&gt;", with: ">")
                .replacingOccurrences(of: "&nbsp;", with: " ")
                .replacingOccurrences(of: "&#x27;", with: "'")
                .replacingOccurrences(of: "&#x2F;", with: "/")
        }
        
        return attributedString.string
    }
    
    /// 빠른 HTML entities 디코딩 (일반적인 경우만)
    func decodingCommonHTMLEntities() -> String {
        return self
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&#x27;", with: "'")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&#x2F;", with: "/")
    }
}
