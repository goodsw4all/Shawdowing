//
//  SentenceItem.swift
//  EnglishShadowing
//
//  Created by Myoungwoo Jang on 12/28/25.
//

import Foundation

enum ProsodyMetric: String, Codable, CaseIterable, Hashable {
    case stress
    case rhythm
    case linking
    
    var displayName: String {
        switch self {
        case .stress: return "강세"
        case .rhythm: return "리듬"
        case .linking: return "연음"
        }
    }
}

enum ProsodyScore: String, Codable, CaseIterable, Hashable {
    case notEvaluated
    case needsPractice
    case confident
    
    /// 사용자가 동일 버튼을 눌렀을 때 다음 상태로 이동시켜 빠르게 자기 점검을 반복할 수 있도록 상태 순서를 정의한다.
    var next: ProsodyScore {
        switch self {
        case .notEvaluated: return .needsPractice
        case .needsPractice: return .confident
        case .confident: return .notEvaluated
        }
    }
}

struct ProsodyAssessment: Codable, Hashable {
    var stress: ProsodyScore = .notEvaluated
    var rhythm: ProsodyScore = .notEvaluated
    var linking: ProsodyScore = .notEvaluated
    
    /// 지정된 메트릭의 현재 스코어를 반환해 UI가 동일한 접근 방식을 재사용할 수 있게 한다.
    func score(for metric: ProsodyMetric) -> ProsodyScore {
        switch metric {
        case .stress: return stress
        case .rhythm: return rhythm
        case .linking: return linking
        }
    }
    
    /// 사용자가 선택한 메트릭만 업데이트하여 다른 평가값을 보존한다.
    mutating func setScore(_ score: ProsodyScore, for metric: ProsodyMetric) {
        switch metric {
        case .stress: stress = score
        case .rhythm: rhythm = score
        case .linking: linking = score
        }
    }
    
    /// 동일 버튼을 눌러 순환할 수 있도록 현재 값을 기준으로 다음 상태를 계산한다.
    mutating func cycle(metric: ProsodyMetric) {
        let nextScore = score(for: metric).next
        setScore(nextScore, for: metric)
    }
}

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
    var prosodyAssessment: ProsodyAssessment = ProsodyAssessment()
    
    var duration: TimeInterval {
        endTime - startTime
    }
    
    init(
        id: UUID = UUID(),
        text: String,
        startTime: TimeInterval,
        endTime: TimeInterval,
        repeatCount: Int = 3
    ) {
        self.id = id
        self.text = text
        self.startTime = startTime
        self.endTime = endTime
        self.repeatCount = repeatCount
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case startTime
        case endTime
        case repeatCount
        case recordings
        case isCompleted
        case isFavorite
        case currentRepeat
        case notes
        case prosodyAssessment
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        startTime = try container.decode(TimeInterval.self, forKey: .startTime)
        endTime = try container.decode(TimeInterval.self, forKey: .endTime)
        repeatCount = try container.decodeIfPresent(Int.self, forKey: .repeatCount) ?? 3
        recordings = try container.decodeIfPresent([URL].self, forKey: .recordings) ?? []
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        currentRepeat = try container.decodeIfPresent(Int.self, forKey: .currentRepeat) ?? 0
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        prosodyAssessment = try container.decodeIfPresent(ProsodyAssessment.self, forKey: .prosodyAssessment) ?? ProsodyAssessment()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
        try container.encode(repeatCount, forKey: .repeatCount)
        try container.encode(recordings, forKey: .recordings)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(isFavorite, forKey: .isFavorite)
        try container.encode(currentRepeat, forKey: .currentRepeat)
        try container.encode(notes, forKey: .notes)
        try container.encode(prosodyAssessment, forKey: .prosodyAssessment)
    }
}
