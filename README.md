# Venu 4 (41mm) Watch Face

A Monkey C watch face for the Garmin Venu 4 (41mm, device id `venu441mm`,
390x390 round AMOLED). Shows time, date, heart rate, steps and battery.

## Layout

```
manifest.xml            App manifest (targets venu441mm only)
monkey.jungle           Build config
source/
  Venu4WatchFaceApp.mc   Application entry point
  Venu4WatchFaceView.mc  Drawing logic
resources/
  strings/strings.xml    App name
  drawables/             Launcher icon
keys/developer_key.*     Local signing key (gitignored, do not share)
```

## Prerequisites

- Garmin Connect IQ SDK (already installed at the path referenced below).
- A Java runtime to run `monkeybrains.jar`. On Windows, install a JDK (e.g.
  via the VS Code "Monkey C" extension, which bundles one, or Eclipse
  Temurin) so `bin\monkeyc.bat` / `bin\monkeydo.bat` / `bin\connectiq.bat`
  work directly.

## Build (from WSL, using a local portable JRE)

This repo already has a compile-tested build using a portable JRE fetched
into `.toolchain/` (gitignored) so no Windows Java install was required:

```bash
SDK="/mnt/c/Users/<you>/AppData/Roaming/Garmin/ConnectIQ/Sdks/<sdk-version>"
JAVA_BIN=".toolchain/jdk-21*/bin/java"

$JAVA_BIN -cp "$SDK/bin/monkeybrains.jar" com.garmin.monkeybrains.Monkeybrains \
  -o bin/Venu4WatchFace.prg \
  -f monkey.jungle \
  -y keys/developer_key.der \
  -d venu441mm \
  -w
```

Note: the compiler looks for installed devices under
`~/.Garmin/ConnectIQ/Devices` (Linux default). Since the SDK/devices here
were installed via the Windows SDK Manager, symlinks were created:

```bash
mkdir -p ~/.Garmin/ConnectIQ
ln -sfn "/mnt/c/Users/<you>/AppData/Roaming/Garmin/ConnectIQ/Devices" ~/.Garmin/ConnectIQ/Devices
ln -sfn "/mnt/c/Users/<you>/AppData/Roaming/Garmin/ConnectIQ/Fonts" ~/.Garmin/ConnectIQ/Fonts
```

## Run in the simulator (from Windows)

The simulator is a native GUI app, best run from Windows directly (requires
a Windows Java install):

```bat
cd "%SDK%\bin"
connectiq.bat
monkeydo.bat "\\wsl.localhost\Debian\home\deviam\dev\venu4-watch\bin\Venu4WatchFace.prg" venu441mm
```

Or open the project folder in VS Code with the official "Monkey C" extension
(from Garmin) and use its "Run" command — it handles the simulator lifecycle
for you and is the recommended day-to-day workflow.

## Deploy to a real Venu 4

Build with `-e` to produce a signed `.iq` package (`monkeyc ... -e -o
Venu4WatchFace.iq`), then copy it via the Garmin Connect IQ Store dev
sideload flow, or use `monkeydo`/the device's Garmin Express "sideload"
folder as usual for developer builds.

## Signing key

`keys/developer_key.pem` / `keys/developer_key.der` were generated locally
with `openssl` and are gitignored. Keep using the same key for all builds of
this app — regenerating it changes the app's identity on-device.
