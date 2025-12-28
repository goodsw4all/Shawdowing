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
    @Published var playerSettings = PlayerSettings()  // 전역 플레이어 설정
    
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
        // init에서는 Task 생성만, 실제 로드는 .task modifier에서
    }
    

    
    func loadAllData() async {
        do {
            print("📂 Loading all sessions...")
            let sessions = try storageService.loadAllSessions()
            
            let activeList = sessions.filter { $0.status == .active }
            let historyList = sessions.filter { $0.status == .completed }
            
            self.activeSessions = activeList
            self.history = historyList
            
            print("✅ Loaded \(activeList.count) active + \(historyList.count) history sessions")
            
            self.playlists = try storageService.loadAllPlaylists()
        } catch {
            print("❌ Failed to load data: \(error)")
            self.activeSessions = []
            self.history = []
            self.playlists = []
        }
    }
    
    func createNewSession(video: YouTubeVideo, sentences: [SentenceItem]) {
        let session = ShadowingSession(video: video, sentences: sentences, status: .active)
        activeSessions.append(session)
        
        print("💾 [createNewSession] Starting save for: \(session.video.title ?? session.video.id)")
        print("💾 [createNewSession] Session ID: \(session.id)")
        print("💾 [createNewSession] Sentences count: \(sentences.count)")
        
        Task {
            do {
                try storageService.saveSession(session)
                print("✅ [createNewSession] Session saved successfully")
            } catch {
                print("❌ [createNewSession] Failed to save session: \(error)")
                print("❌ [createNewSession] Error details: \(error.localizedDescription)")
            }
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
