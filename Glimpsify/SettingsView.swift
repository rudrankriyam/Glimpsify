//
//  SettingsView.swift
//  Glimpsify
//
//  Created by Rudrank Riyam on 5/23/25.
//

import Security
import SwiftUI

struct SettingsView: View {
  @AppStorage("apiProvider") private var apiProvider: APIProvider = .groq
  @AppStorage("maxCharacters") private var maxCharacters: Int = 1_000
  @AppStorage("autoGenerate") private var autoGenerate = false

  @State private var apiKey: String = ""
  @State private var showingAPIKeyAlert = false
  @State private var apiKeyStatus: APIKeyStatus = .notSet
  @State private var isValidating = false
  @State private var validationMessage = ""

  var body: some View {
    Form {
      Section("API Configuration") {
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text("Groq API Key")
              .font(.headline)

            Spacer()

            Circle()
              .fill(apiKeyStatus.color)
              .frame(width: 8, height: 8)

            Text(apiKeyStatus.text)
              .font(.caption)
              .foregroundStyle(.secondary)
          }

          HStack {
            SecureField("Enter your API key", text: $apiKey)
              .textFieldStyle(.roundedBorder)

            Button("Save") {
              Task {
                await saveAndValidateAPIKey()
              }
            }
            .disabled(apiKey.isEmpty || isValidating)
            .overlay {
              if isValidating {
                ProgressView()
                  .scaleEffect(0.7)
              }
            }
          }

          if !validationMessage.isEmpty {
            Text(validationMessage)
              .font(.caption)
              .foregroundStyle(apiKeyStatus == .valid ? .green : .red)
          }

          Text("Get your free API key from console.groq.com")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      Section("Generation Settings") {
        HStack {
          Text("Max Characters")
          Spacer()
          TextField("1000", value: $maxCharacters, format: .number)
            .textFieldStyle(.roundedBorder)
            .frame(width: 80)
        }

        Toggle("Auto-generate on image copy", isOn: $autoGenerate)
      }

      Section("About") {
        HStack {
          Text("Version")
          Spacer()
          Text("1.0.0")
            .foregroundStyle(.secondary)
        }

        HStack {
          Text("Developer")
          Spacer()
          Text("Rudrank Riyam")
            .foregroundStyle(.secondary)
        }
      }
    }
    .formStyle(.grouped)
    .frame(width: 450, height: 400)
    .navigationTitle("Settings")
    .onAppear {
      loadAPIKey()
    }
    .alert("API Key Saved", isPresented: $showingAPIKeyAlert) {
      Button("OK") {}
    } message: {
      Text("Your API key has been securely saved and validated.")
    }
  }

  private func loadAPIKey() {
    if let savedKey = KeychainManager.shared.getAPIKey(for: apiProvider) {
      apiKey = savedKey
      apiKeyStatus = .valid
      validationMessage = "Previously validated"
    } else {
      apiKey = ""
      apiKeyStatus = .notSet
      validationMessage = ""
    }
  }

  private func saveAndValidateAPIKey() async {
    isValidating = true
    validationMessage = "Validating..."

    // Test the API key
    let isValid = await validateGroqKey(apiKey)

    if isValid {
      KeychainManager.shared.saveAPIKey(apiKey, for: apiProvider)
      apiKeyStatus = .valid
      validationMessage = "✓ API key is valid and working"
      showingAPIKeyAlert = true
    } else {
      apiKeyStatus = .invalid
      validationMessage = "✗ API key validation failed"
    }

    isValidating = false
  }

  private func validateGroqKey(_ key: String) async -> Bool {
    do {
      guard let url = APIEndpoint.groqChatCompletions.url else {
        return false
      }
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")

      let payload: [String: Any] = [
        "model": "meta-llama/llama-4-scout-17b-16e-instruct",
        "messages": [
          [
            "role": "user",
            "content": "Hello, this is a test message."
          ]
        ],
        "max_completion_tokens": 10,
        "temperature": 0.1
      ]

      request.httpBody = try JSONSerialization.data(withJSONObject: payload)

      let (_, response) = try await URLSession.shared.data(for: request)

      guard let httpResponse = response as? HTTPURLResponse else {
        return false
      }

      return httpResponse.statusCode == 200
    } catch {
      // Note: Validation failed - error details not logged for security
      return false
    }
  }
}

enum APIKeyStatus {
  case notSet
  case valid
  case invalid

  var text: String {
    switch self {
    case .notSet: return "Not Set"
    case .valid: return "Valid"
    case .invalid: return "Invalid"
    }
  }

  var color: Color {
    switch self {
    case .notSet: return .gray
    case .valid: return .green
    case .invalid: return .red
    }
  }
}

#Preview {
  SettingsView()
}
