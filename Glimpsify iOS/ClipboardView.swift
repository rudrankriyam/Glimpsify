//
//  ClipboardView.swift
//  Glimpsify iOS
//
//  Created by Rudrank Riyam on 5/23/25.
//

import SwiftUI
import UIKit

struct ClipboardView: View {
    @Environment(ClipboardManager.self) private var clipboardManager
    @Environment(AltTextGenerator.self) private var altTextGenerator
    @AppStorage("apiProvider") private var apiProvider: APIProvider = .groq

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header section with beautiful hierarchy
                    headerSection

                    // Main content area
                    mainContentArea

                    // Alt text display section
                    if let altText = altTextGenerator.generatedText {
                        altTextSection(altText)
                    }

                    // Error handling section
                    if let error = altTextGenerator.error {
                        errorSection(error)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("Clipboard")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                clipboardManager.checkClipboard()
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            // App branding with elegant styling
            HStack {
                Image(systemName: "text.bubble.fill")
                    .font(.title)
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Glimpsify")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Powered by \(apiProvider.displayName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.vertical, 8)

            // Status indicator with smooth animations
            HStack {
                Circle()
                    .fill(clipboardManager.hasImage ? .green : .orange)
                    .frame(width: 8, height: 8)
                    .scaleEffect(clipboardManager.hasImage ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: clipboardManager.hasImage)

                Text(clipboardManager.hasImage ? "Image detected in clipboard" : "Monitoring clipboard...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var mainContentArea: some View {
        VStack(spacing: 20) {
            if clipboardManager.hasImage {
                imageDetectedSection
            } else {
                emptyStateSection
            }
        }
    }

    private var imageDetectedSection: some View {
        VStack(spacing: 20) {
            // Image preview with elegant styling
            if let image = clipboardManager.clipboardImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            }

            // Generate button with Apple-style design
            Button(action: {
                Task {
                    await generateAltText()
                }
            }) {
                HStack(spacing: 12) {
                    if altTextGenerator.isGenerating {
                        ProgressView()
                            .scaleEffect(0.9)
                            .tint(.white)
                    } else {
                        Image(systemName: "sparkles")
                            .font(.title3)
                    }

                    Text(altTextGenerator.isGenerating ? "Generating..." : "Generate Alt Text")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.white)
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(altTextGenerator.isGenerating)
            .scaleEffect(altTextGenerator.isGenerating ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: altTextGenerator.isGenerating)
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var emptyStateSection: some View {
        VStack(spacing: 20) {
            // Beautiful empty state illustration
            VStack(spacing: 16) {
                Image(systemName: "clipboard")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue.opacity(0.6))

                VStack(spacing: 8) {
                    Text("Copy an image to clipboard")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("Screenshots, photos, or any image will appear here automatically")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.vertical, 40)

            // Quick action buttons
            VStack(spacing: 12) {
                Button(action: {
                    // Open camera
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Take Photo")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.blue)
                }

                Button(action: {
                    // Open photos
                }) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text("Choose from Photos")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.blue)
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func altTextSection(_ altText: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with character count
            HStack {
                Text("Generated Alt Text")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(altText.count)/1000")
                    .font(.caption)
                    .foregroundStyle(altText.count > 1000 ? .red : .secondary)
                    .monospacedDigit()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
            }

            // Alt text display with elegant styling
            Text(altText)
                .font(.body)
                .textSelection(.enabled)
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.blue.opacity(0.2), lineWidth: 1)
                }

            // Action buttons with perfect spacing
            HStack(spacing: 12) {
                Button(action: {
                    UIPasteboard.general.string = altText
                    // Add haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }) {
                    Label("Copy", systemImage: "doc.on.clipboard")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.blue, in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(.white)
                }

                Button(action: {
                    altTextGenerator.clearText()
                }) {
                    Label("Clear", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func errorSection(_ error: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)

                Text("Error")
                    .font(.headline)
                    .foregroundStyle(.red)

                Spacer()
            }

            Text(error)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(action: {
                altTextGenerator.clearText()
            }) {
                Text("Dismiss")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.red)
            }
        }
        .padding(20)
        .background(.red.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(.red.opacity(0.2), lineWidth: 1)
        }
    }

    private func generateAltText() async {
        guard let image = clipboardManager.clipboardImage else { return }
        await altTextGenerator.generateAltText(for: image)
    }
}

#Preview {
    ClipboardView()
        .environment(ClipboardManager())
        .environment(AltTextGenerator())
}
