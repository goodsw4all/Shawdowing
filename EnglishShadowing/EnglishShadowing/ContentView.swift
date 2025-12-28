//
//  ContentView.swift
//  EnglishShadowing
//
//  Created by Myoungwoo Jang on 12/28/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var navigationVM: NavigationViewModel
    @State private var selectedSession: ShadowingSession?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            SidebarView(selectedSession: $selectedSession)
                .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
        } content: {
            // Detail View
            if let session = selectedSession {
                SessionDetailView(session: session)
                    .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
            } else {
                Text("Select a session")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } detail: {
            // Content View
            if let session = selectedSession {
                ShadowingView(session: session)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "play.circle")
                        .font(.system(size: 80))
                        .foregroundStyle(.secondary)
                    Text("Welcome to English Shadowing")
                        .font(.title)
                    Text("Select a session or create a new one to get started")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(NavigationViewModel())
}
