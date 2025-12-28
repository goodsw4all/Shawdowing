//
//  EnglishShadowingApp.swift
//  EnglishShadowing
//
//  Created by Myoungwoo Jang on 12/28/25.
//

import SwiftUI

@main
struct EnglishShadowingApp: App {
    @StateObject private var navigationVM = NavigationViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(navigationVM)
                .frame(minWidth: 1200, minHeight: 800)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Session") {
                    // TODO: 새 세션 생성
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }
}
