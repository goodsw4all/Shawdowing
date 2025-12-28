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
        }
        .listStyle(.sidebar)
        .navigationTitle("Library")
        .sheet(isPresented: $showingNewSession) {
            NewSessionView()
                .environmentObject(navigationVM)
        }
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
