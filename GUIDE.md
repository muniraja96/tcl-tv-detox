# Step-by-step guide

How to clean up a TCL (or similar) Android TV / Google TV from a Windows PC, the way I did on my TCL 32S5500 (Android TV 11, Google TV home).

You can do it in two ways:

- **With Claude Code (easiest):** do steps 1–2 below, then paste the prompt in [Option A](#option-a-let-claude-code-do-it). It does the rest and asks before every change.
- **By hand:** follow every step. Commands go in PowerShell.

> ⚠️ Use at your own risk. Everything here is reversible (apps are **turned off, not deleted**), but write down what you change. My full list with undo commands is in [tv-changes.md](tv-changes.md).

---

## 1. Turn on developer mode on the TV

1. On the TV, open **Settings → System → About**. On some TVs it's **Settings → Device Preferences → About**.
2. Scroll to **Android TV OS build** (or **Build**) and press **OK 7 times** until it says *"You are now a developer"*.
3. Go back to **System → Developer options** and turn on **USB debugging**.
4. Find the TV's IP address in **Settings → Network & Internet** → your Wi-Fi network, for example `192.168.29.162`.

## 2. Get adb on your PC

adb is the tool that talks to the TV.

- If you have Android Studio, it's already at `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`.
- Otherwise, download **SDK Platform-Tools for Windows** from <https://developer.android.com/tools/releases/platform-tools> and unzip it.

The PC and the TV must be on the **same Wi-Fi**.

---

## Option A: let Claude Code do it

Open [Claude Code](https://claude.com/claude-code) and paste this, filling in your TV and apps:

```text
Help me clean up my Android TV and make it faster.
My TV is a <brand and model>.

1. Connect to my TV over Wi-Fi. Walk me through anything
   I need to tap on the TV.
2. Before changing anything, list every app in plain English:
   safe to turn off, needed by the TV, and apps I use.
   Check free memory.
3. Ask me before every change. Turn apps off instead of
   deleting them. Never turn off Google Play, the keyboard,
   Bluetooth or my HDMI inputs. Keep a list of what you
   changed and how to undo it.
4. Install the home screen: download
   https://github.com/Ansub/tv-detox and run its
   install.sh with my TV and these apps: <your apps>.
5. Turn off animations and the screensaver, and make the TV
   sleep after 5 minutes.
6. Restart the TV and show me free memory before and after.
```

(The prompt comes from [tv-detox](https://github.com/Ansub/tv-detox).) On a **TCL TV**, also tell it: *"Use the patched home screen from github.com/muniraja96/tcl-tv-detox so the HDMI tiles work."*

---

## Option B: by hand

In PowerShell, set these once. Change the IP to your TV's:

```powershell
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$tv  = '192.168.29.162:5555'
```

### 3. Connect

```powershell
& $adb connect $tv
& $adb devices
```

The TV shows **"Allow USB debugging?"**. Tick **Always allow from this computer** and press **OK**. `adb devices` should then list your TV as `device`.

### 4. Check free memory and list apps (nothing changes yet)

```powershell
& $adb -s $tv shell "head -3 /proc/meminfo"      # MemAvailable = free memory
& $adb -s $tv shell pm list packages -3          # apps you installed
& $adb -s $tv shell pm list packages -s -e       # built-in apps that are on
& $adb -s $tv shell "dumpsys meminfo | grep -A15 'Total PSS by process'"   # biggest memory users
```

Write down `MemAvailable`. That's your **before** number. Mine was 611 MB of 1.4 GB.

### 5. Turn off apps you don't use

Turn off, never uninstall:

```powershell
& $adb -s $tv shell pm disable-user --user 0 <package.name>
```

Undo any time:

```powershell
& $adb -s $tv shell pm enable <package.name>
```

What I turned off on my TCL:

| What | Package |
|---|---|
| Streaming apps I don't use | `com.amazon.amazonvideo.livingroom`, `com.sonyliv`, `com.graymatrix.did` (ZEE5), `com.jio.media.jiotvplus`, `com.mubi`, `com.apple.atve.androidtv.appletv` |
| TCL ads and extras | `com.tcl.esticker`, `com.tcl.hotelmenu`, `com.tcl.waterfall.overseas`, `com.tcl.messagebox`, `com.tcl.usercenter`, `com.tcl.smartalexa`, `com.tcl.copydatatotv` |
| Google extras | `com.google.android.youtube.tvmusic`, `com.google.android.play.games`, `com.google.android.feedback`, `com.google.android.marvin.talkback` (screen reader), `com.google.android.apps.tv.dreamx` (screensaver) |
| Voice search (mic button stops working) | `com.google.android.katniss`, `com.google.android.tv.assistant` |
| Other | `com.android.printspooler` |

**Never turn off:** Google Play (`com.android.vending`, `com.google.android.gms`, `com.google.android.gsf`), keyboards (`com.google.android.inputmethod.latin`, `com.tcl.inputmethod.international`), Bluetooth and remote (`com.android.bluetooth`, `com.tcl.tcl_bt_rcu_service`, `com.tcl.autopair`), HDMI/TV (`com.tcl.tvinput`, `com.tcl.tv`, `com.android.providers.tv`), settings (`com.tcl.settings`, `com.android.tv.settings`). Keep `com.google.android.apps.mediashell` if you use Chromecast.

> TCL turned `com.tcl.usercenter` and `com.tcl.smartalexa` back on by itself after a restart. That's harmless.

### 6. Install the new home screen

**On a TCL TV, use the patched build from this repo** ([`tvhome-build/`](tvhome-build/)). The original's HDMI tiles do nothing on TCL. [README](README.md#the-tcl-hdmi-fix) explains why.

**Build it** (needs Android SDK build-tools 30.0.2, platform android-30 and JDK 14 or newer):

```powershell
powershell -File tvhome-build\build.ps1
```

Edit the `$apps` line in `build.ps1` first to choose your apps. The first build creates `key.jks`. Keep it private, because updates must be signed with the same key.

**Install it and pick your apps:**

```powershell
& $adb -s $tv install tvhome-build\out\tvhome.apk
& $adb -s $tv shell am start -n com.ansub.tvhome/.MainActivity --es apps '"com.netflix.ninja,com.google.android.youtube.tv,in.startv.hotstar"'
& $adb -s $tv shell cmd role add-role-holder --user 0 android.app.role.HOME com.ansub.tvhome
& $adb -s $tv shell cmd package set-home-activity com.ansub.tvhome/.MainActivity
```

Not on TCL? You can use the original instead: `sh install.sh <TV_IP>` from [tv-detox](https://github.com/Ansub/tv-detox).

### 7. Make Home open the new screen

Google TV's own home keeps taking over the Home button. **Turn off both of these together**. If you turn off only the first, Home gets stuck in a loop on a "recovery" screen:

```powershell
& $adb -s $tv shell pm disable-user --user 0 com.google.android.apps.tv.launcherx       # Google TV home
& $adb -s $tv shell pm disable-user --user 0 com.google.android.tungsten.setupwraith    # Google TV setup-recovery
& $adb -s $tv shell pm disable-user --user 0 com.google.android.videos                  # "Google TV" app (optional)
& $adb -s $tv shell cmd package set-home-activity com.ansub.tvhome/.MainActivity
& $adb -s $tv shell input keyevent KEYCODE_HOME
```

Press Home on the remote. You should see the new screen.

### 8. Animations, screensaver and sleep

```powershell
& $adb -s $tv shell settings put global window_animation_scale 0
& $adb -s $tv shell settings put global transition_animation_scale 0
& $adb -s $tv shell settings put global animator_duration_scale 0
& $adb -s $tv shell settings put secure screensaver_enabled 0
& $adb -s $tv shell settings put secure screensaver_activate_on_sleep 0
& $adb -s $tv shell settings put secure screensaver_activate_on_dock 0
```

Auto-sleep: I first set 5 minutes, but the TV turned off while I watched the Fire TV Stick, so I switched it off:

```powershell
& $adb -s $tv shell settings put secure sleep_timeout -1                 # never sleep (300000 = 5 min)
& $adb -s $tv shell settings put system screen_off_timeout 2147483647    # never blank the screen
```

### 9. Fire TV Stick: turn on straight into it

```powershell
& $adb -s $tv shell settings put system standby_save_bootsource 1             # TCL: start on the last input used
& $adb -s $tv shell settings put global hdmi_control_enabled 1                # HDMI-CEC on
& $adb -s $tv shell settings put global hdmi_control_auto_wakeup_enabled 1    # Fire TV remote can turn the TV on
```

Now pressing **Home on the Fire TV remote** turns the TV on and switches to the Fire TV.

### 10. Fix over-strong colours on the Fire TV

Do this with the remote while the Fire TV is on screen:

1. **TV:** Settings → Display and sound → Picture → Advanced settings → Colour → **Dynamic Color: Off**
2. **TV:** … → Advanced settings → Expert calibration → **Colour space: Auto** (was Native)
3. **Fire TV:** Settings → Display & Sounds → Display → **Dynamic Range Settings: Adaptive**. This was the one that fixed it for me, because "Always HDR" looks oversaturated on a TV that can't show HDR.

If it still looks too strong: try the **Movie** picture preset, lower **Colour saturation** to about 40, or set **Colour temperature** to **Warm**.

### 11. Restart and compare

```powershell
& $adb -s $tv reboot
# wait ~2 minutes, then:
& $adb connect $tv
& $adb -s $tv shell "head -3 /proc/meminfo"
```

Mine went from **611 MB → 816 MB** free.

### 12. Turn debugging off

When you're done, go to **Settings → System → Developer options → USB debugging → Off**. Everything keeps working, and nobody else on your Wi-Fi can connect.

---

## Undo

- **One app:** `& $adb -s $tv shell pm enable <package.name>`, or on the TV: Settings → Apps → See all apps → Show system apps → pick it → **Enable**.
- **Bring back Google TV home.** Turn Google TV on **before** removing the new home:
  ```powershell
  & $adb -s $tv shell pm enable com.google.android.apps.tv.launcherx
  & $adb -s $tv shell pm enable com.google.android.tungsten.setupwraith
  & $adb -s $tv shell pm enable com.google.android.videos
  & $adb -s $tv uninstall com.ansub.tvhome
  ```
- **Settings:** put back the old values listed in [tv-changes.md](tv-changes.md).

## Troubleshooting

| Problem | Fix |
|---|---|
| `adb connect` says *refused* or *failed* | The TV dropped debugging after standby. Turn **USB debugging** off and on again in Developer options, then reconnect. |
| TV shows "Allow USB debugging?" again | Press OK and tick **Always allow**. |
| Home button still opens Google TV | Do step 7 again. A system update may have turned Google TV home back on. |
| HDMI tile does nothing | You're on the original tv-detox build. Install the patched one from [`tvhome-build/`](tvhome-build/). The Source button on the remote still works too. |
| TV turns off while watching | Set the sleep timers to "never" (step 8). |
| Mic button does nothing | Expected if you turned off voice search. Re-enable `com.google.android.katniss`. |
