# Glimpsify

A macOS menu bar app that generates descriptive alt text for images using AI vision models.

## Features

- 🖼️ **Automatic clipboard monitoring** - Detects when you copy images
- 🤖 **AI-powered descriptions** - Uses OpenAI GPT-4 Vision to generate alt text
- 📝 **Twitter-optimized** - Generates concise descriptions (max 1000 characters)
- ⚡ **Menu bar integration** - Quick access from anywhere
- 📋 **One-click copy** - Copy generated alt text to clipboard
- ⚙️ **Customizable settings** - Configure API providers and generation options

## Requirements

- macOS 14.0+
- OpenAI API key

## Setup

1. **Get an OpenAI API key**

   - Visit [OpenAI API](https://platform.openai.com/api-keys)
   - Create a new API key

2. **Set environment variable**

   ```bash
   export OPENAI_API_KEY="your-api-key-here"
   ```

3. **Build and run**
   - Open `Glimpsify.xcodeproj` in Xcode
   - Build and run (⌘+R)

## Usage

1. **Copy an image** (screenshot, photo, etc.) to your clipboard
2. **Click the Glimpsify icon** in your menu bar
3. **Click "Generate Alt Text"** to create a description
4. **Copy the result** to use on Twitter or anywhere else

## Keyboard Shortcuts

- **⌘+Shift+4** - Take screenshot (automatically copied to clipboard)
- **⌘+C** - Copy image from any app

## Settings

Access settings through the menu bar app to configure:

- API provider (currently OpenAI GPT-4)
- Maximum character count
- Auto-generation preferences

## Privacy

- All image processing happens through OpenAI's API
- No images are stored locally
- API calls are made over HTTPS

## Development

Built with:

- SwiftUI for modern macOS UI
- `@Observable` for state management
- MenuBarExtra for menu bar integration
- OpenAI GPT-4 Vision API

## Contributing

Feel free to submit issues and pull requests!

## License

MIT License - see LICENSE file for details.
