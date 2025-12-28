//
//  StorageService.swift
//  EnglishShadowing
//
//  Created by Myoungwoo Jang on 12/28/25.
//

import Foundation

class StorageService {
    static let shared = StorageService()
    
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    init() {
        // 초기화 시 디렉토리 생성 확인
        _ = sessionsDirectory
        _ = playlistsDirectory
        print("🔧 StorageService initialized")
    }
    
    private var sessionsDirectory: URL {
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let sessionsURL = appSupportURL.appendingPathComponent("com.myoungwoo.EnglishShadowing/Sessions")
        
        print("📁 Sessions directory path: \(sessionsURL.path)")
        print("📁 Directory exists: \(fileManager.fileExists(atPath: sessionsURL.path))")
        
        if !fileManager.fileExists(atPath: sessionsURL.path) {
            do {
                try fileManager.createDirectory(at: sessionsURL, withIntermediateDirectories: true, attributes: nil)
                print("✅ Created sessions directory at: \(sessionsURL.path)")
            } catch {
                print("❌ Failed to create sessions directory: \(error)")
                print("❌ Error details: \(error.localizedDescription)")
            }
        } else {
            print("✅ Sessions directory already exists")
        }
        
        return sessionsURL
    }
    
    private var playlistsDirectory: URL {
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let playlistsURL = appSupportURL.appendingPathComponent("com.myoungwoo.EnglishShadowing/Playlists")
        
        if !fileManager.fileExists(atPath: playlistsURL.path) {
            do {
                try fileManager.createDirectory(at: playlistsURL, withIntermediateDirectories: true)
                print("📁 Created playlists directory at: \(playlistsURL.path)")
            } catch {
                print("❌ Failed to create playlists directory: \(error)")
            }
        }
        return playlistsURL
    }
    
    func saveSession(_ session: ShadowingSession) throws {
        let directory = sessionsDirectory
        print("💾 Attempting to save session to directory: \(directory.path)")
        print("💾 Directory exists: \(fileManager.fileExists(atPath: directory.path))")
        
        let fileURL = directory.appendingPathComponent("\(session.id.uuidString).json")
        print("💾 File URL: \(fileURL.path)")
        
        let data = try encoder.encode(session)
        print("💾 Encoded data size: \(data.count) bytes")
        
        try data.write(to: fileURL, options: .atomic)
        print("✅ Session saved successfully to: \(fileURL.path)")
        
        // 검증
        let exists = fileManager.fileExists(atPath: fileURL.path)
        print("💾 File exists after save: \(exists)")
    }
    
    func loadSession(id: UUID) throws -> ShadowingSession? {
        let fileURL = sessionsDirectory.appendingPathComponent("\(id.uuidString).json")
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(ShadowingSession.self, from: data)
    }
    
    func loadAllSessions() throws -> [ShadowingSession] {
        let files = try fileManager.contentsOfDirectory(at: sessionsDirectory, includingPropertiesForKeys: nil)
        print("📂 Found \(files.count) files in sessions directory")
        
        return try files.compactMap { url in
            guard url.pathExtension == "json" else { return nil }
            print("📄 Loading session from: \(url.lastPathComponent)")
            let data = try Data(contentsOf: url)
            return try decoder.decode(ShadowingSession.self, from: data)
        }
    }
    
    func deleteSession(id: UUID) throws {
        let fileURL = sessionsDirectory.appendingPathComponent("\(id.uuidString).json")
        try fileManager.removeItem(at: fileURL)
    }
    
    func savePlaylist(_ playlist: Playlist) throws {
        let fileURL = playlistsDirectory.appendingPathComponent("\(playlist.id.uuidString).json")
        let data = try encoder.encode(playlist)
        try data.write(to: fileURL)
    }
    
    func loadAllPlaylists() throws -> [Playlist] {
        let files = try fileManager.contentsOfDirectory(at: playlistsDirectory, includingPropertiesForKeys: nil)
        
        return try files.compactMap { url in
            guard url.pathExtension == "json" else { return nil }
            let data = try Data(contentsOf: url)
            return try decoder.decode(Playlist.self, from: data)
        }
    }
    
    func deletePlaylist(id: UUID) throws {
        let fileURL = playlistsDirectory.appendingPathComponent("\(id.uuidString).json")
        try fileManager.removeItem(at: fileURL)
    }
}
