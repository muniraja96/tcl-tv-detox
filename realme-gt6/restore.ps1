# Restore apps removed from the Realme GT 6 (RMX3851) on 2026-10-24.
# Usage:  .\restore.ps1                 -> restores everything
#         .\restore.ps1 com.android.chrome  -> restores one app
# Built-in apps come back instantly (install-existing). The user apps
# (Smart Switch, downloaders, The Hindu x2) were Play Store apps: reinstall from the store
# if install-existing reports they are not present.

$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

$removed = @(
  'com.facebook.appmanager','com.facebook.services','com.facebook.system',
  'com.taboola.scoop','com.heytap.pictorial','com.heytap.browser','com.heytap.music',
  'com.heytap.market.icon.overlay','com.oplus.statistics.rom','com.oplus.logkit',
  'com.oplus.postmanservice','com.redteamobile.roaming','com.coloros.operationManual',
  'com.android.egg','com.android.dreams.basic','com.android.email.partnerprovider',
  'com.android.bookmarkprovider','com.google.android.apps.tachyon',
  'com.google.android.projection.gearhead',
  'com.oppo.quicksearchbox','com.microsoft.appmanager',
  'com.microsoft.deviceintegrationservice','com.microsoftsdk.crossdeviceservicebroker',
  'com.sec.android.easyMover','com.saveinsta.app.savevideo.saveclip','com.shirokovapp.instasave',
  'tweeload.twitter.video.downloader','tweeter.gif.twittervideodownloader','com.maheshtechnicals.sealplus',
  'com.mobstac.thehindu','com.epaper.thehindu.android',
  # 2026-10-25 (Play Store apps: reinstall from the store if install-existing fails)
  'com.habesha.labs.openfit','com.samsung.android.samsungpay.gear',
  'com.discord','com.reddit.frontpage','com.apple.atve.androidtv.appletv','com.jio.media.jiobeats',
  'com.music.bitchord','ahaflix.tv','com.bt.bms','com.flashmonk.flash','com.freedom.android',
  'com.urbanclap.urbanclap','com.yanka.mc','glass.round.voyager','mobi.stratus.hopr',
  'com.brave.browser','com.deodap.gallery','com.tul.tatacliq','com.tnstc',
  'com.google.android.apps.healthdata','com.phonepe.app',
  'com.realme.link'
)
# YouTube Music was also removed, then reinstalled from the Play Store the same day.
# Watch7 plugin was removed on 2026-10-25, then reinstalled from the Play Store (user wears a Watch7).
# Chrome and Gemini were removed, then restored with install-existing on 2026-10-24.
$disabled = @('com.nearme.gamecenter','com.heytap.mcs')
$restricted = @('com.instagram.barcelona','com.instagram.android','in.amazon.mShop.android.shopping',
  'naukriApp.appModules.login','com.truecaller','com.jio.myjio','com.dreamplug.androidapp','com.apollo.patientapp')

# SMS access revoked on 2026-10-25 (CRED kept). The app can simply ask again, or:
$smsRevoked = @('com.myntra.android','in.swiggy.android','com.flipkart.android','in.amazon.mShop.android.shopping',
  'com.tul.tatacliq','com.timesprime.timesprimeandroid','com.popclub.android','in.mobility.cumta',
  'com.nextbillion.groww','com.jio.myjio')
# Truecaller notification access revoked on 2026-10-25. Re-enable in Settings > Notifications > Notification access.

$only = $args
foreach ($p in $smsRevoked) { if ($only -contains $p) {
  & $adb shell pm grant $p android.permission.READ_SMS
  & $adb shell pm grant $p android.permission.RECEIVE_SMS
  "$p : SMS access restored" } }
foreach ($p in $removed)    { if (-not $only -or $only -contains $p) { "$p : " + (& $adb shell cmd package install-existing --user 0 $p) } }
foreach ($p in $disabled)   { if (-not $only -or $only -contains $p) { "$p : " + (& $adb shell pm enable --user 0 $p) } }
foreach ($p in $restricted) { if (-not $only -or $only -contains $p) {
  & $adb shell am set-standby-bucket $p active
  & $adb shell cmd appops set $p RUN_ANY_IN_BACKGROUND allow 2>$null
  "$p : background restored" } }
