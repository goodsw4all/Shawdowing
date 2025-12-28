//
//  NewSessionView.swift
//  EnglishShadowing
//
//  Created by Myoungwoo Jang on 12/28/25.
//

import SwiftUI

struct NewSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var navigationVM: NavigationViewModel
    
    @State private var youtubeURL: String = "https://www.youtube.com/watch?v=dYCpuqbXjmg"
    @State private var sentencesText: String = """
        Hello, welcome to this video.
        Today we're going to learn English through shadowing.
        This is a very effective method for improving pronunciation.
        Let's get started with our first sentence.
        Repeat after me and try to match the rhythm.
        """
    @State private var videoTitle: String = "English Shadowing Practice"
    @State private var intervalSeconds: Double = 5.0
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("새 쉐도잉 세션 만들기")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("YouTube 영상과 학습할 문장을 입력하세요")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // YouTube URL
                    VStack(alignment: .leading, spacing: 8) {
                        Label("YouTube URL", systemImage: "link")
                            .font(.headline)
                        
                        TextField("https://www.youtube.com/watch?v=...", text: $youtubeURL)
                            .textFieldStyle(.roundedBorder)
                            .font(.body)
                        
                        if let videoID = VideoIDExtractor.extractVideoID(from: youtubeURL) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Video ID: \(videoID)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    // Video Title (Optional)
                    VStack(alignment: .leading, spacing: 8) {
                        Label("영상 제목 (선택사항)", systemImage: "text.alignleft")
                            .font(.headline)
                        
                        TextField("영상 제목을 입력하세요", text: $videoTitle)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    // Sentences Input
                    VStack(alignment: .leading, spacing: 8) {
                        Label("학습할 문장 입력", systemImage: "text.quote")
                            .font(.headline)
                        
                        Text("각 줄이 하나의 문장으로 처리됩니다")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        TextEditor(text: $sentencesText)
                            .frame(minHeight: 200)
                            .font(.body)
                            .padding(8)
                            .background(Color(nsColor: .textBackgroundColor))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                            )
                            .scrollContentBackground(.hidden)
                        
                        HStack {
                            Image(systemName: "number")
                                .foregroundStyle(.secondary)
                            Text("\(sentencesCount) 문장")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    // Timing Settings
                    VStack(alignment: .leading, spacing: 12) {
                        Label("타이밍 설정", systemImage: "clock")
                            .font(.headline)
                        
                        HStack {
                            Text("문장 간격:")
                                .font(.subheadline)
                            
                            Slider(value: $intervalSeconds, in: 3...10, step: 0.5)
                            
                            Text("\(intervalSeconds, specifier: "%.1f")초")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(width: 50)
                        }
                        
                        Text("각 문장은 자동으로 \(intervalSeconds, specifier: "%.1f")초 간격으로 배치됩니다")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    Spacer(minLength: 20)
                }
            }
            .background(Color(nsColor: .windowBackgroundColor))
            .navigationTitle("New Session")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("생성") {
                        createSession()
                    }
                    .disabled(!canCreate)
                }
            }
            .alert("오류", isPresented: $showError) {
                Button("확인", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
        .frame(minWidth: 600, minHeight: 700)
    }
    
    private var sentencesCount: Int {
        sentencesText
            .components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .count
    }
    
    private var canCreate: Bool {
        !youtubeURL.isEmpty &&
        VideoIDExtractor.extractVideoID(from: youtubeURL) != nil &&
        sentencesCount > 0
    }
    
    private func createSession() {
        guard let videoID = VideoIDExtractor.extractVideoID(from: youtubeURL) else {
            errorMessage = "유효하지 않은 YouTube URL입니다"
            showError = true
            return
        }
        
        let sentences = sentencesText
            .components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        guard !sentences.isEmpty else {
            errorMessage = "최소 1개 이상의 문장을 입력해주세요"
            showError = true
            return
        }
        
        // Create Video
        let video = YouTubeVideo(
            id: videoID,
            title: videoTitle.isEmpty ? nil : videoTitle
        )
        
        // Create Sentences with auto timing
        var currentTime: TimeInterval = 0
        let sentenceItems = sentences.map { text -> SentenceItem in
            let estimatedDuration = max(Double(text.count) / 10.0, 3.0)
            let startTime = currentTime
            let endTime = currentTime + estimatedDuration
            
            currentTime = endTime + intervalSeconds
            
            return SentenceItem(
                text: text,
                startTime: startTime,
                endTime: endTime
            )
        }
        
        // Create Session
        navigationVM.createNewSession(video: video, sentences: sentenceItems)
        
        dismiss()
    }
}

#Preview {
    NewSessionView()
        .environmentObject(NavigationViewModel())
}
