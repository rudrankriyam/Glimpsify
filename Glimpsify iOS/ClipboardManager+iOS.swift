//
//  ClipboardManager+iOS.swift
//  Glimpsify iOS
//
//  Created by Rudrank Riyam on 5/23/25.
//

import SwiftUI
import UIKit

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
    timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
      Task { @MainActor in
        self.checkClipboard()
      }
    }
  }

  func checkClipboard() {
    let pasteboard = UIPasteboard.general

    if pasteboard.changeCount != lastChangeCount {
      lastChangeCount = pasteboard.changeCount

      if let image = pasteboard.image {
        clipboardImage = image
        hasImage = true
      } else {
        clipboardImage = nil
        hasImage = false
      }
    }
  }

  deinit {
    timer?.invalidate()
  }
}
