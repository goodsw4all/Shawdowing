//
//  EnglishShadowingApp.swift
//  EnglishShadowing
//
//  Created by Myoungwoo Jang on 12/28/25.
//

import SwiftUI
import AppKit

@main
struct EnglishShadowingApp: App {
    @StateObject private var navigationVM = NavigationViewModel()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(navigationVM)
                .frame(minWidth: 1200, minHeight: 800)
                .task {
                    // 앱 시작 시 데이터 로드
                    await navigationVM.loadAllData()
                }
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

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
