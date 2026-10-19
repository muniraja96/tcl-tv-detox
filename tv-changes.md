# TCL 32S5500 cleanup log

TV: TCL 32S5500 (Android TV 11, Google TV home), IP 192.168.29.162
adb: `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`

## Baseline (2026-10-18, before any change)

- Total memory: 1,463,160 kB (~1.4 GB)
- Available memory: 625,480 kB (~611 MB, 43%)
- Storage /data: 7.1 GB free of 10 GB
- Disabled apps: none

## After restart (2026-10-18 23:13)

- Available memory: 835,696 kB (~816 MB, 57%), up from ~611 MB (+~205 MB)
- Home button opens the tv-detox home screen
- All settings stayed changed after the restart
- The TV turned TCL User Center (`com.tcl.usercenter`) and TCL Smart Alexa (`com.tcl.smartalexa`) back on during the restart

## HDMI tile fix (2026-10-18 23:26)

The original tv-detox home screen sent its HDMI tiles to Android's stock Live TV app (`com.android.tv`). This TCL doesn't have that app, so pressing a tile did nothing. The fixed build sends a plain "open this input" request, which TCL's own TV app (`com.tcl.tv`) handles. I tested the HDMI 2 tile and it showed the Fire TV Stick.

- Source and build script: `tvhome-build\` (the change is in `MainActivity.java`, in `open()`)
- Rebuild with `powershell -File "D:\TV backup\tvhome-build\build.ps1"` (uses build-tools 30.0.2, android-30 and JDK 14)
- `tvhome-build\key.jks` signs the app. Keep it: updates must be signed with the same key. If you lose it, uninstall the app before reinstalling.

## Undo everything

1. Run `sh undo.sh 192.168.29.162` from tv-detox, or run these commands:
   ```
   adb -s 192.168.29.162:5555 shell pm enable com.google.android.apps.tv.launcherx
   adb -s 192.168.29.162:5555 shell pm enable com.google.android.tungsten.setupwraith
   adb -s 192.168.29.162:5555 shell pm enable com.google.android.videos
   adb -s 192.168.29.162:5555 uninstall com.ansub.tvhome
   ```
2. Run `pm enable` for each package in the tables below.
3. Put each setting back to its "Old" value.

Without a computer: on the TV, go to **Settings → Apps → See all apps → Show system apps**, pick an app, then choose **Enable**. Animations are under Developer options, and screensaver and sleep are under **Settings → System**.

## Changes

Each change below gets its undo command (run from PowerShell; `adb` = the path above).

| # | What changed | Undo command |
|---|--------------|--------------|
| 1 | Disabled Google voice search (`com.google.android.katniss`) | `adb -s 192.168.29.162:5555 shell pm enable com.google.android.katniss` |
| 2 | Disabled Google Assistant (`com.google.android.tv.assistant`) | `adb -s 192.168.29.162:5555 shell pm enable com.google.android.tv.assistant` |
| 3 | Installed tv-detox home screen (`com.ansub.tvhome` 1.0.1) with Netflix, YouTube, JioHotstar, set as preferred home | `adb -s 192.168.29.162:5555 uninstall com.ansub.tvhome` |
| 4 | Disabled Google TV home (`com.google.android.apps.tv.launcherx`) | `adb -s 192.168.29.162:5555 shell pm enable com.google.android.apps.tv.launcherx` |
| 5 | Disabled Google TV app (`com.google.android.videos`) | `adb -s 192.168.29.162:5555 shell pm enable com.google.android.videos` |
| 3b | Replaced change 3 with the HDMI-fixed build (signed with `tvhome-build\key.jks`), same apps, set as home again | `adb -s 192.168.29.162:5555 uninstall com.ansub.tvhome` |

Changes 4 and 5 are also listed in `/data/local/tmp/tvhome-disabled.txt` on the TV, so tv-detox's `undo.sh` turns them back on.

### Apps turned off (changes 6–24)

Undo any one with `adb -s 192.168.29.162:5555 shell pm enable <package>`.

| # | App | Package |
|---|-----|---------|
| 6 | Prime Video | `com.amazon.amazonvideo.livingroom` |
| 7 | SonyLIV | `com.sonyliv` |
| 8 | ZEE5 | `com.graymatrix.did` |
| 9 | JioTV+ | `com.jio.media.jiotvplus` |
| 10 | MUBI | `com.mubi` |
| 11 | Apple TV | `com.apple.atve.androidtv.appletv` |
| 12 | TCL Stickers | `com.tcl.esticker` |
| 13 | TCL Hotel Menu | `com.tcl.hotelmenu` |
| 14 | TCL Channel / home feed | `com.tcl.waterfall.overseas` |
| 15 | TCL Message Box | `com.tcl.messagebox` |
| 16 | TCL User Center | `com.tcl.usercenter` |
| 17 | TCL Smart Alexa | `com.tcl.smartalexa` |
| 18 | TCL Copy Data to TV | `com.tcl.copydatatotv` |
| 19 | YouTube Music | `com.google.android.youtube.tvmusic` |
| 20 | Google Play Games | `com.google.android.play.games` |
| 21 | Google Feedback | `com.google.android.feedback` |
| 22 | Print Spooler | `com.android.printspooler` |
| 23 | TalkBack | `com.google.android.marvin.talkback` |
| 24 | Google screensaver | `com.google.android.apps.tv.dreamx` |
| 25 | Google TV setup-recovery (`setupwraith`). Also in `tvhome-disabled.txt` | `com.google.android.tungsten.setupwraith` |

### Settings (changes 26–33)

Undo with `adb -s 192.168.29.162:5555 shell settings put <namespace> <name> <old value>`. Use `settings delete` where the old value was `null`.

| # | Setting | Old | New |
|---|---------|-----|-----|
| 26 | `global window_animation_scale` | 1.0 | 0 |
| 27 | `global transition_animation_scale` | 1.0 | 0 |
| 28 | `global animator_duration_scale` | null (delete) | 0 |
| 29 | `secure screensaver_enabled` | 1 | 0 |
| 30 | `secure screensaver_activate_on_sleep` | 1 | 0 |
| 31 | `secure screensaver_activate_on_dock` | 1 | 0 |
| 32 | `secure sleep_timeout` (sleep after) | -1 (never) | 300000 (5 min) |
| 33 | `system screen_off_timeout` | 600000 (10 min) | 300000 (5 min) |
| 34 | Auto-sleep turned off (replaces 32): `secure sleep_timeout` | 300000 | -1 (never) |
| 35 | Screen-off turned off (replaces 33): `system screen_off_timeout` | 300000 | 2147483647 (never) |

Original factory values to restore: `sleep_timeout` -1, `screen_off_timeout` 600000.

| # | Setting | Old | New | What it does |
|---|---------|-----|-----|--------------|
| 36 | `system standby_save_bootsource` | 0 | 1 | TCL: turn on to the last input used |
| 37 | `global hdmi_control_enabled` | 0 | 1 | HDMI-CEC on. TV sees "Fire TV Stick" on HDMI 2 |
| 38 | `global hdmi_control_auto_wakeup_enabled` | 0 | 1 | Fire TV remote can turn the TV on |

`hdmi_control_auto_device_off_enabled` stays 0, so turning the TV off doesn't turn the Fire TV Stick off.

### Picture on HDMI 2 (Fire TV Stick), changed through the TV's own menus

| # | Setting | Old | New | Where to undo |
|---|---------|-----|-----|---------------|
| 39 | Dynamic Color | On | Off | Settings → Display and sound → Picture → Advanced settings → Colour → Dynamic Color |
| 40 | Colour space (you set it by hand) | Native | Auto | Settings → Display and sound → Picture → Advanced settings → Expert calibration → Colour space |

| 41 | Fire TV Stick: Dynamic Range Settings (changed on the Fire TV, not the TCL) | (previous value not recorded) | Adaptive | Fire TV Settings → Display & Sounds → Display → Dynamic Range Settings |

Picture preset stayed **Standard**. The Fire TV's Dynamic Range setting is what fixed the over-strong colours.

Other values I read and left alone: Picture preset Standard, Brightness 100, Colour saturation 50, Tint 50, Contrast 90, Black level 50, Dynamic contrast Low.
