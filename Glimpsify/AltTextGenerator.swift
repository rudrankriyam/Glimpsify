//
//  AltTextGenerator.swift
//  Glimpsify
//
//  Created by Rudrank Riyam on 5/23/25.
//

import SwiftUI
import AppKit

@Observable
class AltTextGenerator {
    var isGenerating = false
    var generatedText: String?
    var error: String?
    
    private let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
    
    @MainActor
    func generateAltText(for image: NSImage) async {
        isGenerating = true
        error = nil
        
        do {
            let base64Image = image.base64String()
            let altText = try await callVisionAPI(base64Image: base64Image)
            
            generatedText = altText
            isGenerating = false
        } catch {
            self.error = error.localizedDescription
            isGenerating = false
        }
    }
    
    @MainActor
    func clearText() {
        generatedText = nil
        error = nil
    }
    
    private func callVisionAPI(base64Image: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw AltTextError.missingAPIKey
        }
        
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": """
                            Generate concise, descriptive alt text for this image suitable for Twitter (max 1000 characters). 
                            Focus on:
                            - Main subject and important details
                            - Actions or context if relevant
                            - Text content if visible
                            - Colors, composition, or mood if significant
                            
                            Be specific but concise. Avoid starting with "This image shows" or similar phrases.
                            """
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 300,
            "temperature": 0.3
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AltTextError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw AltTextError.apiError(httpResponse.statusCode)
        }
        
        let apiResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        return apiResponse.choices.first?.message.content?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unable to generate alt text"
    }
}

// MARK: - Error Types
enum AltTextError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case apiError(Int)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API key not found. Please set OPENAI_API_KEY environment variable."
        case .invalidResponse:
            return "Invalid response from API"
        case .apiError(let code):
            return "API error with status code: \(code)"
        }
    }
}

// MARK: - API Response Models
struct OpenAIResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: Message
}

struct Message: Codable {
    let content: String?
}
