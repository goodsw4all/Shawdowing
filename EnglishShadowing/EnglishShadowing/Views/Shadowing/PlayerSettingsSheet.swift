//
//  PlayerSettingsSheet.swift
//  EnglishShadowing
//
//  Created by Myoungwoo Jang on 12/28/25.
//

import SwiftUI

struct PlayerSettingsSheet: View {
    @Binding var settings: PlayerSettings
    @Environment(\.dismiss) private var dismiss
    let onApply: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("재생 설정") {
                    Toggle("자동 재생", isOn: $settings.autoPlay)
                    Toggle("반복 재생", isOn: $settings.loop)
                }
                
                Section("표시 설정") {
                    Toggle("YouTube 컨트롤 표시", isOn: $settings.showControls)
                    Toggle("전체화면 버튼 표시", isOn: $settings.showFullscreenButton)
                    Toggle("자막 표시", isOn: $settings.showCaptions)
                }
                
                Section("화질 설정") {
                    Picker("화질", selection: $settings.quality) {
                        ForEach(PlayerSettings.PlaybackQuality.allCases, id: \.self) { quality in
                            Text(quality.displayName).tag(quality)
                        }
                    }
                }
                
                Section {
                    Text("설정을 변경하면 플레이어가 다시 로드됩니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("플레이어 설정")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("적용") {
                        onApply()
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .frame(width: 450, height: 400)
    }
}

#Preview {
    PlayerSettingsSheet(settings: .constant(PlayerSettings())) {
        print("Applied")
    }
}
