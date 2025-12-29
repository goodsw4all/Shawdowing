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
        } detail: {
            // Content View
            if let session = selectedSession {
                ShadowingView(
                    session: session,
                    playerSettings: navigationVM.playerSettings
                )
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
