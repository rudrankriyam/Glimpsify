//
//  ContentView.swift
//  Glimpsify iOS
//
//  Created by Rudrank Riyam on 5/23/25.
//

import SwiftUI

struct ContentView: View {
  @State private var selectedTab = 0

  var body: some View {
    TabView(selection: $selectedTab) {
      CameraView()
        .tabItem {
          Label("Camera", systemImage: "camera.fill")
        }
        .tag(0)

      PhotosView()
        .tabItem {
          Label("Photos", systemImage: "photo.on.rectangle")
        }
        .tag(1)

      ClipboardView()
        .tabItem {
          Label("Clipboard", systemImage: "clipboard.fill")
        }
        .tag(2)

      SettingsView()
        .tabItem {
          Label("Settings", systemImage: "gear")
        }
        .tag(3)
    }
    .tint(.blue)  // Apple's signature blue
    .onAppear {
      // Customize tab bar appearance for premium feel
      let appearance = UITabBarAppearance()
      appearance.configureWithOpaqueBackground()
      appearance.backgroundColor = UIColor.systemBackground

      // Add subtle shadow for depth
      appearance.shadowColor = UIColor.black.withAlphaComponent(0.1)

      UITabBar.appearance().standardAppearance = appearance
      UITabBar.appearance().scrollEdgeAppearance = appearance
    }
  }
}

#Preview {
  ContentView()
}
