# 📱 Smart-Patrol Logbook App

**Aplikasi logbook terintegrasi untuk tracking kerusakan dengan Vision Detection + Image Processing**

- 🎥 **Vision Module**: Real-time detection dengan overlay
- 🎨 **PCD Processing**: 10+ image filter operations (Grayscale, Blur, Sharpen, Canny Edge, dll)
- ☁️ **MongoDB Integration**: Cloud sync dengan offline support
- 🔐 **Multi-User Support**: Role-based access (Ketua/Anggota), team collaboration
- 📊 **Smart Analytics**: Categorized logging (Mechanical, Electronic, Software)

---

## 🚀 Quick Start

### Prerequisites

Sebelum installasi, pastikan sudah installed:

- **Flutter SDK**: >= 3.10.8 ([Download](https://flutter.dev/docs/get-started/install))
- **Dart**: Included dalam Flutter SDK
- **Git**: Untuk clone repository
- **Android/iOS Development Tools**:
  - **Android**: Android Studio + Android SDK (API 21+)
  - **iOS**: Xcode + CocoaPods (macOS only)
- **MongoDB Atlas Account**: Free tier untuk cloud database

### System Requirements

| Component      | macOS    | Windows  | Linux    |
| -------------- | -------- | -------- | -------- |
| Flutter        | ✅ 3.24+ | ✅ 3.24+ | ✅ 3.24+ |
| Xcode          | ✅ 15+   | -        | -        |
| Android Studio | ✅       | ✅       | ✅       |
| RAM (min)      | 8GB      | 8GB      | 8GB      |
| Storage        | 20GB     | 20GB     | 20GB     |

---

## 📥 Installation Steps

### Step 1: Clone Repository

```bash
cd ~/Documents
git clone <repository-url>
cd logbook_app_001
```

### Step 2: Install Dependencies

```bash
# Install Flutter packages
flutter pub get

# Clean cache (optional, but recommended)
flutter clean
flutter pub get
```

### Step 3: Setup Environment Variables

1. **Buat file `.env`** di root project:

```bash
touch .env
# Atau manual di VS Code: New File → `.env`
```

2. **Isi dengan konfigurasi MongoDB**:

```env
# ⚠️ JANGAN commit .env ke git!
# Format: mongodb://<username>:<password>@<cluster>.mongodb.net/<database>

MONGODB_URI=mongodb+srv://<USERNAME>:<PASSWORD>@<CLUSTER>.mongodb.net/logbook_db?retryWrites=true&w=majority
```

**Cara mendapatkan URI:**

1. Login ke [MongoDB Atlas](https://account.mongodb.com/account/login)
2. Cluster → Connect → Connect Your Application
3. Copy connection string
4. Replace `<password>` dengan password user
5. Replace `<cluster>` dengan nama cluster Anda

6. **Setup IP Whitelist:**
   - MongoDB Atlas → Network Access
   - Add IP Address → **Allow Access from Anywhere** (0.0.0.0/0)
   - ⚠️ Production: Restrict ke IP specific Anda

### Step 4: Configure Platform-Specific Setup

#### ✅ Android Setup

```bash
# Navigate ke android folder
cd android

# Download gradle
./gradlew --version

# Back to root
cd ..
```

**Pastikan minimum SDK:**

- Edit: `android/app/build.gradle`
- Set `minSdkVersion` ke 21 minimum

#### ✅ iOS Setup (macOS only)

```bash
cd ios

# Install CocoaPods dependencies
pod install
# atau update: pod repo update && pod install

cd ..
```

**Jika error "pod install":**

```bash
# Clear pod cache
sudo gem install cocoapods
pod repo update
cd ios && pod install && cd ..
```

### Step 5: Verify Installation

```bash
# Check Flutter setup
flutter doctor

# Expected output: ✓ Flutter, ✓ Android Studio, ✓ Xcode (iOS), ✓ VS Code
```

**Troubleshoot jika ada ❌:**

- Android: `flutter config --android-studio-path /path/to/android/studio`
- iOS: `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`

---

## 🎯 Running the Application

### Development Mode (Hot Reload)

```bash
# List connected devices
flutter devices

# Run di emulator/device default
flutter run

# Run di emulator spesifik
flutter run -d <device-id>

# Run di iOS (macOS only)
flutter run -d "iPhone 15 Pro"
```

### Build Release

```bash
# Android Release APK
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk

# iOS Release (macOS only)
flutter build ios --release
```

### Web (Development only - tidak untuk production)

```bash
flutter run -d chrome
```

---

## 🔧 Project Structure

```
logbook_app_001/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── features/
│   │   ├── auth/                    # Login/Onboarding
│   │   │   ├── login_view.dart
│   │   │   ├── login_controller.dart
│   │   │   └── ...
│   │   ├── logbook/                 # Main Logbook Feature
│   │   │   ├── log_view.dart        # List view dengan 2 FAB
│   │   │   ├── log_editor_page.dart # Add/Edit entry
│   │   │   ├── log_controller.dart  # Business logic
│   │   │   ├── models/
│   │   │   │   └── log_model.dart   # Data model
│   │   │   └── ...
│   │   ├── vision/                  # Vision Detection + PCD
│   │   │   ├── vision_view.dart     # Unified camera interface
│   │   │   ├── vision_controller.dart
│   │   │   ├── vision_pcd_result_page.dart
│   │   │   ├── damage_painter.dart  # Detection overlay
│   │   │   └── ...
│   │   ├── pcd/                     # Image Processing
│   │   │   └── pcd_processor.dart   # 10 PCD operations
│   │   ├── camera/                  # (DEPRECATED - merged to vision)
│   │   └── ...
│   ├── services/
│   │   └── mongo_service.dart       # MongoDB CRUD operations
│   ├── helpers/
│   │   └── log_helper.dart          # Debug logging
│   └── ...
├── test/                            # Unit & integration tests
├── android/                         # Android native code
├── ios/                             # iOS native code
├── pubspec.yaml                     # Dependencies
├── .env                             # Environment variables (NOT in git)
└── README.md                        # This file
```

---

## 🔐 Configuration & Security

### Environment Setup

**File `.env` (Jangan di-commit!):**

```env
MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/logbook_db
```

**Add ke `.gitignore`:**

```bash
echo ".env" >> .gitignore
```

### MongoDB Collections

Aplikasi akan auto-create collections:

1. **`logs`** - Regular logbook entries

   ```javascript
   {
     _id: ObjectId,
     title: String,
     description: String,
     imageData: String (Base64),
     imageFilter: String,
     category: String,
     teamId: String,
     authorId: String,
     isPublic: Boolean,
     date: ISO8601String,
     syncStatus: "synced" | "pending"
   }
   ```

2. **`camera_pcd`** - Direct camera vision captures

   ```javascript
   {
     _id: ObjectId,
     userId: String,
     teamId: String,
     originalImage: String (Base64),
     processedImage: String (Base64),
     filterName: String,
     timestamp: ISO8601String,
     status: "completed"
   }
   ```

3. **`users`** - User profiles
   ```javascript
   {
     _id: ObjectId,
     uid: String,
     username: String,
     email: String,
     role: "Ketua" | "Anggota",
     teamId: String
   }
   ```

---

## ⚙️ Troubleshooting

### Problem: "MONGODB_URI not found in .env"

**Solution:**

```bash
# Verify .env file exists di root project
ls -la .env

# Check format
cat .env

# Should output:
# MONGODB_URI=mongodb+srv://...
```

### Problem: Connection Timeout saat Sync

**Causes & Solutions:**

1. ✅ Check MongoDB IP Whitelist: `0.0.0.0/0` allowed?
2. ✅ Check internet connection
3. ✅ Verify MONGODB_URI format
4. ✅ Check cluster status di MongoDB Atlas

```bash
# Di app: Refresh button atau Manual Sync
# Developer: Check logs di `logs/` folder
cat logs/app.log
```

### Problem: Android/iOS Build Error

```bash
# Full clean & rebuild
flutter clean
rm -rf ios/Pods ios/Podfile.lock
flutter pub get

# Android specific
flutter build apk --verbose

# iOS specific (macOS only)
cd ios && pod install && cd ..
flutter build ios --verbose
```

### Problem: Hot Reload Tidak Bekerja

```bash
# Kill previous process
flutter clean

# Restart dengan verbose
flutter run -v

# Jika masih error, full restart:
# 1. Ctrl+C (stop process)
# 2. flutter run
```

---

## 🧪 Testing

### Run Tests

```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Specific test file
flutter test test/connection_test.dart

# With verbose output
flutter test -v
```

### Test Coverage

```bash
# Generate coverage report
flutter test --coverage

# View coverage
# Open coverage/lcov.info di browser
```

---

## 📦 Dependencies Overview

| Package              | Version | Purpose                |
| -------------------- | ------- | ---------------------- |
| `flutter`            | 3.24+   | Framework              |
| `camera`             | ^0.12.0 | Camera access          |
| `image`              | ^4.0.0  | Image processing (PCD) |
| `mongo_dart`         | ^0.10.8 | MongoDB driver         |
| `hive`               | ^2.2.3  | Local offline storage  |
| `connectivity_plus`  | ^7.1.1  | Network detection      |
| `permission_handler` | ^12.0.1 | Platform permissions   |
| `flutter_dotenv`     | ^6.0.0  | Environment variables  |
| `shared_preferences` | ^2.5.4  | Key-value storage      |

---

## 🎓 Key Features Usage

### 1. Vision Detection + PCD Processing

```dart
// Open camera dari LogView atau LogEditor
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const VisionView()),
);

// VisionView → capture frame → apply PCD filter → result page → return
```

**Flow:**

1. Tap 📷 camera button (FAB atas di LogView)
2. VisionView opens with live detection overlay
3. Select PCD filter dari chips
4. Tap "Ambil & Proses"
5. See before/after comparison
6. Tap "Gunakan" untuk save

### 2. Offline-First Architecture

```dart
// Data automatically saved locally (Hive)
// Syncs ke MongoDB saat online
// Jika offline saat save, auto-retry saat network returns
```
