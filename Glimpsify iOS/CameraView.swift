//
//  CameraView.swift
//  Glimpsify iOS
//
//  Created by Rudrank Riyam on 5/23/25.
//

import AVFoundation
import SwiftUI

struct CameraView: View {
  @Environment(CameraManager.self) private var cameraManager
  @Environment(AltTextGenerator.self) private var altTextGenerator
  @State private var showingImagePicker = false
  @State private var capturedImage: UIImage?
  @State private var showingAltText = false
  @State private var isFlashOn = false

  var body: some View {
    NavigationView {
      ZStack {
        // Background gradient for premium feel
        LinearGradient(
          colors: [Color.black, Color.gray.opacity(0.8)],
          startPoint: .top,
          endPoint: .bottom
        )
        .ignoresSafeArea()

        VStack(spacing: 0) {
          // Header with hierarchy
          headerView

          // Camera preview area
          cameraPreviewArea

          // Controls with perfect balance
          cameraControls
        }
      }
      .navigationBarHidden(true)
    }
    .sheet(isPresented: $showingImagePicker) {
      ImagePicker(image: $capturedImage)
    }
    .sheet(isPresented: $showingAltText) {
      if let image = capturedImage {
        AltTextResultView(image: image)
          .environment(altTextGenerator)
      }
    }
    .onChange(of: capturedImage) { _, newImage in
      if newImage != nil {
        showingAltText = true
      }
    }
  }

  private var headerView: some View {
    HStack {
      Text("Glimpsify")
        .font(.largeTitle)
        .fontWeight(.bold)
        .foregroundStyle(.white)

      Spacer()

      // Flash toggle with smooth animation
      Button(action: {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
          isFlashOn.toggle()
        }
      }) {
        Image(systemName: isFlashOn ? "bolt.fill" : "bolt.slash.fill")
          .font(.title2)
          .foregroundStyle(isFlashOn ? .yellow : .white)
          .scaleEffect(isFlashOn ? 1.1 : 1.0)
          .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFlashOn)
      }
    }
    .padding(.horizontal, 24)
    .padding(.top, 8)
  }

  private var cameraPreviewArea: some View {
    ZStack {
      // Camera preview placeholder with beautiful styling
      RoundedRectangle(cornerRadius: 24)
        .fill(.ultraThinMaterial)
        .overlay {
          VStack(spacing: 16) {
            Image(systemName: "camera.viewfinder")
              .font(.system(size: 60))
              .foregroundStyle(.white.opacity(0.8))

            Text("Tap to capture and generate alt text")
              .font(.headline)
              .foregroundStyle(.white.opacity(0.9))
              .multilineTextAlignment(.center)
          }
          .padding(32)
        }
        .overlay {
          // Elegant border with subtle glow
          RoundedRectangle(cornerRadius: 24)
            .stroke(.white.opacity(0.2), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 32)
    .frame(maxHeight: .infinity)
  }

  private var cameraControls: some View {
    VStack(spacing: 24) {
      // Primary capture button with Apple-style design
      Button(action: {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
          showingImagePicker = true
        }
      }) {
        ZStack {
          Circle()
            .fill(.white)
            .frame(width: 80, height: 80)
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)

          Circle()
            .fill(.blue)
            .frame(width: 68, height: 68)

          Image(systemName: "camera.fill")
            .font(.title)
            .foregroundStyle(.white)
        }
      }
      .scaleEffect(1.0)
      .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showingImagePicker)

      // Secondary actions with perfect spacing
      HStack(spacing: 40) {
        // Photo library access
        Button(action: {}) {
          VStack(spacing: 8) {
            Image(systemName: "photo.on.rectangle")
              .font(.title2)
              .foregroundStyle(.white)

            Text("Photos")
              .font(.caption)
              .foregroundStyle(.white.opacity(0.8))
          }
        }

        Spacer()

        // Settings quick access
        Button(action: {}) {
          VStack(spacing: 8) {
            Image(systemName: "gear")
              .font(.title2)
              .foregroundStyle(.white)

            Text("Settings")
              .font(.caption)
              .foregroundStyle(.white.opacity(0.8))
          }
        }
      }
      .padding(.horizontal, 60)
    }
    .padding(.bottom, 40)
  }
}

// MARK: - Supporting Views

struct ImagePicker: UIViewControllerRepresentable {
  @Binding var image: UIImage?
  @Environment(\.dismiss) private var dismiss

  func makeUIViewController(context: Context) -> UIImagePickerController {
    let picker = UIImagePickerController()
    picker.delegate = context.coordinator
    picker.sourceType = .camera
    picker.allowsEditing = true
    return picker
  }

  func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let parent: ImagePicker

    init(_ parent: ImagePicker) {
      self.parent = parent
    }

    func imagePickerController(
      _ picker: UIImagePickerController,
      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
      if let editedImage = info[.editedImage] as? UIImage {
        parent.image = editedImage
      } else if let originalImage = info[.originalImage] as? UIImage {
        parent.image = originalImage
      }
      parent.dismiss()
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      parent.dismiss()
    }
  }
}

struct AltTextResultView: View {
  let image: UIImage
  @Environment(AltTextGenerator.self) private var altTextGenerator
  @Environment(\.dismiss) private var dismiss
  @State private var hasGeneratedText = false

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 24) {
          // Image preview with elegant styling
          Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxHeight: 300)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)

          // Alt text section with hierarchy
          VStack(alignment: .leading, spacing: 16) {
            HStack {
              Text("Generated Alt Text")
                .font(.title2)
                .fontWeight(.semibold)

              Spacer()

              if let text = altTextGenerator.generatedText {
                Text("\(text.count)/1000")
                  .font(.caption)
                  .foregroundStyle(.secondary)
                  .monospacedDigit()
              }
            }

            if altTextGenerator.isGenerating {
              generatingView
            } else if let text = altTextGenerator.generatedText {
              generatedTextView(text)
            } else {
              generateButton
            }
          }
          .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
      }
      .navigationTitle("Alt Text")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
    .onAppear {
      if !hasGeneratedText {
        generateAltText()
        hasGeneratedText = true
      }
    }
  }

  private var generatingView: some View {
    VStack(spacing: 16) {
      ProgressView()
        .scaleEffect(1.2)
        .tint(.blue)

      Text("Analyzing image...")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 40)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
  }

  private func generatedTextView(_ text: String) -> some View {
    VStack(spacing: 16) {
      Text(text)
        .font(.body)
        .textSelection(.enabled)
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

      HStack(spacing: 12) {
        Button(action: {
          UIPasteboard.general.string = text
        }) {
          Label("Copy", systemImage: "doc.on.clipboard")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)

        Button(action: {
          // Share functionality
        }) {
          Label("Share", systemImage: "square.and.arrow.up")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
      }
    }
  }

  private var generateButton: some View {
    Button(action: generateAltText) {
      Label("Generate Alt Text", systemImage: "sparkles")
        .frame(maxWidth: .infinity)
    }
    .buttonStyle(.borderedProminent)
    .controlSize(.large)
  }

  private func generateAltText() {
    Task {
      await altTextGenerator.generateAltText(for: image)
    }
  }
}

#Preview {
  CameraView()
    .environment(CameraManager())
    .environment(AltTextGenerator())
}
