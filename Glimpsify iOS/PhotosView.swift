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
    GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 2)
  ]

  var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        // Search bar with elegant styling
        searchBar

        // Photo grid with smooth animations
        photoGrid
      }
      .navigationTitle("Photos")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button(action: { showingPhotoPicker = true }) {
            Image(systemName: "plus")
              .font(.title2)
              .fontWeight(.medium)
          }
        }
      }
    }
    .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedPhoto, matching: .images)
    .sheet(isPresented: $showingAltText) {
      if let image = selectedImage {
        AltTextResultView(image: image)
          .environment(altTextGenerator)
      }
    }
    .onChange(of: selectedPhoto) { _, newPhoto in
      Task {
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

  private var searchBar: some View {
    HStack(spacing: 12) {
      HStack(spacing: 8) {
        Image(systemName: "magnifyingglass")
          .foregroundStyle(.secondary)
          .font(.system(size: 16, weight: .medium))

        TextField("Search photos", text: $searchText)
          .textFieldStyle(.plain)

        if !searchText.isEmpty {
          Button(action: { searchText = "" }) {
            Image(systemName: "xmark.circle.fill")
              .foregroundStyle(.secondary)
              .font(.system(size: 16))
          }
        }
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
  }

  private var photoGrid: some View {
    ScrollView {
      LazyVGrid(columns: columns, spacing: 2) {
        ForEach(photoManager.photos.indices, id: \.self) { index in
          PhotoThumbnailView(
            photo: photoManager.photos[index],
            onTap: { image in
              selectedImage = image
              showingAltText = true
            }
          )
          .aspectRatio(1, contentMode: .fit)
          .clipShape(RoundedRectangle(cornerRadius: 8))
          .onAppear {
            // Load more photos when reaching the end
            if index == photoManager.photos.count - 10 {
              photoManager.loadMorePhotos()
            }
          }
        }
      }
      .padding(.horizontal, 16)
      .padding(.bottom, 100)  // Safe area for tab bar
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
          .transition(.opacity.combined(with: .scale(scale: 0.95)))
      } else {
        Rectangle()
          .fill(.ultraThinMaterial)
          .overlay {
            if isLoading {
              ProgressView()
                .scaleEffect(0.8)
                .tint(.secondary)
            } else {
              Image(systemName: "photo")
                .font(.title2)
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

    let targetSize = CGSize(width: 200, height: 200)

    manager.requestImage(
      for: photo,
      targetSize: targetSize,
      contentMode: .aspectFill,
      options: options
    ) { result, _ in
      DispatchQueue.main.async {
        withAnimation(.easeInOut(duration: 0.3)) {
          self.image = result
          self.isLoading = false
        }
      }
    }
  }
}

#Preview {
  PhotosView()
    .environment(PhotoLibraryManager())
    .environment(AltTextGenerator())
}
