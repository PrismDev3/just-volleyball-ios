# Just Volleyball - iOS build

Godot 4.7.2 project plus a GitHub Actions pipeline that produces an **unsigned
`.ipa`** on GitHub's macOS runners. You do not need a Mac and you do not need an
Apple Developer account to get the file; you only need an Apple ID on the device
to sign it at install time.

- **Download:** [`Releases`](../../releases) - file name `volleyball-unsigned.ipa`
- **Fallback:** the same file is attached to every run under *Actions -> iOS ->
  Artifacts* (`just-volleyball-unsigned-ipa`), for 90 days.
- **Target:** iOS 15+, iPhone and iPad, landscape only
- **Device requirement:** A12 or newer (iPhone XS/XR and later, any current
  iPad). Godot's Metal renderer declares the
  `iphone-ipad-minimum-performance-a12` capability, so older devices will refuse
  to install it.

## Install on the phone

The build is intentionally unsigned. Sideloadly or AltStore will sign it with
your own (free) Apple ID and install it over USB / Wi-Fi.

1. Download `volleyball-unsigned.ipa` from the Releases page.
2. Install [Sideloadly](https://sideloadly.io/) (Windows/macOS) or
   [AltStore](https://altstore.io/).
3. Connect the iPhone, drag the `.ipa` in, enter your Apple ID, start.
4. On the phone: **Settings -> General -> VPN & Device Management** and trust
   your developer certificate.
5. Free Apple IDs produce a 7-day signature - re-sideload to renew. A paid
   developer account gives 1 year.

The bundle identifier is `com.justvolleyball.game`. If it collides with an
existing install, change `application/bundle_identifier` in
`export_presets.cfg` (preset `iOS`) and rebuild.

## Check the download first

Every build ships `volleyball-unsigned.ipa.sha256` next to the `.ipa`. On
Windows:

```bat
certutil -hashfile volleyball-unsigned.ipa SHA256
```

That should print the hash in the `.sha256` file. What the file contains, if you
want to look inside it yourself:

```
Payload/volleyball.app/volleyball         arm64 Mach-O, the Godot engine,
                                          statically linked (no nested
                                          .framework to re-sign)
Payload/volleyball.app/volleyball.pck    the whole packed project, ~90 MB
Payload/volleyball.app/Info.plist        com.justvolleyball.game, landscape only
```

The CI job fails unless all of that holds - the binary is arm64-only, the pck is
large enough to be real data, the imported textures and the on-screen control
script are inside the pck, both orientation arrays are landscape-only and no
`aps-environment` entitlement leaked in.

## Touch controls

The project now ships an on-screen pad that is drawn with the game's own UI
kit - the same rounded slabs, the same `UiStyle` palette, the same black glyph
set and Nunito family, so it sits in the interface instead of on top of it.

| Where | Control | Action |
| --- | --- | --- |
| Bottom left | Thumbstick (analog) | move |
| Right cluster | **hit** (large, yellow) | bump / spike / dump / toss - the label follows the HUD legend, and becomes **serve** while serving |
| Right cluster | **jump** (white card) | jump |
| Right cluster | **set** (blue) | set |
| Right cluster | **dive** (pink) | dive, reads **block** while airborne |
| Right cluster | **strafe** (grey) | strafe |
| Empty area | drag anywhere else | aim, and drag to look/pan the camera |
| Top right | icon strip | pause, scoreboard, camera, zoom, re-centre aim |

Details that matter on a phone:

- The stick is **analog** - pushing it halfway walks, the edge runs. It drives
  the real `move_*` actions through `Input.action_press(value)`, so the same
  handling the keyboard and gamepad use is reused, including aim assist.
- Thumbs **roll** between buttons: sliding from `hit` onto `jump` releases the
  first and presses the second, so nothing gets stuck down.
- The pad disappears in menus, cinematics, replays and spectator mode, and
  while the pause menu or the chat box is up. It is also released the moment
  it becomes inactive, so the player can never be left jogging into a wall.
- The desktop legend is hidden while the pad is up, because it only ever showed
  keyboard/controller glyphs.
- Auto-detection: on by default on anything with a touchscreen or on a mobile
  platform. Override in **Settings -> Gameplay -> Touch controls**
  (Auto / On / Off), or with `--touch` / `--no-touch` on the command line.

## How the build works

`.github/workflows/ios.yml` runs on `macos-15`:

1. Install Godot 4.7.2 (universal editor) and the matching `ios.zip` export
   template, both cached between runs.
2. `godot --headless --import` - imports 10k+ assets from scratch.
3. `godot --headless --export-release iOS build/volleyball.ipa` - the iOS
   preset sets `application/export_project_only=true`, so this writes
   `build/volleyball.pck` and a complete `build/volleyball.xcodeproj` and stops
   before Godot would try to sign anything.
4. `xcodebuild -sdk iphoneos ... CODE_SIGNING_ALLOWED=NO` - builds the app
   without a certificate or profile.
5. Zip the `.app` into `Payload/` to get an `.ipa`, verify the binary, the
   packed game data and the touch-control script are actually inside it, then
   upload it as an artifact. Pushing a `v*` tag publishes it as a GitHub
   Release.

Notes about the preset (`export_presets.cfg`, preset `iOS`):

- `application/app_store_team_id` is a placeholder - Godot refuses to export
  without a non-empty value, and it is irrelevant while everything is unsigned.
- `entitlements/increased_memory_limit=false` is deliberate: free Apple IDs
  cannot sign `com.apple.developer.kernel.increased-memory-limit`, and an
  unsigned build that carries it fails to install through Sideloadly or
  AltStore. Flip it to `true` only with a paid developer account.
- `entitlements/push_notifications` must stay the string `"Disabled"`; anything
  else writes an `aps-environment` entitlement that breaks re-signing.
- `application/export_project_only=true` is what keeps CI away from signing.

## Building locally (on a Mac)

```sh
# once: install the editor + the ios.zip export template for 4.7.2
godot --headless --path . --import
godot --headless --path . --export-release iOS build/volleyball.ipa

cd build
xcodebuild -project volleyball.xcodeproj -scheme volleyball -sdk iphoneos \
  -configuration Release -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" build
```

`export_project_only` means you can also just open `build/volleyball.xcodeproj`
in Xcode and run it on a device with a normal signing team selected.

## Layout

```
project.godot                  autoloads (TouchControls is one of them)
export_presets.cfg             Windows / Web / iOS export presets
game/                          game source
game/ui/touch/touch_controls.gd on-screen pad
game/ui/style/ui_style.gd      shared UI kit the pad draws with
.assets/                       original 3D sources (.glb/.obj) - required to reimport
.github/workflows/ios.yml      the iOS pipeline
```
