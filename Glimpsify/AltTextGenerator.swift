//
//  AltTextGenerator.swift
//  Glimpsify
//
//  Created by Rudrank Riyam on 5/23/25.
//

import AppKit
import SwiftUI

@Observable
class AltTextGenerator {
    var isGenerating = false
    var generatedText: String?
    var error: String?

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
        let provider = UserDefaults.standard.object(forKey: "apiProvider") as? String ?? "groq"
        let apiProvider = APIProvider(rawValue: provider) ?? .groq

        guard let apiKey = KeychainManager.shared.getAPIKey(for: apiProvider) else {
            throw AltTextError.missingAPIKey(apiProvider)
        }

        switch apiProvider {
        case .groq:
            return try await callGroqAPI(base64Image: base64Image, apiKey: apiKey)
        }
    }

    // MARK: - Groq API
    private func callGroqAPI(base64Image: String, apiKey: String) async throws -> String {
        let url = URL(string: "https://api.groq.com/openai/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "model": "meta-llama/llama-4-scout-17b-16e-instruct",
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
              """,
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ],
                        ],
                    ],
                ]
            ],
            "max_completion_tokens": 300,
            "temperature": 0.3,
            "top_p": 1,
            "stream": false,
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AltTextError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AltTextError.apiError(httpResponse.statusCode, errorMessage)
        }

        let apiResponse = try JSONDecoder().decode(GroqResponse.self, from: data)

        return apiResponse.choices.first?.message.content?.trimmingCharacters(
            in: .whitespacesAndNewlines) ?? "Unable to generate alt text"
    }
}

// MARK: - Error Types
enum AltTextError: LocalizedError {
    case missingAPIKey(APIProvider)
    case invalidResponse
    case apiError(Int, String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey(let provider):
            return "\(provider.displayName) API key not found. Please set it in Settings."
        case .invalidResponse:
            return "Invalid response from API"
        case .apiError(let code, let message):
            return "API error (\(code)): \(message)"
        }
    }
}

// MARK: - API Response Models

// Groq Response (same as OpenAI format)
struct GroqResponse: Codable {
    let choices: [GroqChoice]
}

struct GroqChoice: Codable {
    let message: GroqMessage
}

struct GroqMessage: Codable {
    let content: String?
}

// OpenAI Response
struct OpenAIResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: Message
}

struct Message: Codable {
    let content: String?
}

// Claude Response
struct ClaudeResponse: Codable {
    let content: [ClaudeContent]
}

struct ClaudeContent: Codable {
    let text: String?
    let type: String
}
