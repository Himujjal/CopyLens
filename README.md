# CopyLens

A macOS menu-bar app that copies text you can see but can't select: press a hotkey,
drag a region of the screen, and the on-device OCR result lands in your clipboard.
It also keeps a local clipboard history.

**This is an independent reimplementation (clone) of [Letra](https://getletra.app/),**
built for learning and personal use. It uses a distinct name, icon, and copy per the
legal note in the plan. All credit for the original product concept and design goes to
the Letra team.

## Stack

- Swift + SwiftUI + AppKit, macOS 14+
- Apple Vision (`VNRecognizeTextRequest`) for on-device, multi-language OCR
- `NSPasteboard` for the clipboard
- JSON-file history store in Application Support
- Carbon global hotkey (`⇧⌘2`) and a transparent drag-to-select overlay (upcoming)

## Layout

```
Sources/CopyLens/
  App/        App entry, NSApplicationDelegate, shared AppState
  Models/     CaptureItem, Settings
  Services/   OCR, clipboard, history, text assembly
  UI/         Menu bar history list, settings, toast
Tests/CopyLensTests/
Scripts/bundle.sh   Assembles the .app bundle
```

## Build & run

```sh
mise run build     # swift build -c release
mise run run       # bundle + open CopyLens.app
```

Or with raw commands:

```sh
swift build
swift test
./Scripts/bundle.sh
open build/release/CopyLens.app
```

## Create a DMG for distribution

```sh
./Scripts/create-dmg.sh
```

This produces `build/release/CopyLens.dmg` — a ready-to-distribute disk image.

## Quality gates

```sh
mise run fmt       # swift-format format (in place)
mise run lint      # swift-format lint
mise run test      # swift test
mise run check     # swift build -Xswiftc -warnings-as-errors
```

## Status

- [x] M0 — scaffold, data model, history store, menu-bar UI, settings, tests
- [x] M1 — global hotkey (⇧⌘2), overlay selection, screen capture, permission flow
- [x] M2 — OCR + clipboard end to end (wired; manual QA pending)
- [ ] M3 — history polish (search, ⌘1–9 quick slots, thumbnails)
- [ ] M4 — settings persistence, launch at login, auto-paste
- [ ] M5 — full test/QA pass

## License

MIT — see `LICENSE` for details. This project is not affiliated with, endorsed by, or
connected to the original Letra product or its creators.