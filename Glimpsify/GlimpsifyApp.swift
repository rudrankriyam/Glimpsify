//
//  GlimpsifyApp.swift
//  Glimpsify
//
//  Created by Rudrank Riyam on 5/23/25.
//

import SwiftUI

@main
struct GlimpsifyApp: App {
    @State private var clipboardManager = ClipboardManager()
    @State private var altTextGenerator = AltTextGenerator()

    var body: some Scene {
        MenuBarExtra("Glimpsify", systemImage: "text.bubble") {
            ContentView()
                .environment(clipboardManager)
                .environment(altTextGenerator)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
        }
    }
}
