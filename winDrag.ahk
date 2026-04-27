; =========================
; Script by Z1proW
; https://github.com/Z1proW/WinDrag
; =========================


#NoEnv
#SingleInstance Force
#Persistent
SetBatchLines, -1
SetWinDelay, -1
CoordMode, Mouse, Screen


global SettingsFile := A_ScriptDir "\settings.ini"

; =========================
; DEFAULT SETTINGS
; =========================
global ENABLE_DRAG := 1  ; Win + Left-click drag to move windows
global DRAG_ALT_VERSION := 0  ; experimental

global ENABLE_CLOSE := 1  ; Win + middle-click to close
global MINIMIZE_INSTEAD := 0  ; if true, Win + middle-click will minimize instead of close

global ENABLE_RESIZE := 1  ; Win + right-click drag to resize
global RESIZE_ALT_VERSION := 0  ; experimental

global ENABLE_SNAP := 1  ; enable dragging windows to screen edges to snap/resize them
global SNAP_HALF := 1  ; if false, windows will not snap to left/right edges
global SNAP_MAXIMIZE := 1  ; if false, dragging to top edge will not maximize
global SNAP_MINIMIZE := 1  ; if false, dragging to bottom edge will not minimize
global SNAP_THRESHOLD_TOP_BOT := 50  ; distance (pixels) from top/bottom edge to trigger maximize/minimize
global SNAP_THRESHOLD_LEFT_RIGHT := 50  ; distance from left/right edge to trigger snap
global SNAP_LEFT_RIGHT_TILES := 0  ; if true, left/right snap will trigger on the entire screen, effectively tiling the window

global ENABLE_ALWAYS_ON_TOP := 1  ; enable always-on-top functionality (Win + A)
global ALWAYS_ON_TOP_KEYBIND := "A"  ; key to toggle always-on-top (used with Win key, e.g. Win + A)


; =========================
; LOAD DEFAULT KEYBINDS
; =========================
; always on top keybind
Hotkey, LWin & %ALWAYS_ON_TOP_KEYBIND%, ToggleAlwaysOnTop, On




; =========================
; LOAD GLOBAL STATE
; =========================
global dragging := false
global resizing := false
global winDown := false
global winId := 0

; install mouse hook
global hMod := DllCall("GetModuleHandle", "Ptr", 0, "Ptr")
global hookProc := RegisterCallback("MouseHook", "StdCall")
global hook := DllCall("SetWindowsHookEx"
    , "Int", 14  ; WH_MOUSE_LL
    , "Ptr", hookProc
    , "Ptr", hMod
    , "UInt", 0)

; keyboard hook
global kHookProc := RegisterCallback("KeyboardHook", "StdCall")
global kHook := DllCall("SetWindowsHookEx"
    , "Int", 13  ; WH_KEYBOARD_LL
    , "Ptr", kHookProc
    , "Ptr", hMod
    , "UInt", 0)

; load settings from file if it exists, otherwise defaults will be used and saved on exit
if FileExist(SettingsFile)
    Gosub, LoadSettingsFromDisk

; TRAY MENU
Menu, Tray, NoStandard
Menu, Tray, Add, WinDrag Settings, OpenSettings
Menu, Tray, Add, Open Script Directory, OpenScriptDir
Menu, Tray, Add
Menu, Tray, Add, Reload Script, Reload
Menu, Tray, Add, Exit, Cleanup
Menu, Tray, Default, WinDrag Settings
Menu, Tray, Click, 1

; SETTINGS GUI

Gui, Font, s9, Segoe UI

Gui, Add, Button, gSaveSettings, Save
Gui, Add, Button, x+10 vBtnRestoreDefaults gRestoreDefaults, Restore Defaults
Gui, Add, Button, x+10 vBtnRestoreBackup gRestoreBackup, Restore Backup

; add tabs for different categories of settings
Gui, Add, Tab2, Buttons x13 y+10 vSETTINGS_TAB, Drag|Close|Resize|Snap|Always-on-top

; drag category
Gui, Tab, Drag
Gui, Add, CheckBox, y+10 vENABLE_DRAG Checked%ENABLE_DRAG%, Enable Win + Left-click drag
Gui, Add, CheckBox, vDRAG_ALT_VERSION Checked%DRAG_ALT_VERSION%, Use experimental drag method (moves mouse to title bar)

; close category
Gui, Tab, Close
Gui, Add, CheckBox, y+10 vENABLE_CLOSE Checked%ENABLE_CLOSE%, Enable Win + Middle-click close
Gui, Add, CheckBox, vMINIMIZE_INSTEAD Checked%MINIMIZE_INSTEAD%, Minimize instead of close

; resize category
Gui, Tab, Resize
Gui, Add, CheckBox, y+10 vENABLE_RESIZE Checked%ENABLE_RESIZE%, Enable Win + Right-click drag resize
Gui, Add, CheckBox, vRESIZE_ALT_VERSION Checked%RESIZE_ALT_VERSION%, Use experimental resize method (resizes around center, may have visual artifacts)

; snap category
Gui, Tab, Snap
Gui, Add, CheckBox, y+10 vENABLE_SNAP gUpdateSnapMode Checked%ENABLE_SNAP%, Enable window snapping to screen edges
Gui, Add, CheckBox, vSNAP_HALF gUpdateSnapMode Checked%SNAP_HALF%, Enable snapping to left/right edges for half-screen snap
Gui, Add, CheckBox, vSNAP_MAXIMIZE gUpdateSnapMode Checked%SNAP_MAXIMIZE%, Enable snapping to top edge for maximize
Gui, Add, CheckBox, vSNAP_MINIMIZE gUpdateSnapMode Checked%SNAP_MINIMIZE%, Enable snapping to bottom edge for minimize

Gui, Add, CheckBox, vSNAP_LEFT_RIGHT_TILES gUpdateSnapMode Checked%SNAP_LEFT_RIGHT_TILES%, Make left/right snap trigger on entire screen (tile)

Gui, Add, Text,,
Gui, Add, Text,, Left/right snap threshold (px):
maxH := A_ScreenWidth // 2
Gui, Add, Slider, w200 Range0-%maxH% AltSubmit gUpdateSnapSlider vSNAP_THRESHOLD_LEFT_RIGHT, %SNAP_THRESHOLD_LEFT_RIGHT%
Gui, Add, Text, vSnapLRText w60, %SNAP_THRESHOLD_LEFT_RIGHT%px

Gui, Add, Text,,
Gui, Add, Text,, Top/bottom snap threshold (px)
maxV := A_ScreenHeight // 4
Gui, Add, Slider, w200 Range0-%maxV% AltSubmit gUpdateSnapSliderV vSNAP_THRESHOLD_TOP_BOT, %SNAP_THRESHOLD_TOP_BOT%
Gui, Add, Text, vSnapTBText w250, %SNAP_THRESHOLD_TOP_BOT%px
Gui, Add, Text,,

; always-on-top category
Gui, Tab, Always-on-top
Gui, Add, CheckBox, y+10 vENABLE_ALWAYS_ON_TOP Checked%ENABLE_ALWAYS_ON_TOP%, Enable always-on-top toggle (Win + %ALWAYS_ON_TOP_KEYBIND%)
Gui, Add, Edit, w100 vALWAYS_ON_TOP_KEYBIND, %ALWAYS_ON_TOP_KEYBIND%
Gui, Add, Text,, (Change the keybind for always-on-top. Default is "A", used with Win key, e.g. Win + A)


return

LoadSettingsFromDisk:
Hotkey, LWin & %ALWAYS_ON_TOP_KEYBIND%, ToggleAlwaysOnTop, Off  ; unregister old keybind

IniRead, ENABLE_DRAG, %SettingsFile%, Settings, ENABLE_DRAG, 1
IniRead, DRAG_ALT_VERSION, %SettingsFile%, Settings, DRAG_ALT_VERSION, 0

IniRead, ENABLE_CLOSE, %SettingsFile%, Settings, ENABLE_CLOSE, 1
IniRead, MINIMIZE_INSTEAD, %SettingsFile%, Settings, MINIMIZE_INSTEAD, 0

IniRead, ENABLE_RESIZE, %SettingsFile%, Settings, ENABLE_RESIZE, 1
IniRead, RESIZE_ALT_VERSION, %SettingsFile%, Settings, RESIZE_ALT_VERSION, 0

IniRead, ENABLE_SNAP, %SettingsFile%, Settings, ENABLE_SNAP, 1
IniRead, SNAP_HALF, %SettingsFile%, Settings, SNAP_HALF, 1
IniRead, SNAP_MAXIMIZE, %SettingsFile%, Settings, SNAP_MAXIMIZE, 1
IniRead, SNAP_MINIMIZE, %SettingsFile%, Settings, SNAP_MINIMIZE, 1

IniRead, SNAP_THRESHOLD_TOP_BOT, %SettingsFile%, Settings, SNAP_THRESHOLD_TOP_BOT, 50
IniRead, SNAP_THRESHOLD_LEFT_RIGHT, %SettingsFile%, Settings, SNAP_THRESHOLD_LEFT_RIGHT, 50
IniRead, SNAP_LEFT_RIGHT_TILES, %SettingsFile%, Settings, SNAP_LEFT_RIGHT_TILES, 0

IniRead, ENABLE_ALWAYS_ON_TOP, %SettingsFile%, Settings, ENABLE_ALWAYS_ON_TOP, 1
IniRead, ALWAYS_ON_TOP_KEYBIND, %SettingsFile%, Settings, ALWAYS_ON_TOP_KEYBIND, A

; load keybinds based on settings
Hotkey, LWin & %ALWAYS_ON_TOP_KEYBIND%, ToggleAlwaysOnTop, On

return


UpdateSettingsButtons:
; Restore Defaults button enabled only if settings.ini exists
if FileExist(SettingsFile)
    GuiControl, Enable, BtnRestoreDefaults
else
    GuiControl, Disable, BtnRestoreDefaults

; Restore Backup button enabled only if .bak exists
if FileExist(SettingsFile ".bak")
    GuiControl, Enable, BtnRestoreBackup
else
    GuiControl, Disable, BtnRestoreBackup
return


UpdateSnapMode:
Gui, Submit, NoHide

if (!ENABLE_SNAP)
{
    GuiControl, Disable, SNAP_THRESHOLD_LEFT_RIGHT
    GuiControl, Disable, SNAP_THRESHOLD_TOP_BOT
    GuiControl,, SnapLRText, Disabled
    GuiControl,, SnapTBText, Disabled
    return
}

if (SNAP_MAXIMIZE || SNAP_MINIMIZE)
{
    GuiControl, Enable, SNAP_THRESHOLD_TOP_BOT
    GuiControl,, SnapTBText, %SNAP_THRESHOLD_TOP_BOT%px
}
else 
{
    GuiControl, Disable, SNAP_THRESHOLD_TOP_BOT
    GuiControl,, SnapTBText, Disabled
}

if (!SNAP_HALF)
{
    GuiControl, Disable, SNAP_THRESHOLD_LEFT_RIGHT
    GuiControl,, SnapLRText, Disabled
    return
}

if (!SNAP_LEFT_RIGHT_TILES)
{
    GuiControl, Enable, SNAP_THRESHOLD_LEFT_RIGHT
    GuiControl,, SnapLRText, %SNAP_THRESHOLD_LEFT_RIGHT%px
}
else
{
    GuiControl, Disable, SNAP_THRESHOLD_LEFT_RIGHT
    val := A_ScreenWidth // 2
    GuiControl,, SnapLRText, Tiling
    ;GuiControl,, SNAP_THRESHOLD_LEFT_RIGHT, % A_ScreenWidth//2
}
return

UpdateSnapSlider:
GuiControlGet, val,, SNAP_THRESHOLD_LEFT_RIGHT
GuiControl,, SnapLRText, %val%px
return

UpdateSnapSliderV:
GuiControlGet, val,, SNAP_THRESHOLD_TOP_BOT
GuiControl,, SnapTBText, %val%px
return

SaveSettings:
Hotkey, LWin & %ALWAYS_ON_TOP_KEYBIND%, ToggleAlwaysOnTop, Off  ; unregister old keybind

Gui, Submit, NoHide

; update variables with new settings
global ENABLE_DRAG := ENABLE_DRAG
global DRAG_ALT_VERSION := DRAG_ALT_VERSION
global ENABLE_CLOSE := ENABLE_CLOSE
global MINIMIZE_INSTEAD := MINIMIZE_INSTEAD
global ENABLE_RESIZE := ENABLE_RESIZE
global RESIZE_ALT_VERSION := RESIZE_ALT_VERSION
global ENABLE_SNAP := ENABLE_SNAP
global SNAP_HALF := SNAP_HALF
global SNAP_MAXIMIZE := SNAP_MAXIMIZE
global SNAP_MINIMIZE := SNAP_MINIMIZE
global SNAP_THRESHOLD_TOP_BOT := SNAP_THRESHOLD_TOP_BOT
global SNAP_THRESHOLD_LEFT_RIGHT := SNAP_THRESHOLD_LEFT_RIGHT
global SNAP_LEFT_RIGHT_TILES := SNAP_LEFT_RIGHT_TILES
global ENABLE_ALWAYS_ON_TOP := ENABLE_ALWAYS_ON_TOP
global ALWAYS_ON_TOP_KEYBIND := ALWAYS_ON_TOP_KEYBIND

; update hotkeys
Hotkey, LWin & %ALWAYS_ON_TOP_KEYBIND%, ToggleAlwaysOnTop

Gosub, SaveSettingsOnDisk
Gosub, UpdateSettingsButtons

return

GuiClose(GuiHwnd)
{
    MsgBox, 4,, Do you want to exit? (discards unsaved changes)
    IfMsgBox, No
        return true
    Reload
}

ApplySettingsToGui()
{
    GuiControl,, ENABLE_DRAG, %ENABLE_DRAG%
    GuiControl,, DRAG_ALT_VERSION, %DRAG_ALT_VERSION%

    GuiControl,, ENABLE_CLOSE, %ENABLE_CLOSE%
    GuiControl,, MINIMIZE_INSTEAD, %MINIMIZE_INSTEAD%

    GuiControl,, ENABLE_RESIZE, %ENABLE_RESIZE%
    GuiControl,, RESIZE_ALT_VERSION, %RESIZE_ALT_VERSION%

    GuiControl,, ENABLE_SNAP, %ENABLE_SNAP%
    GuiControl,, SNAP_HALF, %SNAP_HALF%
    GuiControl,, SNAP_MAXIMIZE, %SNAP_MAXIMIZE%
    GuiControl,, SNAP_MINIMIZE, %SNAP_MINIMIZE%
    GuiControl,, SNAP_LEFT_RIGHT_TILES, %SNAP_LEFT_RIGHT_TILES%

    GuiControl,, SNAP_THRESHOLD_LEFT_RIGHT, %SNAP_THRESHOLD_LEFT_RIGHT%
    GuiControl,, SNAP_THRESHOLD_TOP_BOT, %SNAP_THRESHOLD_TOP_BOT%

    GuiControl,, ENABLE_ALWAYS_ON_TOP, %ENABLE_ALWAYS_ON_TOP%
    GuiControl,, ALWAYS_ON_TOP_KEYBIND, %ALWAYS_ON_TOP_KEYBIND%

    Gosub, UpdateSnapMode
    Gosub, UpdateSettingsButtons
}


RestoreDefaults:
MsgBox, 4,, Reset all settings to defaults? (This will overwrite current settings and create a backup)
IfMsgBox, No
    return

if FileExist(SettingsFile)
{
    FileMove, %SettingsFile%, %SettingsFile%.bak, 1  ; overwrite existing backup
}

Gosub, LoadSettingsFromDisk  ; this will load defaults since settings.ini is now gone
ApplySettingsToGui()

return


RestoreBackup:
MsgBox, 4,, Restore settings from backup? (This will overwrite current settings and create a backup)
IfMsgBox, No
    return

if !FileExist(SettingsFile ".bak")
{
    MsgBox, Backup file not found!
    return
}
FileMove, %SettingsFile%, %SettingsFile%.tmp, 1  ; create temp backup of current settings
FileMove, %SettingsFile%.bak, %SettingsFile%, 1  ; restore backup
FileMove, %SettingsFile%.tmp, %SettingsFile%.bak, 1  ; move temp backup to .bak

Gosub, LoadSettingsFromDisk
ApplySettingsToGui()
return


Reload:
Gosub, SaveSettingsOnDisk
Reload
return

OpenSettings:
Gui, Show,, WinDrag Settings
Gosub, UpdateSettingsButtons
return


OpenScriptDir:
Run, %A_ScriptDir%
return



; =========================
; CLOSE WINDOW (Win + Middle Click)
; =========================
~LWin & MButton::
if (!ENABLE_CLOSE)
    return

MouseGetPos,,, winId
; ignore invalid windows
if (!IsRealWindow(winId))
    return

if (MINIMIZE_INSTEAD)
{
    WinMinimize, ahk_id %winId%
    return
}

WinClose, ahk_id %winId%
return



; =========================
; RESIZE WINDOW (Win + Right Mouse)
; =========================
~LWin & RButton::
if (!ENABLE_RESIZE)
    return
if (dragging)
    return

MouseGetPos,,, winId
; ignore invalid windows
if (!IsRealWindow(winId))
    return
                    
; Exclude maximized Windows
WinGet, wasMax, MinMax, ahk_id %winId%
if (wasMax = 1)
    return
                        
WinActivate, ahk_id %winId%
DllCall("ReleaseCapture")
PostMessage, 0xA1, 17,,, ahk_id %winId% ; 17 = HTBOTTOMRIGHT
resizing := true
return

~LWin & RButton up::
if (!ENABLE_RESIZE)
    return
if (dragging)
    return

PostMessage, 0x202, 0,,, ahk_id %winId% ; Exit resize
resizing := false
winId := 0
winDown := false
return



; =========================
; NATIVE DRAG [ALT VERSION] (Win + Left Mouse)
; moves mouse on the title bar
; =========================
~LWin & LButton::
if (!ENABLE_DRAG)
    return
if (!DRAG_ALT_VERSION)
    return

MouseGetPos, mx, my, winId
if (!winId)
    return

WinGetPos, x, y, w, h, ahk_id %winId%
WinActivate, ahk_id %winId%

; approximate title bar position
titleX := x + (w // 2)
titleY := y + 10   ; safely inside title bar area

DllCall("SetCursorPos", "int", titleX, "int", titleY)

; simulate real click on title bar
Send {LButton down}
return

~LWin & LButton Up::
if (!ENABLE_DRAG)
    return
if (!DRAG_ALT_VERSION)
    return
Send {LButton up}
return



; =========================
; ALWAYS ON TOP KEYBIND (Win + A by default)
; toggles always-on-top for the active window
; =========================
ToggleAlwaysOnTop:
if (!ENABLE_ALWAYS_ON_TOP)
    return

WinGet, activeWindow, ID, A

; ignore invalid windows
if (!IsRealWindow(activeWindow))
    return

Winset, Alwaysontop, , A
return




; -----------------------------
; Mouse events
; -----------------------------
MouseHook(nCode, wParam, lParam)
{
    global dragging, winId
    global startMouseX, startMouseY
    global startWinX, startWinY
    global startWinW, startWinH
    global winDown

    Critical

    if (!winDown && !GetKeyState("LWin", "P"))
    {
        winId := 0
        dragging := false
        return CallNextHook(hook, nCode, wParam, lParam)
    }
    ; now LWin is pressed (or a drag/resize is still active)

    ; =========================
    ; DRAG LOGIC
    ; =========================
    if (ENABLE_DRAG && !resizing && !DRAG_ALT_VERSION)
    {
        if (wParam = 0x201 && GetKeyState("LWin", "P")) ; WM_LBUTTONDOWN
        {
            MouseGetPos,,, winId

            ; ignore invalid windows
            if (!IsRealWindow(winId))
                return CallNextHook(hook, nCode, wParam, lParam)

            WinActivate, ahk_id %winId%

            WinGet, wasMax, MinMax, ahk_id %winId%

            ; restore maximized window before dragging
            if (wasMax = 1)
            {
                WinRestore, ahk_id %winId%

                ; put window at mouse location
                MouseGetPos, curX, curY
                WinGetPos,,, ww, wh, ahk_id %winId%
                DllCall("SetWindowPos"
                    , "Ptr", winId
                    , "Ptr", 0
                    , "Int", curX - ww // 2
                    , "Int", curY - wh // 2
                    , "Int", 0 , "Int", 0
                    , "UInt", 0x0001 | 0x0004) ; SWP_NOSIZE | SWP_NOZORDER
            }

            MouseGetPos, startMouseX, startMouseY
            WinGetPos, startWinX, startWinY,,, ahk_id %winId%
            dragging := true
            return 1 ; don't pass click event to OS
        }
        else if (wParam = 0x200 && dragging) ; WM_MOUSEMOVE
        {
            MouseGetPos, curX, curY

            dx := curX - startMouseX
            dy := curY - startMouseY

            DllCall("SetWindowPos"
                , "Ptr", winId
                , "Ptr", 0
                , "Int", startWinX + dx
                , "Int", startWinY + dy
                , "Int", 0
                , "Int", 0
                , "UInt", 0x0001 | 0x0004) ; SWP_NOSIZE | SWP_NOZORDER
        }
        else if (wParam = 0x202 && dragging) ; WM_LBUTTONUP
        {
            dragging := false

            ; -----------------------------
            ; WINDOW SNAPPING
            ; -----------------------------
            if (ENABLE_SNAP)
            {
                MouseGetPos, curX, curY
                SnapWindow(winId, curX, curY)
            }

            winId := 0
            winDown := false
            CloseStartMenu()

            return 1 ; don't pass click event to OS
        }
    }

    ; =========================
    ; RESIZE WINDOW [ALT VERSION] (Win + Right Mouse)
    ; resizes around the center
    ; may contain visual artifacts
    ; =========================
    if (ENABLE_RESIZE && !dragging && RESIZE_ALT_VERSION)
    {
        if (wParam = 0x204) ; WM_RBUTTONDOWN
        {
            MouseGetPos,,, winId

            ; ignore invalid windows
            if (!IsRealWindow(winId))
                return CallNextHook(hook, nCode, wParam, lParam)

            ; Exclude maximized Windows
            WinGet, wasMax, MinMax, ahk_id %winId%
            if (wasMax = 1)
                return CallNextHook(hook, nCode, wParam, lParam)

            WinRestore, ahk_id %winId%
                    
            MouseGetPos, startMouseX, startMouseY
            WinGetPos, startWinX, startWinY, startWinW, startWinH, ahk_id %winId%
            resizing := true
            return 1 ; don't pass click event to OS
        }
        else if (wParam = 0x200 && resizing) ; WM_MOUSEMOVE
        {
            MouseGetPos, curX, curY
            dx := curX - startMouseX
            dy := curY - startMouseY
            DllCall("SetWindowPos"
                , "ptr", winId
                , "ptr", 0
                , "int", startWinX - dx // 2
                , "int", startWinY - dy // 2
                , "int", startWinW + dx
                , "int", startWinH + dy
                , "uint", 0x0010 | 0x0004) ; SWP_NOACTIVATE | SWP_NOZORDER
        }
        else if (wParam = 0x205 && resizing) ; WM_RBUTTONUP
        {
            resizing := false
            winId := 0
            winDown := false
            CloseStartMenu()
            return 1 ; don't pass click event to OS
        }
    }
    return CallNextHook(hook, nCode, wParam, lParam)
}

SnapWindow(winId, curX, curY)
{
    global SNAP_THRESHOLD_TOP_BOT, SNAP_THRESHOLD_LEFT_RIGHT, SNAP_HALF

    SysGet, monCount, MonitorCount

    Loop %monCount%
    {
        SysGet, mon, Monitor, %A_Index%

        if (curX < monLeft || curX > monRight || curY < monTop || curY > monBottom)
            continue
        ; cursor is inside this Monitor mon

        ; =========================
        ; TOP EDGE -> MAXIMIZE
        ; =========================
        if (SNAP_MAXIMIZE && curY <= monTop + SNAP_THRESHOLD_TOP_BOT)
        {
            WinMaximize, ahk_id %winId%
            return 1
        }

        ; =========================
        ; BOTTOM EDGE -> MINIMIZE
        ; =========================
        if (SNAP_MINIMIZE && curY >= monBottom - SNAP_THRESHOLD_TOP_BOT)
        {
            WinMinimize, ahk_id %winId%
            return 1
        }

        ; =========================
        ; LEFT / RIGHT SNAP (HALF SCREEN)
        ; =========================
        if (SNAP_HALF)
        {
            width := monRight - monLeft
            height := monBottom - monTop

            if (SNAP_LEFT_RIGHT_TILES)
            {
                SNAP_THRESHOLD_LEFT_RIGHT := width // 2
            }

            ; LEFT
            if (curX <= monLeft + SNAP_THRESHOLD_LEFT_RIGHT)
            {
                ; Move window fully into this monitor first
                DllCall("SetWindowPos"
                    , "Ptr", winId
                    , "Ptr", 0
                    , "Int", monLeft + 50
                    , "Int", monTop + 50
                    , "Int", width - 100
                    , "Int", height - 100
                    , "UInt", 0x0004) ; SWP_NOZORDER

                ; Now do real Windows snap
                WinActivate, ahk_id %winId%
                Send, #{Left}
                Send, {LWin down}
                return 1
            }

            ; RIGHT
            if (curX >= monRight - SNAP_THRESHOLD_LEFT_RIGHT)
            {
                ; Force window onto this monitor first
                DllCall("SetWindowPos"
                    , "Ptr", winId
                    , "Ptr", 0
                    , "Int", monLeft + 50
                    , "Int", monTop + 50
                    , "Int", width - 100
                    , "Int", height - 100
                    , "UInt", 0x0004) ; SWP_NOZORDER

                ; Activate + native snap
                WinActivate, ahk_id %winId%
                Send, #{Right}
                Send, {LWin down}
                return 1
            }
        }

        break
    }

    return 0
}

; calling this prevents opening start menu by pressing Esc before LWin release
CloseStartMenu()
{
    DllCall("keybd_event", "UChar", 0x1B, "UChar", 0, "UInt", 0, "UPtr", 0) ; Esc Down
    DllCall("keybd_event", "UChar", 0x1B, "UChar", 0, "UInt", 2, "UPtr", 0) ; Esc Up
}

CallNextHook(hHook, nCode, wParam, lParam)
{
    return DllCall("CallNextHookEx"
        , "Ptr", hHook
        , "Int", nCode
        , "Ptr", wParam
        , "Ptr", lParam)
}

KeyboardHook(nCode, wParam, lParam)
{
    global winDown, kHook
    global dragging, resizing

    if (nCode < 0)
        return CallNextHook(kHook, nCode, wParam, lParam)

    vk := NumGet(lParam+0, 0, "UInt")

    if (vk = 0x5B) ; LWin
    {
        if (wParam = 0x100) ; WM_KEYDOWN
        {
            winDown := true
            winId := 0
            dragging := false
        }
        else if (wParam = 0x101 && dragging) ; WM_KEYUP
        {
            CloseStartMenu()
            winId := 0
            dragging := false
        }
    }

    return CallNextHook(kHook, nCode, wParam, lParam)
}

IsRealWindow(hwnd)
{
    ; must exist
    if (!hwnd)
        return false

    ; must be visible
    if !DllCall("IsWindowVisible", "Ptr", hwnd)
        return false
    
    ; skip cloaked (UWP, previews, virtual desktops)
    cloaked := 0
    if (DllCall("dwmapi\DwmGetWindowAttribute"
        , "Ptr", hwnd
        , "UInt", 14 ; DWMWA_CLOAKED
        , "UInt*", cloaked
        , "UInt", 4) = 0)
    {
        if (cloaked)
            return false
    }
    
    ; skip tool windows (common for previews)
    WinGet, exStyle, ExStyle, ahk_id %hwnd%
    if (exStyle & 0x80) ; WS_EX_TOOLWINDOW
        return false

    ; skip non-activatable windows
    if (exStyle & 0x08000000) ; WS_EX_NOACTIVATE
        return false

    ; ignore Taskbar
    WinGetClass, cls, ahk_id %hwnd%
    if (cls = "Shell_TrayWnd"
    || cls = "Shell_SecondaryTrayWnd")
        return false
    
    ; ignore sys ui
    if (cls = "Button"
    || cls = "SysPager"
    || cls = "Windows.UI.Core.CoreWindow")
        return false

    ; ignore Start menu
    WinGet, exe, ProcessName, ahk_id %hwnd%
    if (exe = "StartMenuExperienceHost.exe"
    || exe = "SearchHost.exe")
        return

    return true
}

SaveSettingsOnDisk:

; create backup of current settings if they exist
if FileExist(SettingsFile)
{
    FileMove, %SettingsFile%, %SettingsFile%.bak, 1  ; overwrite existing backup
}

; write settings
IniWrite, %ENABLE_DRAG%, %SettingsFile%, Settings, ENABLE_DRAG
IniWrite, %DRAG_ALT_VERSION%, %SettingsFile%, Settings, DRAG_ALT_VERSION

IniWrite, %ENABLE_CLOSE%, %SettingsFile%, Settings, ENABLE_CLOSE
IniWrite, %MINIMIZE_INSTEAD%, %SettingsFile%, Settings, MINIMIZE_INSTEAD

IniWrite, %ENABLE_RESIZE%, %SettingsFile%, Settings, ENABLE_RESIZE
IniWrite, %RESIZE_ALT_VERSION%, %SettingsFile%, Settings, RESIZE_ALT_VERSION

IniWrite, %ENABLE_SNAP%, %SettingsFile%, Settings, ENABLE_SNAP
IniWrite, %SNAP_HALF%, %SettingsFile%, Settings, SNAP_HALF
IniWrite, %SNAP_MAXIMIZE%, %SettingsFile%, Settings, SNAP_MAXIMIZE
IniWrite, %SNAP_MINIMIZE%, %SettingsFile%, Settings, SNAP_MINIMIZE

IniWrite, %SNAP_THRESHOLD_TOP_BOT%, %SettingsFile%, Settings, SNAP_THRESHOLD_TOP_BOT
IniWrite, %SNAP_THRESHOLD_LEFT_RIGHT%, %SettingsFile%, Settings, SNAP_THRESHOLD_LEFT_RIGHT
IniWrite, %SNAP_LEFT_RIGHT_TILES%, %SettingsFile%, Settings, SNAP_LEFT_RIGHT_TILES

IniWrite, %ENABLE_ALWAYS_ON_TOP%, %SettingsFile%, Settings, ENABLE_ALWAYS_ON_TOP
IniWrite, %ALWAYS_ON_TOP_KEYBIND%, %SettingsFile%, Settings, ALWAYS_ON_TOP_KEYBIND
return

; =========================
; SAVE SETTINGS AND EXIT
; =========================
Cleanup:
Gosub, SaveSettingsOnDisk

; hooks cleanup
if (hook)
    DllCall("UnhookWindowsHookEx", "Ptr", hook), hook := 0
if (hookProc)
    DllCall("GlobalFree", "Ptr", hookProc), hookProc := 0
if (kHook)
    DllCall("UnhookWindowsHookEx", "Ptr", kHook), kHook
if (kHookProc)
    DllCall("GlobalFree", "Ptr", kHookProc), kHookProc := 0

ExitApp
return
