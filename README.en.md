# Live a Long Life（长命百岁）

[中文](README.md)

Live a Long Life is a local-first personal health journal. You log what you eat, how you slept, your mood, discomfort and exercise the way you'd send chat messages, and it organizes them into structured records. Medical records, lab reports and exam reports become data you can review and trace back to the original page. A weekly report on your computer helps you see how things change over time.

Your data stays on your own devices. The phone is for recording; the computer handles analysis and archiving. The two sync over your local network with end-to-end encryption. Whether to use a model at all, which provider to use, and whether it runs locally or in the cloud is always your choice.

## Features

### Daily journaling (iPhone)

- **Log like chatting**: send text, several photos or PDFs in a row. Every message is saved immediately and can be edited or deleted, with edit history kept.
- **Daily check-ins**: reminders at times you choose ask only about what's still missing today (breakfast, last night's bedtime, whether you exercised…).
- **Automatic organizing**: a model turns messages into meal, sleep, mood, symptom, exercise and note records. Something you mention a day late ("I forgot to say yesterday…") is filed under the right date. Every record links back to your original words and photos, and fields you corrected are never overwritten.
- **Apple Health**: sleep, steps, workouts and active energy fill in the gaps so you type less. What you tell the app yourself takes priority.
- **Day view** and per-field corrections. Unwanted records can be deleted, optionally together with the messages they came from.
- **Profile** collected gradually (birth month, sex, height, exercise preferences, chronic conditions, allergies…). Every item can be skipped.
- **Export and restore**: export to JSON plus a folder of files with a manifest, and restore from an export, including the records and checkups folders and Q&A history. On Android you can also restore directly from a zip of an export made on another device. After a restore, the next sync prompts you on the Mac home screen to rebuild its copy: once you confirm, the Mac backs up first, then re-receives everything from the phone as the source of truth.

### Medical records and lab reports (iPhone)

- **Records and checkups folders**: take a photo, pick from the photo library or import a PDF; files are listed by visit or checkup date. When a file is extracted, the model gives the visit a short title from the documents (say, "thyroid nodule follow-up"), so the list shows why you went; you can edit the title. Duplicate uploads are flagged, including a re-photographed page or a re-exported image whose bytes differ, recognized by its content.
- **Preview before sending**: text is recognized on-device (Apple Vision; PDFs with a text layer are read directly). Names, ID numbers and clinic card numbers are masked automatically. You see every line that would go to the model, can edit or remove any line, or multi-select lines to remove them in bulk (edits are saved with the file and restored next time), and nothing is sent until you confirm. Long checkup reports are processed in batches automatically. Images are never sent unless you explicitly choose the image fallback below.
- **Model image fallback**: for handwritten, skewed or oddly laid-out reports that on-device recognition gets wrong, you can choose "Recognize with model". Draw a box around the part to read, leaving names and IDs outside it. Only the boxed image goes to a model that supports images, and the crop is discarded after sending.
- **Tidy text with model**: ultrasound and similar reports often split one organ's description and conclusion into two entries, and checkup reports repeat the same finding in the summary and the details. "Tidy with model" sends the extracted diagnosis and report text to the model, which merges entries about the same organ or exam and removes duplicates without rewriting the wording. Only that text is sent, never images. Merged entries need to be reviewed again, and the tidy-up can be undone.
- **Structured extraction**: lab values (item, result, unit, reference range, abnormal flag), diagnosis and report text (chief complaint, diagnosis, treatment advice, ultrasound findings and conclusions…), prescribed medications, and suggested health conditions. The model fixes OCR typos from context and lists every correction for you to check.
- **Health records hub**: one bottom-bar entry gathers the records and checkups folders, long-term conditions, visit timeline, body map, trends, weekly reports and correction suggestions, each marked with how many files await review or extraction; pending suggestions put a badge on the icon.
- **Item-by-item review**: everything extracted starts as "not reviewed" and only counts in analysis once you confirm or correct it. A bar at the top of each file shows review progress and the abnormal count, with filters for unreviewed or abnormal items; abnormal values are bold red, and "confirm all" or a deletion can be undone. Re-extraction and the model-based options sit under "More", each with a line on when to use it. Entries you do not need in the diagnosis and report text, lab results or prescribed medications (an empty remarks field, say) can be deleted one by one. Tapping a value or passage opens the original page, with the exact spot highlighted.
- **Hospital name and exam date**: correct them by hand when OCR gets them wrong or skips them; re-extraction keeps your correction, and trends and health conditions follow the corrected date.
- **Long-term conditions**: kept separate from temporary illnesses. Once marked recovered, a long-term condition reaches weekly reports and consultations only as past history, never as a current illness; recovered temporary illnesses drop out. Follow-ups and recoveries are appended; past diagnoses and the values measured at the time are never rewritten. The same problem found in reports from different years appears as one entry showing the latest report's wording, and the earlier reports' originals can still be opened.
- **Trends and visit timeline**: a search box at the top finds items by name, abbreviation (ALT, HGB), an older spelling or test panel. Each lab item is charted by exam date against its reference range. Different spellings of one item across hospitals and years (for example a lymphocyte ratio versus a lymphocyte percentage) are merged, as are names marked with the "*" some regions add for mutually recognized results, with decimal ratios (hematocrit written as 0.45, too) converted to percentages first. Blood pressure written as one reading, "122/86", is split into systolic and diastolic so it joins reports that list them separately and any re-measurements; unmeasured "-" values are left off the chart. The list is grouped by test panel (complete blood count, urinalysis, chemistry, tumor markers, allergens…); each hospital's name for one panel lands in a single group, and items with no panel are placed by name (blood pressure, blood type, hepatitis B, allergens), so urinalysis items such as white cells, glucose and bilirubin stay apart from same-named blood items and show up on the kidneys and bladder in the body map; for reports extracted earlier, or items a long report left unlabeled when it was sent in batches, the model can fill in the panels from the item names and the panels already known, without the values; symptoms, visits and tests are laid out in order.
- **Body map**: the colored figure in the middle of the home screen's bottom bar. Tap the head and neck, chest, abdomen or pelvis on the full-body view and it zooms in on that area, with organ labels along both sides and leader lines pointing to each organ. The pelvis shows different organs depending on the sex at birth in your profile, and you can switch it from the top-right corner. A label shows how many items need attention, in red when they have been checked and orange when they are waiting to be checked: lab values that were still abnormal the last time they were measured, abnormal findings in report text, unresolved health conditions, and discomfort reported in the last 30 days. Each problem is counted once: when a checkup report lists it in the summary and again in the details, the two are merged, and when reports from different years describe the same problem (fatty liver going from mild to moderate, say), the latest one is used and the earlier wording is listed under "Earlier". Tap a label to see the items; each one opens its original file. Items such as blood lipids, blood glucose and blood counts that don't belong to a single organ go under "Blood and metabolism" below the figure, and anything whose body part can't be recognized goes under "Other".
- **Free up phone storage**: once originals are archived on the Mac, you can remove the phone's copies. Extracted data, review status and source links all stay; originals can be retrieved from the Mac whenever needed.

### Ask a question (iPhone, Mac)

- Ask the model a health question at any time. It starts with your basic profile and confirmed conditions; when it needs specifics, it looks up your records, Apple Health data, lab history and report conclusions on its own (for medical content, only what you have reviewed), then answers from what it found. What it looked up is listed under your question, and everything sent in each round can be seen in the model call log. Turn off "Let the model look up my records" to send only your profile and conditions.
- Conversations never turn into health records, and replies are shown with formatting. The model does not diagnose or prescribe, and says clearly when you should see a doctor.

### Computer (Mac, Windows)

- **Full replica**: every message, record and original synced from the phone, read-only.
- **Weekly report**: a weekly summary with suggestions for the week ahead, generated by the model configured on the Mac. Every factual statement links to its source record. The phone can fetch and show it.
- **Medical records and health profile**: read-only views of the records and checkups folders, long-term conditions, lab trends and visit timeline, alongside the archived originals.
- **Encrypted backups**: built from a file manifest and only marked usable after verification, with restore drills. The backup password lives only in the computer's system-protected storage (the Keychain on Mac; on Windows, encrypted with a key held in Credential Manager).
- **QR pairing**: scan a code shown on the Mac to set up a mutually authenticated, encrypted connection. After that, changes sync incrementally over the local network and resume where they left off. If the Mac's IP address changes, the phone finds it again on the local network (Bonjour) without re-pairing.
- **Stays in the menu bar / system tray**: after you close the main window, the app lives on in the macOS menu bar or the Windows notification area and keeps receiving phone syncs. Its menu shows the latest sync, plus Open and Quit. On Windows only one instance runs, and the installer can optionally start it at sign-in (tray icon only, no window).

## Privacy and data

- **Local first**: data lives in an on-device SQLite database. There is no app server.
- **Sync stays on your network**: the phone and Mac authenticate each other and encrypt everything.
- **Your choice of model**: OpenAI, Anthropic, DeepSeek, Kimi, Zhipu GLM, Ollama (on-device or on your LAN) and any OpenAI-compatible service. Just enter a base URL and key. Each model is labeled with its data boundary (device, LAN, cloud), and the app never falls back to the cloud when a local model is unavailable. If the model can't be reached, your messages are still saved: the chat says the model is currently unavailable, the day view lists that day's messages waiting to be organized, and they are organized automatically once the model is back. API keys are stored only in the system Keychain.
- **See what was sent**: every model call records what was sent, what came back and how many items were masked, viewable under "Model call history".
- **Unreviewed isn't fact**: anything a model inferred stays out of analysis until you confirm it.

## Platforms

| Platform | Status |
|---|---|
| iPhone | Available, the main recording device |
| Mac | Available, for analysis, archiving and backups |
| Android | In progress: the phone app installs and runs; on-device verification under way (Xiaomi 12) |
| Windows | In progress: the computer replica, tray and local-network announcement work on the test PC; pairing with a phone not yet verified |

The app is currently installed with a free developer signature, which must be renewed every 7 days (see below).

## Build and run

Requires Flutter 3.38 or later (Dart 3.10), Xcode, and an Apple developer account (a free one works).

```bash
cd app
flutter pub get
dart run build_runner build --force-jit --delete-conflicting-outputs  # generate database code
flutter test                                                           # run the tests
```

**Install on iPhone**: with the phone connected, run `./scripts/resign-install.sh`. It builds, signs and installs over the existing app, keeping your data. Don't use `flutter install`, which uninstalls the app first and wipes its data. Run the script again before the signature expires to renew it.

**Run on Mac**:

```bash
cd app
flutter build macos --debug
open build/macos/Build/Products/Debug/live_a_long_life.app
```

To pair the first time, show the QR code under Settings → Phone connection on the Mac and scan it from Settings → Connect Mac on the phone.

**Run on Windows**: on Windows, `cd app && flutter run -d windows`. Building the installer needs the Visual Studio C++ tools and Inno Setup 6.5+; run `./scripts/windows-package.sh` from Git Bash and find the setup in `app/build/windows/installer/`. It installs per user without admin rights, and upgrading or uninstalling leaves your data alone. While an installed copy is running in the tray, launching again (including `flutter run`) only brings back its window, so quit it from the tray before debugging.

**Troubleshooting**: if installation fails with an invalid framework signature, or the app opens to a blank screen, native build caches are usually stale. Run `flutter clean` in `app/` and build again.

## Project layout

```
app/                 Flutter app (one codebase for iPhone, Android, Mac and Windows)
  lib/data/          database tables, repositories, time and field metadata
  lib/services/      organizing, extraction, masking, sync, backup, analysis, Q&A
  lib/ui/            screens
  ios/ macos/        platform projects (Apple Vision text recognition lives here)
  android/           Android project (ML Kit text recognition, LAN discovery)
  windows/           Windows project (system tray, local-network announcement)
  test/              unit and widget tests
docs/                requirements, design decisions, data model, product spec, prompts, platform verification
scripts/             one-step re-sign and install script, Windows packaging script, body-map image cutout script
```

Design documents start at [docs/README.md](docs/README.md) (in Chinese). Every prompt sent to a model is listed in [docs/prompts.md](docs/prompts.md).

## Disclaimer

Live a Long Life is for personal health journaling and long-term trend analysis. It does not provide medical diagnosis. Always follow your doctor's advice on health matters.
