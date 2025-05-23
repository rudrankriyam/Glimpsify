# Glimpsify

A macOS menu bar app that generates descriptive alt text for images using AI vision models.

## Features

- 🖼️ **Automatic clipboard monitoring** - Detects when you copy images
- 🤖 **Multiple AI providers** - Choose between Groq, OpenAI, or Anthropic Claude
- ⚡ **Ultra-fast inference** - Groq provides lightning-fast image analysis
- 📝 **Twitter-optimized** - Generates concise descriptions (max 1000 characters)
- 🔐 **Secure API key storage** - Keys stored safely in macOS Keychain
- 📋 **One-click copy** - Copy generated alt text to clipboard
- ⚙️ **Customizable settings** - Configure API providers and generation options

## Supported AI Models

### Groq (Default - Recommended)
- **Model**: `meta-llama/llama-4-scout-17b-16e-instruct`
- **Speed**: Ultra-fast inference with low latency
- **Cost**: Free tier available
- **Features**: Multimodal, tool use, JSON mode

### OpenAI
- **Model**: `gpt-4o`
- **Quality**: High-quality vision analysis
- **Cost**: Pay-per-use

### Anthropic Claude
- **Model**: `claude-3-5-sonnet-20241022`
- **Quality**: Excellent vision understanding
- **Cost**: Pay-per-use

## Requirements

- macOS 14.0+
- API key from your chosen provider (Groq recommended)

## Setup

### Option 1: Groq (Recommended - Free)

1. **Get a Groq API key**
   - Visit [Groq Console](https://console.groq.com)
   - Sign up for a free account
   - Create a new API key

2. **Configure in app**
   - Build and run the app
   - Click the Glimpsify menu bar icon
   - Go to Settings
   - Select "Groq" as provider
   - Enter your API key and click "Save"

### Option 2: OpenAI

1. **Get an OpenAI API key**
   - Visit [OpenAI API](https://platform.openai.com/api-keys)
   - Create a new API key

2. **Configure in app**
   - Select "OpenAI GPT-4" in Settings
   - Enter your API key and click "Save"

### Option 3: Anthropic Claude

1. **Get a Claude API key**
   - Visit [Anthropic Console](https://console.anthropic.com)
   - Create a new API key

2. **Configure in app**
   - Select "Anthropic Claude" in Settings
   - Enter your API key and click "Save"

## Building

1. **Clone the repository**
   ```bash
   git clone https://github.com/rudrankriyam/Glimpsify.git
   cd Glimpsify
   ```

2. **Open in Xcode**
   ```bash
   open Glimpsify.xcodeproj
   ```

3. **Build and run** (⌘+R)

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

- **API Provider**: Choose between Groq, OpenAI, or Claude
- **API Key Management**: Securely store keys in macOS Keychain
- **Maximum Character Count**: Customize output length
- **Auto-generation**: Enable automatic alt text generation

## Privacy & Security

- **Secure Storage**: API keys stored in macOS Keychain
- **No Local Storage**: Images are not stored locally
- **HTTPS**: All API calls made over secure connections
- **Provider Choice**: You control which AI service processes your images

## Why Groq?

Groq offers several advantages as the default provider:

- **Speed**: Ultra-fast inference (often 10x faster than alternatives)
- **Cost**: Generous free tier
- **Quality**: Llama 4 Scout provides excellent vision capabilities
- **Features**: Supports advanced features like tool use and JSON mode
- **Reliability**: High uptime and consistent performance

## Development

Built with:

- SwiftUI for modern macOS UI
- `@Observable` for state management
- MenuBarExtra for menu bar integration
- Security framework for Keychain integration
- Multiple AI vision APIs (Groq, OpenAI, Claude)

## API Limits

### Groq
- **Image Size**: 20MB max per request
- **Resolution**: 33 megapixels max per image
- **Base64**: 4MB max for base64 encoded images
- **Rate Limits**: Generous free tier

### OpenAI
- **Image Size**: 20MB max
- **Rate Limits**: Based on your plan

### Claude
- **Image Size**: 5MB max
- **Rate Limits**: Based on your plan

## Contributing

Feel free to submit issues and pull requests!

## License

MIT License - see LICENSE file for details.

