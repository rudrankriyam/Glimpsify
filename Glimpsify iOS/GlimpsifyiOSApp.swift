//
//  GlimpsifyiOSApp.swift
//  Glimpsify iOS
//
//  Created by Rudrank Riyam on 5/23/25.
//

import SwiftUI

@main
struct GlimpsifyiOSApp: App {
  @State private var clipboardManager = ClipboardManager()
  @State private var altTextGenerator = AltTextGenerator()
  @State private var photoLibraryManager = PhotoLibraryManager()
  @State private var cameraManager = CameraManager()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(clipboardManager)
        .environment(altTextGenerator)
        .environment(photoLibraryManager)
        .environment(cameraManager)
        .preferredColorScheme(.none)  // Respect system setting
    }
  }
}
