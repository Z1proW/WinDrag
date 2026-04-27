# Smooth Windows Drag Script

A highly responsive AutoHotkey window management script focused on smooth,
low-latency dragging, snapping, and resizing using the **Left Windows modifier key**.

------------------------------------------------------------------------

## ✨ Features

### 🖱 Window Dragging

-   Hold **LWin + Left Mouse Button**
-   Drag windows freely with buttery-smooth motion across screens
-   Automatically restores maximized windows before moving

------------------------------------------------------------------------

### 🧲 Smart Snapping (on release)

Snapping triggers when you release the mouse:

-   ⬆ Top edge → Maximize
-   ⬇ Bottom edge → Minimize
-   ⬅ Left edge → Snap left half
-   ➡ Right edge → Snap right half

Supports multi-monitor setups.

------------------------------------------------------------------------

### ❌ Quick Close

-   **LWin + Middle Mouse Button**
-   Closes the window under cursor
-   Safely ignores system UI (Start Menu, Search, taskbar)

------------------------------------------------------------------------

### 📏 Native Resize Mode

-   **LWin + Right Mouse Button**
-   Uses Windows built-in resize system for smooth visuals
-   Fully compatible with Snap layouts, DPI scaling, and multi-monitor
    setups

------------------------------------------------------------------------

## Video Demo

https://github.com/user-attachments/assets/7ecf3290-65a8-4647-8a65-e2ec6ce8db84

------------------------------------------------------------------------
## ⚙️ Configuration

You can tweak behavior by using the GUI Settings in the tray icon.

------------------------------------------------------------------------

## 🚀 Usage

-   Hold **LWin + drag** → move window
-   Drag to screen edge → release → snap action
-   **LWin + Right Click** → resize
-   **LWin + Middle Click** → close window (or minimize)

------------------------------------------------------------------------

## ▶️ Running the script (Windows only)

You have two options:

* **Precompiled version:**
  Download and run `winDrag.exe`, no installation required.
  [Download latest release](https://github.com/Z1proW/WinDrag/releases)

* **Script version:**
  Download `winDrag.ahk` and run it with [AutoHotkey v1.1+](https://www.autohotkey.com/)
  Recommended for advanced users who want to edit the script.

---

### 🚀 Start on boot

To launch the script automatically at startup:

1. Press `Win + R`
2. Type:

   ```
   shell:startup
   ```
3. Place a shortcut of `winDrag.ahk` or `winDrag.exe` in that folder

4. Running the script on Administrator windows:

    If you want the script to interact with applications running as Administrator, you must run the script itself with elevated privileges.

    To do this:

    * Right-click the script file
    * Select **Properties**
    * Go to **Advanced…**
    * Check **Run as administrator**
