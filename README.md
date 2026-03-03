# 🚀 Flutter Drift SQLite Riverpod
### Multi Database Manager with Authentication

A test project demonstrating how to build a multi-database system in Flutter using:

- 🧱 Drift (SQLite ORM)
- 🔐 SQLite / SQLCipher Ready
- 🧠 Riverpod (State Management)
- 📂 Multi Database Support
- 👤 Initial User Creation
- 🔑 Login Authentication
- 🖥 Desktop (macOS) Support

---

## ✨ Features

### 🗂 Create Database
- Create unlimited .db files
- Automatically generates required tables
- Creates an initial user
- Secure password hashing
- Encrypted database support (SQLCipher-ready)

---

### 📂 Open Database
- Browse and select existing .db files
- Automatically imports into app storage
- Connects and validates credentials
- Secure login dialog

---

### 📌 Database Management
- Pin / Unpin databases
- Rename display name
- Delete database safely
- Open containing folder (Finder / Explorer)

---

### 👤 Inside Database
- Login with username & password
- Create additional users
- View user list
- Real-time updates via Drift streams

---

## 🧱 Tech Stack

| Technology | Purpose |
|------------|----------|
| Flutter | UI Framework |
| Drift | SQLite ORM |
| SQLite / SQLCipher | Local Storage |
| Riverpod | State Management |
| File Picker | Import existing databases |
| Shared Preferences | Metadata (pin/rename) |
| macOS Entitlements | File system access |

---

## 🔐 Encryption (Optional SQLCipher Setup)

To enable database encryption:

dependencies:
  sqlcipher_flutter_libs: ^0.7.0

Then set encryption key inside NativeDatabase:

setup: (db) async {
  await db.execute("PRAGMA key = 'your-secret-key';");
}

Encrypted databases cannot be opened by regular SQLite editors without the key.

---

## 🖥 macOS Sandbox Setup (Required for File Picker)

Add this to:

macos/Runner/DebugProfile.entitlements
macos/Runner/Release.entitlements

<key>com.apple.security.app-sandbox</key>
<true/>

<key>com.apple.security.files.user-selected.read-write</key>
<true/>

Then run:

flutter clean
flutter pub get
flutter run -d macos

---

## ▶️ Run the Project

flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run

---

## 🎯 Learning Goals of This Project

- Dynamically create and manage multiple SQLite databases
- Open/connect databases at runtime
- Structure Drift with Riverpod
- Implement secure authentication locally
- Handle macOS sandbox permissions
- Prepare for SQLCipher encryption

---

## 🧪 Ideal For

- Local-first applications
- Multi-tenant apps
- Accounting software
- Offline tools
- Learning advanced Flutter architecture

---

## 👨‍💻 Author

Built as a learning & testing project for mastering:

Flutter + Drift + SQLite + Riverpod

---

## 📜 License

MIT — Feel free to use, modify, and improve.