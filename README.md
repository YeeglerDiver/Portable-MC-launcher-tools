# OfflineMC Launcher

A small Windows launcher that starts your own copy of Minecraft: Java Edition **26.3** in offline mode. When it starts, it asks for a player name and lets you pick a skin PNG.

This repo contains **only scripts**. It does not contain, and must never contain, any Minecraft files. You need to own the game and supply the files from your own install.

## Features

- Offline launch with no login (uses a dummy access token)
- Prompts for a player name on startup
- Skin picker: generates a resource pack that replaces the default player skins with your PNG
- Optional build step that bundles everything into a single self-extracting `OfflineMC-Portable.exe` (with Java 25 included)
- Works with Open to LAN for local multiplayer

## Limitations

- Cannot join online-mode servers (they verify your account with Mojang)
- Skins are local only. Other players will not see them.
- Realms and account features do not work. You will see 401 and Realms errors in the log, which are expected and harmless.
- Built and tested for 26.3 only. Other versions may need changes.

## Files

| File | Purpose |
|---|---|
| `rip.ps1` | The launcher. Asks for a name and skin, then starts the game offline. |
| `build-portable.ps1` | Packs an `OfflineMC` folder into one self-extracting exe. |
| `build.bat` | One-click build: compiles the launcher, gathers files, runs `build-portable.ps1`. |

## Requirements

- Windows 10 or 11
- A legitimate copy of Minecraft: Java Edition
- Minecraft 26.3 launched at least once from the official launcher, so `versions`, `libraries` and `assets` exist in `%APPDATA%\.minecraft`
- Java 25 (the launcher needs it):
  ```
  winget install EclipseAdoptium.Temurin.25.JDK
  ```

## Quick start (run the script directly)

1. Put `rip.ps1` in `%APPDATA%\.minecraft`.
2. Open PowerShell in that folder and run:
   ```
   powershell -ExecutionPolicy Bypass -STA -File rip.ps1
   ```
3. Enter a player name, then pick a skin PNG (64x64, or cancel to skip).

## Building the portable exe

1. Put `rip.ps1`, `build-portable.ps1` and `build.bat` together in `%APPDATA%\.minecraft`.
2. Make sure `rip.ps1` is the launcher (it has the `Player name` prompt). `build.bat` checks this and stops if it isn't.
3. Double-click `build.bat`. It will:
   - install the `ps2exe` module if needed
   - compile `rip.ps1` into `OfflineMC.exe`
   - copy only the version, libraries and assets that 26.3 needs, plus Java 25
   - run `build-portable.ps1` to produce `OfflineMC-Portable.exe`
4. Wait for the green `Done!` message. The last step is slow, so a quiet minute or two is normal.
5. Run `OfflineMC-Portable.exe`. The first launch unpacks to `%LOCALAPPDATA%\OfflineMC`, then the name and skin prompts appear.

Worlds and settings are kept in `%LOCALAPPDATA%\OfflineMC\game`. Rebuilt exes re-extract over the old files but keep `saves` and `options.txt`.

You can delete `OfflineMC`, `payload.zip` and `Stub.cs` after a successful build.

## Troubleshooting

| Problem | Fix |
|---|---|
| `rip.ps1 is not the launcher script` | The build script overwrote it. Restore the launcher version. |
| `build-portable.ps1 not found` | Put it next to `build.bat`. |
| `Java 25 not found` | Run the winget command above. |
| `UnsupportedClassVersionError` | Your Java is too old. Install Java 25. |
| `This app can't run on your PC` | The embedded payload is over about 2 GB, or the build was incomplete. Rebuild with `build.bat`. |
| Skin is still the default | Check the log for `Failed to read pack` lines and make sure the PNG is 64x64. Press F5 to see yourself in third person. |
| SmartScreen or antivirus warning | Expected for an unsigned self-extracting exe you built yourself. |
| Game closes instantly | Check `logs\latest.log` in the game folder. |

## Legal

- This project is not affiliated with, endorsed by, or associated with Mojang Studios, Microsoft, or Minecraft.
- You must own Minecraft: Java Edition to use this. It does not bypass any purchase.
- Do not commit or upload any Minecraft files (the client jar, `libraries`, `assets`, or a built `OfflineMC-Portable.exe`). They are Mojang's copyrighted files, and redistributing them is not allowed by the [Minecraft EULA](https://www.minecraft.net/eula).
- A built `OfflineMC-Portable.exe` contains those files, so keep it for your own machines.

Add this `.gitignore` to the repo so you do not upload them by accident:

```
OfflineMC/
OfflineMC.exe
OfflineMC-Portable.exe
payload.zip
Stub.cs
*.jar
libraries/
assets/
versions/
saves/
```

## License

Add the license of your choice for the scripts (for example MIT). It covers only the scripts in this repo, not Minecraft.
