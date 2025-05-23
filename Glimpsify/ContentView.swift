//
//  ContentView.swift
//  Glimpsify
//
//  Created by Rudrank Riyam on 5/23/25.
//

import SwiftUI

struct ContentView: View {
  @Environment(ClipboardManager.self) private var clipboardManager
  @Environment(AltTextGenerator.self) private var altTextGenerator
  @Environment(\.openSettings) private var openSettings
  @AppStorage("apiProvider") private var apiProvider: APIProvider = .groq

  var body: some View {
    VStack(spacing: 16) {
      // Header
      HStack {
        Image(systemName: "text.bubble.fill")
          .foregroundStyle(.blue)
        VStack(alignment: .leading, spacing: 2) {
          Text("Glimpsify")
            .font(.headline)
          Text("Powered by \(apiProvider.displayName)")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        Spacer()
      }

      Divider()

      // Main Content
      Group {
        if clipboardManager.hasImage {
          imageSection
        } else {
          emptyStateSection
        }
      }

      if let altText = altTextGenerator.generatedText {
        altTextSection(altText)
      }

      if let error = altTextGenerator.error {
        errorSection(error)
      }

      Divider()

      // Footer Actions
      HStack {
        Button("Settings", systemImage: "gear") {
          openSettings()
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)

        Spacer()

        Button("Quit", systemImage: "power") {
          NSApplication.shared.terminate(nil)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
      }
    }
    .padding()
    .frame(width: 320, height: 320)
  }

  @ViewBuilder
  private var imageSection: some View {
    VStack(spacing: 12) {
      HStack {
        Image(systemName: "photo.fill")
          .foregroundStyle(.green)
        Text("Image detected in clipboard")
          .font(.subheadline)
        Spacer()
      }

      Button {
        Task {
          await generateAltText()
        }
      } label: {
        HStack {
          if altTextGenerator.isGenerating {
            ProgressView()
              .scaleEffect(0.8)
              .progressViewStyle(CircularProgressViewStyle(tint: .white))
          } else {
            Image(systemName: "sparkles")
          }
          Text(altTextGenerator.isGenerating ? "Generating..." : "Generate Alt Text")
        }
        .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .disabled(altTextGenerator.isGenerating)
      .controlSize(.large)
    }
  }

  @ViewBuilder
  private var emptyStateSection: some View {
    VStack(spacing: 8) {
      Image(systemName: "clipboard")
        .font(.title2)
        .foregroundStyle(.secondary)

      Text("Copy an image to clipboard")
        .font(.subheadline)
        .foregroundStyle(.secondary)

      Text("Screenshots, photos, or any image")
        .font(.caption)
        .foregroundStyle(.tertiary)
    }
    .frame(maxWidth: .infinity, minHeight: 80)
  }

  @ViewBuilder
  private func altTextSection(_ altText: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text("Generated Alt Text")
          .font(.caption)
          .foregroundStyle(.secondary)

        Spacer()

        Text("\(altText.count)/1000")
          .font(.caption2)
          .foregroundStyle(altText.count > 1000 ? .red : .secondary)
          .monospacedDigit()
      }

      ScrollView {
        Text(altText)
          .font(.system(.callout, design: .rounded))
          .textSelection(.enabled)
          .padding(8)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
      }
      .frame(maxHeight: 60)

      HStack {
        Button("Copy", systemImage: "doc.on.clipboard") {
          NSPasteboard.general.clearContents()
          NSPasteboard.general.setString(altText, forType: .string)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)

        Button("Clear", systemImage: "trash") {
          altTextGenerator.clearText()
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .foregroundStyle(.red)
      }
    }
  }

  @ViewBuilder
  private func errorSection(_ error: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Image(systemName: "exclamationmark.triangle.fill")
          .foregroundStyle(.red)
        Text("Error")
          .font(.caption)
          .foregroundStyle(.red)
        Spacer()
      }

      Text(error)
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))

      HStack {
        Button("Dismiss", systemImage: "xmark") {
          altTextGenerator.clearText()
        }
        .buttonStyle(.bordered)
        .controlSize(.small)

        Button("Settings", systemImage: "gear") {
          openSettings()
        }
        .buttonStyle(.bordered)
        .controlSize(.small)

        Spacer()
      }
    }
  }

  private func generateAltText() async {
    guard let image = clipboardManager.clipboardImage else { return }
    await altTextGenerator.generateAltText(for: image)
  }
}

#Preview {
  ContentView()
    .environment(ClipboardManager())
    .environment(AltTextGenerator())
}
