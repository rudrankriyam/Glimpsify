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
  @AppStorage("maxCharacters") private var maxCharacters: Int = 1000
  @AppStorage("autoGenerate") private var autoGenerate: Bool = false

  @State private var apiKey: String = ""
  @State private var showingAPIKeyAlert = false
  @State private var apiKeyStatus: APIKeyStatus = .notSet

  var body: some View {
    Form {
      Section("API Configuration") {
        Picker("Provider", selection: $apiProvider) {
          ForEach(APIProvider.allCases, id: \.self) { provider in
            Text(provider.displayName)
              .tag(provider)
          }
        }
        .pickerStyle(.menu)
        .onChange(of: apiProvider) { _, newValue in
          loadAPIKey()
        }

        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text("\(apiProvider.displayName) API Key")
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
              saveAPIKey()
            }
            .disabled(apiKey.isEmpty)
          }

          Text(apiProvider.instructionText)
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
      Text("Your API key has been securely saved to the keychain.")
    }
  }

  private func loadAPIKey() {
    if let savedKey = KeychainManager.shared.getAPIKey(for: apiProvider) {
      apiKey = savedKey
      apiKeyStatus = .valid
    } else {
      apiKey = ""
      apiKeyStatus = .notSet
    }
  }

  private func saveAPIKey() {
    KeychainManager.shared.saveAPIKey(apiKey, for: apiProvider)
    apiKeyStatus = .valid
    showingAPIKeyAlert = true
  }
}

enum APIProvider: String, CaseIterable, Codable {
  case groq = "groq"

  var displayName: String {
    switch self {
    case .groq: return "Groq"
    }
  }

    var instructionText: String {
        switch self {
        case .groq:
            return "Get your free API key from console.groq.com"
        }
    }

  var keychainKey: String {
    return "glimpsify_\(rawValue)_api_key"
  }
}

enum APIKeyStatus {
  case notSet
  case valid
  case invalid

  var text: String {
    switch self {
    case .notSet: return "Not Set"
    case .valid: return "Set"
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

// MARK: - Keychain Manager
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

#Preview {
  SettingsView()
}
