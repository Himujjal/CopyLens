# Plan — Clone "Letra" (macOS screen-text capture + clipboard app)

Source: `UvsgCwDuTDC9zZCj.mp4` (32.7s product ad).

## 1. What the product is

**Letra** is a macOS menu-bar app that lets you copy text you can *see* but can't *select*:
select a region of the screen, the app runs on-device OCR, and the recognized text lands in
your clipboard. It also keeps a local clipboard history so you can re-copy anything later.

Product site referenced in the video: **getletra.app**.

## 2. Audio transcript (verbatim)

> Ever notice how much text you can see, but can't copy?
> Like a link on a co-worker's screen share, or a command in a recording.
> Shift-Command-2, and it's in terminal.
> Notes from a course.
> An error that won't copy.
> A lunch receipt.
> Words stuck in a design.
> A menu in Japanese.
> An address in a photo.
> Eight copies. Zero retyping.
> All saved on your Mac.
> Letra.
> Get it now at getletra.app.

## 3. Feature inventory (mapped to the video scenes)

| # | Scene in video | Feature |
|---|----------------|---------|
| 1 | "Link on a co-worker's screen share" | OCR text from any visible screen content (screen share, video call) |
| 2 | "A command in a recording" → `~/northwind $ git pull` | OCR text from video/images; paste into terminal |
| 3 | "Shift-Command-2, and it's in terminal" | Global hotkey (`⇧⌘2`) triggers capture → auto-copies to clipboard |
| 4 | "Notes from a course" ("Three rules for clean APIs") | OCR from documents/notes; multi-line text preserved |
| 5 | "An error that won't copy" ("Northwind Sync" couldn't connect) | OCR from modal/error dialogs |
| 6 | "A lunch receipt" (Café LINDE Zürich) | OCR from photos/receipts; structured-ish text (lines/amounts) |
| 7 | "Words stuck in a design" ("Hero copy", Figma-like UI) | OCR from design tools / images |
| 8 | "A menu in Japanese" (ramen prices ¥980 / ¥1,050 / ¥480) | Multi-language OCR (Japanese + English + more) |
| 9 | "An address in a photo" (Riedstrasse 7) | OCR from a photo of an address |
| 10 | "Eight copies. Zero retyping." | Clipboard history (list of recent captures), one-click re-copy |
| 11 | "All saved on your Mac." | Local-only storage; on-device OCR; no cloud (privacy) |
| 12 | Menu-bar icon + "Copied" toast | Menu-bar app with capture confirmation HUD |

## 4. Non-goals (v1)

- No cloud sync / account system (the product explicitly sells "all saved on your Mac").
- No full-screen video recording; we capture a single still region per hotkey press.
- No PDF/image export; we output **text** to the clipboard (and history).
- No cross-platform (Windows/Linux) in v1.

## 5. Tech stack recommendation

**Primary: Swift + SwiftUI + AppKit, Xcode 15+, macOS 13+ (Ventura).**

Rationale:
- **Apple Vision** (`VNRecognizeTextRequest`) gives best-in-class on-device, multi-language OCR
  (English, Japanese, and ~18 languages) with zero cost and no network.
- **ScreenCaptureKit** (`SCScreenshotManager` / `SCStream`) is the supported, permission-aware
  way to capture the screen on modern macOS.
- **`NSPasteboard`** for clipboard, **`MenuBarExtra` / `NSStatusItem`** for the menu-bar UI,
  **Carbon `RegisterEventHotKey`** or `NSEvent` global monitor for the global hotkey.
- Native is the only realistic path to a polished menu-bar OCR tool.

Alternatives (not recommended for v1):
- **Tauri (Rust) + TS web UI**: fine for the shell, but OCR and screen capture still require a
  Swift/Obj-C bridge to Vision/ScreenCaptureKit. More moving parts for weaker OCR.
- **Electron + Tesseract**: Tesseract's on-device multi-language quality is markedly worse than
  Vision, and packaging is heavier.
- **Rust/Zig core**: no first-class Vision bindings; would need FFI to Obj-C. Skip for v1.

## 6. Architecture

```text
Letra.app
├── App (menu-bar lifecycle, permissions gate, launch-at-login)
├── HotkeyManager        — registers global ⇧⌘2 (configurable)
├── CaptureService       — ScreenCaptureKit region capture + overlay orchestration
├── OverlayWindow        — transparent full-screen selection overlay (drag-to-select)
├── OCRService           — Vision VNRecognizeTextRequest, language set, text assembly
├── ClipboardService     — writes recognized text to NSPasteboard + fires "Copied" HUD
├── HistoryStore         — persists captured items (SwiftData / SQLite)
├── MenuBarView          — history list, search, re-copy, delete, settings entry
├── SettingsView         — hotkey, OCR languages, history limit, launch at login, auto-paste
└── Toast/HUD            — transient "Copied" confirmation
```

### Key flows

1. **Capture flow**: global hotkey → `HotkeyManager` → `CaptureService` shows `OverlayWindow` →
   user drags a region → `SCScreenshotManager.captureImage` (or `SCStream` frame) → `OCRService`
   recognizes text → `ClipboardService` copies → toast "Copied" → item appended to `HistoryStore`.
2. **History flow**: click menu-bar icon → `MenuBarView` lists recent captures (text preview +
   source thumbnail) → click to re-copy → keyboard shortcuts (return to copy, ⌫ to delete,
   ⌘1–9 for quick slots).
3. **Permissions flow**: first launch → explain + request **Screen Recording** permission
   (required for screen capture) and optionally **Accessibility** (only if we add auto-paste).
   Re-check state with `CGPreflightScreenCaptureAccess()` / `CGRequestScreenCaptureAccess()`.

## 7. Data model

```text
CaptureItem
  id: UUID
  text: String              // recognized, line breaks preserved
  createdAt: Date
  languages: [String]       // detected/source languages used
  imageThumbnail: Data?     // small PNG of the captured region (optional)
  appSource: String?        // frontmost app at capture time (optional, nice-to-have)
```

Persistence: SwiftData or SQLite. Cap history length (default e.g. 100 items, configurable).
Optionally redact/exclude items on quit (privacy).

## 8. Implementation notes

- **Hotkey**: default `⇧⌘2`. Use Carbon `RegisterEventHotKey` for a true global hotkey (works even
  when the app isn't frontmost); fall back to `NSEvent.addGlobalMonitorForEvents` for the mask.
- **OCR**: `VNRecognizeTextRequest` with `recognitionLevel = .accurate`,
  `usesLanguageCorrection = true`, `recognitionLanguages` from Settings (default
  `["en-US", "ja-JP"]`). Sort observations top-to-bottom, left-to-right; join lines by vertical
  grouping to preserve multi-line text.
- **Capture**: `SCScreenshotManager.captureImage(contentFilter:configuration:)` is the simplest
  modern API; alternatively `CGWindowListCreateImage` for broad compatibility. Strip the overlay
  from the capture so the selection box isn't OCR'd.
- **Clipboard**: write via `NSPasteboard.general.clearContents()` + `setString`. Keep a
  "capture-succeeded" transient state for the HUD; do not spam the pasteboard history on every
  OCR (only on actual captures).
- **Menu bar**: `MenuBarExtra` (SwiftUI) for the dropdown; an `NSStatusItem` for the icon/left-click
  behavior and the "Copied" toast window.

## 9. Milestones

### M0 — Scaffold
- Xcode macOS app project, SwiftUI + AppKit bridging, `MenuBarExtra` showing a placeholder list.
- Decide persistence (SwiftData vs SQLite) and wire the `CaptureItem` model.

### M1 — Capture + overlay
- Global hotkey ⇧⌘2 registers and fires.
- Transparent full-screen `OverlayWindow` with dim + crosshair + drag-to-select region.
- Screen Recording permission request flow + state check.
- ScreenCaptureKit capture of the selected region → save temp image.

### M2 — OCR + clipboard
- `OCRService` using Vision; multi-language support.
- Correct line ordering/assembly for multi-line text.
- Copy result to `NSPasteboard`; show "Copied" toast.
- Verify against the video's scenarios: terminal commands, course notes, error dialog,
  receipt, Japanese menu, photo address.

### M3 — History
- `HistoryStore` persistence; menu-bar list with preview + thumbnail.
- Re-copy on click, delete item, clear-all, search/filter.
- Quick slots ⌘1–9 (maps to "eight copies" framing).

### M4 — Settings & polish
- Settings: hotkey rebinding, OCR languages, history limit, launch-at-login (`SMAppService`),
  auto-paste (optional, needs Accessibility permission).
- Empty/error states, permission-revoked handling, menu-bar icon.
- App icon, onboarding tooltip on first run.

### M5 — Quality gates
- Unit tests: OCR line assembly, history store CRUD, hotkey parsing.
- UI tests: capture flow smoke test (using a test fixture image region).
- Manual QA checklist across the video's eight scenarios.
- Run project quality gates (`fmt`, `lint`, `test`, `check` equivalents — for Swift:
  `swift-format`, `swiftlint`, `swift test`).

## 10. Risks / open questions

- **Screen Recording permission** is mandatory and is the most common point of failure; need a
  clear first-run explainer and a "grant permission" deep-link into System Settings.
- **OCR accuracy on stylized/design text and small text** — use `.accurate` level and allow the
  user to add languages; consider a post-capture "edit before copy" affordance if needed.
- **Auto-paste** (not in the video) requires Accessibility permission; keep optional in v1.
- **Menu bar item UX**: decide left-click (open history) vs the hotkey (capture) mapping clearly.

## 11. Legal note

`Letra` / `getletra.app` is an existing commercial product. This plan clones the *functionality*
and UX for learning/internal use. Do not reuse the name, logo, website copy, or marketing assets.
Use a distinct working name, icon, and tagline in any public or distributed build.
