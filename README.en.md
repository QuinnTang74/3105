<p align="center">
  <img src="docs/images/app-icon.png" width="120" alt="3106">
</p>

<h1 align="center">3106</h1>

<p align="center">
  A no-jailbreak iOS container manager: app data, patches, cleaning, wallpapers, and dialer themes.
</p>

<p align="center">
  <a href="README.md">简体中文</a> ·
  <a href="CHANGELOG.md">Changelog</a> ·
  <a href="docs/PATCH_GUIDE.md">Patch guide</a>
</p>

## Project

| Item | Value |
| --- | --- |
| Version | **3.1.13** (stable) |
| Current release | **v3.1.13** (build 17, feature hub, fast catalog, backup center, device customization and file tools) |
| Supported systems | iOS 17.0–18.7.1 · 26.0–26.7.2 · 27.0–27.2.1 · 27.3 beta 1 (experimental) |
| Access backend | kernel / `bad_query` / `worse_query` |
| UI languages | Simplified Chinese · English · Vietnamese |
| Signing | iOS 26.7+ / 27.x requires an App Group entitlement |
| Bundle ID | `com.qingtang.3106` |
| Repository | <https://github.com/QuinnTang74/3106.git> |

## Features

| Module | Description |
| --- | --- |
| App data browser | App containers, App Groups, extension data, internal daemons; iOS 27 can list System Data and some System Groups |
| Patch manager | Exports `.3106`, imports legacy `.3105`; multi-target, user inputs, optional password, rollback |
| Cleaner | Per-app `Library/Caches` and `tmp` cleanup, plus crash/diagnostic log cleanup |
| Backup center | Immutable originals, per-write versions, manual backups, restore and unfinished-transaction recovery |
| Fast catalog | App Data and Cleaner read lsd's database directly with a persisted compact cache; filesystem scan only as fallback |
| Scan control | Progress, ETA, hide/stop and background time; `pathleak` fallback enumeration |
| Maintenance | App Group launch alert, acknowledgements/license page, WebKit respring |
| Device customization | Safe MobileGestalt subset with original/version backups; keypad theme with backup/restore |
| File tools | Read-only SQLite viewer, hex viewer/overwrite, structured plist editor, file info and swipe-to-delete |
| Wallpapers and themes | `.tendies` PosterBoard wallpapers; keypad themes live under Device Customization |
| Feature hub | Local home page with patches, market, app data, cleaner, wallpapers, backups and logs |
| Fixed tab bar | Features / Files / Search / Cleaner / Wallpapers |
| Localization | Simplified Chinese, English, Vietnamese |

## Recent changes

| Version | Highlights |
| --- | --- |
| **3.1.13** | Stable: feature hub + fixed five tabs; LaunchServices fast catalog; backup center and verified writes; scan progress/stop; App Group alert, acknowledgements, respring; safe MobileGestalt subset, keypad theme; SQLite/hex/plist tools; per-target patch grants |
| **3.1.12** | Stable: wallpaper import/scan, update prompt, and Cleaner-to-Files stutter fixes; includes all 3.1.8–3.1.11 fixes |
| **3.1.11** | Test build: collect descriptors from the same successful tree enumeration; add import stage logs and a launch version banner |
| **3.1.10** | Test build: fix `isContained` `/var` vs `/private/var` after `.tendies` extraction; find device descriptors with an enumerator first |
| **3.1.9** | Test build: force `/private/var` for wallpaper scans; ZIP GB18030 names, backslash paths, duplicate dirs and 768 MB video entries; reuse LS/filesystem caches and skip redundant MHA scanning |
| **3.1.8** | Fix update prompt on the latest build, cleaner freeze when switching tabs, wallpaper `/var` path scan, and add import error details |
| **3.1.7** | Wallpaper: fix iOS 27.3 layout scan, Mercury folder names, video descriptor mapping, loose descriptor packages; cleaner updates per app with a loaded count |
| **3.1.6** | Folder favorites: long-press to favorite, favorite paths listed inline at the top of the file tab page, compatible with 3105 2.0 data |
| **3.1.5** | App data browser shows every container again: MHA guard removed, LaunchServices `bdsl` parser, unidentified containers in a read-only section |
| **3.1.4-r2** | Project URL moved to **QuinnTang74/3106**; in-app GitHub link, update checker, and README updated |
| **3.1.4** | Cleaner deletion uses the scanned container path; `FileManager` removal refuses symlinks escaping the container |
| 3.1.3 | Wallpaper scanner supports nested/non-standard iOS 27.3 PosterBoard layouts and creates required descriptors directories |
| 3.1.2 | Cleaner measurement via `FileManager`; PosterBoard resolved by scanning the poster store; Settings gear always visible on Cleaner |
| 3.1.1 | Filesystem app enumeration and container-index fallback; per-path grants for wallpaper scan/probe/install/reset |
| 3.1.0 | Configurable tab bar, Developer Mode default on, promotion/credits removed, Chinese-first README |

See [CHANGELOG.md](CHANGELOG.md) for the full history.

## 3.1.13 in detail

### Home and navigation

- The home page is now a local feature hub; it never loads the remote repository feed on launch.
- The bottom bar is fixed to **Features / Files / Search / Cleaner / Wallpapers**.
- Market, sources, patch projects, backup center, acknowledgements and respring live inside the hub.

### Loading and scanning

- App Data and the Cleaner build their lists directly from lsd's LaunchServices database instead of a 6–13 second inode scan.
- The store path and a compact catalog are persisted; later launches read the cache and rebuild only when the store changes.
- First-run catalog discovery runs in parallel with API/MCM enrichment; MHA candidates are skipped when the catalog is complete.
- Long scans show progress, ETA, hide and stop, and request background time.
- The filesystem fallback uses `pathleak` (fsgetpath), reports progress every 4096 inodes and responds to cancellation.

### Backup and safe writes

- Backup Center keeps immutable originals, per-write versions and manual restore points.
- A journal is written before mutation; unfinished transactions are offered for recovery on launch; a failed backup aborts the write.
- `VerifiedFileWriter` writes in place, keeps the inode/xattrs, verifies SHA-256 on read-back and rolls back on failure.
- Patches, file delete/replace, plist/hex saves, MobileGestalt and keypad themes all use it.
- Backup data is excluded from system backup and the cleaner; originals cannot be deleted; versions default to 20 per target / 30 days.
- The cleaner can also measure and remove crash/diagnostic logs under CrashReporter.

### Device customization

- Safe MobileGestalt subset: device name, Device Subtype, Dynamic Island, AOD/AOD Vibrancy, 80% charge limit and boot chime.
- Read-only load, original/version backups, read-back verification, automatic rollback and one-tap restore.
- Keypad theme: 12 key images, per-file backup and restore-original.
- Both features only touch files explicitly selected by the user.

### File tools

- Read-only SQLite viewer: tables/views, row counts, rows, read-only SQL and CSV, on a private copy including `-wal`.
- Hex viewer/overwrite: paging, offset jump, hex/text search, same-length overwrite; edits limited to 64 MB.
- Structured plist editor: root dictionary, container navigation, typed leaf editing and add/delete.
- File info, swipe-to-delete and Open As (Plist/SQLite/Hex).
- Every save goes through `VerifiedFileWriter` and is backed up first.

### Maintenance and compliance

- App Group launch alert: an explicit App ID with App Groups is required; wildcard profiles do not work.
- Acknowledgements/license page for WQ Files, Erosion, worse_query and 3105.
- WebKit respring, with an automatic fallback dismissal if the method is unavailable.
- All new strings are localized in Simplified Chinese, English and Vietnamese.

### Exploit hardening and compatibility

- Each patch target's own folder is granted before writing, not just the container root.
- worse_query remembers the working query flags per device and retries the other set when a token does not open the target.
- iOS 27.2.1 is explicitly covered; 27.3 beta 1 remains experimental.
- Policy/unit tests: 76 checks covering the version matrix, catalog cache, backup/restore and journals.

### Upgrade and asset

- Install over the previous version; favorites, patches, wallpapers and backups are preserved.
- The first log line should read `3106 3.1.13 (17) launching`.
- Asset: `dist/3106-3.1.13-unsigned.ipa` (SHA256 `00ea0503fc27c0a98d7d6c6e045c275143acc8b739ccb15c4932b4a52aaecd15`).

### Known limitations

- A–Z index, app sorting by size, whole-app backup, Supervision/Config tweaks are not implemented.
- `pathleak` start-inode persistence and the pre-scan “file count + estimate” confirmation are not implemented.
- Plist nested-container additions currently create empty string leaves only; hex editing is limited to 64 MB.
- MobileGestalt, keypad themes, SQLite runtime loading and respring should be validated on a test device first.

## Compatibility

| System | Verified range | Backend |
| --- | --- | --- |
| iOS 17 | 17.0–17.7.x | kernel chain |
| iOS 18 | 18.0–18.7.1 | kernel chain |
| iOS 26 | 26.0–26.6.1 | `bad_query` |
| iOS 26 | 26.7–26.7.2 | `worse_query` |
| iOS 27 | 27.0–27.2.1 | `worse_query` |
| iOS 27 | 27.3 beta 1 (`24C5037i`) | `worse_query` (experimental) |

> iOS 17/18 still uses the manual kernel chain; iOS 26/27 does not use a kernel exploit. System Data is listing-only on iOS 27.

## Installation and signing

| Signing method | App Group | Notes |
| --- | --- | --- |
| AltStore / SideStore / Sideloadly with an Apple ID | Created automatically | Recommended; a free Apple ID works |
| Own developer account | Explicit App ID with App Groups | Create a dedicated profile |
| Certificate (`.p12`) + wildcard profile | Not supported | `worse_query` reports “No App Group” |
| LiveContainer | Depends on the signing environment | Check **Settings → App Group** |

With a certificate and provisioning profile, the profile must be an explicit App ID with the **App Groups** capability. Wildcard profiles cannot carry an App Group.

## Build and test

| Task | Command |
| --- | --- |
| Unsigned build | `xcodebuild -project ThreeOneOSSix.xcodeproj -scheme 3106 -configuration Release -sdk iphoneos CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" build` |
| Policy tests | `bash Tests/run_policy_tests.sh` |
| Output | `dist/`, this release is `3106-3.1.13-unsigned.ipa` |

## Download

Stable releases are published on GitHub Releases:

<https://github.com/QuinnTang74/3106/releases>

The release asset is an unsigned IPA; sign it with one of the methods above before installing.

Current asset: `3106-3.1.13-unsigned.ipa` (SHA256 `00ea0503fc27c0a98d7d6c6e045c275143acc8b739ccb15c4932b4a52aaecd15`).

## License and commercial use

This repository is distributed under the **GNU GPL v3.0**; the full text is in [LICENSE](LICENSE).

The project contains GPL-3.0 code from 3105, `worse_query`, WQ Files, and others. GPL-3.0 does not permit an additional “non-commercial” restriction, so the combined work cannot be relicensed as a strictly non-commercial project.

The author does not want this project used commercially. For commercial use, please contact the repository author first. This sentence states the author's preference; it is not an additional restriction on GPL-3.0 and does not change the licenses of upstream or third-party code.

When modifying or redistributing, you must keep the copyright, origin, and license notices in [LICENSE](LICENSE) and [NOTICE.md](NOTICE.md), and state what you changed. This is required by GPL-3.0 and by this project.

## Reference

This project references and is based on the **3105 project** (original author YangJiii) 2.0 source; the iOS 27 adaptation, `worse_query` port, cleaner and wallpaper fixes, and the 3106 rename were built on top of it. Third-party copyright and origin notices are in [NOTICE.md](NOTICE.md) (required by GPL-3.0, not promotional content).