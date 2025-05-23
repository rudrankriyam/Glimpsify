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
    ZStack {
      // Pure Apple background
      Color(.systemGroupedBackground)
        .ignoresSafeArea()

      VStack(spacing: 0) {
        // Apple-style header
        headerSection

        // Main content with Apple transitions
        TabView(selection: $selectedTab) {
          ForEach(Tab.allCases, id: \.self) { tab in
            contentView(for: tab)
              .tag(tab)
          }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut(duration: 0.3), value: selectedTab)
      }
    }
    .sheet(isPresented: $showingSettings) {
      SettingsView()
    }
  }

  private var headerSection: some View {
    VStack(spacing: 0) {
      // Top navigation bar
      HStack {
        // App title with Apple typography
        VStack(alignment: .leading, spacing: 2) {
          Text("Glimpsify")
            .font(.system(size: 28, weight: .bold, design: .default))
            .foregroundStyle(.primary)

          Text("Accessibility made simple")
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(.secondary)
        }

        Spacer()

        // Settings button with Apple styling
        Button(action: { showingSettings = true }) {
          Image(systemName: "ellipsis.circle")
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(.secondary)
        }
      }
      .padding(.horizontal, 20)
      .padding(.top, 8)
      .padding(.bottom, 20)

      // Apple-style segmented control
      customSegmentedControl
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    .background(.regularMaterial)
  }

  private var customSegmentedControl: some View {
    HStack(spacing: 0) {
      ForEach(Tab.allCases, id: \.self) { tab in
        Button(action: {
          withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            selectedTab = tab
          }
        }) {
          HStack(spacing: 6) {
            Image(systemName: selectedTab == tab ? tab.selectedIcon : tab.icon)
              .font(.system(size: 16, weight: .medium))
              .foregroundStyle(selectedTab == tab ? .white : .secondary)

            Text(tab.rawValue)
              .font(.system(size: 15, weight: .semibold))
              .foregroundStyle(selectedTab == tab ? .white : .secondary)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 10)
          .background(
            RoundedRectangle(cornerRadius: 8)
              .fill(selectedTab == tab ? .blue : .clear)
          )
        }
        .buttonStyle(.plain)
      }
    }
    .padding(3)
    .background(
      RoundedRectangle(cornerRadius: 11)
        .fill(.quaternary)
    )
  }

  @ViewBuilder
  private func contentView(for tab: Tab) -> some View {
    switch tab {
    case .camera:
      CameraView()
    case .photos:
      PhotosView()
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
