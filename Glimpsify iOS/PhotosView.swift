//
//  PhotosView.swift
//  Glimpsify iOS
//
//  Created by Rudrank Riyam on 5/23/25.
//

import Photos
import PhotosUI
import SwiftUI

struct PhotosView: View {
  @Environment(PhotoLibraryManager.self) private var photoManager
  @Environment(AltTextGenerator.self) private var altTextGenerator
  @State private var selectedPhoto: PhotosPickerItem?
  @State private var selectedImage: UIImage?
  @State private var showingAltText = false
  @State private var searchText = ""
  @State private var showingPhotoPicker = false

  private let columns = [
    GridItem(.adaptive(minimum: 110, maximum: 130), spacing: 1)
  ]

  var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        // Search section
        if !searchText.isEmpty || photoManager.photos.isEmpty {
          searchSection
        }

        // Photos grid
        photoGrid
      }
      .background(Color(.systemBackground))
      .navigationTitle("Photos")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button(action: { showingPhotoPicker = true }) {
            Image(systemName: "plus")
              .font(.system(size: 18, weight: .medium))
          }
        }
      }
      .searchable(text: $searchText, prompt: "Search photos")
    }
    .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedPhoto, matching: .images)
    .sheet(isPresented: $showingAltText) {
      if let image = selectedImage {
        AltTextResultView(image: image)
          .environment(altTextGenerator)
      }
    }
    .onChange(of: selectedPhoto) { _, newPhoto in
      Task { @MainActor in
        if let data = try? await newPhoto?.loadTransferable(type: Data.self),
          let image = UIImage(data: data)
        {
          selectedImage = image
          showingAltText = true
        }
      }
    }
    .onAppear {
      photoManager.requestPermission()
    }
  }

  private var searchSection: some View {
    VStack(spacing: 16) {
      if photoManager.photos.isEmpty {
        VStack(spacing: 12) {
          Image(systemName: "photo.on.rectangle")
            .font(.system(size: 48, weight: .ultraLight))
            .foregroundStyle(.secondary)

          Text("No Photos")
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(.primary)

          Text("Photos you select will appear here")
            .font(.system(size: 16, weight: .regular))
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
      }
    }
    .padding(.horizontal, 20)
  }

  private var photoGrid: some View {
    ScrollView {
      LazyVGrid(columns: columns, spacing: 1) {
        ForEach(photoManager.photos.indices, id: \.self) { index in
          PhotoThumbnailView(
            photo: photoManager.photos[index],
            onTap: { image in
              selectedImage = image
              showingAltText = true
            }
          )
          .aspectRatio(1, contentMode: .fit)
          .onAppear {
            if index == photoManager.photos.count - 10 {
              photoManager.loadMorePhotos()
            }
          }
        }
      }
      .padding(.bottom, 100)
    }
    .refreshable {
      await photoManager.refreshPhotos()
    }
  }
}

struct PhotoThumbnailView: View {
  let photo: PHAsset
  let onTap: (UIImage) -> Void

  @State private var image: UIImage?
  @State private var isLoading = true

  var body: some View {
    ZStack {
      if let image = image {
        Image(uiImage: image)
          .resizable()
          .aspectRatio(contentMode: .fill)
          .clipped()
          .onTapGesture {
            onTap(image)
          }
          .transition(.opacity.combined(with: .scale(scale: 0.98)))
      } else {
        Rectangle()
          .fill(.quaternary)
          .overlay {
            if isLoading {
              ProgressView()
                .scaleEffect(0.7)
                .tint(.secondary)
            } else {
              Image(systemName: "photo")
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(.secondary)
            }
          }
      }
    }
    .onAppear {
      loadImage()
    }
  }

  private func loadImage() {
    let manager = PHImageManager.default()
    let options = PHImageRequestOptions()
    options.deliveryMode = .highQualityFormat
    options.isNetworkAccessAllowed = true

    let targetSize = CGSize(width: 300, height: 300)

    manager.requestImage(
      for: photo,
      targetSize: targetSize,
      contentMode: .aspectFill,
      options: options
    ) { result, _ in
      DispatchQueue.main.async {
        withAnimation(.easeInOut(duration: 0.2)) {
          self.image = result
          self.isLoading = false
        }
      }
    }
  }
}

// MARK: - Alt Text Result View
struct AltTextResultView: View {
  let image: UIImage
  @Environment(AltTextGenerator.self) private var altTextGenerator
  @Environment(\.dismiss) private var dismiss
  @State private var isGenerating = false
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

            if isGenerating {
              HStack(spacing: 12) {
                ProgressView()
                  .scaleEffect(0.9)
                Text("Generating description...")
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
                Text("Tap 'Generate' to create an accessible description")
                  .font(.system(size: 16, weight: .regular))
                  .foregroundStyle(.secondary)
                  .multilineTextAlignment(.center)
                  .padding(16)
                  .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))

                Button(action: generateAltText) {
                  HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                      .font(.system(size: 16, weight: .semibold))
                    Text("Generate Description")
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
      .navigationTitle("Photo")
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
      if altTextGenerator.generatedText?.isEmpty == false {
        generatedText = altTextGenerator.generatedText ?? ""
      }
    }
  }

  private func generateAltText() {
    isGenerating = true

    Task {
      await altTextGenerator.generateAltText(for: image)
      await MainActor.run {
        if let text = altTextGenerator.generatedText {
          generatedText = text
        } else if let error = altTextGenerator.error {
          generatedText = "Failed to generate alt text: \(error)"
        }
        isGenerating = false
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

#Preview {
  PhotosView()
    .environment(PhotoLibraryManager())
    .environment(AltTextGenerator())
}
