# Clipboard Image Paste Helper

Paste WeChat/QQ Windows screenshots into terminal-based agents with `Ctrl+V`,
and save copied browser images directly into Windows Explorer folders.

This project is primarily a Windows helper, not just a Codex skill.

The helper bridges a Windows clipboard limitation: terminal hosts generally paste
text, while screenshot tools often place bitmap data on the clipboard. When the
clipboard contains an image and the active window is a terminal, the helper saves
a short-lived PNG under `%TEMP%\cli-clipboard-images`, records a label mapping,
and pastes a compact token such as:

```text
[image1]
```

The bundled Codex skill is optional. It teaches Codex how to resolve labels like
`[image1]` to the temporary PNG path when Codex can access the local Windows
filesystem.

## What Each Part Does

- `scripts/terminal-image-paste.ahk`: the core helper. It intercepts `Ctrl+V`
  in terminal windows and inserts `[imageN]`. In Windows Explorer folders, it
  saves clipboard images as PNG files.
- `scripts/save-clipboard-image.ps1`: saves the current clipboard image as PNG.
- `scripts/resolve-image-label.ps1`: resolves `[imageN]` to a PNG path through
  `%TEMP%\cli-clipboard-images\manifest.tsv`.
- `SKILL.md`: optional Codex instructions for resolving image labels.

Remote terminal note: if Codex runs on a remote Linux server inside Cursor, the
helper can still paste `[image1]` because the hotkey runs on your local Windows
desktop. The remote agent may not be able to read the PNG unless the local file
is also available to that remote environment.

## Install

Install AutoHotkey v2:

```powershell
winget install AutoHotkey.AutoHotkey --accept-package-agreements --accept-source-agreements
```

Start the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-terminal-helper.ps1
```

Start it now and enable Windows startup:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-terminal-helper.ps1 -Startup
```

## Use

Terminal agents:

1. Take a screenshot with WeChat or QQ and click the confirm checkmark.
2. Focus Codex, Claude Code, Hermes, or another terminal agent.
3. Press `Ctrl+V`.
4. The terminal receives `[image1]`, `[image2]`, etc.

Windows Explorer:

1. Copy an image from Chrome or another app.
2. Focus a File Explorer folder.
3. Press `Ctrl+V`.
4. The helper creates `clipboard-image-yyyyMMdd-HHmmss.png` in that folder.

## Diagnose

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\diagnose.ps1
```

## Temporary Files

Images are written to:

```text
%TEMP%\cli-clipboard-images
```

The helper checks every 10 minutes and deletes PNG files older than 6 hours.
The manifest is pruned when images are removed.

Explorer-saved images are real files in the folder you pasted into. They are not
temporary files and are not deleted by the helper.

## Tuning

Edit `scripts/terminal-image-paste.ahk`:

```ahk
TtlHours := 6
PasteTemplate := "[{label}]"
```

Use a shorter TTL if you want more aggressive cleanup.

## Acknowledgements

- Thanks to the [Linux.do](https://linux.do/) community for feedback and
  discussion.
