# Project State

## Current status

Independent Android TV screensaver implemented in `tv-screensaver/android`; family revision installed and enabled on Xiaomi MiTV-AFKR0 on 2026-10-25. Existing Flutter/preview application code is unchanged.

## Working features

- Native offline DreamService and TV-remote settings.
- Default 687 distinct Chechen headwords selected for contemporary family use, with exact Maciev gloss validation, including animals, birds, trees and plants; 425 child-suitable words and 11 checked polysemy hints.
- Default backgrounds: 11 FLUX.1-schnell works upscaled to 4K and two native-resolution 4K Commons photographs (CC BY-SA 4.0); 100 earlier backgrounds remain optional.
- Background and text draw into a physical-resolution SurfaceView. On Xiaomi SurfaceFlinger reports a 3840 × 2160 buffer in DEVICE composition despite the vendor's 1920 × 1080 logical UI override.
- No captions or controls at the bottom of the dream; source and image attribution in Settings/About and project documentation.
- Optional separate full dictionary mode: 38,013 automatically filtered Maciev records.
- Delayed Russian translation, three designs, font/brightness/timing controls, personal known-word skipping.
- Java tests and Android lint pass; final APK built with 687 family words and 113 backgrounds.

## Important constraints

- User explicitly allowed Xiaomi interaction again on 2026-10-24; earlier film-related prohibition has been lifted.
- No commits or pushes without explicit user request.
- Do not describe community rarity lists as population knowledge surveys.
- Source dictionaries remain unmodified; root source copies verified identical to canonical Git objects.

## Next priorities

Latest APK installed on Xiaomi; automatic dream selection saved. Idle timeout 5 minutes, sleep timeout 2 hours. After final checks on 2026-10-25 the box was powered off at the user's request (`reboot -p`); ADB became offline and its network port stopped responding.

- Previous 2026-10-24 build used 571 words and 100 backgrounds; superseded by the 2026-10-25 family build.

## Xiaomi verification — 2026-10-24

Installed release APK on MiTV-AFKR0 / Android14 at192.168.1.159:5555; selected LanguageDream. Verified actual system dream rendering, Russian translation, exit on key and restart. TOTAL PSS33630KB. No app crash in recent crash buffer. Xiaomi starts dreams through com.google.android.pano.action.SLEEP; cmd dreams requires root and was not used further. No root or reboot performed. Existing idle/sleep timeouts preserved.

## Saved device access —2026-10-24

User requested persistent access. Disabled expiration of previously approved ADB keys (`adb_allowed_connection_time=0`), reconnected and verified device identity. Repeatable helper: `tv-screensaver/android/tools/connect_xiaomi.py`; limits in DEVICE_ACCESS.md. Local LAN only; no background daemon added, no root/reboot, no DHCP reservation. TCP port persistence across reboot remains unverified; firmware denied setting persist.adb.tcp.port.

## Idle sleep updated —2026-10-24

User requested2 hours of inactivity before sleep. Set secure sleep_timeout from900000 to7200000 and verified effective mSleepTimeoutSetting=7200000. Kept screen_off_timeout=600000 for screensaver start after10 minutes; attentive_timeout remains default disabled (-1 effective). Actual2-hour wait was not performed.

## Screensaver start updated

Latest user preference: screensaver after5 minutes idle, sleep after2 hours. Set system screen_off_timeout=300000, verified effective power setting; sleep_timeout remains7200000. This supersedes earlier10-minute screensaver timing.
