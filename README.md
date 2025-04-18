# DriveNotes

DriveNotes is a modern note-taking application built with Flutter that allows users to create, edit, and organize notes with a beautiful interface. The app features Google authentication, dark/light mode themes, and stores notes using local storage with Google Drive sync capabilities.

![DriveNotes App Logo](assets/l.png)

## Table of Contents

- [Features](#features)
- [Getting Started](#getting-started)
    - [Prerequisites](#prerequisites)
    - [Installation](#installation)
- [App Structure](#app-structure)
- [Authentication](#authentication)
- [Usage](#usage)
- [Known Limitations](#known-limitations)
- [Contributing](#contributing)
- [License](#license)

## Features

✨ **Core Features**:
- Create, edit, and delete notes
- Google account authentication
- Elegant UI with light and dark theme support
- Welcome animation for first-time users
- Local notifications
- Notes sync with Google Drive integration

🎨 **UI Features**:
- Beautiful card-based notes display
- Responsive grid layout
- Custom animations and transitions
- Material Design 3 inspired components
- Themed note cards with different colors

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK (latest stable version)
- Android Studio / VS Code with Flutter extensions
- An Android device or emulator / iOS device or simulator

### Installation

#### Method 1: Install from APK (Easiest)

1. Download the APK file from the [releases page]([https://github.com/Chandu-geesala/drivenotes/releases](https://github.com/Chandu-geesala/Drive-Notes/releases/tag/DriveNote))
2. Install it on your Android device
3. Open the app and sign in with your Google account

#### Method 2: Build from Source

1. Clone the repository:

```bash
git clone https://github.com/Chandu-geesala/drivenotes.git
cd drivenotes
```

2. Install dependencies:

```bash
flutter pub get
```

3. Run the app:

```bash
flutter run
```

**Note**: The app uses Firebase for authentication, so you don't need to set up Google API credentials separately. All necessary configurations are included in the project files.

## App Structure

The project follows a clean architecture pattern with separation of concerns:

```
lib/
├── providers/
│   ├── notes_provider.dart
│   ├── theme_provider.dart
│   └── user_provider.dart
├── view/
│   ├── splashScreen/
│   │   ├── intro.dart
│   │   └── splash_screen.dart
│   ├── home.dart
│   ├── login.dart
│   └── notes_screen.dart
├── viewModel/
│   ├── authService.dart
│   └── drive_service.dart
├── utils/
│   └── notificationService.dart
└── main.dart
```

## Authentication

DriveNotes uses Firebase Authentication with Google Sign-In. The authentication flow is:

1. User opens the app
2. If not authenticated, user is redirected to login screen
3. User authenticates with Google account
4. After successful authentication, user is redirected to home screen

No additional setup is required as the Firebase configuration is included in the project.

## Usage

### First Launch Experience

When you first launch the app, you'll be greeted with:
1. A welcome animation
2. A personalized notification welcoming you to DriveNotes
3. The login screen to authenticate with your Google account

### Creating Notes

1. Tap the floating action button (+) at the bottom of the home screen
2. Enter a title and content for your note
3. Your note is automatically saved

### Managing Notes

- **View/Edit**: Tap on any note to open and edit it
- **Delete**: Long press on a note to delete it or use the more options menu
- **Options**: Tap the three dots on a note card to see more options

### Theme Switching

Toggle between light and dark themes by tapping the sun/moon icon in the app bar.

## Known Limitations

- **Offline Mode**: While the app works offline, synchronization requires an internet connection
- **Rich Text**: Currently supports plain text only, rich text formatting will be added in future updates
- **Attachments**: File attachments are planned for future releases
- **Search**: Full-text search functionality is coming soon
- **Collaboration**: Shared notes and collaboration features are on the roadmap

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

Created with ❤️ by Chandu
