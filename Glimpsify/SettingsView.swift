//
//  SettingsView.swift
//  Glimpsify
//
//  Created by Rudrank Riyam on 5/23/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("apiProvider") private var apiProvider: APIProvider = .openAI
    @AppStorage("maxCharacters") private var maxCharacters: Int = 1000
    @AppStorage("autoGenerate") private var autoGenerate: Bool = false
    
    var body: some View {
        Form {
            Section("API Configuration") {
                Picker("Provider", selection: $apiProvider) {
                    ForEach(APIProvider.allCases, id: \.self) { provider in
                        Text(provider.displayName)
                            .tag(provider)
                    }
                }
                .pickerStyle(.menu)
                
                if apiProvider == .openAI {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("OpenAI API Key")
                            .font(.headline)
                        Text("Set OPENAI_API_KEY environment variable")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section("Generation Settings") {
                HStack {
                    Text("Max Characters")
                    Spacer()
                    TextField("1000", value: $maxCharacters, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
                
                Toggle("Auto-generate on image copy", isOn: $autoGenerate)
            }
            
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("Developer")
                    Spacer()
                    Text("Rudrank Riyam")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 300)
        .navigationTitle("Settings")
    }
}

enum APIProvider: String, CaseIterable, Codable {
    case openAI = "openai"
    case claude = "claude"
    
    var displayName: String {
        switch self {
        case .openAI: return "OpenAI GPT-4"
        case .claude: return "Anthropic Claude"
        }
    }
}

#Preview {
    SettingsView()
}
