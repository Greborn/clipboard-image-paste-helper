---
name: clipboard-image-paste
description: Use when the user wants to paste a Windows clipboard screenshot directly into CLI agents such as Codex, Claude Code, or Hermes, especially after WeChat/QQ screenshot tools put only bitmap data on the clipboard, or when the user's prompt contains image labels like [image1], [image2], or [image3]. Provides a temporary-file bridge and optional Ctrl+V helper for terminal windows.
---

# Clipboard Image Paste

This skill is the optional Codex layer for Clipboard Image Paste Helper. The
actual `Ctrl+V` behavior is provided by the AutoHotkey helper. This skill tells
Codex what to do when it sees compact image labels such as `[image1]`.

The helper handles a Windows limitation: many terminal hosts treat `Ctrl+V` as
text paste only, while WeChat/QQ screenshot completion often places bitmap image
data on the clipboard. The helper saves the clipboard image to a short lived PNG
in `%TEMP%` and pastes a compact label that maps to the temporary file.

## Use Cases

Use this skill when the user says:

- they took a screenshot with WeChat/QQ and cannot paste it into Codex, Claude
  Code, Hermes, or another terminal agent
- pasting through WeChat/QQ chat first makes the screenshot work
- they want direct screenshot paste into a CLI workflow

## Important Constraint

A Codex skill alone cannot intercept global Windows `Ctrl+V` or change how a
terminal host transfers clipboard image formats. For true `Ctrl+V` behavior,
run the AutoHotkey helper in `scripts/terminal-image-paste.ahk`.

If Codex is running inside a remote terminal, the helper may still paste
`[image1]` because that happens locally on Windows. The remote agent can only
read the underlying PNG if it has access to the local temporary file path.

The helper does not keep a permanent screenshot collection. It writes images to:

```text
%TEMP%\cli-clipboard-images
```

and deletes files older than the configured TTL.

## Agent Workflow

When this skill is active and the user's prompt contains labels like
`[image1]`:

1. Run `scripts/resolve-image-label.ps1 -Label image1` to resolve the temporary
   PNG path.
2. Pass the resolved PNG path to the model or CLI command using that CLI's
   normal image/file mechanism.
3. Tell the user the file is temporary and will be cleaned up.

Example PowerShell call:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\resolve-image-label.ps1 -Label image1
```

If `pwsh` is unavailable, use `powershell.exe` instead.

## Direct Ctrl+V Helper

For the user's desired behavior, install AutoHotkey v2 and run:

```powershell
autohotkey.exe .\scripts\terminal-image-paste.ahk
```

While the helper is running:

- In terminal windows, `Ctrl+V` checks whether the clipboard contains an image.
- If yes, it saves a temporary PNG, records a label mapping in
  `%TEMP%\cli-clipboard-images\manifest.tsv`, pastes a short label like
  `[image1]` into the terminal, then restores the original clipboard image.
- If no image is present, it performs normal `Ctrl+V`.

This is intentionally terminal-scoped so normal WeChat/QQ/browser paste behavior
is not changed.

## Notes

- Some CLIs cannot resolve labels automatically. In those cases, use
  `scripts/resolve-image-label.ps1 -Label image1` and pass the resolved path
  with that CLI's normal image/file option.
- For support checks, run `scripts/diagnose.ps1` and inspect AutoHotkey,
  startup, manifest, and recent temporary images.
- This bridge avoids permanent storage, but a terminal CLI still needs some
  local file reference because most terminal protocols do not deliver raw
  clipboard image bytes to the running process.
