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

You can tweak behavior in the settings section:

``` ahk
global ENABLE_DRAG := true  ; Win + Left-click drag to move windows
global DRAG_ALT_VERSION := false  ; experimental

global ENABLE_CLOSE := true  ; Win + middle-click to close
global MINIMIZE_INSTEAD := false  ; if true, Win + middle-click will minimize instead of close

global ENABLE_RESIZE := true  ; Win + right-click drag to resize
global RESIZE_ALT_VERSION := false  ; experimental

global ENABLE_SNAP := true  ; enable dragging windows to screen edges to snap/resize them
global SNAP_HALF := true  ; if false, windows will not snap to left/right edges
global SNAP_MAXIMIZE := true  ; if false, dragging to top edge will not maximize
global SNAP_MINIMIZE := true  ; if false, dragging to bottom edge will not minimize
global SNAP_THRESHOLD_TOP_BOT := 50  ; distance (pixels) from top/bottom edge to trigger maximize/minimize
global SNAP_THRESHOLD_LEFT_RIGHT := 50  ; distance from left/right edge to trigger snap
global SNAP_LEFT_RIGHT_TILES := false  ; if true, left/right snap will trigger on the entire screen, effectively tiling the window
```

------------------------------------------------------------------------

## 🚀 Usage

-   Hold **LWin + drag** → move window
-   Drag to screen edge → release → snap action
-   **LWin + Right Click** → resize
-   **LWin + Middle Click** → close window (or minimize)

------------------------------------------------------------------------

## ▶️ Running the script (Windows only)

You have two options:

* **Script version:**
  Download `winDrag.ahk` and run it with [AutoHotkey v1.1+](https://www.autohotkey.com/)
  Recommended for advanced customization.

* **Precompiled version:**
  Download and run `winDrag.exe`, no installation required.
  [Download latest release](https://github.com/Z1proW/WinDrag/releases)

---

### 🚀 Start on boot (AutoHotkey version only)

To launch the script automatically at startup:

1. Press `Win + R`
2. Type:

   ```
   shell:startup
   ```
3. Place a shortcut of `winDrag.ahk` in that folder
