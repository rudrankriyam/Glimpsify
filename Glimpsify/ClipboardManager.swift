//
//  ClipboardManager.swift
//  Glimpsify
//
//  Created by Rudrank Riyam on 5/23/25.
//

import AppKit
import SwiftUI

@Observable
class ClipboardManager {
    var hasImage = false
    var clipboardImage: NSImage?

    private var timer: Timer?
    private var lastChangeCount = NSPasteboard.general.changeCount

    init() {
        startMonitoring()
        checkClipboard()
    }

    private func startMonitoring() {
        // Increase the polling interval to 1 second to reduce CPU usage while maintaining responsiveness.
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task {
                self.checkClipboard()
            }
        }
    }

    func checkClipboard() {
        let pasteboard = NSPasteboard.general
        
        // Check if the change count has changed
        let changeCountChanged = pasteboard.changeCount != lastChangeCount
        if changeCountChanged {
            lastChangeCount = pasteboard.changeCount
        }
        
        // Always check for image content (handles Universal Clipboard from iOS devices)
        if let image = NSImage(pasteboard: pasteboard) {
            // Only update if the image has changed or change count changed
            if changeCountChanged || clipboardImage == nil || !image.dataEquals(clipboardImage) {
                clipboardImage = image
                hasImage = true
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
