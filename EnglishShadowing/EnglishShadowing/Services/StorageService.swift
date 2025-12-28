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
    
    private var sessionsDirectory: URL {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let sessionsURL = documentsURL.appendingPathComponent("EnglishShadowing/Sessions")
        
        if !fileManager.fileExists(atPath: sessionsURL.path) {
            try? fileManager.createDirectory(at: sessionsURL, withIntermediateDirectories: true)
        }
        return sessionsURL
    }
    
    private var playlistsDirectory: URL {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let playlistsURL = documentsURL.appendingPathComponent("EnglishShadowing/Playlists")
        
        if !fileManager.fileExists(atPath: playlistsURL.path) {
            try? fileManager.createDirectory(at: playlistsURL, withIntermediateDirectories: true)
        }
        return playlistsURL
    }
    
    func saveSession(_ session: ShadowingSession) throws {
        let fileURL = sessionsDirectory.appendingPathComponent("\(session.id.uuidString).json")
        let data = try encoder.encode(session)
        try data.write(to: fileURL)
    }
    
    func loadSession(id: UUID) throws -> ShadowingSession? {
        let fileURL = sessionsDirectory.appendingPathComponent("\(id.uuidString).json")
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(ShadowingSession.self, from: data)
    }
    
    func loadAllSessions() throws -> [ShadowingSession] {
        let files = try fileManager.contentsOfDirectory(at: sessionsDirectory, includingPropertiesForKeys: nil)
        
        return try files.compactMap { url in
            guard url.pathExtension == "json" else { return nil }
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
