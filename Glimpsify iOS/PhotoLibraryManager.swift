//
//  PhotoLibraryManager.swift
//  Glimpsify iOS
//
//  Created by Rudrank Riyam on 5/23/25.
//

import Photos
import PhotosUI
import SwiftUI

@Observable
class PhotoLibraryManager {
  var photos: [PHAsset] = []
  var authorizationStatus: PHAuthorizationStatus = .notDetermined
  var isLoading = false
  var hasMorePhotos = true

  private var fetchResult: PHFetchResult<PHAsset>?
  private let fetchLimit = 50
  private var currentOffset = 0

  init() {
    authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    if authorizationStatus == .authorized || authorizationStatus == .limited {
      loadPhotos()
    }
  }

  func requestPermission() {
    guard authorizationStatus == .notDetermined else { return }

    PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
      DispatchQueue.main.async {
        self?.authorizationStatus = status
        if status == .authorized || status == .limited {
          self?.loadPhotos()
        }
      }
    }
  }

  func loadPhotos() {
    guard authorizationStatus == .authorized || authorizationStatus == .limited else { return }
    guard !isLoading else { return }

    isLoading = true

    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      guard let self = self else { return }

      let options = PHFetchOptions()
      options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
      options.fetchLimit = self.fetchLimit

      if self.fetchResult == nil {
        // Initial load
        self.fetchResult = PHAsset.fetchAssets(with: .image, options: options)
        self.currentOffset = 0
      }

      guard let fetchResult = self.fetchResult else {
        DispatchQueue.main.async {
          self.isLoading = false
        }
        return
      }

      let startIndex = self.currentOffset
      let endIndex = min(startIndex + self.fetchLimit, fetchResult.count)

      var newPhotos: [PHAsset] = []
      for i in startIndex..<endIndex {
        newPhotos.append(fetchResult.object(at: i))
      }

      DispatchQueue.main.async {
        if self.currentOffset == 0 {
          self.photos = newPhotos
        } else {
          self.photos.append(contentsOf: newPhotos)
        }

        self.currentOffset = endIndex
        self.hasMorePhotos = endIndex < fetchResult.count
        self.isLoading = false
      }
    }
  }

  func loadMorePhotos() {
    guard hasMorePhotos && !isLoading else { return }
    loadPhotos()
  }

  func refreshPhotos() async {
    await MainActor.run {
      photos.removeAll()
      fetchResult = nil
      currentOffset = 0
      hasMorePhotos = true
    }

    loadPhotos()
  }

  func getImage(for asset: PHAsset, targetSize: CGSize = CGSize(width: 300, height: 300)) async
    -> UIImage? {
    await withCheckedContinuation { continuation in
      let manager = PHImageManager.default()
      let options = PHImageRequestOptions()
      options.deliveryMode = .highQualityFormat
      options.isNetworkAccessAllowed = true
      options.isSynchronous = false

      manager.requestImage(
        for: asset,
        targetSize: targetSize,
        contentMode: .aspectFill,
        options: options
      ) { image, _ in
        continuation.resume(returning: image)
      }
    }
  }

  func getFullResolutionImage(for asset: PHAsset) async -> UIImage? {
    await withCheckedContinuation { continuation in
      let manager = PHImageManager.default()
      let options = PHImageRequestOptions()
      options.deliveryMode = .highQualityFormat
      options.isNetworkAccessAllowed = true
      options.isSynchronous = false

      manager.requestImage(
        for: asset,
        targetSize: PHImageManagerMaximumSize,
        contentMode: .aspectFit,
        options: options
      ) { image, _ in
        continuation.resume(returning: image)
      }
    }
  }
}
