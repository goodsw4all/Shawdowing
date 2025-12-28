//
//  SidebarView.swift
//  EnglishShadowing
//
//  Created by Myoungwoo Jang on 12/28/25.
//

import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var navigationVM: NavigationViewModel
    @Binding var selectedSession: ShadowingSession?
    @State private var showingNewSession = false
    @State private var showingSettings = false  // Settings Sheet
    
    var body: some View {
        List(selection: $selectedSession) {
            Section {
                ForEach(navigationVM.activeSessions) { session in
                    SessionRowView(session: session)
                        .tag(session)
                }
                
                Button {
                    showingNewSession = true
                } label: {
                    Label("New Session", systemImage: "plus.circle")
                }
            } header: {
                Label("Active", systemImage: "play.circle.fill")
            }
            
            // 즐겨찾기 섹션
            Section {
                ForEach(navigationVM.favoriteSentences, id: \.sentence.id) { item in
                    FavoriteSentenceRow(
                        session: item.session,
                        sentence: item.sentence,
                        onSelect: {
                            selectedSession = item.session
                        }
                    )
                }
            } header: {
                Label("Favorites", systemImage: "star.fill")
                    .foregroundStyle(.yellow)
            }
            
            Section {
                ForEach(navigationVM.history) { session in
                    SessionRowView(session: session)
                        .tag(session)
                }
            } header: {
                Label("History", systemImage: "checkmark.circle")
            }
            
            Section {
                ForEach(navigationVM.playlists) { playlist in
                    Label(playlist.name, systemImage: "folder")
                }
            } header: {
                Label("Playlists", systemImage: "folder.fill")
            }
            
            // Settings 섹션
            Section {
                Button {
                    showingSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Library")
        .sheet(isPresented: $showingNewSession) {
            NewSessionView()
                .environmentObject(navigationVM)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(navigationVM)
        }
    }
}

struct FavoriteSentenceRow: View {
    let session: ShadowingSession
    let sentence: SentenceItem
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                    
                    Text(session.video.title ?? "Untitled")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Text(sentence.text)
                    .font(.body)
                    .lineLimit(2)
                
                Text(TimeFormatter.formatTime(sentence.startTime))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct SessionRowView: View {
    let session: ShadowingSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.video.title ?? "Untitled")
                .font(.body)
                .lineLimit(1)
            
            HStack {
                Text("\(session.sentences.count) sentences")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if session.progress > 0 {
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text("\(Int(session.progress * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationSplitView {
        SidebarView(selectedSession: .constant(nil))
            .environmentObject(NavigationViewModel())
    } detail: {
        Text("Detail")
    }
}
