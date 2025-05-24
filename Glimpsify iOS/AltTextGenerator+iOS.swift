//
//  AltTextGenerator+iOS.swift
//  Glimpsify iOS
//
//  Created by Rudrank Riyam on 5/23/25.
//

import Foundation
import Security
import SwiftUI
import UIKit

// MARK: - Groq API Request/Response Models
struct GroqChatRequest: Codable {
  let model: String
  let messages: [GroqMessage]
  let maxCompletionTokens: Int
  let temperature: Double
  let topP: Double
  let stream: Bool

  enum CodingKeys: String, CodingKey {
    case model, messages, temperature, stream
    case maxCompletionTokens = "max_completion_tokens"
    case topP = "top_p"
  }
}

struct GroqMessage: Codable {
  let role: String
  let content: [GroqContent]
}

struct GroqContent: Codable {
  let type: String
  let text: String?
  let imageUrl: GroqImageUrl?

  enum CodingKeys: String, CodingKey {
    case type, text
    case imageUrl = "image_url"
  }
}

struct GroqImageUrl: Codable {
  let url: String
}

struct GroqChatResponse: Codable {
  let choices: [GroqChoice]
}

struct GroqChoice: Codable {
  let message: GroqResponseMessage
}

struct GroqResponseMessage: Codable {
  let content: String
}

// MARK: - Types
enum APIProvider: String, CaseIterable, Codable {
  case groq = "groq"

  var displayName: String {
    switch self {
    case .groq: return "Groq"
    }
  }

  var keychainKey: String {
    "glimpsify_\(rawValue)_api_key"
  }
}

// MARK: - Error Types
enum AltTextError: LocalizedError {
  case missingAPIKey
  case invalidResponse
  case apiError(Int, String)
  case imageProcessingError

  var errorDescription: String? {
    switch self {
    case .missingAPIKey:
      return "Groq API key not found. Please set it in Settings."
    case .invalidResponse:
      return "Invalid response from API"
    case .apiError(let code, let message):
      return "API error (\(code)): \(message)"
    case .imageProcessingError:
      return "Failed to process image"
    }
  }
}

// MARK: - Keychain Manager
class KeychainManager {
  static let shared = KeychainManager()
  private init() {}

  func saveAPIKey(_ key: String, for provider: APIProvider) {
    guard let data = key.data(using: .utf8) else {
      return
    }

    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: provider.keychainKey,
      kSecValueData as String: data
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
      kSecMatchLimit as String: kSecMatchLimitOne
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
      kSecAttrAccount as String: provider.keychainKey
    ]

    SecItemDelete(query as CFDictionary)
  }
}

// MARK: - Alt Text Generator
@Observable
class AltTextGenerator {
  var isGenerating = false
  var generatedText: String?
  var error: String?
  
  @AppStorage("customInstructions") private var customInstructions = ""
  private let apiProvider: APIProvider = .groq

  func generateAltText(for image: UIImage) async {
    await MainActor.run {
      isGenerating = true
      error = nil
      generatedText = nil
    }

    do {
      let altText = try await performGeneration(for: image)

      await MainActor.run {
        generatedText = altText
        isGenerating = false
      }
    } catch {
      await MainActor.run {
        self.error = error.localizedDescription
        isGenerating = false
      }
    }
  }

  private func performGeneration(for image: UIImage) async throws -> String {
    guard let apiKey = KeychainManager.shared.getAPIKey(for: apiProvider) else {
      throw AltTextError.missingAPIKey
    }

    // Convert UIImage to base64
    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
      throw AltTextError.imageProcessingError
    }

    let base64String = imageData.base64EncodedString()
    let dataURL = "data:image/jpeg;base64,\(base64String)"

    // Create request
    let request = GroqChatRequest(
      model: "meta-llama/llama-4-scout-17b-16e-instruct",
      messages: [
        GroqMessage(
          role: "user",
          content: [
            GroqContent(
              type: "text",
              text:
                "Generate a concise, descriptive alt text for this image. Focus on the main subject, important details, and context. Keep it under 1000 characters and make it accessible for screen readers.\n\(customInstructions.isEmpty ? "" : "\n\(customInstructions)")",
              imageUrl: nil
            ),
            GroqContent(
              type: "image_url",
              text: nil,
              imageUrl: GroqImageUrl(url: dataURL)
            )
          ]
        )
      ],
      maxCompletionTokens: 300,
      temperature: 0.3,
      topP: 0.9,
      stream: false
    )

    // Make API call
    guard let url = URL(string: "https://api.groq.com/openai/v1/chat/completions") else {
      throw AltTextError.invalidResponse
    }

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let encoder = JSONEncoder()
    urlRequest.httpBody = try encoder.encode(request)

    let (data, response) = try await URLSession.shared.data(for: urlRequest)

    if let httpResponse = response as? HTTPURLResponse,
      httpResponse.statusCode != 200 {
      let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
      throw AltTextError.apiError(httpResponse.statusCode, errorMessage)
    }

    let decoder = JSONDecoder()
    let groqResponse = try decoder.decode(GroqChatResponse.self, from: data)

    guard let choice = groqResponse.choices.first else {
      throw AltTextError.invalidResponse
    }

    return choice.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  func clearText() {
    generatedText = nil
    error = nil
  }
}
