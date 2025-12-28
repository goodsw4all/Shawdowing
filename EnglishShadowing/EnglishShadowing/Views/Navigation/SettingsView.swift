//
//  SettingsView.swift
//  EnglishShadowing
//
//  Created by Myoungwoo Jang on 12/28/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var navigationVM: NavigationViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("플레이어 설정") {
                    Toggle("자동 재생", isOn: $navigationVM.playerSettings.autoPlay)
                    Toggle("반복 재생", isOn: $navigationVM.playerSettings.loop)
                }
                
                Section("표시 설정") {
                    Toggle("YouTube 컨트롤 표시", isOn: $navigationVM.playerSettings.showControls)
                    Toggle("전체화면 버튼 표시", isOn: $navigationVM.playerSettings.showFullscreenButton)
                    Toggle("자막 표시", isOn: $navigationVM.playerSettings.showCaptions)
                    Toggle("추천 동영상 표시", isOn: $navigationVM.playerSettings.showRelatedVideos)
                        .help("OFF: 같은 채널 동영상만 추천")
                }
                
                Section("화질 설정") {
                    Picker("화질", selection: $navigationVM.playerSettings.quality) {
                        ForEach(PlayerSettings.PlaybackQuality.allCases, id: \.self) { quality in
                            Text(quality.displayName).tag(quality)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section {
                    Text("플레이어 설정은 새로운 세션을 시작할 때 적용됩니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section("정보") {
                    LabeledContent("버전", value: "1.0.0")
                    LabeledContent("활성 세션", value: "\(navigationVM.activeSessions.count)")
                    LabeledContent("히스토리", value: "\(navigationVM.history.count)")
                    LabeledContent("즐겨찾기", value: "\(navigationVM.favoriteSentences.count)")
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") {
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .frame(width: 500, height: 500)
    }
}

#Preview {
    SettingsView()
        .environmentObject(NavigationViewModel())
}
