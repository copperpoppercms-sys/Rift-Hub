# Rift Hub

Prepared from the saved universal hub, intro, home-video and game launcher sources, plus the latest Superhero Arena standalone script. Published as `copperpoppercms-sys/Rift-Hub`, with the full MM2 script maintained separately in `copperpoppercms-sys/Rift-Hub-MM2`.

Run the universal hub:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub/main/main.lua"))()
```

The **Hub → Murder Mystery 2 → Execute** button opens the separate MM2 script and closes the universal hub.

## Contents

- `main.lua` loads the universal hub and the intro.
- `src/ui/Intro.lua` retains footage playback, a bottom-right skip button that skips only the footage, and the welcome screen tied to welcome audio. The native title now reads Welcome to Rift.
- `src/ui/HomeVideo.lua` retains the looping in-hub video and expanded player with a close control.
- `assets/` includes the saved video frame packs, audio, welcome background and source media.
- `src/ui/GameLibrary.lua` opens the separate MM2 script and unloads the universal hub on a successful handoff. Failed startup cleans up and reopens the hub.
- `games/mm2.lua` is a forwarding loader; the full MM2 implementation belongs only in the separate MM2 repo.
- `games/superhero-arena.lua` contains the focused v3.0 standalone Superhero Arena hub, containing Combat, Hero Skills, Movement, Visuals and Server sections. See `docs/SuperheroArena.md`. Its game/place ID has not been supplied, so it is bundled as standalone source rather than an unverified catalogue entry.

## Validation

Set `LUAU_BIN` and `LUAU_COMPILE_BIN` to the native Luau executables, then run `python tests/run_features.py`, `python tests/run_game_library.py` and `python tests/run_superhero.py`.

These checks verify compilation and simulated behavior. Playback, game controls and server behavior require live Roblox testing. Original third-party credits are preserved.

## Execute snippet

`execute.lua` contains the copy/paste execution snippet for this repository.
