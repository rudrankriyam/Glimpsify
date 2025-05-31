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
  @State private var showingResult = false
  @State private var customInstructions = ""
  @State private var twitterManager = TwitterIntentManager()

  var body: some View {
    ScrollView {
      LazyVStack(spacing: 24) {
        if clipboardManager.hasImage {
          imageReadyCard
        } else {
          monitoringCard
        }

        if let altText = altTextGenerator.generatedText, !altText.isEmpty {
          resultCard(altText)
        }

        if let error = altTextGenerator.error {
          errorCard(error)
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 16)
    }
    .background(Color(.systemGroupedBackground))
    .refreshable {
      clipboardManager.checkClipboard()
    }
    .onAppear {
      clipboardManager.checkClipboard()
    }
  }

  private var imageReadyCard: some View {
    VStack(spacing: 20) {
      if let image = clipboardManager.clipboardImage {
        // Image preview with Apple card styling
        VStack(spacing: 16) {
          Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxHeight: 240)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .background(
              RoundedRectangle(cornerRadius: 12)
                .fill(.quaternary)
            )

          VStack(spacing: 8) {
            Text("Image Ready")
              .font(.system(size: 22, weight: .semibold))
              .foregroundStyle(.primary)

            Text("Generate accessible description")
              .font(.system(size: 16, weight: .regular))
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)
          }
          
          // Custom instructions field
          TextField("Custom instructions (optional)", text: $customInstructions)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .font(.system(size: 16))

          // Apple-style action button
          Button(action: {
            Task {
              await generateAltText()
            }
          }) {
            HStack(spacing: 8) {
              if altTextGenerator.isGenerating {
                ProgressView()
                  .scaleEffect(0.9)
                  .tint(.white)
              } else {
                Image(systemName: "sparkles")
                  .font(.system(size: 16, weight: .semibold))
              }

              Text(altTextGenerator.isGenerating ? "Analyzing..." : "Generate Description")
                .font(.system(size: 17, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(.blue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
          }
          .disabled(altTextGenerator.isGenerating)
          .scaleEffect(altTextGenerator.isGenerating ? 0.98 : 1.0)
          .animation(.easeInOut(duration: 0.2), value: altTextGenerator.isGenerating)
        }
      }
    }
    .padding(20)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
  }

  private var monitoringCard: some View {
    VStack(spacing: 24) {
      // Apple-style icon
      ZStack {
        Circle()
          .fill(.blue.opacity(0.1))
          .frame(width: 80, height: 80)

        Image(systemName: "doc.on.clipboard")
          .font(.system(size: 32, weight: .regular))
          .foregroundStyle(.blue)
      }

      VStack(spacing: 12) {
        Text("Clipboard Monitor")
          .font(.system(size: 24, weight: .bold))
          .foregroundStyle(.primary)

        Text("Copy any image to automatically generate accessible descriptions")
          .font(.system(size: 16, weight: .regular))
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .lineLimit(3)
      }
    }
    .padding(24)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
  }

  private func resultCard(_ altText: String) -> some View {
    VStack(spacing: 16) {
      // Header
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("Description")
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(.primary)

          Text("AI-generated accessibility text")
            .font(.system(size: 14, weight: .regular))
            .foregroundStyle(.secondary)
        }

        Spacer()

        Text("\(altText.count)")
          .font(.system(size: 13, weight: .medium))
          .foregroundStyle(.secondary)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(.quaternary, in: Capsule())
      }

      // Content
      Text(altText)
        .font(.system(size: 16, weight: .regular))
        .lineSpacing(4)
        .textSelection(.enabled)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))

      // Actions
      VStack(spacing: 12) {
        // Twitter share button
        Button(action: {
          shareToTwitter(altText)
        }) {
          HStack(spacing: 6) {
            Image(systemName: "bird")
              .font(.system(size: 15, weight: .medium))
            Text("Share on Twitter")
              .font(.system(size: 16, weight: .semibold))
          }
          .frame(maxWidth: .infinity)
          .frame(height: 44)
          .background(.blue)
          .foregroundStyle(.white)
          .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        
        HStack(spacing: 12) {
          Button(action: {
            UIPasteboard.general.string = altText
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
          }) {
            HStack(spacing: 6) {
              Image(systemName: "doc.on.clipboard")
                .font(.system(size: 15, weight: .medium))
              Text("Copy")
                .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(.secondary.opacity(0.2))
            .foregroundStyle(.primary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
          }

          Button(action: {
            altTextGenerator.clearText()
          }) {
            HStack(spacing: 6) {
              Image(systemName: "arrow.clockwise")
                .font(.system(size: 15, weight: .medium))
              Text("Clear")
                .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(.quaternary)
            .foregroundStyle(.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
          }
        }
      }
    }
    .padding(20)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
  }

  private func errorCard(_ error: String) -> some View {
    VStack(spacing: 16) {
      HStack(spacing: 12) {
        Image(systemName: "exclamationmark.triangle")
          .font(.system(size: 20, weight: .medium))
          .foregroundStyle(.red)

        VStack(alignment: .leading, spacing: 4) {
          Text("Analysis Failed")
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.primary)

          Text(error)
            .font(.system(size: 15, weight: .regular))
            .foregroundStyle(.secondary)
        }

        Spacer()
      }

      Button(action: {
        altTextGenerator.clearText()
      }) {
        Text("Try Again")
          .font(.system(size: 16, weight: .semibold))
          .frame(maxWidth: .infinity)
          .frame(height: 44)
          .background(.red.opacity(0.1))
          .foregroundStyle(.red)
          .clipShape(RoundedRectangle(cornerRadius: 10))
      }
    }
    .padding(20)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
  }

  private func generateAltText() async {
    guard let image = clipboardManager.clipboardImage else { return }
    await altTextGenerator.generateAltText(for: image, customInstructions: customInstructions)
  }
  
  private func shareToTwitter(_ altText: String) {
    let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
    hapticFeedback.impactOccurred()
    
    // Create tweet text with hashtags
    let tweetText = "\(altText)\n\n#Accessibility #AltText #InclusiveDesign"
    
    // Share both image and text if image is available using modern async/await
    Task {
      if let image = clipboardManager.clipboardImage {
        await twitterManager.shareToTwitter(text: tweetText, image: image)
      } else {
        // Share just text if no image
        await twitterManager.shareTextToTwitter(text: tweetText)
      }
    }
  }
}

#Preview {
  ClipboardView()
    .environment(ClipboardManager())
    .environment(AltTextGenerator())
}
