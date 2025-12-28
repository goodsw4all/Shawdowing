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
    @State private var sentencesText: String = ""
    @State private var videoTitle: String = ""
    @State private var intervalSeconds: Double = 5.0
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isLoadingTranscript: Bool = false
    @State private var transcriptError: String? = nil
    @State private var extractedSentences: [SentenceItem]? = nil  // 자막에서 추출한 문장 (타이밍 포함)
    
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
                        
                        HStack {
                            if let videoID = VideoIDExtractor.extractVideoID(from: youtubeURL) {
                                // Video ID 인식 표시
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                    Text("Video ID: \(videoID)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                // 자막 자동 추출 버튼
                                Button {
                                    Task {
                                        await autoExtractTranscript(videoID: videoID)
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        if isLoadingTranscript {
                                            ProgressView()
                                                .controlSize(.small)
                                        } else {
                                            Image(systemName: "text.bubble")
                                        }
                                        Text("자막 추출")
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(isLoadingTranscript)
                            }
                        }
                        
                        // 자막 추출 에러 메시지
                        if let error = transcriptError {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text(error)
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
                        HStack {
                            Label("학습할 문장", systemImage: "text.quote")
                                .font(.headline)
                            
                            Spacer()
                            
                            if sentencesCount > 0 {
                                Text("\(sentencesCount) 문장")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        if sentencesText.isEmpty {
                            Text("위의 '자막 추출' 버튼을 클릭하거나 직접 입력하세요")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("자막이 자동으로 추출되었습니다. 수정 가능합니다.")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                        
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
                    
                    // Timing Settings - 자막 추출 시 자동 설정됨
                    if extractedSentences == nil {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("타이밍 정보", systemImage: "info.circle")
                                .font(.headline)
                            
                            Text("자막 자동 추출 시 정확한 타이밍이 적용됩니다.\n수동 입력 시 문장 길이에 따라 자동 계산됩니다.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        .padding(.horizontal)
                    }
                    
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
    
    /// 자막 자동 추출
    private func autoExtractTranscript(videoID: String) async {
        isLoadingTranscript = true
        transcriptError = nil
        
        print("🎬 Starting transcript extraction for video: \(videoID)")
        
        do {
            // 1. TranscriptService로 자막 가져오기
            let sentences = try await TranscriptService.shared.fetchTranscript(videoID: videoID)
            
            guard !sentences.isEmpty else {
                throw TranscriptService.TranscriptError.notAvailable
            }
            
            // 2. 문장 병합 (짧은 자막들을 합침)
            let merged = TranscriptService.shared.mergeSentences(sentences)
            
            // 3. TextEditor에 표시 (UI 업데이트는 MainActor에서)
            await MainActor.run {
                // 타이밍 정보 포함된 문장들 저장
                extractedSentences = merged
                
                // 텍스트만 TextEditor에 표시
                sentencesText = merged.map { $0.text }.joined(separator: "\n")
                isLoadingTranscript = false
                
                print("✅ Transcript extracted successfully: \(merged.count) sentences")
            }
            
        } catch let error as TranscriptService.TranscriptError {
            // 4. 에러 처리
            await MainActor.run {
                transcriptError = error.userFriendlyMessage
                isLoadingTranscript = false
                
                print("❌ Transcript extraction failed: \(error.localizedDescription ?? "Unknown error")")
            }
        } catch {
            await MainActor.run {
                transcriptError = "알 수 없는 오류가 발생했습니다"
                isLoadingTranscript = false
                
                print("❌ Unexpected error: \(error)")
            }
        }
    }
    
    private func createSession() {
        guard let videoID = VideoIDExtractor.extractVideoID(from: youtubeURL) else {
            errorMessage = "유효하지 않은 YouTube URL입니다"
            showError = true
            return
        }
        
        // Create Video
        let video = YouTubeVideo(
            id: videoID,
            title: videoTitle.isEmpty ? nil : videoTitle
        )
        
        // 자막에서 추출한 문장이 있으면 사용 (타이밍 포함)
        let sentenceItems: [SentenceItem]
        
        if let extracted = extractedSentences {
            // 자막 자동 추출된 경우: 원본 타이밍 사용
            print("✅ Using extracted sentences with original timing")
            sentenceItems = extracted
        } else {
            // 수동 입력된 경우: 타이밍 자동 계산
            print("⚠️ Using manual input, calculating timing")
            let sentences = sentencesText
                .components(separatedBy: .newlines)
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            
            guard !sentences.isEmpty else {
                errorMessage = "최소 1개 이상의 문장을 입력해주세요"
                showError = true
                return
            }
            
            var currentTime: TimeInterval = 0
            sentenceItems = sentences.map { text -> SentenceItem in
                let estimatedDuration = max(Double(text.count) / 10.0, 3.0)
                let startTime = currentTime
                let endTime = currentTime + estimatedDuration
                
                // 다음 문장은 이전 문장 종료 시점부터 시작 (연속)
                currentTime = endTime
                
                return SentenceItem(
                    text: text,
                    startTime: startTime,
                    endTime: endTime
                )
            }
        }
        
        // Create Session
        print("🎬 Creating session with video ID: \(videoID)")
        navigationVM.createNewSession(video: video, sentences: sentenceItems)
        
        dismiss()
    }
}

#Preview {
    NewSessionView()
        .environmentObject(NavigationViewModel())
}
