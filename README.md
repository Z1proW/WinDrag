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

## ⚙️ Configuration

You can tweak behavior in the settings section:

``` ahk
global ENABLE_DRAG := true
global DRAG_ALT_VERSION := false  ; experimental

global ENABLE_CLOSE := true

global ENABLE_RESIZE := true
global RESIZE_ALT_VERSION := false  ; experimental

global ENABLE_SNAP := true
global SNAP_THRESHOLD_TOP_BOT := 50  ; pixels from screen edge
global SNAP_THRESHOLD_LEFT_RIGHT := 50
global SNAP_LEFT_RIGHT_TILES := false  ; only for default drag version
global SNAP_HALF := true
```

------------------------------------------------------------------------

## 🚀 Usage

-   Hold **LWin + drag** → move window
-   Drag to screen edge → release → snap action
-   **LWin + Right Click** → resize
-   **LWin + Middle Click** → close window

------------------------------------------------------------------------

## 📦 Requirements

* Windows 10 / 11
* AutoHotkey v1.1+ (only if running the `.ahk` script)

### ▶️ Running the script

You have two options:

* **Precompiled version:**
  Download and run `winDrag.exe` — no installation required.

* **Script version:**
  Download `winDrag.ahk` and run it with [AutoHotkey](https://www.autohotkey.com/)

---

### 🚀 Start on boot (AutoHotkey version only)

To launch the script automatically at startup:

1. Press `Win + R`
2. Type:

   ```
   shell:startup
   ```
3. Place a shortcut of `winDrag.ahk` in that folder
