# StoryTots 📚🎙️

**StoryTots** is an interactive reading app for kids that combines karaoke-style reading with speech recognition and educational games. Built with Flutter, it features multiple speech-to-text engines and engaging learning activities.

![Flutter](https://img.shields.io/badge/Flutter-3.8.0+-02569B?style=flat&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.8.0+-0175C2?style=flat&logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-brightgreen)

## ✨ Features

### 📖 Reading Experience

- **Karaoke-Style Reading**: Word-by-word highlighting as you read
- **Multiple Speech Recognition**:
  - Device STT (built-in speech recognition)
  - Azure Speech-to-Text (cloud-based, high accuracy)
- **Multi-Language Support**: English and Filipino
- **Text-to-Speech**: Pronunciation help for difficult words

### 🎮 Educational Games

- **Word Match Game**: Drag words to matching pictures
- **Story Sequence Game**: Arrange story events in correct order
- Interactive learning with immediate feedback

### 👤 User Features

- **Authentication**: Secure email/OTP login system
- **Personal Library**: Save and manage favorite stories
- **Progress Tracking**: Resume reading where you left off
- **User Profiles**: Personalized reading experience

## 🚀 Quick Start

### Prerequisites

- **Flutter SDK**: `>=3.8.0 <4.0.0`
- **Android Studio** or **VS Code** with Flutter extension
- **Git** for version control

### Installation

1. **Clone the repository**

```bash
git clone https://github.com/YOUR_USERNAME/storytots.git
cd storytots
```

2. **Install dependencies**

```bash
flutter pub get
```

3. **Verify Flutter installation**

```bash
flutter doctor
```

4. **Run the app**

```bash
# On connected device/emulator
flutter run

# On web browser
flutter run -d chrome
```

## 🔧 Build & Deploy

### Android APK

```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release
```

### iOS Build

```bash
flutter build ios --release
```

## 📱 System Requirements

### Development Environment

- **Flutter**: 3.8.0+
- **Dart**: 3.8.0+ (included with Flutter)
- **Android**: API Level 21+ (Android 5.0+)
- **iOS**: iOS 11.0+
- **Web**: Modern browsers (Chrome, Safari, Edge)

### Permissions Required

- **Microphone**: For speech recognition
- **Internet**: For cloud services and authentication

## 🏗️ Architecture

```
lib/
├── features/
│   ├── auth/              # Authentication & user management
│   ├── games/             # Educational games
│   ├── reader/            # Reading & speech recognition
│   │   ├── speech/        # Speech engines
│   │   └── karaoke_text.dart
│   ├── library/           # User's story library
│   └── shell/             # App navigation & tabs
├── core/                  # Constants & utilities
├── data/                  # Repositories & data models
└── main.dart              # App entry point
```

## 🎯 Speech Recognition Engines

### 1. Device STT (Default)

- Built-in mobile speech recognition
- Works offline
- No API costs
- Platform-dependent accuracy

### 2. Azure Speech-to-Text

- Cloud-based recognition
- High accuracy and reliability
- Real-time processing
- Requires internet connection
- **Setup**: Add your Azure subscription key in `azure_speech_engine.dart`

## 🎮 Games Overview

### Word Match Game

- **Objective**: Match spoken/written words with corresponding images
- **Skills**: Vocabulary building, word recognition
- **Mechanics**: Drag-and-drop interface

### Story Sequence Game

- **Objective**: Arrange story events in chronological order
- **Skills**: Reading comprehension, logical thinking
- **Mechanics**: Reorderable list interface

## 🔐 Backend Services

### Supabase Integration

- **Authentication**: Email/OTP verification
- **Database**: User profiles and reading progress
- **Storage**: Story content and user data
- **Real-time**: Sync across devices

## 🛠️ Development Guide

### Running Tests

```bash
flutter test
```

### Code Analysis

```bash
flutter analyze
```

### Formatting

```bash
dart format .
```

### Adding New Speech Engines

1. Implement `SpeechEngine` interface in `lib/features/reader/speech/`
2. Add new service type to `SpeechServiceType` enum
3. Update `SpeechServiceFactory.create()` method
4. Add UI support in reading pages

## 📚 Educational Value

This project demonstrates:

- **Mobile Development**: Cross-platform Flutter development
- **Speech Processing**: Multiple speech recognition implementations
- **Game Development**: Interactive educational games
- **Backend Integration**: Authentication and data persistence
- **UI/UX Design**: Kid-friendly interface design
- **State Management**: Flutter state management patterns

## 🔧 Configuration

### Azure Speech Service (Optional)

1. Create Azure Speech service resource
2. Get subscription key and region
3. Update configuration:

```dart
// lib/features/reader/speech/azure_speech_engine.dart
static const String _subscriptionKey = 'YOUR_AZURE_KEY';
static const String _region = 'YOUR_REGION';
```

### Supabase Setup (Optional for Custom Backend)

1. Create Supabase project
2. Update configuration in `lib/core/constants.dart`
3. Set up authentication and database schemas

## 🐛 Troubleshooting

### Common Issues

**"Microphone permission denied"**

- Grant microphone permission when prompted
- Check device settings if needed

**"Speech recognition not working"**

- Ensure microphone permission is granted
- Test with different speech engines
- Check internet connection for cloud services

**"Build failures"**

```bash
flutter clean
flutter pub get
```

**"Android build issues"**

```bash
cd android && ./gradlew clean
cd .. && flutter clean && flutter pub get
```

## 📄 License

This project is created for educational purposes. Please check individual package licenses for dependencies.

## 🤝 Contributing

This is an educational project. Students are encouraged to:

1. Fork the repository
2. Create feature branches
3. Submit pull requests with improvements
4. Report issues and bugs

## 📞 Support

For technical support or questions:

1. Check the troubleshooting section
2. Review Flutter documentation
3. Check individual package documentation
4. Create an issue in the repository

## 🎉 Acknowledgments

- **Flutter Team** for the amazing framework
- **Supabase** for backend services
- **Speech Recognition** package maintainers
- All contributing developers and educators

---

**Happy Learning! 🚀📚**
# storytots
