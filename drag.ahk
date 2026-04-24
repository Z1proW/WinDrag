#NoEnv
#SingleInstance Force
#Persistent
SetBatchLines, -1
SetWinDelay, -1
CoordMode, Mouse, Screen


; =========================
; SETTINGS
; =========================
global ENABLE_DRAG := true

global ENABLE_CLOSE := true

global ENABLE_RESIZE := true
global RESIZE_ALT_VERSION := true

global ENABLE_SNAP := true
global SNAP_THRESHOLD_TOP_BOT := 50  ; pixels from screen edge
global SNAP_THRESHOLD_LEFT_RIGHT := 50
global SNAP_LEFT_RIGHT_TILES := true
global SNAP_HALF := true



; =========================
; GLOBAL STATE
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

; Exclude Start menu and taskbar
WinGetClass, cls, ahk_id %winId%
WinGet, exe, ProcessName, ahk_id %winId%
if (exe = "StartMenuExperienceHost.exe"
|| exe = "SearchHost.exe"
|| cls = "Windows.UI.Core.CoreWindow"
|| cls = "Shell_TrayWnd"
|| cls = "Shell_SecondaryTrayWnd")
    return

WinClose, ahk_id %winId%
return



; =========================
; RESIZE WINDOW (Win + Right Mouse)
; =========================
~LWin & RButton::
if (!ENABLE_CLOSE)
    return
if (dragging)
    return

MouseGetPos,,, winId
; ignore invalid windows
if (!IsRealWindow(winId))
    return

; Exclude Start menu and taskbar
WinGetClass, cls, ahk_id %winId%
WinGet, exe, ProcessName, ahk_id %winId%
if (exe = "StartMenuExperienceHost.exe"
 || exe = "SearchHost.exe"
 || cls = "Windows.UI.Core.CoreWindow"
 || cls = "Shell_TrayWnd"
 || cls = "Shell_SecondaryTrayWnd")
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
; clicks on the title bar
; =========================
~LWin & LButton::
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
Send {LButton up}
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
    if (ENABLE_DRAG && !resizing)
    {
        if (wParam = 0x201 && GetKeyState("LWin", "P")) ; WM_LBUTTONDOWN
        {
            MouseGetPos,,, winId

            ; ignore invalid windows
            if (!IsRealWindow(winId))
                return CallNextHook(hook, nCode, wParam, lParam)

            ; Exclude Start menu and taskbar
            WinGetClass, winClass, ahk_id %winId%
            WinGet, winExe, ProcessName, ahk_id %winId%
            if (winExe = "StartMenuExperienceHost.exe"
                || winExe = "SearchHost.exe"
                || winClass = "Windows.UI.Core.CoreWindow"
                || winClass = "Shell_TrayWnd"
                || winClass = "Shell_SecondaryTrayWnd") {
                return CallNextHook(hook, nCode, wParam, lParam)
            }

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

            ; Exclude Start menu and taskbar
            WinGetClass, winClass, ahk_id %winId%
            WinGet, winExe, ProcessName, ahk_id %winId%
            if (winExe = "StartMenuExperienceHost.exe"
             || winExe = "SearchHost.exe"
             || winClass = "Windows.UI.Core.CoreWindow"
             || winClass = "Shell_TrayWnd"
             || winClass = "Shell_SecondaryTrayWnd") {
                return CallNextHook(hook, nCode, wParam, lParam)
            }

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
        if (curY <= monTop + SNAP_THRESHOLD_TOP_BOT)
        {
            WinMaximize, ahk_id %winId%
            return 1
        }

        ; =========================
        ; BOTTOM EDGE -> MINIMIZE
        ; =========================
        if (curY >= monBottom - SNAP_THRESHOLD_TOP_BOT)
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
    MouseGetPos,,, hoveredWin
    WinGetClass, hoverClass, ahk_id %hoveredWin%
    if (hoverClass = "Shell_TrayWnd"
    || hoverClass = "Shell_SecondaryTrayWnd")
        return false
    
    ; ignore sys ui
    if (hoverClass = "Button"
    || hoverClass = "SysPager"
    || hoverClass = "Windows.UI.Core.CoreWindow")
        return false

    return true
}

; =========================
; CLEAN EXIT
; =========================
OnExit, Cleanup
return

Cleanup:
if (hook)
    DllCall("UnhookWindowsHookEx", "Ptr", hook), hook := 0
if (hookProc)
    DllCall("GlobalFree", "Ptr", hookProc), hookProc := 0
ExitApp
return
