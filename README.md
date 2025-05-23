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

## Setup

### Get a Groq API Key

1. Visit [Groq Console](https://console.groq.com)
2. Sign up for a free account
3. Create a new API key

### Configure the App

1. Build and run the app
2. Click the Glimpsify menu bar icon
3. Go to Settings
4. Enter your API key and click "Save"
5. The app will validate your key automatically

## Building

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