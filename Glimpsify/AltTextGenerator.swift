//
//  AltTextGenerator.swift
//  Glimpsify
//
//  Created by Rudrank Riyam on 5/23/25.
//

import AppKit
import Security
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
            let altText = try await callGroqAPI(base64Image: base64Image)

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

    private func callGroqAPI(base64Image: String) async throws -> String {
        guard let apiKey = KeychainManager.shared.getAPIKey(for: .groq) else {
            throw AltTextError.missingAPIKey
        }

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
    case missingAPIKey
    case invalidResponse
    case apiError(Int, String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Groq API key not found. Please set it in Settings."
        case .invalidResponse:
            return "Invalid response from API"
        case .apiError(let code, let message):
            return "API error (\(code)): \(message)"
        }
    }
}

// MARK: - API Response Models

struct GroqResponse: Codable {
    let choices: [GroqChoice]
}

struct GroqChoice: Codable {
    let message: GroqMessage
}

struct GroqMessage: Codable {
    let content: String?
}

// MARK: - Types (shared with SettingsView)

enum APIProvider: String, CaseIterable, Codable {
    case groq = "groq"

    var displayName: String {
        switch self {
        case .groq: return "Groq"
        }
    }

    var keychainKey: String {
        return "glimpsify_\(rawValue)_api_key"
    }
}

// MARK: - Keychain Manager (shared with SettingsView)

class KeychainManager {
    static let shared = KeychainManager()
    private init() {}

    func saveAPIKey(_ key: String, for provider: APIProvider) {
        let data = key.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: provider.keychainKey,
            kSecValueData as String: data,
        ]

        // Delete existing item
        SecItemDelete(query as CFDictionary)

        // Add new item
        SecItemAdd(query as CFDictionary, nil)
    }

    func getAPIKey(for provider: APIProvider) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: provider.keychainKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8)
        else {
            return nil
        }

        return key
    }

    func deleteAPIKey(for provider: APIProvider) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: provider.keychainKey,
        ]

        SecItemDelete(query as CFDictionary)
    }
}
