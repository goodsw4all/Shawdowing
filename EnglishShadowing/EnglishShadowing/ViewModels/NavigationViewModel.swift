//
//  NavigationViewModel.swift
//  EnglishShadowing
//
//  Created by Myoungwoo Jang on 12/28/25.
//

import Foundation
import Combine

@MainActor
class NavigationViewModel: ObservableObject {
    @Published var activeSessions: [ShadowingSession] = []
    @Published var history: [ShadowingSession] = []
    @Published var playlists: [Playlist] = []
    
    private let storageService = StorageService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Computed property: 모든 세션에서 즐겨찾기된 문장들
    var favoriteSentences: [(session: ShadowingSession, sentence: SentenceItem)] {
        let allSessions = activeSessions + history
        var favorites: [(ShadowingSession, SentenceItem)] = []
        
        for session in allSessions {
            let favs = session.sentences.filter { $0.isFavorite }
            for sentence in favs {
                favorites.append((session, sentence))
            }
        }
        
        return favorites
    }
    
    init() {
        loadAllData()
        createSampleDataIfNeeded()
    }
    
    private func createSampleDataIfNeeded() {
        // 샘플 데이터가 없으면 생성
        if activeSessions.isEmpty && history.isEmpty {
            createSampleSessions()
        }
    }
    
    private func createSampleSessions() {
        // Sample Video 1: Active Session
        let video1 = YouTubeVideo(
            id: "dQw4w9WgXcQ",
            title: "Sample English Learning Video"
        )
        let sentences1 = [
            SentenceItem(text: "Hello, welcome to this English learning session.", startTime: 0, endTime: 5),
            SentenceItem(text: "Today we're going to practice shadowing.", startTime: 10, endTime: 15),
            SentenceItem(text: "Repeat after me and improve your pronunciation.", startTime: 20, endTime: 25),
        ]
        var session1 = ShadowingSession(video: video1, sentences: sentences1, status: .active)
        session1.completedSentences.insert(sentences1[0].id)
        
        activeSessions.append(session1)
        
        Task {
            try? storageService.saveSession(session1)
        }
    }
    
    func loadAllData() {
        Task {
            do {
                let sessions = try storageService.loadAllSessions()
                
                self.activeSessions = sessions.filter { $0.status == .active }
                self.history = sessions.filter { $0.status == .completed }
                
                self.playlists = try storageService.loadAllPlaylists()
            } catch {
                print("Failed to load data: \(error)")
                // 데이터 로드 실패 시 초기화
                self.activeSessions = []
                self.history = []
                self.playlists = []
                
                // 샘플 데이터 생성
                createSampleSessions()
            }
        }
    }
    
    func createNewSession(video: YouTubeVideo, sentences: [SentenceItem]) {
        let session = ShadowingSession(video: video, sentences: sentences, status: .active)
        activeSessions.append(session)
        
        Task {
            try? storageService.saveSession(session)
        }
    }
    
    func updateSession(_ session: ShadowingSession) {
        if let index = activeSessions.firstIndex(where: { $0.id == session.id }) {
            activeSessions[index] = session
        } else if let index = history.firstIndex(where: { $0.id == session.id }) {
            history[index] = session
        }
        
        Task {
            try? storageService.saveSession(session)
        }
    }
    
    func deleteSession(_ session: ShadowingSession) {
        activeSessions.removeAll { $0.id == session.id }
        history.removeAll { $0.id == session.id }
        
        Task {
            try? storageService.deleteSession(id: session.id)
        }
    }
    
    func completeSession(_ session: ShadowingSession) {
        var updatedSession = session
        updatedSession.status = .completed
        updatedSession.updatedAt = Date()
        
        if let index = activeSessions.firstIndex(where: { $0.id == session.id }) {
            activeSessions.remove(at: index)
        }
        
        history.insert(updatedSession, at: 0)
        
        Task {
            try? storageService.saveSession(updatedSession)
        }
    }
}
