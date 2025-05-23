# Glimpsify

A macOS menu bar app that generates descriptive alt text for images!

## Features

- Automatic clipboard monitoring - Detects when you copy images
- Groq AI integration - Ultra-fast image analysis with Llama 4 Scout
- Twitter-optimized - Generates concise descriptions (max 1000 characters)
- Secure API key storage - Keys stored safely in macOS Keychain
- API key validation - Tests keys when saving to ensure they work
- One-click copy - Copy generated alt text to clipboard
- Customizable settings - Configure generation options

## AI Model

**Groq Llama 4 Scout**
- Model: `meta-llama/llama-4-scout-17b-16e-instruct`
- Speed: Ultra-fast inference with low latency
- Cost: Free tier available
- Features: Multimodal vision capabilities

## Requirements

- macOS 14.0+
- Groq API key (free at console.groq.com)

## Installation

### Download from Releases

1. Go to the [Releases page](https://github.com/rudrankriyam/Glimpsify/releases)
2. Download the latest `Glimpsify.dmg` file
3. Open the DMG and drag Glimpsify.app to your Applications folder
4. Launch from Applications or Spotlight

**Note**: Official releases are code-signed and notarized by Apple for security.

### Build from Source

1. Clone the repository
   ```bash
   git clone https://github.com/rudrankriyam/Glimpsify.git
   cd Glimpsify
   ```

2. Open in Xcode
   ```bash
   open Glimpsify.xcodeproj
   ```

3. Build and run (⌘+R)

## Setup

### Get a Groq API Key

1. Visit [Groq Console](https://console.groq.com)
2. Sign up for a free account
3. Create a new API key

### Configure the App

1. Launch Glimpsify
2. Click the Glimpsify menu bar icon
3. Go to Settings
4. Enter your API key and click "Save"
5. The app will validate your key automatically

## Usage

1. Copy an image (screenshot, photo, etc.) to your clipboard
2. Click the Glimpsify icon in your menu bar
3. Click "Generate Alt Text" to create a description
4. Copy the result to use on Twitter or anywhere else

## Keyboard Shortcuts

- **⌘+Shift+4** - Take screenshot (automatically copied to clipboard)
- **⌘+C** - Copy image from any app

## Settings

Access settings through the menu bar app to configure:

- **API Key Management**: Securely store and validate your Groq API key
- **Maximum Character Count**: Customize output length
- **Auto-generation**: Enable automatic alt text generation

## Development

Built with:

- SwiftUI for modern macOS UI
- `@Observable` for state management
- MenuBarExtra for menu bar integration
- Security framework for Keychain integration
- Groq API for AI vision processing

## GitHub Actions

This project includes automated building and releasing:

### Automatic Builds

- **On every push to main**: Builds the app and uploads artifacts
- **On pull requests**: Validates that the app builds successfully
- **On tags**: Creates a release with DMG file

### Creating a Release

1. **Using the release script** (recommended):
   ```bash
   ./scripts/release.sh 1.0.0
   ```

2. **Manual process**:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

The GitHub Actions workflow will automatically:
- Build the app in Release configuration
- Create a DMG file
- Upload artifacts
- Create a GitHub release (for tags)

### Code Signing and Notarization

For official releases, the app is code-signed and notarized to prevent "damaged app" warnings on macOS.

**For maintainers**: See [NOTARIZATION_SETUP.md](NOTARIZATION_SETUP.md) for detailed instructions on setting up:
- Apple Developer certificates
- GitHub repository secrets
- Notarization workflow

**For contributors**: Pull requests build unsigned versions for testing. Only tagged releases are signed and notarized.

## API Limits

### Groq
- **Image Size**: 20MB max per request
- **Resolution**: 33 megapixels max per image
- **Base64**: 4MB max for base64 encoded images
- **Rate Limits**: Generous free tier

## Contributing

Feel free to submit issues and pull requests!

## License

MIT License - see LICENSE file for details.