# PomoFloating ⏱️

**PomoFloating** is a lightweight, distraction-free macOS menu bar Pomodoro timer built with SwiftUI. It integrates seamlessly with **Notion** to let you track your tasks, manage focus sessions, and automatically log your time spent working.

---

## ✨ Features

* **Menu Bar Utility:** Stays out of your way in the macOS menu bar, giving you quick access to your timer without cluttering your dock.
* **Notion Integration:** Automatically syncs tasks from your Notion database, updates task statuses (`In Progress` / `Done`), and logs focus duration directly back into Notion.
* **Local Mode Fallback:** Functions smoothly even when offline or without an active Notion connection using local task storage.
* **Focus History & Stats:** Keeps track of your productivity sessions to help you stay on target.

---

## 🛠️ Tech Stack

* **Language:** Swift / SwiftUI
* **Platform:** macOS
* **Architecture:** ObservableObject state management, Combine, URLSession API client

---

## ⚙️ Configuration & Setup (Optional)

> **Note:** Notion integration is completely optional! If you choose not to set up Notion credentials, the app will still work perfectly as a standalone Pomodoro timer and timer tracker. Your task dropdown list will simply remain empty or utilize local tasks.

If you *do* want to sync with Notion, you will need an integration token and a configured database.

### Required Notion Database Structure

| Property Name | Property Type | Description |
| :--- | :--- | :--- |
| **Name** | `Title` | The main title/name of the task. |
| **Status** | `Status` *(or `Select`)* | Tracks the workflow state. The app looks for values like `"In Progress"` or `"Done"`. |
| **Time Spent** | `Number` | A numeric field where the app logs total minutes spent working during focus sessions. |

### Setting Up Environment Variables in Xcode

1. Open `PomoFloating.xcodeproj` in Xcode.
2. In Xcode, click your active scheme dropdown menu next to the play button and select **Edit Scheme...**
3. Navigate to **Run** ➔ **Arguments** ➔ **Environment Variables**.
4. Add the following keys:
   * **`NOTION_API_KEY`**: Your Notion Internal Integration Token.
   * **`NOTION_DATABASE_ID`**: Your Notion Database ID.

---

## 🚀 Building and Running

1. Open the project in Xcode (requires Xcode 15+ and macOS Sonoma or newer).
2. Select **My Mac** as your target run destination.
3. Press `Cmd + R` to build and launch the app.

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.
