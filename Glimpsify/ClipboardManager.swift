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
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            Task {
                self.checkClipboard()
            }
        }
    }

    private func checkClipboard() {
        let pasteboard = NSPasteboard.general

        if pasteboard.changeCount != lastChangeCount {
            lastChangeCount = pasteboard.changeCount

            if let image = NSImage(pasteboard: pasteboard) {
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
