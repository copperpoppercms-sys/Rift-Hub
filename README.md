# Rift Hub

Prepared from the saved universal hub, intro, home-video and game launcher sources, plus the latest Superhero Arena standalone script. Published as `copperpoppercms-sys/Rift-Hub`, with MM2 maintained in `copperpoppercms-sys/Rift-Hub-MM2`, Superhero Arena v5.5 in `copperpoppercms-sys/Rift-Hub-Superhero-Arena`, and Survive The Hulk in `copperpoppercms-sys/Rift-Hub-Survive-The-Hulk`.

Run the universal hub:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub/main/main.lua"))()
```

The **Hub** tab shows **Murder Mystery 2**, **Superhero Arena** and **Survive The Hulk** cards in a compact two-column grid, each with its game icon and Execute button. Execute opens that game’s separate script and closes the universal hub. Join the selected game first; failed downloads leave the main hub open, and failed startup restores it. Superhero Arena opens its animated Combat, Visuals and Settings interface with Auto Farm and Ultra Instinct off.

All four scripts use the uploaded Rift Hub logo. The original JPEG is retained in each repository; compact headers and minimized controls use its R emblem. An executor without custom-image support keeps a text fallback. The intro stays disabled and its saved files remain unchanged.

## Contents

- `main.lua` opens the universal hub immediately. The intro video and Welcome to Rift are temporarily disabled with `INTRO_ENABLED = false`; all media and code are retained. See `docs/IntroRestore.md` to restore them.
- `src/ui/Intro.lua` retains footage playback, a bottom-right skip button that skips only the footage, and the welcome screen tied to welcome audio. The native title now reads Welcome to Rift.
- `src/ui/HomeVideo.lua` retains the looping in-hub video and expanded player with a close control.
- `assets/` includes the saved video frame packs, audio, welcome background and source media.
- `src/ui/GameLibrary.lua` loads MM2, Superhero Arena and Survive The Hulk from their separate repositories. It verifies each game’s place/universe and returned window before completing the handoff.
- `games/mm2.lua` is a forwarding loader; the full MM2 implementation belongs only in the separate MM2 repo.
- `games/superhero-arena.lua` forwards to the separate Superhero Arena repository. The v5.5 implementation, full editable HTML, tests and game icon are maintained there. See `docs/SuperheroArena.md`.
- `games/survive-the-hulk.lua` forwards to the separate Hulk repository. Its Hub card has a small game icon, Execute button and “Opens Survive The Hulk and closes hub” caption.
- `src/ui/Brand.lua` handles shared logo loading and caching for the universal window and minimized island.

## Validation

Set `LUAU_BIN` and `LUAU_COMPILE_BIN` to the native Luau executables, then run `python tests/run_features.py`, `python tests/run_game_library.py`, `python tests/run_superhero.py` and `python tests/run_branding.py`.

These checks verify compilation and simulated behavior. Playback, game controls and server behavior require live Roblox testing. Original third-party credits are preserved.

## Execute snippet

`execute.lua` contains the copy/paste execution snippet for this repository.
