//
//  ContentView.swift
//  Glimpsify iOS
//
//  Created by Rudrank Riyam on 5/23/25.
//

import SwiftUI

struct ContentView: View {
  @Environment(ClipboardManager.self) private var clipboardManager
  @Environment(AltTextGenerator.self) private var altTextGenerator
  @State private var selectedTab: Tab = .camera
  @State private var showingSettings = false

  enum Tab: String, CaseIterable {
    case camera = "Camera"
    case photos = "Photos"
    case clipboard = "Clipboard"

    var icon: String {
      switch self {
      case .camera: return "camera"
      case .photos: return "photo.on.rectangle.angled"
      case .clipboard: return "doc.on.clipboard"
      }
    }

    var selectedIcon: String {
      switch self {
      case .camera: return "camera.fill"
      case .photos: return "photo.fill.on.rectangle.fill"
      case .clipboard: return "doc.on.clipboard.fill"
      }
    }
  }

  var body: some View {
    TabView(selection: $selectedTab) {
      ForEach(Tab.allCases, id: \.self) { tab in
        contentView(for: tab)
          .tabItem {
            Image(systemName: selectedTab == tab ? tab.selectedIcon : tab.icon)
            Text(tab.rawValue)
          }
          .tag(tab)
      }
    }
    .onAppear {
      // Make tab bar opaque
      let appearance = UITabBarAppearance()
      appearance.configureWithOpaqueBackground()
      appearance.backgroundColor = UIColor.systemBackground

      UITabBar.appearance().standardAppearance = appearance
      UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    .sheet(isPresented: $showingSettings) {
      SettingsView()
    }
  }

  @ViewBuilder
  private func contentView(for tab: Tab) -> some View {
    switch tab {
    case .camera:
      CameraView()
    case .photos:
      PhotosView()
        .toolbar {
          ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: { showingSettings = true }) {
              Image(systemName: "gear")
            }
          }
        }
    case .clipboard:
      ClipboardView()
    }
  }
}

#Preview {
  ContentView()
    .environment(ClipboardManager())
    .environment(AltTextGenerator())
}
