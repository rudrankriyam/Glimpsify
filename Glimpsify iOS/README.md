# Glimpsify iOS

A beautiful, Apple-designed iOS app for generating accessible alt text for images using AI.

## 🌟 Features

### Core Functionality
- **Camera Integration**: Take photos directly in the app with professional camera controls
- **Photo Library Access**: Browse and select images from your photo library with elegant grid layout
- **Clipboard Monitoring**: Automatically detect images copied to clipboard
- **AI-Powered Alt Text**: Generate descriptive, accessible alt text using Groq's LLaMA models

### Design Excellence
Built with Apple's design principles in mind:
- **Hierarchy**: Clear information architecture with proper typography scales
- **Contrast**: Beautiful color schemes that work in light and dark modes
- **Balance**: Perfectly spaced layouts with harmonious proportions
- **Movement**: Smooth animations and transitions that feel natural

### User Experience
- **Tab-Based Navigation**: Intuitive four-tab interface (Camera, Photos, Clipboard, Settings)
- **Real-Time Feedback**: Live status indicators and progress animations
- **Haptic Feedback**: Tactile responses for important actions
- **Accessibility**: Full VoiceOver support and dynamic type compatibility
- **Privacy-First**: All processing happens locally, only API calls to Groq for generation

## 📱 Screenshots

### Camera View
- Professional camera interface with viewfinder
- Flash controls and capture button
- Instant alt text generation after capture

### Photos View
- Beautiful grid layout with smooth scrolling
- Search functionality for finding specific images
- Pull-to-refresh and infinite loading

### Clipboard View
- Real-time clipboard monitoring
- Elegant empty states and loading animations
- Copy and share generated alt text

### Settings View
- Clean, iOS-native settings interface
- API key management with validation
- Privacy controls and permissions

## 🛠 Technical Architecture

### SwiftUI + Observation Framework
- Modern SwiftUI architecture with `@Observable` classes
- Reactive UI updates with automatic state management
- Environment-based dependency injection

### Managers
- **CameraManager**: AVFoundation integration for camera functionality
- **PhotoLibraryManager**: Photos framework integration with permission handling
- **ClipboardManager**: UIPasteboard monitoring with change detection
- **AltTextGenerator**: Groq API integration with error handling

### Security
- **Keychain Integration**: Secure API key storage using iOS Keychain
- **Permission Handling**: Proper camera and photo library permission requests
- **Privacy Descriptions**: Clear usage descriptions for all permissions

## 🚀 Setup Instructions

### Prerequisites
1. Xcode 15.0 or later
2. iOS 17.0 or later target
3. Groq API key (free at console.groq.com)

### Installation
1. Open `Glimpsify.xcodeproj` in Xcode
2. Select the "Glimpsify iOS" scheme
3. Choose your target device or simulator
4. Build and run (⌘+R)

### Configuration
1. Launch the app
2. Go to Settings tab
3. Enter your Groq API key
4. Grant camera and photo library permissions when prompted

## 🎨 Design System

### Colors
- **Primary Blue**: Apple's signature blue (#007AFF)
- **Accent Colors**: Dynamic colors that adapt to light/dark mode
- **System Colors**: Native iOS colors for consistency

### Typography
- **Large Title**: App headers and main navigation
- **Title**: Section headers and important content
- **Headline**: Primary content and buttons
- **Body**: Regular text content
- **Caption**: Secondary information and metadata

### Layout
- **Safe Areas**: Proper handling of notches and home indicators
- **Margins**: Consistent 16-24pt margins throughout
- **Spacing**: 8pt grid system for perfect alignment
- **Corner Radius**: 8-16pt rounded corners for modern feel

## 🔧 Build Configuration

### Target Settings
- **Bundle Identifier**: `com.rudrankriyam.glimpsify.ios`
- **Deployment Target**: iOS 17.0
- **Supported Devices**: iPhone and iPad
- **Orientations**: Portrait, Landscape Left, Landscape Right

### Permissions Required
- **Camera**: For taking photos to generate alt text
- **Photo Library**: For selecting existing images
- **Network**: For API calls to Groq

### Info.plist Keys
```xml
<key>NSCameraUsageDescription</key>
<string>Glimpsify needs camera access to take photos and generate alt text descriptions for accessibility.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Glimpsify needs photo library access to select images and generate alt text descriptions for accessibility.</string>
```

## 🧪 Testing

### Unit Tests
- API integration tests
- Image processing tests
- Keychain security tests

### UI Tests
- Navigation flow tests
- Permission handling tests
- Camera and photo picker integration tests

### Manual Testing Checklist
- [ ] Camera capture and alt text generation
- [ ] Photo library selection and processing
- [ ] Clipboard monitoring and detection
- [ ] Settings configuration and validation
- [ ] Dark mode compatibility
- [ ] VoiceOver accessibility
- [ ] Different device sizes and orientations

## 🚀 Deployment

### App Store Preparation
1. Update version numbers in Info.plist
2. Generate app icons for all required sizes
3. Create App Store screenshots
4. Write App Store description focusing on accessibility
5. Submit for review

### TestFlight Distribution
1. Archive the app (Product → Archive)
2. Upload to App Store Connect
3. Add beta testers
4. Distribute for testing

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Follow Apple's Human Interface Guidelines
4. Ensure accessibility compliance
5. Test on multiple devices
6. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- **Groq**: For providing fast, efficient AI models
- **Apple**: For the incredible development tools and design guidelines
- **Accessibility Community**: For inspiring this project's mission

---

Built with ❤️ for accessibility and beautiful design. 