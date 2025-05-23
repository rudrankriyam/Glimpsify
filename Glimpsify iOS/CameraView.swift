//
//  CameraView.swift
//  Glimpsify iOS
//
//  Created by Rudrank Riyam on 5/23/25.
//

import AVFoundation
import SwiftUI
import UIKit

struct CameraView: View {
  @Environment(CameraManager.self) private var cameraManager
  @Environment(AltTextGenerator.self) private var altTextGenerator
  @State private var showingImagePicker = false
  @State private var capturedImage: UIImage?
  @State private var showingResult = false
  @State private var flashMode: AVCaptureDevice.FlashMode = .off
  @State private var isCapturing = false

  var body: some View {
    ZStack {
      // Black background that fills the safe area but respects tab bar
      Color.black
        .ignoresSafeArea(.all, edges: [.top, .leading, .trailing])

      // Camera preview
      cameraPreview
        .ignoresSafeArea(.all, edges: [.top, .leading, .trailing])

      // Minimalistic overlay controls
      VStack {
        // Top minimal controls
        topControls
          .padding(.horizontal, 24)
          .padding(.top, 16)

        Spacer()

        // Bottom capture controls
        bottomControls
          .padding(.horizontal, 24)
          .padding(.bottom, 34)
      }
    }
    .task {
      await setupCamera()
    }
    .onAppear {
      if cameraManager.isAuthorized && !cameraManager.isSessionRunning {
        cameraManager.startSession()
      }
    }
    .onDisappear {
      cameraManager.stopSession()
    }
    .sheet(isPresented: $showingImagePicker) {
      ImagePicker(image: $capturedImage)
    }
    .sheet(isPresented: $showingResult) {
      if let image = capturedImage {
        CaptureResultView(image: image, isAnalyzing: $isCapturing)
          .environment(altTextGenerator)
      }
    }
  }

  private func setupCamera() async {
    let granted = await cameraManager.requestPermission()
    if granted {
      await cameraManager.setupCamera()
      await MainActor.run {
        cameraManager.startSession()
      }
    }
  }

  private var cameraPreview: some View {
    CameraPreviewView(cameraManager: cameraManager)
      .overlay(
        // Subtle center focus indicator
        RoundedRectangle(cornerRadius: 8)
          .stroke(.white.opacity(0.4), lineWidth: 1)
          .frame(width: 200, height: 150)
          .animation(.easeInOut(duration: 0.3), value: isCapturing)
          .scaleEffect(isCapturing ? 1.1 : 1.0)
      )
  }

  private var topControls: some View {
    HStack {
      // Flash control - more prominent when on, only show if available
      if cameraManager.isFlashAvailable {
        Button(action: toggleFlash) {
          Image(systemName: flashIconName)
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(flashMode == .on ? .yellow : (flashMode == .auto ? .orange : .white))
            .frame(width: 44, height: 44)
            .background(
              (flashMode != .off ? .white.opacity(0.2) : .clear),
              in: Circle()
            )
            .overlay(
              Circle()
                .stroke(.white.opacity(flashMode != .off ? 0.4 : 0.2), lineWidth: 1)
            )
        }
      } else {
        // Spacer when flash is not available
        Spacer()
          .frame(width: 44, height: 44)
      }

      Spacer()

      // Camera flip button
      Button(action: {
        withAnimation(.easeInOut(duration: 0.3)) {
          cameraManager.flipCamera()

          // Turn off flash if switching to front camera (typically no flash)
          if !cameraManager.isFlashAvailable && flashMode != .off {
            flashMode = .off
            cameraManager.setFlashMode(flashMode)
          }
        }
      }) {
        Image(systemName: "camera.rotate")
          .font(.system(size: 20, weight: .medium))
          .foregroundStyle(.white)
          .frame(width: 44, height: 44)
          .background(.clear)
          .overlay(
            Circle()
              .stroke(.white.opacity(0.2), lineWidth: 1)
          )
      }
    }
  }

  private var bottomControls: some View {
    HStack(alignment: .center, spacing: 0) {
      // Photo library button
      Button(action: {
        showingImagePicker = true
      }) {
        Image(systemName: "photo")
          .font(.system(size: 24, weight: .medium))
          .foregroundStyle(.white)
          .frame(width: 50, height: 50)
      }
      .frame(maxWidth: .infinity)

      // Main capture button - Apple style
      Button(action: capturePhoto) {
        ZStack {
          Circle()
            .fill(.white)
            .frame(width: 72, height: 72)

          Circle()
            .stroke(.white.opacity(0.3), lineWidth: 2)
            .frame(width: 88, height: 88)

          if isCapturing {
            ProgressView()
              .scaleEffect(1.2)
              .tint(.black)
          }
        }
      }
      .disabled(isCapturing || !cameraManager.isAuthorized)
      .scaleEffect(isCapturing ? 0.9 : 1.0)
      .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCapturing)
      .frame(maxWidth: .infinity)

      // Settings/Info button
      Button(action: {
        // TODO: Show camera info or settings
      }) {
        Image(systemName: "info.circle")
          .font(.system(size: 24, weight: .medium))
          .foregroundStyle(.white.opacity(0.7))
          .frame(width: 50, height: 50)
      }
      .frame(maxWidth: .infinity)
    }
  }

  private var flashIconName: String {
    switch flashMode {
    case .on: return "bolt.fill"
    case .off: return "bolt.slash"
    case .auto: return "bolt.badge.automatic"
    @unknown default: return "bolt.slash"
    }
  }

  private func toggleFlash() {
    withAnimation(.easeInOut(duration: 0.2)) {
      switch flashMode {
      case .off: flashMode = .auto
      case .auto: flashMode = .on
      case .on: flashMode = .off
      @unknown default: flashMode = .off
      }
    }
    cameraManager.setFlashMode(flashMode)
  }

  private func capturePhoto() {
    guard cameraManager.isAuthorized else { return }

    isCapturing = true

    // Add haptic feedback
    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    impactFeedback.impactOccurred()

    cameraManager.capturePhoto { image in
      DispatchQueue.main.async {
        if let image = image {
          self.capturedImage = image
          self.showingResult = true
        }
        self.isCapturing = false
      }
    }
  }
}

// MARK: - Camera Preview View
struct CameraPreviewView: UIViewRepresentable {
  let cameraManager: CameraManager
  @State private var lastFrameUpdate = Date()

  func makeUIView(context: Context) -> UIView {
    let view = UIView()
    view.backgroundColor = .black
    return view
  }

  func updateUIView(_ uiView: UIView, context: Context) {
    // Ensure black background is maintained
    uiView.backgroundColor = .black

    // Remove any existing preview layers
    uiView.layer.sublayers?.forEach { layer in
      if layer is AVCaptureVideoPreviewLayer {
        layer.removeFromSuperlayer()
      }
    }

    // Add the current preview layer if available
    if let previewLayer = cameraManager.previewLayer {
      previewLayer.frame = uiView.bounds
      previewLayer.videoGravity = .resizeAspectFill
      uiView.layer.addSublayer(previewLayer)

      // Force a layout update
      DispatchQueue.main.async {
        previewLayer.frame = uiView.bounds
      }
    }
  }
}

// MARK: - Capture Result View
struct CaptureResultView: View {
  let image: UIImage
  @Environment(AltTextGenerator.self) private var altTextGenerator
  @Environment(\.dismiss) private var dismiss
  @Binding var isAnalyzing: Bool
  @State private var generatedText = ""

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 24) {
          // Image preview with Apple styling
          Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxHeight: 350)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .background(
              RoundedRectangle(cornerRadius: 12)
                .fill(.quaternary)
            )

          // Result section
          VStack(spacing: 16) {
            HStack {
              Text("Description")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.primary)
              Spacer()
            }

            if isAnalyzing {
              HStack(spacing: 12) {
                ProgressView()
                  .scaleEffect(0.9)
                Text("Analyzing image...")
                  .font(.system(size: 16, weight: .regular))
                  .foregroundStyle(.secondary)
                Spacer()
              }
              .padding(16)
              .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
            } else if !generatedText.isEmpty {
              VStack(spacing: 12) {
                Text(generatedText)
                  .font(.system(size: 16, weight: .regular))
                  .lineSpacing(4)
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .padding(16)
                  .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                  .textSelection(.enabled)

                HStack(spacing: 12) {
                  Button(action: shareText) {
                    HStack(spacing: 6) {
                      Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15, weight: .medium))
                      Text("Share")
                        .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                  }

                  Button(action: copyText) {
                    HStack(spacing: 6) {
                      Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 15, weight: .medium))
                      Text("Copy")
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
            } else {
              VStack(spacing: 16) {
                Text("Tap 'Analyze' to generate an accessible description")
                  .font(.system(size: 16, weight: .regular))
                  .foregroundStyle(.secondary)
                  .multilineTextAlignment(.center)
                  .padding(16)
                  .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))

                Button(action: analyzeImage) {
                  HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                      .font(.system(size: 16, weight: .semibold))
                    Text("Analyze Image")
                      .font(.system(size: 17, weight: .semibold))
                  }
                  .frame(maxWidth: .infinity)
                  .frame(height: 50)
                  .background(.blue)
                  .foregroundStyle(.white)
                  .clipShape(RoundedRectangle(cornerRadius: 12))
                }
              }
            }
          }
        }
        .padding(20)
      }
      .background(Color(.systemGroupedBackground))
      .navigationTitle("Captured Image")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            dismiss()
          }
          .font(.system(size: 16, weight: .medium))
        }
      }
    }
    .onAppear {
      if let existingText = altTextGenerator.generatedText, !existingText.isEmpty {
        generatedText = existingText
      }
    }
  }

  private func analyzeImage() {
    isAnalyzing = true

    Task {
      await altTextGenerator.generateAltText(for: image)
      await MainActor.run {
        if let text = altTextGenerator.generatedText {
          generatedText = text
        } else if let error = altTextGenerator.error {
          generatedText = "Failed to analyze image: \(error)"
        }
        isAnalyzing = false
      }
    }
  }

  private func copyText() {
    UIPasteboard.general.string = generatedText
    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    impactFeedback.impactOccurred()
  }

  private func shareText() {
    let activityController = UIActivityViewController(
      activityItems: [generatedText],
      applicationActivities: nil
    )

    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
      let window = windowScene.windows.first
    {
      window.rootViewController?.present(activityController, animated: true)
    }
  }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
  @Binding var image: UIImage?
  @Environment(\.dismiss) private var dismiss

  func makeUIViewController(context: Context) -> UIImagePickerController {
    let picker = UIImagePickerController()
    picker.delegate = context.coordinator
    picker.sourceType = .photoLibrary
    picker.allowsEditing = false
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
      if let image = info[.originalImage] as? UIImage {
        parent.image = image
      }
      parent.dismiss()
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      parent.dismiss()
    }
  }
}

#Preview {
  CameraView()
    .environment(CameraManager())
    .environment(AltTextGenerator())
}
