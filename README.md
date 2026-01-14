# No Nonsense Meditation

<p align="center">
  <img src="https://img.shields.io/badge/iOS-17.0+-blue.svg" alt="iOS 17.0+">
  <img src="https://img.shields.io/badge/Swift-5.0-orange.svg" alt="Swift 5.0">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="MIT License">
</p>

A beautifully simple meditation and focus timer for iOS. No accounts, no ads, no distractions—just the stuff you need to stay mindful.

## ✨ Features

### Core Meditation
- ⏱️ **Simple Timer**: Choose from preset durations (1-120 minutes)
- 🎵 **Background Sounds**: A few bundled in, and the option to pick from your own library.
- 🔔 **Customizable Bells**: Different sounds for start and end of sessions
- 📱 **Lock Screen Controls**: Pause, resume, and monitor progress without unlocking

### Progress Tracking
- 🔥 **Streak Tracking**: Build and maintain your daily meditation habit
- 📊 **Statistics Dashboard**: View total sessions, time meditated, and current streak
- 📈 **Session History**: Track your meditation journey over time

### Integrations
- 💚 **Apple Health**: Automatically log mindful minutes (optional)
- ☁️ **iCloud Sync**: Keep your data synchronized across all your devices (optional)
- 🗣️ **Siri & Shortcuts**: Start sessions with voice commands
- 🔔 **Daily Reminders**: Get notified at your preferred time

### Privacy First
- 🔒 **No data collection**: All data stays on your device
- 🚫 **No analytics or tracking**: Your practice is private
- 📂 **Export/Import**: Full control over your meditation data
- 🌐 **Open Source**: Verify our privacy claims yourself

## 📱 Requirements

- iOS 17.0 or later
- iPhone or iPad
- Optional: Apple Health for mindful minutes tracking
- Optional: iCloud account for cross-device sync

## 🛠️ Building from Source

### Prerequisites
- Xcode 15.0 or later
- Swift 5.9 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (optional, for project generation)

### Setup

1. Clone the repository:
```bash
git clone https://github.com/jeandavidt/no-nonsense-meditation.git
cd no-nonsense-meditation/ios
```

2. (Optional) Generate the Xcode project using XcodeGen:
```bash
xcodegen generate
```

3. Open the project in Xcode:
```bash
open NoNonsenseMeditation.xcodeproj
```

4. Update the Development Team:
   - Select the project in the navigator
   - Under "Signing & Capabilities", change the Team to your Apple Developer account
   - Update the bundle identifier if needed

5. Build and run (⌘R)

### Project Structure

```
ios/
├── NoNonsenseMeditation/
│   ├── Core/                    # Core services and business logic
│   │   ├── Services/           # Timer, Audio, Notification services
│   │   ├── Persistence/        # CoreData + CloudKit sync
│   │   └── Models/             # Data models
│   ├── Features/               # Feature modules
│   │   ├── Timer/              # Meditation timer UI
│   │   ├── Settings/           # Settings and preferences
│   │   └── Statistics/         # Stats dashboard
│   ├── Intents/                # Siri & Shortcuts support
│   ├── Resources/              # Assets, sounds, colors
│   └── Utilities/              # Helpers and extensions
├── NoNonsenseMeditationTests/  # Unit tests
└── NoNonsenseMeditationUITests/# UI tests
```

## 🧪 Testing

Run tests using Xcode Test Navigator (⌘U) or via command line:

```bash
xcodebuild test -scheme NoNonsenseMeditation -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

## 🔐 Privacy

No Nonsense Meditation takes your privacy seriously. Read our full [Privacy Policy](PRIVACY.md).

**TL;DR:**
- Zero data collection
- No analytics or tracking
- No third-party services
- All data stays on your device
- Optional iCloud sync uses your personal iCloud
- Optional HealthKit integration writes directly to Apple Health

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Guidelines
- Follow existing code style and architecture
- Add tests for new features
- Update documentation as needed
- Keep commits atomic and well-described

## 🐛 Bug Reports & Feature Requests

Found a bug or have a feature request? Please [open an issue](https://github.com/jeandavidt/no-nonsense-meditation/issues).

## 🙏 Acknowledgments

- Built with SwiftUI and modern Swift concurrency
- Uses CoreData with CloudKit for seamless sync
- Integrates with HealthKit for wellness tracking
- Supports Siri and Shortcuts for voice control

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/jeandavidt/no-nonsense-meditation/issues)
- **Email**: jeandavidt@gmail.com

## 🌟 Philosophy

No Nonsense Meditation embodies simplicity:
- **No accounts**: Just download and meditate
- **No subscriptions**: Free forever
- **No ads**: Your practice, uninterrupted
- **No tracking**: Your meditation is private
- **No complexity**: Focus on what matters

---

**Made with mindfulness** 🧘
