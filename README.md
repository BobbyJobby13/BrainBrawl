# Brainbrawl frontend
## Problem Statement:
"In an era where educational institutions seek advanced and seamless methods for academic assessments, a challenge persists in providing user-friendly, real-time evaluation platforms for universities and colleges. The current systems often lack interactive features and fail to deliver an engaging 1v1 contest-based assessment experience. The absence of such an effective evaluation platform hinders the enhancement of learning experiences and the achievement of academic excellence within educational institutions. This prompts the need to address the deficiency by developing an innovative, comprehensive solution that facilitates real-time, user-friendly evaluations while fostering interactive 1v1 contest-based assessments, aligning with the project's vision to empower educational institutions and promote enhanced learning experiences."

## Solution : 
Welcome to the Brain-Brawl Django REST application repository! This backend application is designed to support the Flutter-based "Brain-Brawl" application, where students from different universities can compete in knockout competitions involving assessments that challenge both accuracy and speed.

## About The Project : 
We provide a 1-on-1 learning experience in knockout series form, whereas, when you start a game you are matched with a player who also joined under the same subject as you did, and from there you both get to battle each other by answering assessments that require both accuracy and speed to win. Winners will rise on the leaderboard until there is only one winner among all the universities participating in the knockout competition.

## Vision : 
"Empowering educational institutions through seamless, user-friendly online examination platforms, fostering interactive 1v1 contest-based assessments for enhanced learning experiences and academic excellence."

## Mission : 
"Our mission is to provide educational institutions with seamless, user-friendly online examination platforms that enable interactive 1v1 contest-based assessments. By fostering these experiences, we aim to enhance learning methodologies, promoting academic excellence and fostering a conducive environment for educational growth and achievement."
  
## How does it work?
Upon logging in, users will be directed to a webpage displaying all currently active competitions. Participating in a knockout competition entails being paired with a student from another university who has also enrolled under the same subject. Subsequently, both participants engage in a timed battle, answering assessments within 30-45 seconds. Success in this competition necessitates a blend of accuracy and speed. As participants progress, winners ascend on the leaderboard until ultimately, a single winner emerges among all the universities involved in the knockout competition.

### Backend Repository Link: https://github.com/Dhruv-IGI/BrainBrawl-Backend
### Project Presentation: https://www.canva.com/design/DAFzOcRR3Fc/4HsyCJ5oXb7JRiyoBEooXQ/edit?utm_content=DAFzOcRR3Fc&utm_campaign=designshare&utm_medium=link2&utm_source=sharebutton
### Hosted Project Link: https://brainbrawl-0001.web.app
### Figma Design Link: https://www.figma.com/file/tc2vPJYsZqPBrt8cqTSNOV/HackCBS?type=design&node-id=0%3A1&mode=design&t=ynFpkVBPMfrKGaKJ-1

## Desktop app (macOS and Windows)

The app is a Flutter web app, but it also builds as a real desktop application:
the same code, packaged as `Brain Brawl.app` on macOS and `brainbrawl_frontend.exe`
on Windows. No browser, no local web server, and the host console can open a
buzzer receiver socket directly.

### Get a build without a Mac or a Windows license

GitHub Actions builds both installers for you: **Actions → Desktop builds →
Run workflow**. When it finishes, download `Brain-Brawl-macOS` or
`Brain-Brawl-Windows` from the run's **Artifacts** section.

* **macOS — `Brain-Brawl-1.0.0-macOS.dmg`.** Open the disk image, drag
  **Brain Brawl** onto the **Applications** shortcut, then launch it from
  Launchpad. It is not signed with an Apple Developer ID, so the first launch
  needs **right-click → Open** in Finder, or once:
  `xattr -dr com.apple.quarantine "/Applications/Brain Brawl.app"`.
* **Windows — `Brain-Brawl-1.0.0-Windows.msi`.** Double-click and run through the
  installer: it adds **Brain Brawl** to the Start Menu and to *Apps & features*
  for a clean uninstall. Installing for all users needs an administrator account,
  and the installer is unsigned, so SmartScreen shows *Windows protected your PC*
  — choose **More info → Run anyway**.
* **Windows portable — `Brain-Brawl-1.0.0-Windows-portable.zip`.** Unzip anywhere
  and run `brainbrawl_frontend.exe`; no installer and no admin rights. The `.exe`
  needs the `data` folder and DLLs beside it, so keep the folder intact.

### Build it yourself

On a Mac with Xcode and CocoaPods:

```bash
flutter pub get
flutter build macos --release   # build/macos/Build/Products/Release/Brain Brawl.app
```

On Windows with Visual Studio ("Desktop development with C++"):

```powershell
flutter pub get
flutter build windows --release   # build\windows\x64\runner\Release\
```

Both use the pinned Flutter 3.16.9 toolchain. Ship the whole `Release` folder for
Windows (the `.exe` needs `data/` and the DLLs beside it); macOS produces a
single self-contained `.app`.

To build the same installers locally, after the step above:

```bash
# macOS: disk image with an Applications shortcut
mkdir -p build/dmg-staging
cp -R "build/macos/Build/Products/Release/Brain Brawl.app" build/dmg-staging/
ln -s /Applications build/dmg-staging/Applications
hdiutil create -volname "Brain Brawl" -srcfolder build/dmg-staging \
  -ov -format UDZO Brain-Brawl-1.0.0-macOS.dmg
```

```powershell
# Windows: MSI (needs the WiX Toolset 3.x on PATH, `choco install wixtoolset`)
heat dir build\windows\x64\runner\Release -cg AppFiles -gg -g1 -sfrag -srd `
  -dr INSTALLFOLDER -var var.SourceDir -out windows\installer\Files.wxs
candle -arch x64 "-dSourceDir=$PWD\build\windows\x64\runner\Release" -dVersion=1.0.0 `
  -out obj\ windows\installer\Product.wxs windows\installer\Files.wxs
light -out Brain-Brawl-1.0.0-Windows.msi obj\Product.wixobj obj\Files.wixobj
```

The installer layout and Start Menu shortcut live in
[`windows/installer/Product.wxs`](windows/installer/Product.wxs).

### Updates

On launch, the macOS and Windows builds ask GitHub for the newest release
(`/repos/BobbyJobby13/BrainBrawl/releases/latest`). If it is newer than the
running version, the landing page offers **Download**, which opens the release
page in the default browser. The check runs once per launch, times out after
eight seconds, and stays silent when there is no network — a venue without wifi
sees nothing rather than an error. The browser build never checks, because it is
always served the current code.

To publish a version:

1. Bump `version:` in `pubspec.yaml` **and** `appVersion` in
   `lib/app/app_version.dart` (a test fails if they drift apart).
2. Tag and push: `git tag v1.1.0 && git push origin v1.1.0`.

The workflow then builds both installers, attaches them to a GitHub Release for
that tag, and every older desktop copy offers the update on its next launch.

### Notes

* Hardware buzzers work over `ws://` on desktop too (`dart:io`), so the host
  console's receiver field works exactly as it does in the browser.
* The macOS builds are sandboxed and request outbound network access; without
  that entitlement the packaged app cannot reach the API or a buzzer receiver.
* Settings, teams and imported question packs are stored locally per device
  (desktop uses the app-support directory instead of browser storage).

## Snapshots

![Home Page](https://github.com/Dhruv-IGI/BrainBrawl/assets/86194637/fa2cdbe3-b2fd-4fff-b9ac-d7444058131c)
![joining test details](https://github.com/Dhruv-IGI/BrainBrawl/assets/86194637/41c9436c-1a41-4ff4-aa25-67f7ea62c2e6)
![About Us](https://github.com/Dhruv-IGI/BrainBrawl/assets/86194637/63760ba0-da47-4825-98fd-95246ca0179e)





