//
//  SessionDetailView.swift
//  EnglishShadowing
//
//  Created by Myoungwoo Jang on 12/28/25.
//

import SwiftUI

struct SessionDetailView: View {
    let session: ShadowingSession
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(session.video.title ?? "Untitled")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    HStack {
                        Label("Video ID: \(session.video.id)", systemImage: "link")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Progress")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(Int(session.progress * 100))%")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading) {
                            Text("Sentences")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(session.completedSentences.count)/\(session.sentences.count)")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    ProgressView(value: session.progress)
                        .tint(Color(hex: "#A8DADC"))
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sentences")
                        .font(.headline)
                    
                    ForEach(Array(session.sentences.enumerated()), id: \.element.id) { index, sentence in
                        HStack {
                            Image(systemName: sentence.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(sentence.isCompleted ? .green : .secondary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(sentence.text)
                                    .font(.body)
                                    .lineLimit(2)
                                
                                Text("\(TimeFormatter.formatTime(sentence.startTime)) - \(TimeFormatter.formatTime(sentence.endTime))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            sentence.isCompleted 
                                ? Color.green.opacity(0.15) 
                                : Color(nsColor: .controlBackgroundColor)
                        )
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    sentence.isCompleted 
                                        ? Color.green.opacity(0.3) 
                                        : Color(nsColor: .separatorColor).opacity(0.5),
                                    lineWidth: 1
                                )
                        )
                    }
                }
                .padding()
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Session Details")
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    let video = YouTubeVideo(id: "dQw4w9WgXcQ", title: "Sample Video")
    let sentences = [
        SentenceItem(text: "Hello, welcome to this video.", startTime: 0, endTime: 5),
        SentenceItem(text: "This is a sample sentence.", startTime: 5, endTime: 10)
    ]
    let session = ShadowingSession(video: video, sentences: sentences)
    
    return NavigationStack {
        SessionDetailView(session: session)
    }
}
