# Code Signing and Notarization Setup for GitHub Actions

This guide explains how to set up code signing and notarization for Glimpsify in GitHub Actions to eliminate the "damaged app" error on macOS.

## Prerequisites

1. **Apple Developer Account** - You need a paid Apple Developer account ($99/year)
2. **Developer ID Certificate** - For distributing outside the Mac App Store
3. **App-Specific Password** - For notarization

## Step 1: Create Developer ID Certificate

1. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/certificates/list)
2. Click "+" to create a new certificate
3. Select "Developer ID Application" under "Software"
4. Follow the instructions to create a Certificate Signing Request (CSR)
5. Download the certificate (.cer file)
6. Double-click to install it in Keychain Access

## Step 2: Export Certificate for GitHub Actions

1. Open Keychain Access
2. Find your "Developer ID Application" certificate
3. Right-click and select "Export"
4. Choose .p12 format and set a password
5. Convert to base64:
   ```bash
   base64 -i YourCertificate.p12 | pbcopy
   ```

## Step 3: Create App-Specific Password

1. Go to [Apple ID Account](https://appleid.apple.com/account/manage)
2. Sign in with your Apple Developer account
3. Go to "App-Specific Passwords"
4. Generate a new password for "Glimpsify Notarization"
5. Save this password securely

## Step 4: Get Your Team ID

1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Your Team ID is displayed in the top right corner
3. It's a 10-character alphanumeric string

## Step 5: Set Up GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions

Add these repository secrets:

### Required Secrets:

1. **BUILD_CERTIFICATE_BASE64**
   - The base64-encoded .p12 certificate from Step 2

2. **P12_PASSWORD**
   - The password you set when exporting the .p12 certificate

3. **TEAM_ID**
   - Your Apple Developer Team ID from Step 4

4. **NOTARIZATION_APPLE_ID**
   - Your Apple ID email address (same as Developer account)

5. **NOTARIZATION_PASSWORD**
   - The app-specific password from Step 3

### Optional Secrets (for App Store Connect API):

6. **APPSTORE_ISSUER_ID**
   - From App Store Connect → Users and Access → Integrations → App Store Connect API

7. **APPSTORE_KEY_ID**
   - The Key ID from your App Store Connect API key

8. **APPSTORE_PRIVATE_KEY**
   - The private key content from your .p8 file

## Step 6: Update Bundle Identifier

Make sure your app's bundle identifier matches what's in the workflow:
- Current: `com.rudrankriyam.Glimpsify`
- Update in Xcode project settings if different

## Step 7: Test the Workflow

1. Push a commit to trigger the workflow
2. Check GitHub Actions for any errors
3. For releases, create a tag:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

## Troubleshooting

### Common Issues:

1. **Certificate not found**
   - Ensure the base64 certificate is correct
   - Check that the certificate is "Developer ID Application"

2. **Notarization fails**
   - Verify Apple ID and app-specific password
   - Ensure 2FA is enabled on Apple ID

3. **Team ID mismatch**
   - Double-check the Team ID in Apple Developer Portal

4. **Bundle ID issues**
   - Ensure bundle ID matches between Xcode and workflow

### Testing Locally:

You can test code signing locally:

```bash
# Build with signing
xcodebuild build \
  -project Glimpsify.xcodeproj \
  -scheme Glimpsify \
  -configuration Release \
  CODE_SIGN_IDENTITY="Developer ID Application"

# Check signature
codesign -dv --verbose=4 ./build/Release/Glimpsify.app

# Test notarization
ditto -c -k --keepParent ./build/Release/Glimpsify.app Glimpsify.zip
xcrun notarytool submit Glimpsify.zip \
  --apple-id "your@email.com" \
  --password "app-specific-password" \
  --team-id "TEAM_ID" \
  --wait
```

## Benefits

Once set up, every release will be:
- ✅ Code-signed with your Developer ID
- ✅ Notarized by Apple
- ✅ Trusted by macOS Gatekeeper
- ✅ No more "damaged app" warnings

Users can download and run your app immediately without security warnings. 