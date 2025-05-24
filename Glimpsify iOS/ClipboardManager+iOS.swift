//
//  ClipboardManager+iOS.swift
//  Glimpsify iOS
//
//  Created by Rudrank Riyam on 5/23/25.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

@Observable
class ClipboardManager {
  var hasImage = false
  var clipboardImage: UIImage?

  private var timer: Timer?
  private var lastChangeCount = UIPasteboard.general.changeCount

  init() {
    startMonitoring()
    checkClipboard()
  }

  private func startMonitoring() {
    timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
      Task { @MainActor in
        self.checkClipboard()
      }
    }
  }

  func checkClipboard() {
    let pasteboard = UIPasteboard.general
    
    // Check if the change count has changed
    let changeCountChanged = pasteboard.changeCount != lastChangeCount
    if changeCountChanged {
      lastChangeCount = pasteboard.changeCount
    }
    
    // Always check for image content (handles Universal Clipboard from macOS devices)
    if pasteboard.contains(pasteboardTypes: [UTType.image.identifier]) {
      if let image = pasteboard.image {
        // Only update if the image has changed or change count changed
        if changeCountChanged || clipboardImage == nil || !clipboardImage!.isEqual(image) {
          clipboardImage = image
          hasImage = true
        }
      }
    } else if hasImage {
      // Only clear if we previously had an image
      clipboardImage = nil
      hasImage = false
    }
  }

  deinit {
    timer?.invalidate()
  }
}
