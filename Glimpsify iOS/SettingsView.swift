//
//  SettingsView.swift
//  Glimpsify iOS
//
//  Created by Rudrank Riyam on 5/23/25.
//

import SwiftUI
import UIKit

// MARK: - Constants
private enum ExternalURLs {
  static let groqConsole = "https://console.groq.com"
  static let githubRepo = "https://github.com/rudrankriyam/Glimpsify"

  static func url(for string: String) -> URL? {
    URL(string: string)
  }
}

struct SettingsView: View {
  @AppStorage("apiProvider") private var apiProvider: APIProvider = .groq
  @AppStorage("maxCharacterCount") private var maxCharacterCount = 1_000
  @AppStorage("autoGeneration") private var autoGeneration = false

  @State private var apiKey = ""
  @State private var isValidatingKey = false
  @State private var keyValidationResult: KeyValidationResult?
  @State private var showingAbout = false

  var body: some View {
    NavigationView {
      List {
        // API Configuration Section
        apiConfigurationSection

        // Generation Settings Section
        generationSettingsSection

        // Privacy & Permissions Section
        privacySection

        // About Section
        aboutSection
      }
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.large)
      .onAppear {
        loadAPIKey()
      }
    }
  }

  private var apiConfigurationSection: some View {
    Section {
      // API Provider Selection
      HStack {
        Image(systemName: "brain.head.profile")
          .foregroundStyle(.blue)
          .frame(width: 24)

        VStack(alignment: .leading, spacing: 2) {
          Text("AI Provider")
            .font(.body)
          Text("Currently using \(apiProvider.displayName)")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer()

        Text("Groq")
          .foregroundStyle(.secondary)
      }
      .padding(.vertical, 4)

      // API Key Input
      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Image(systemName: "key.fill")
            .foregroundStyle(.blue)
            .frame(width: 24)

          Text("API Key")
            .font(.body)

          Spacer()

          if isValidatingKey {
            ProgressView()
              .scaleEffect(0.8)
          } else if let result = keyValidationResult {
            Image(systemName: result.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
              .foregroundStyle(result.isValid ? .green : .red)
          }
        }

        SecureField("Enter your Groq API key", text: $apiKey)
          .textFieldStyle(.roundedBorder)
          .textContentType(.password)
          .autocorrectionDisabled()
          .textInputAutocapitalization(.never)

        if let result = keyValidationResult, !result.isValid {
          Text(result.message)
            .font(.caption)
            .foregroundStyle(.red)
        }

        Button(action: saveAPIKey) {
          HStack {
            Image(systemName: "checkmark")
            Text("Save & Validate")
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 8)
          .background(.blue, in: RoundedRectangle(cornerRadius: 8))
          .foregroundStyle(.white)
        }
        .disabled(apiKey.isEmpty || isValidatingKey)
      }
      .padding(.vertical, 8)
    } header: {
      Label("API Configuration", systemImage: "gear")
    } footer: {
      VStack(alignment: .leading, spacing: 8) {
        Text("Get your free API key from console.groq.com")

        if let url = ExternalURLs.url(for: ExternalURLs.groqConsole) {
          Link("Get Groq API Key", destination: url)
            .font(.caption)
        }
      }
    }
  }

  private var generationSettingsSection: some View {
    Section {
      // Character Limit
      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Image(systemName: "textformat.123")
            .foregroundStyle(.blue)
            .frame(width: 24)

          Text("Character Limit")

          Spacer()

          Text("\(maxCharacterCount)")
            .foregroundStyle(.secondary)
            .monospacedDigit()
        }

        Slider(
          value: Binding(
            get: { Double(maxCharacterCount) },
            set: { maxCharacterCount = Int($0) }
          ), in: 100...2_000, step: 50
        ) {
          Text("Character Limit")
        } minimumValueLabel: {
          Text("100")
            .font(.caption)
            .foregroundStyle(.secondary)
        } maximumValueLabel: {
          Text("2000")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .tint(.blue)
      }
      .padding(.vertical, 8)

      // Auto Generation Toggle
      HStack {
        Image(systemName: "wand.and.stars")
          .foregroundStyle(.blue)
          .frame(width: 24)

        VStack(alignment: .leading, spacing: 2) {
          Text("Auto Generation")
            .font(.body)
          Text("Generate alt text automatically when images are detected")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer()

        Toggle("", isOn: $autoGeneration)
          .labelsHidden()
      }
      .padding(.vertical, 4)
    } header: {
      Label("Generation Settings", systemImage: "sparkles")
    }
  }

  private var privacySection: some View {
    Section {
      // Camera Permission
      PermissionRow(
        icon: "camera.fill",
        title: "Camera Access",
        description: "Take photos to generate alt text",
        action: openCameraSettings
      )

      // Photos Permission
      PermissionRow(
        icon: "photo.on.rectangle",
        title: "Photos Access",
        description: "Select images from your photo library",
        action: openPhotosSettings
      )
    } header: {
      Label("Privacy & Permissions", systemImage: "hand.raised.fill")
    } footer: {
      Text(
        "Glimpsify processes images locally and only sends them to Groq's API for analysis. No images are stored on our servers."
      )
      .font(.caption)
    }
  }

  private var aboutSection: some View {
    Section {
      // App Version
      HStack {
        Image(systemName: "info.circle.fill")
          .foregroundStyle(.blue)
          .frame(width: 24)

        Text("Version")

        Spacer()

        Text("1.0.0")
          .foregroundStyle(.secondary)
      }
      .padding(.vertical, 4)

      // About Button
      Button(action: { showingAbout = true }) {
        HStack {
          Image(systemName: "questionmark.circle.fill")
            .foregroundStyle(.blue)
            .frame(width: 24)

          Text("About Glimpsify")
            .foregroundStyle(.primary)

          Spacer()

          Image(systemName: "chevron.right")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      .padding(.vertical, 4)

      // Support
      if let url = ExternalURLs.url(for: ExternalURLs.githubRepo) {
        Link(destination: url) {
          HStack {
            Image(systemName: "heart.fill")
              .foregroundStyle(.red)
              .frame(width: 24)

            Text("Support & Feedback")

            Spacer()

            Image(systemName: "arrow.up.right")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        .padding(.vertical, 4)
      }
    } header: {
      Label("About", systemImage: "heart.fill")
    }
  }

  private func loadAPIKey() {
    apiKey = KeychainManager.shared.getAPIKey(for: apiProvider) ?? ""
  }

  private func saveAPIKey() {
    guard !apiKey.isEmpty else { return }

    isValidatingKey = true
    keyValidationResult = nil

    Task {
      let isValid = await validateAPIKey(apiKey)

      await MainActor.run {
        isValidatingKey = false

        if isValid {
          KeychainManager.shared.saveAPIKey(apiKey, for: apiProvider)
          keyValidationResult = KeyValidationResult(isValid: true, message: "API key is valid")

          // Haptic feedback for success
          let impactFeedback = UIImpactFeedbackGenerator(style: .light)
          impactFeedback.impactOccurred()
        } else {
          keyValidationResult = KeyValidationResult(isValid: false, message: "Invalid API key")

          // Haptic feedback for error
          let notificationFeedback = UINotificationFeedbackGenerator()
          notificationFeedback.notificationOccurred(.error)
        }
      }
    }
  }

  private func validateAPIKey(_ key: String) async -> Bool {
    // Implement API key validation logic here
    // For now, just check if it's not empty and has reasonable length
    return key.count > 10
  }

  private func openCameraSettings() {
    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
      UIApplication.shared.open(settingsUrl)
    }
  }

  private func openPhotosSettings() {
    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
      UIApplication.shared.open(settingsUrl)
    }
  }
}

struct PermissionRow: View {
  let icon: String
  let title: String
  let description: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack {
        Image(systemName: icon)
          .foregroundStyle(.blue)
          .frame(width: 24)

        VStack(alignment: .leading, spacing: 2) {
          Text(title)
            .font(.body)
            .foregroundStyle(.primary)

          Text(description)
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer()

        Image(systemName: "chevron.right")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .padding(.vertical, 4)
  }
}

struct KeyValidationResult {
  let isValid: Bool
  let message: String
}

#Preview {
  SettingsView()
}
