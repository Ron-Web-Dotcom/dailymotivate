# iOS Release Signing Configuration

## 🍎 Apple Developer Setup for Production Builds

### Prerequisites

- [ ] Apple Developer Account ($99/year) - [Sign up here](https://developer.apple.com/programs/)
- [ ] Xcode installed (latest version recommended)
- [ ] Mac computer (required for iOS builds)
- [ ] DailyMotivate app ready for submission

---

## Step 1: Apple Developer Account Setup

### 1.1 Purchase Apple Developer Membership

1. Go to [Apple Developer Program](https://developer.apple.com/programs/)
2. Click "Enroll"
3. Sign in with your Apple ID
4. Complete enrollment form
5. Pay $99 annual fee
6. Wait 24-48 hours for approval

### 1.2 Accept Developer Agreement

1. Log in to [App Store Connect](https://appstoreconnect.apple.com/)
2. Accept the latest Apple Developer Program License Agreement
3. Complete tax and banking information (for paid apps)

---

## Step 2: Create App ID

### 2.1 Register App ID in Developer Portal

1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **Identifiers** > **+** button
4. Select **App IDs** > **Continue**
5. Select **App** > **Continue**
6. Fill in details:
   - **Description**: DailyMotivate
   - **Bundle ID**: `com.dailymotivate.app` (Explicit)
   - **Capabilities**: Check these:
     - [x] Push Notifications (if using remote notifications)
     - [x] Associated Domains (if using deep links)
7. Click **Continue** > **Register**

---

## Step 3: Create Certificates

### 3.1 Generate Certificate Signing Request (CSR)

1. Open **Keychain Access** on Mac
2. Menu: **Keychain Access** > **Certificate Assistant** > **Request a Certificate from a Certificate Authority**
3. Fill in:
   - **User Email Address**: your@email.com
   - **Common Name**: DailyMotivate Distribution
   - **CA Email Address**: Leave empty
   - **Request is**: Saved to disk
4. Click **Continue** > Save `CertificateSigningRequest.certSigningRequest`

### 3.2 Create Distribution Certificate

1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to **Certificates, Identifiers & Profiles** > **Certificates**
3. Click **+** button
4. Select **Apple Distribution** > **Continue**
5. Upload the CSR file created in Step 3.1
6. Click **Continue** > **Download** certificate
7. Double-click downloaded certificate to install in Keychain Access

---

## Step 4: Create Provisioning Profile

### 4.1 Create App Store Provisioning Profile

1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to **Certificates, Identifiers & Profiles** > **Profiles**
3. Click **+** button
4. Select **App Store** > **Continue**
5. Select App ID: `com.dailymotivate.app` > **Continue**
6. Select Distribution Certificate created in Step 3.2 > **Continue**
7. Profile Name: `DailyMotivate App Store`
8. Click **Generate** > **Download**
9. Double-click to install in Xcode

---

## Step 5: Configure Xcode Project

### 5.1 Open Project in Xcode

```bash
open ios/Runner.xcworkspace
```

### 5.2 Configure Signing & Capabilities

1. Select **Runner** project in left sidebar
2. Select **Runner** target
3. Go to **Signing & Capabilities** tab
4. **Uncheck** "Automatically manage signing"
5. Configure for each build configuration:

   **Debug**:
   - Provisioning Profile: Xcode Managed Profile
   - Signing Certificate: Apple Development

   **Release**:
   - Provisioning Profile: DailyMotivate App Store (created in Step 4.1)
   - Signing Certificate: Apple Distribution

6. Verify Bundle Identifier: `com.dailymotivate.app`

### 5.3 Verify Capabilities

Ensure these capabilities are enabled if needed:
- [ ] Push Notifications (if using remote notifications)
- [ ] Associated Domains (if using deep links)
- [ ] Background Modes > Remote notifications (if using push)

---

## Step 6: Create App in App Store Connect

### 6.1 Create New App

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Click **My Apps** > **+** > **New App**
3. Fill in details:
   - **Platforms**: iOS
   - **Name**: DailyMotivate
   - **Primary Language**: English (U.S.)
   - **Bundle ID**: com.dailymotivate.app
   - **SKU**: dailymotivate-ios (unique identifier)
   - **User Access**: Full Access
4. Click **Create**

### 6.2 Fill App Information

1. Go to **App Information** section:
   - **Subtitle**: Daily Inspirational Quotes (30 chars max)
   - **Category**: Primary: Lifestyle, Secondary: Health & Fitness
   - **Content Rights**: Check if app contains third-party content

2. Go to **Pricing and Availability**:
   - **Price**: Free
   - **Availability**: All countries or select specific

---

## Step 7: Prepare App Metadata

### 7.1 App Store Listing

1. Go to **App Store** tab > **iOS App** > **1.0 Prepare for Submission**

2. **App Information**:
   - **Name**: DailyMotivate (30 chars max)
   - **Subtitle**: Daily Inspirational Quotes (30 chars max)
   - **Privacy Policy URL**: https://ron-web-dotcom.github.io/legal-page/privacy.html

3. **Description** (4000 chars max):
   ```
   Get inspired daily with AI-powered motivational quotes from real historical figures and leaders.

   DailyMotivate delivers personalized motivational quotes to inspire your day. Powered by AI, our app curates authentic quotes from real historical figures, entrepreneurs, athletes, and thought leaders.

   FEATURES:
   • AI-powered quote generation with OpenAI & Gemini
   • Daily notifications at your preferred time
   • Save favorite quotes with cloud sync
   • Browse quotes by category (Success, Courage, Wisdom, etc.)
   • Share quotes to social media (WhatsApp, Instagram, Twitter, TikTok)
   • Dark mode support
   • Offline access to saved quotes
   • No ads, no tracking

   PERFECT FOR:
   - Morning motivation routines
   - Mindfulness practices
   - Personal development
   - Social media content creators
   - Anyone seeking daily inspiration

   CATEGORIES:
   Success, Courage, Wisdom, Leadership, Perseverance, Creativity, Gratitude, Mindfulness, Resilience, Innovation, Passion, Focus, Growth, Confidence, Kindness

   Start your day with inspiration. Download DailyMotivate now!
   ```

4. **Keywords** (100 chars max, comma-separated):
   ```
   motivation,quotes,inspiration,daily,mindfulness,wellness,self-improvement,success,wisdom,leadership
   ```

5. **Promotional Text** (170 chars max):
   ```
   Start every day inspired! Get AI-powered motivational quotes from historical figures. Save favorites, set daily reminders, and share inspiration with friends.
   ```

6. **Support URL**: Your support website or email
7. **Marketing URL**: Your app website (optional)

### 7.2 Screenshots (REQUIRED)

You need screenshots for these sizes:
- **6.7" (iPhone 15 Pro Max)**: 1290 x 2796 pixels (required)
- **6.5" (iPhone 11 Pro Max)**: 1242 x 2688 pixels (required)
- **5.5" (iPhone 8 Plus)**: 1242 x 2208 pixels (required)

**How to capture**:
1. Run app on simulator: `flutter run --dart-define-from-file=env.json`
2. Open iOS Simulator
3. Device > iPhone 15 Pro Max
4. Navigate to key screens (Home, Categories, Favorites, Settings)
5. Cmd+S to save screenshot
6. Repeat for other device sizes

**Screens to capture**:
1. Home screen with quote
2. Categories screen
3. Favorites screen
4. Settings screen
5. Quote sharing options

### 7.3 App Icon

- Upload 1024x1024 icon (already created: `assets/images/dailymotivate_app_icon_ios_store.png`)
- Must be PNG, no transparency, no rounded corners

### 7.4 Age Rating

1. Click **Edit** next to Age Rating
2. Answer questionnaire (all "No" for DailyMotivate)
3. Expected rating: **4+** (no objectionable content)

---

## Step 8: Build and Upload to App Store Connect

### 8.1 Build Release Archive

```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build iOS release
flutter build ios --release --dart-define-from-file=env.json
```

### 8.2 Create Archive in Xcode

1. Open Xcode: `open ios/Runner.xcworkspace`
2. Select **Any iOS Device** (not simulator) in device dropdown
3. Menu: **Product** > **Archive**
4. Wait for archive to complete (5-10 minutes)
5. Xcode Organizer window will open automatically

### 8.3 Upload to App Store Connect

1. In Xcode Organizer, select the archive
2. Click **Distribute App**
3. Select **App Store Connect** > **Next**
4. Select **Upload** > **Next**
5. Select distribution options:
   - [x] Include bitcode: No (Flutter doesn't support)
   - [x] Upload symbols: Yes (for crash reports)
   - [ ] Manage Version and Build Number: No
6. Select signing certificate: **Automatically manage signing**
7. Click **Upload**
8. Wait for upload to complete (5-15 minutes)

### 8.4 Verify Upload

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Select **DailyMotivate** app
3. Go to **TestFlight** tab
4. Wait for build to appear (10-30 minutes)
5. Status should change from "Processing" to "Ready to Submit"

---

## Step 9: Submit for Review

### 9.1 Select Build

1. Go to **App Store** tab > **1.0 Prepare for Submission**
2. Scroll to **Build** section
3. Click **+** and select the uploaded build

### 9.2 Export Compliance

1. Answer: **Does your app use encryption?**
   - Select **No** (or **Yes** if using HTTPS only, then select "Standard encryption")

### 9.3 Advertising Identifier (IDFA)

1. Answer: **Does this app use the Advertising Identifier (IDFA)?**
   - Select **No** (DailyMotivate doesn't use ads or tracking)

### 9.4 App Review Information

1. **Contact Information**:
   - First Name, Last Name, Phone, Email

2. **Notes** (optional but recommended):
   ```
   DailyMotivate is a motivational quotes app powered by AI (OpenAI and Google Gemini APIs).
   
   Key features:
   - AI generates quotes inspired by historical figures
   - Users can save favorites and sync across devices
   - Daily notifications for motivation
   - No user tracking or advertising
   
   The app requires internet connection for AI quote generation but works offline for saved quotes.
   
   All quotes are AI-generated and marked as such. We do not claim historical accuracy.
   ```

3. **Demo Account**: Not required (no login needed)

### 9.5 Version Release

1. Select: **Manually release this version**
   - Allows you to control release timing after approval

### 9.6 Submit

1. Click **Add for Review** (top right)
2. Review all information
3. Click **Submit to App Review**
4. Wait for review (typically 1-3 days)

---

## Step 10: Post-Submission

### 10.1 Monitor Review Status

1. Check App Store Connect daily
2. Possible statuses:
   - **Waiting for Review**: In queue
   - **In Review**: Being reviewed (1-2 days)
   - **Pending Developer Release**: Approved! Ready to release
   - **Ready for Sale**: Live on App Store
   - **Rejected**: See rejection reasons and resubmit

### 10.2 If Rejected

1. Read rejection reason carefully
2. Fix issues in app
3. Increment build number in `pubspec.yaml`:
   ```yaml
   version: 1.0.0+2  # Increment +1 to +2
   ```
4. Rebuild and upload new build
5. Reply to reviewer in Resolution Center
6. Resubmit for review

### 10.3 Release to App Store

1. Once approved, status changes to **Pending Developer Release**
2. Click **Release This Version**
3. App goes live within 24 hours
4. Monitor reviews and crash reports

---

## 🚨 Common Rejection Reasons & Solutions

### 1. Missing Privacy Policy
- **Solution**: Ensure privacy policy URL is accessible and covers all data collection

### 2. Incomplete App Information
- **Solution**: Fill all required fields in App Store Connect

### 3. App Crashes on Launch
- **Solution**: Test on physical device before submission

### 4. Misleading Content
- **Solution**: Add disclaimer that quotes are AI-generated

### 5. Minimum Functionality
- **Solution**: DailyMotivate has sufficient features (passes this requirement)

### 6. Intellectual Property Issues
- **Solution**: Ensure quotes are properly attributed and AI-generated disclaimer is clear

---

## 📋 Pre-Submission Checklist

### Apple Developer Account
- [ ] Developer account active ($99/year paid)
- [ ] Developer agreement accepted
- [ ] Tax and banking info completed (if paid app)

### Certificates & Profiles
- [ ] App ID registered: `com.dailymotivate.app`
- [ ] Distribution certificate created and installed
- [ ] App Store provisioning profile created and installed
- [ ] Xcode signing configured (Release build)

### App Store Connect
- [ ] App created in App Store Connect
- [ ] App name: DailyMotivate
- [ ] Bundle ID: com.dailymotivate.app
- [ ] Privacy policy URL added
- [ ] App description written
- [ ] Keywords selected
- [ ] Screenshots uploaded (all required sizes)
- [ ] App icon uploaded (1024x1024)
- [ ] Age rating completed
- [ ] Pricing set (Free)
- [ ] Availability/territories selected

### Build & Upload
- [ ] Release build successful: `flutter build ios --release`
- [ ] Archive created in Xcode
- [ ] Build uploaded to App Store Connect
- [ ] Build processing completed
- [ ] Build selected in app version

### Review Information
- [ ] Export compliance answered
- [ ] IDFA usage answered (No)
- [ ] Contact information provided
- [ ] Review notes added (explaining AI usage)
- [ ] Version release option selected

### Final Checks
- [ ] App tested on physical iOS device
- [ ] All features working (quote generation, favorites, notifications, sharing)
- [ ] Privacy policy accessible
- [ ] No crashes or critical bugs
- [ ] App icon displays correctly
- [ ] Display name correct: "DailyMotivate"

---

## 🔗 Useful Resources

- [Flutter iOS Deployment Guide](https://docs.flutter.dev/deployment/ios)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [TestFlight Documentation](https://developer.apple.com/testflight/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

---

## 📞 Support

**Apple Developer Support**:
- Phone: 1-800-633-2152 (US)
- Email: https://developer.apple.com/contact/

**App Review**:
- Resolution Center in App Store Connect
- Phone: Available during review process

---

**Last Updated**: 2026-02-07
**App**: DailyMotivate v1.0.0+1
**Bundle ID**: com.dailymotivate.app