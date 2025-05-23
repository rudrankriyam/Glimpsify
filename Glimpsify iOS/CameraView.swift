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
  @State private var showingResult = false
  @State private var flashMode: AVCaptureDevice.FlashMode = .off
  @State private var isCapturing = false

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        // Black background covering everything
        Color.black
          .ignoresSafeArea(.all)

        // Camera preview
        cameraPreview
          .ignoresSafeArea(.all)

        // Camera controls overlay
        VStack {
          // Top controls
          topControls

          Spacer()

          // Bottom controls
          bottomControls
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, max(16, geometry.safeAreaInsets.bottom + 16))
      }
    }
    .background(.black)
    .task {
      _ = await cameraManager.requestPermission()
      await cameraManager.setupCamera()
      cameraManager.startSession()
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

  private var cameraPreview: some View {
    GeometryReader { geometry in
      ZStack {
        // Ensure black background
        Color.black
          .ignoresSafeArea(.all)

        CameraPreviewView(cameraManager: cameraManager)

        // Subtle viewfinder overlay
        VStack {
          Spacer()

          RoundedRectangle(cornerRadius: 16)
            .stroke(.white.opacity(0.3), lineWidth: 1)
            .frame(width: min(280, geometry.size.width - 60), height: 180)
            .overlay(
              VStack {
                HStack {
                  Rectangle()
                    .fill(.white.opacity(0.6))
                    .frame(width: 16, height: 1)
                  Spacer()
                  Rectangle()
                    .fill(.white.opacity(0.6))
                    .frame(width: 16, height: 1)
                }
                Spacer()
                HStack {
                  Rectangle()
                    .fill(.white.opacity(0.6))
                    .frame(width: 16, height: 1)
                  Spacer()
                  Rectangle()
                    .fill(.white.opacity(0.6))
                    .frame(width: 16, height: 1)
                }
              }
              .padding(6)
            )

          Text("Position subject in frame")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.white.opacity(0.8))
            .padding(.top, 12)

          Spacer()
        }
      }
    }
  }

  private var topControls: some View {
    HStack {
      // Flash control
      Button(action: toggleFlash) {
        Image(systemName: flashIconName)
          .font(.system(size: 18, weight: .medium))
          .foregroundStyle(flashMode == .on ? .yellow : .white)
          .frame(width: 40, height: 40)
          .background(.black.opacity(0.3), in: Circle())
          .overlay(
            Circle()
              .stroke(.white.opacity(0.2), lineWidth: 0.5)
          )
      }

      Spacer()

      // Camera status
      HStack(spacing: 6) {
        Circle()
          .fill(cameraManager.isAuthorized ? .green : .red)
          .frame(width: 6, height: 6)

        Text(cameraManager.isAuthorized ? "Ready" : "No Access")
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(.white)
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 6)
      .background(.black.opacity(0.4), in: Capsule())

      Spacer()

      // Camera flip
      Button(action: {
        cameraManager.flipCamera()
      }) {
        Image(systemName: "camera.rotate")
          .font(.system(size: 18, weight: .medium))
          .foregroundStyle(.white)
          .frame(width: 40, height: 40)
          .background(.black.opacity(0.3), in: Circle())
          .overlay(
            Circle()
              .stroke(.white.opacity(0.2), lineWidth: 0.5)
          )
      }
    }
  }

  private var bottomControls: some View {
    VStack(spacing: 20) {
      // Instruction text
      Text("Tap to capture and analyze")
        .font(.system(size: 15, weight: .medium))
        .foregroundStyle(.white.opacity(0.9))

      HStack(spacing: 50) {
        // Photo library
        Button(action: {
          showingImagePicker = true
        }) {
          RoundedRectangle(cornerRadius: 8)
            .fill(.white.opacity(0.2))
            .frame(width: 50, height: 50)
            .overlay(
              Image(systemName: "photo.on.rectangle")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white)
            )
        }

        // Capture button - Apple style
        Button(action: capturePhoto) {
          ZStack {
            Circle()
              .fill(.white)
              .frame(width: 70, height: 70)

            Circle()
              .stroke(.white, lineWidth: 3)
              .frame(width: 84, height: 84)

            if isCapturing {
              ProgressView()
                .scaleEffect(1.2)
                .tint(.black)
            }
          }
        }
        .disabled(isCapturing || !cameraManager.isAuthorized)
        .scaleEffect(isCapturing ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isCapturing)

        // Info/settings
        Button(action: {
          // Show info
        }) {
          RoundedRectangle(cornerRadius: 8)
            .fill(.white.opacity(0.2))
            .frame(width: 50, height: 50)
            .overlay(
              Image(systemName: "info")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white)
            )
        }
      }
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
    switch flashMode {
    case .off: flashMode = .on
    case .on: flashMode = .auto
    case .auto: flashMode = .off
    @unknown default: flashMode = .off
    }
    cameraManager.setFlashMode(flashMode)
  }

  private func capturePhoto() {
    guard cameraManager.isAuthorized else { return }

    isCapturing = true

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

  func makeUIView(context: Context) -> UIView {
    let view = UIView()
    view.backgroundColor = .black

    if let previewLayer = cameraManager.previewLayer {
      previewLayer.frame = view.bounds
      previewLayer.videoGravity = .resizeAspectFill
      view.layer.addSublayer(previewLayer)
    }

    return view
  }

  func updateUIView(_ uiView: UIView, context: Context) {
    // Ensure black background is maintained
    uiView.backgroundColor = .black

    if let previewLayer = cameraManager.previewLayer {
      previewLayer.frame = uiView.bounds
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
