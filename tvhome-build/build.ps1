# Builds tvhome.apk on Windows with build-tools 30.0.2, platform android-30 and JDK 14.
# Usage: powershell -File build.ps1
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
$sdk  = "$env:LOCALAPPDATA\Android\Sdk"
$bt   = "$sdk\build-tools\30.0.2"
$jar  = "$sdk\platforms\android-30\android.jar"
$jdk  = 'C:\Program Files\Java\jdk-14.0.2'
$env:JAVA_HOME = $jdk; $env:Path = "$jdk\bin;$env:Path"
$apps = 'com.netflix.ninja', 'com.google.android.youtube.tv', 'in.startv.hotstar'

Remove-Item -Recurse -Force out -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force out\classes, out\dex, out\gen\com\ansub\tvhome | Out-Null

$list = ($apps | ForEach-Object { "    `"$_`"," }) -join "`n"
Set-Content -Encoding ascii out\gen\com\ansub\tvhome\Apps.java "package com.ansub.tvhome;`nfinal class Apps { static final String[] LIST = {`n$list`n}; }"

& "$bt\aapt2.exe" link -o out\base.apk -I $jar --manifest AndroidManifest.xml --min-sdk-version 21 --target-sdk-version 30
if ($LASTEXITCODE) { throw 'aapt2 failed' }

$java = Get-ChildItem -Recurse src, out\gen -Filter *.java | ForEach-Object FullName
& javac -nowarn -source 8 -target 8 -bootclasspath "$jar;$bt\core-lambda-stubs.jar" -d out\classes $java
if ($LASTEXITCODE) { throw 'javac failed' }

$classes = Get-ChildItem -Recurse out\classes -Filter *.class | ForEach-Object FullName
# build-tools 30's d8.bat passes -Djava.ext.dirs, which JDK 9+ rejects, so call the jar directly.
& java -cp "$bt\lib\d8.jar" com.android.tools.r8.D8 --min-api 21 --release --lib $jar --output out\dex $classes
if ($LASTEXITCODE) { throw 'd8 failed' }

Copy-Item out\base.apk out\unsigned.apk
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::Open("$PWD\out\unsigned.apk", 'Update')
[IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, "$PWD\out\dex\classes.dex", 'classes.dex') | Out-Null
$zip.Dispose()

& "$bt\zipalign.exe" -f 4 out\unsigned.apk out\aligned.apk
if ($LASTEXITCODE) { throw 'zipalign failed' }

# Keep key.jks: future updates must be signed with the same key.
$pass = 'tvhome123'
if (-not (Test-Path key.jks)) {
  & keytool -genkeypair -keystore key.jks -storepass $pass -keypass $pass -alias tvhome -keyalg RSA -keysize 2048 -validity 10000 -dname 'CN=tvhome'
}
& java -jar "$bt\lib\apksigner.jar" sign --ks key.jks --ks-pass "pass:$pass" --out out\tvhome.apk out\aligned.apk
if ($LASTEXITCODE) { throw 'apksigner failed' }
Write-Output "Built $PWD\out\tvhome.apk"
