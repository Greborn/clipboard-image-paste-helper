#Requires AutoHotkey v2.0
#SingleInstance Force

; Text inserted into the terminal for each pasted screenshot.
PasteTemplate := "[{label}]"

TempRoot := A_Temp "\cli-clipboard-images"
TtlHours := 6
ManifestPath := TempRoot "\manifest.tsv"
CounterPath := TempRoot "\counter.txt"

TerminalProcesses := Map(
    "WindowsTerminal.exe", true,
    "Code.exe", true,
    "Cursor.exe", true,
    "powershell.exe", true,
    "pwsh.exe", true,
    "cmd.exe", true,
    "wezterm-gui.exe", true,
    "mintty.exe", true,
    "alacritty.exe", true
)

DirCreate TempRoot
SetTimer CleanupOldImages, 10 * 60 * 1000
CleanupOldImages()

#HotIf IsExplorerActive()
^v::{
    if !HasClipboardImage() {
        Send "^v"
        return
    }

    folder := GetActiveExplorerFolder()
    if !folder {
        Send "^v"
        return
    }

    path := BuildExplorerImagePath(folder)
    if SaveClipboardImageTo(path) {
        return
    }

    Send "^v"
}
#HotIf

#HotIf IsTerminalActive()
^v::{
    if !HasClipboardImage() {
        Send "^v"
        return
    }

    originalClipboard := ClipboardAll()
    path := SaveClipboardImage()
    if !path {
        A_Clipboard := originalClipboard
        Send "^v"
        return
    }

    label := RegisterImage(path)
    if !label {
        A_Clipboard := originalClipboard
        Send "^v"
        return
    }

    text := StrReplace(PasteTemplate, "{label}", label)
    text := StrReplace(text, "{path}", path)
    A_Clipboard := text
    ClipWait 0.5
    Send "^v"
    Sleep 200
    A_Clipboard := originalClipboard
}
#HotIf

IsTerminalActive() {
    global TerminalProcesses

    try {
        processName := WinGetProcessName("A")
    } catch {
        return false
    }

    if TerminalProcesses.Has(processName) {
        return true
    }

    try {
        className := WinGetClass("A")
    } catch {
        className := ""
    }

    return className = "CASCADIA_HOSTING_WINDOW_CLASS"
        || className = "ConsoleWindowClass"
}

IsExplorerActive() {
    try {
        processName := WinGetProcessName("A")
        className := WinGetClass("A")
    } catch {
        return false
    }

    return processName = "explorer.exe"
        && (className = "CabinetWClass" || className = "ExploreWClass")
}

GetActiveExplorerFolder() {
    hwnd := WinGetID("A")
    shell := ComObject("Shell.Application")

    for window in shell.Windows {
        try {
            if window.HWND = hwnd {
                return window.Document.Folder.Self.Path
            }
        }
    }

    return ""
}

BuildExplorerImagePath(folder) {
    stamp := FormatTime(, "yyyyMMdd-HHmmss")
    base := folder "\clipboard-image-" stamp
    path := base ".png"
    index := 1

    while FileExist(path) {
        path := base "-" index ".png"
        index += 1
    }

    return path
}

HasClipboardImage() {
    ; CF_BITMAP = 2, CF_DIB = 8, CF_DIBV5 = 17.
    return DllCall("IsClipboardFormatAvailable", "UInt", 2)
        || DllCall("IsClipboardFormatAvailable", "UInt", 8)
        || DllCall("IsClipboardFormatAvailable", "UInt", 17)
}

SaveClipboardImage() {
    global TempRoot

    scriptPath := A_ScriptDir "\save-clipboard-image.ps1"
    stamp := FormatTime(, "yyyyMMdd-HHmmss")
    path := TempRoot "\clip-" stamp "-" Random(1000, 9999) ".png"

    return SaveClipboardImageTo(path) ? path : ""
}

SaveClipboardImageTo(path) {
    scriptPath := A_ScriptDir "\save-clipboard-image.ps1"

    command := 'powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "'
        . scriptPath . '" -Path "' . path . '"'

    exitCode := RunWait(command, , "Hide")
    return exitCode = 0 && FileExist(path)
}

RegisterImage(path) {
    global ManifestPath, CounterPath

    next := 1
    if FileExist(CounterPath) {
        try {
            current := Trim(FileRead(CounterPath))
            if IsInteger(current) {
                next := Integer(current) + 1
            }
        }
    }

    label := "image" next

    try FileDelete CounterPath
    try {
        FileAppend next, CounterPath, "UTF-8"
        line := label "`t" path "`t" FormatTime(, "yyyy-MM-dd HH:mm:ss") "`n"
        FileAppend line, ManifestPath, "UTF-8"
    } catch {
        return ""
    }

    return label
}

CleanupOldImages(*) {
    global TempRoot, TtlHours, ManifestPath

    if !DirExist(TempRoot) {
        return
    }

    cutoff := DateAdd(A_Now, -TtlHours, "Hours")
    loop files TempRoot "\*.png", "F" {
        if A_LoopFileTimeModified < cutoff {
            try FileDelete A_LoopFileFullPath
        }
    }

    if FileExist(ManifestPath) {
        PruneManifest()
    }
}

PruneManifest() {
    global ManifestPath

    kept := ""
    try {
        for line in StrSplit(FileRead(ManifestPath), "`n", "`r") {
            if !Trim(line) {
                continue
            }

            parts := StrSplit(line, "`t")
            if parts.Length >= 2 && FileExist(parts[2]) {
                kept .= line "`n"
            }
        }

        FileDelete ManifestPath
        if kept {
            FileAppend kept, ManifestPath, "UTF-8"
        }
    }
}
