//
//  AltTextGenerator.swift
//  Glimpsify
//
//  Created by Rudrank Riyam on 5/23/25.
//

import AppKit
import Foundation
import Security
import SwiftUI

// MARK: - API Configuration
enum APIEndpoint {
  case groqChatCompletions

  var url: URL? {
    switch self {
    case .groqChatCompletions:
      return URL(string: "https://api.groq.com/openai/v1/chat/completions")
    }
  }
}

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
  case invalidURL
  case apiError(Int, String)

  var errorDescription: String? {
    switch self {
    case .missingAPIKey:
      return "Groq API key not found. Please set it in Settings."
    case .invalidResponse:
      return "Invalid response from API"
    case .invalidURL:
      return "Invalid API endpoint URL"
    case .apiError(let code, let message):
      return "API error (\(code)): \(message)"
    }
  }
}

// MARK: - Keychain Manager
class KeychainManager {
  static let shared = KeychainManager()
  private init() {}

  func saveAPIKey(_ key: String, for provider: APIProvider) {
    guard let data = key.data(using: .utf8) else {
      return  // Failed to encode key
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

  // Additional methods for direct key access (used by SettingsView)
  func save(key: String, value: String) -> Bool {
    guard let data = value.data(using: .utf8) else {
      return false  // Failed to encode value
    }

    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
      kSecValueData as String: data
    ]

    SecItemDelete(query as CFDictionary)
    let status = SecItemAdd(query as CFDictionary, nil)
    return status == errSecSuccess
  }

  func load(key: String) -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]

    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)

    guard status == errSecSuccess,
      let data = result as? Data,
      let string = String(data: data, encoding: .utf8)
    else {
      return nil
    }

    return string
  }

  func delete(key: String) -> Bool {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key
    ]

    let status = SecItemDelete(query as CFDictionary)
    return status == errSecSuccess
  }
}

// MARK: - Alt Text Generator
@Observable
class AltTextGenerator {
  var isGenerating = false
  var generatedText: String?
  var error: String?
  
  @AppStorage("customInstructions") private var customInstructions = ""
  private let keychainManager = KeychainManager.shared

  @MainActor
  func generateAltText(for image: NSImage) async {
    isGenerating = true
    error = nil

    do {
      guard let base64Image = convertImageToBase64(image) else {
        throw AltTextError.invalidResponse
      }

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
    guard let apiKey = keychainManager.getAPIKey(for: .groq) else {
      throw AltTextError.missingAPIKey
    }

    let request = GroqChatRequest(
      model: "meta-llama/llama-4-scout-17b-16e-instruct",
      messages: [
        GroqMessage(
          role: "user",
          content: [
            GroqContent(
              type: "text",
              text: """
                Generate concise, descriptive alt text for this image suitable for Twitter (max 1000 characters).
                Focus on:
                - Main subject and important details
                - Actions or context if relevant
                - Text content if visible
                - Colors, composition, or mood if significant

                Be specific but concise. Avoid starting with "This image shows" or similar phrases.
                
                \(customInstructions.isEmpty ? "" : "Additional instructions:\n\(customInstructions)\n\n")IMPORTANT: Return only the alt text without any quotes, formatting, or additional text.
                """,
              imageUrl: nil
            ),
            GroqContent(
              type: "image_url",
              text: nil,
              imageUrl: GroqImageUrl(url: "data:image/jpeg;base64,\(base64Image)")
            )
          ]
        )
      ],
      maxCompletionTokens: 300,
      temperature: 0.3,
      topP: 1,
      stream: false
    )

    let jsonData = try JSONEncoder().encode(request)

    guard let url = APIEndpoint.groqChatCompletions.url else {
      throw AltTextError.invalidURL
    }
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    urlRequest.httpBody = jsonData

    let (data, response) = try await URLSession.shared.data(for: urlRequest)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw AltTextError.invalidResponse
    }

    guard httpResponse.statusCode == 200 else {
      let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
      throw AltTextError.apiError(httpResponse.statusCode, errorMessage)
    }

    let apiResponse = try JSONDecoder().decode(GroqChatResponse.self, from: data)

    guard let choice = apiResponse.choices.first else {
      throw AltTextError.invalidResponse
    }

    // Clean up the response by removing quotes and extra whitespace
    let cleanedContent = choice.message.content
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
      .trimmingCharacters(in: .whitespacesAndNewlines)

    return cleanedContent
  }

  // MARK: - API Key Validation
  func validateAPIKey(_ apiKey: String) async -> Bool {
    guard !apiKey.isEmpty else { return false }

    let testRequest = GroqChatRequest(
      model: "meta-llama/llama-4-scout-17b-16e-instruct",
      messages: [
        GroqMessage(
          role: "user",
          content: [
            GroqContent(
              type: "text",
              text: "Hello",
              imageUrl: nil
            )
          ]
        )
      ],
      maxCompletionTokens: 10,
      temperature: 0.3,
      topP: 1,
      stream: false
    )

    do {
      let jsonData = try JSONEncoder().encode(testRequest)

      guard let url = APIEndpoint.groqChatCompletions.url else {
        throw AltTextError.invalidURL
      }
      var urlRequest = URLRequest(url: url)
      urlRequest.httpMethod = "POST"
      urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
      urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
      urlRequest.httpBody = jsonData

      let (_, response) = try await URLSession.shared.data(for: urlRequest)

      if let httpResponse = response as? HTTPURLResponse {
        return httpResponse.statusCode == 200
      }

      return false
    } catch {
      return false
    }
  }

  private func convertImageToBase64(_ image: NSImage) -> String? {
    guard let tiffData = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData)
    else {
      return nil
    }

    // Convert to JPEG with compression
    guard let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.8])
    else {
      return nil
    }

    return jpegData.base64EncodedString()
  }
}

// MARK: - NSImage Extension
extension NSImage {
  func base64String() -> String? {
    guard let tiffData = self.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData)
    else {
      return nil
    }

    // Convert to JPEG with compression
    guard let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.8])
    else {
      return nil
    }

    return jpegData.base64EncodedString()
  }
}
