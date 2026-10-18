# Rift Hub

Prepared from the saved universal hub, intro, home-video and game launcher sources, plus the latest Superhero Arena standalone script. Published as `copperpoppercms-sys/Rift-Hub`, with MM2 maintained in `copperpoppercms-sys/Rift-Hub-MM2` and Superhero Arena v4.6 in `copperpoppercms-sys/Rift-Hub-Superhero-Arena`.

Run the universal hub:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub/main/main.lua"))()
```

The **Hub** tab shows compact **Murder Mystery 2** and **Superhero Arena** cards side by side, each with its game icon and Execute button. Execute opens that game’s separate script and closes the universal hub. Join the selected game first; failed downloads leave the main hub open, and failed startup restores it. Superhero Arena opens its current PLAY/STOP panel with PLAY off.

## Contents

- `main.lua` loads the universal hub and the intro.
- `src/ui/Intro.lua` retains footage playback, a bottom-right skip button that skips only the footage, and the welcome screen tied to welcome audio. The native title now reads Welcome to Rift.
- `src/ui/HomeVideo.lua` retains the looping in-hub video and expanded player with a close control.
- `assets/` includes the saved video frame packs, audio, welcome background and source media.
- `src/ui/GameLibrary.lua` loads MM2 and Superhero Arena from their separate repositories. It verifies each game’s place/universe and returned window before completing the handoff.
- `games/mm2.lua` is a forwarding loader; the full MM2 implementation belongs only in the separate MM2 repo.
- `games/superhero-arena.lua` forwards to the separate Superhero Arena repository. The v4.6 implementation, full editable HTML, tests and game icon are maintained there. See `docs/SuperheroArena.md`.

## Validation

Set `LUAU_BIN` and `LUAU_COMPILE_BIN` to the native Luau executables, then run `python tests/run_features.py`, `python tests/run_game_library.py` and `python tests/run_superhero.py`.

These checks verify compilation and simulated behavior. Playback, game controls and server behavior require live Roblox testing. Original third-party credits are preserved.

## Execute snippet

`execute.lua` contains the copy/paste execution snippet for this repository.
