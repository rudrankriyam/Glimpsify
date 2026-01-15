# Glimpsify
[![Star History Chart](https://api.star-history.com/svg?repos=rudrankriyam/Glimpsify&type=Date)](https://star-history.com/#rudrankriyam/Glimpsify&Date)


A cross-platform app that generates descriptive alt text for images using AI! Available for both macOS and iOS.

## Features

### macOS (Menu Bar App)
- **Automatic clipboard monitoring** - Detects when you copy images
- **One-click generation** - Generate alt text from the menu bar
- **System integration** - Works seamlessly with screenshots and copied images
- **Customizable settings** - Configure generation options

### iOS (Native App)
- **Camera integration** - Take photos directly in the app with professional controls
- **Photo library access** - Browse and select images with elegant grid layout
- **Clipboard monitoring** - Automatically detect images copied to clipboard
- **Beautiful design** - Built with Apple's design principles and guidelines
- **Tab-based navigation** - Intuitive interface across Camera, Photos, Clipboard, and Settings

### Shared Features
- **Groq AI integration** - Ultra-fast image analysis with Llama 4 Scout
- **Twitter-optimized** - Generates concise descriptions (max 1000 characters)
- **Secure API key storage** - Keys stored safely in Keychain (macOS) or iOS Keychain
- **API key validation** - Tests keys when saving to ensure they work
- **One-click copy** - Copy generated alt text to clipboard
- **Privacy-first** - All processing happens locally, only API calls for generation

## AI Model

**Groq Llama 4 Scout**
- Model: `meta-llama/llama-4-scout-17b-16e-instruct`
- Speed: Ultra-fast inference with low latency
- Cost: Free tier available
- Features: Multimodal vision capabilities

## Requirements

### macOS
- macOS 14.0+
- Groq API key (free at console.groq.com)

### iOS
- iOS 18.0+
- iPhone or iPad
- Groq API key (free at console.groq.com)

## Installation

### Download from Releases (macOS)

1. Go to the [Releases page](https://github.com/rudrankriyam/Glimpsify/releases)
2. Download the latest `Glimpsify.dmg` file
3. Open the DMG and drag Glimpsify.app to your Applications folder
4. Launch from Applications or Spotlight

**Note**: Official releases are code-signed and notarized by Apple for security.

### iOS App Store (Coming Soon)

The iOS version will be available on the App Store soon. For now, you can build from source.

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

3. Select your target platform:
   - **For macOS**: Select "Glimpsify" scheme
   - **For iOS**: Select "Glimpsify iOS" scheme

4. Build and run (⌘+R)

## Setup

### Get a Groq API Key

1. Visit [Groq Console](https://console.groq.com)
2. Sign up for a free account
3. Create a new API key

### Configure the App

#### macOS
1. Launch Glimpsify
2. Click the Glimpsify menu bar icon
3. Go to Settings
4. Enter your API key and click "Save"
5. The app will validate your key automatically

#### iOS
1. Launch the app
2. Go to Settings tab
3. Enter your Groq API key
4. Grant camera and photo library permissions when prompted

## Usage

### macOS
1. Copy an image (screenshot, photo, etc.) to your clipboard
2. Click the Glimpsify icon in your menu bar
3. Click "Generate Alt Text" to create a description
4. Copy the result to use on Twitter or anywhere else

### iOS
1. **Camera**: Take a new photo and generate alt text instantly
2. **Photos**: Select an image from your photo library
3. **Clipboard**: Copy an image from any app and switch to Glimpsify
4. **Generated text**: Copy or share the alt text description

## GitHub Actions

This project includes automated building and releasing:

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
- Build both macOS and iOS apps in Release configuration
- Create a DMG file for macOS
- Upload artifacts for both platforms
- Create a GitHub release (for tags)

### Code Signing and Notarization

For official releases, the macOS app is code-signed and notarized to prevent "damaged app" warnings.

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

Feel free to submit issues and pull requests! When contributing:

- Follow Apple's Human Interface Guidelines for UI changes
- Ensure accessibility compliance
- Test on multiple devices and screen sizes
- Consider both macOS and iOS impacts for shared code changes

## License

MIT License - see LICENSE file for details.