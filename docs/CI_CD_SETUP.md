# CI/CD Pipeline Setup Guide

## Overview

This guide explains how to set up and configure the CI/CD pipelines for the ChunkUp Flutter application.

## CI Pipeline (Continuous Integration)

The CI pipeline runs on every push and pull request to ensure code quality.

### Features
- Code analysis and linting
- Format checking
- Unit tests with coverage
- Build verification for Web, Android, and iOS

### Configuration Steps

1. **Enable GitHub Actions**
   - Go to your repository settings
   - Navigate to Actions > General
   - Enable "Allow all actions and reusable workflows"

2. **No additional secrets required for CI**
   - The CI pipeline uses only public actions and doesn't require secrets

## CD Pipeline (Continuous Deployment)

The CD pipeline automatically deploys your app when you create a new version tag.

### Prerequisites

1. **Firebase Project Setup**
   - Create a Firebase project at https://console.firebase.google.com
   - Enable Firebase Hosting
   - Install Firebase CLI locally: `npm install -g firebase-tools`

2. **Google Play Console Setup**
   - Create a developer account
   - Create your app listing
   - Set up a service account for API access

3. **Apple Developer Account**
   - Enroll in the Apple Developer Program
   - Create App ID and provisioning profiles
   - Generate certificates for distribution

### Required GitHub Secrets

Add these secrets in your repository settings (Settings > Secrets and variables > Actions):

#### Firebase Deployment
- `FIREBASE_SERVICE_ACCOUNT`: Service account JSON for Firebase
  ```bash
  # Generate with:
  firebase init hosting
  firebase login:ci
  ```

#### Android Deployment
- `ANDROID_KEYSTORE_BASE64`: Base64 encoded keystore file
  ```bash
  # Encode your keystore:
  base64 -i upload-keystore.jks -o keystore_base64.txt
  ```
- `KEY_PROPERTIES`: Contents of key.properties file
  ```properties
  storePassword=<your-store-password>
  keyPassword=<your-key-password>
  keyAlias=<your-key-alias>
  storeFile=upload-keystore.jks
  ```
- `PLAY_STORE_SERVICE_ACCOUNT_JSON`: Service account JSON for Play Store API

#### iOS Deployment
- `BUILD_CERTIFICATE_BASE64`: Base64 encoded p12 certificate
- `P12_PASSWORD`: Password for the p12 certificate
- `BUILD_PROVISION_PROFILE_BASE64`: Base64 encoded provisioning profile
- `KEYCHAIN_PASSWORD`: Temporary keychain password (any secure password)
- `APP_STORE_CONNECT_API_KEY_ID`: App Store Connect API key ID
- `APP_STORE_CONNECT_ISSUER_ID`: App Store Connect issuer ID
- `APP_STORE_CONNECT_API_KEY`: App Store Connect API private key

## Usage

### Running CI
CI runs automatically on:
- Every push to `main` or `develop` branches
- Every pull request targeting `main` or `develop`

### Triggering Deployment
1. Create and push a version tag:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. The CD pipeline will automatically:
   - Build all platforms
   - Deploy web to Firebase Hosting
   - Upload Android app to Play Store
   - Upload iOS app to App Store Connect
   - Create a GitHub release

### Manual Deployment
You can also trigger deployment manually:
1. Go to Actions tab in your repository
2. Select "CD" workflow
3. Click "Run workflow"

## Customization

### Changing Flutter Version
Update the Flutter version in both workflows:
```yaml
flutter-version: '3.24.0'
```

### Adding Environment Variables
Add environment-specific variables in the workflow:
```yaml
env:
  API_URL: ${{ secrets.PRODUCTION_API_URL }}
  SENTRY_DSN: ${{ secrets.SENTRY_DSN }}
```

### Platform-Specific Builds
Remove platforms you don't need by commenting out or removing the respective jobs.

## Troubleshooting

### Common Issues

1. **iOS Build Fails**
   - Ensure certificates and provisioning profiles are valid
   - Check that the bundle ID matches your App Store Connect app

2. **Android Build Fails**
   - Verify keystore password and alias
   - Ensure package name matches Play Console

3. **Firebase Deploy Fails**
   - Check Firebase project permissions
   - Verify service account has necessary roles

### Debugging
- Check workflow runs in the Actions tab
- Download artifacts for local inspection
- Review logs for specific error messages

## Best Practices

1. **Version Tagging**
   - Use semantic versioning (v1.0.0, v1.0.1, etc.)
   - Create detailed release notes

2. **Branch Protection**
   - Require CI to pass before merging
   - Use pull request reviews

3. **Secrets Management**
   - Rotate secrets regularly
   - Use environment-specific secrets
   - Never commit secrets to the repository

4. **Testing**
   - Maintain high test coverage
   - Add integration tests for critical paths
   - Test deployment process in staging first