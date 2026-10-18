# Rift Hub

Prepared from the saved universal hub, intro, home-video and game launcher sources, plus the latest Superhero Arena standalone script. Published as `copperpoppercms-sys/Rift-Hub`, with MM2 maintained in `copperpoppercms-sys/Rift-Hub-MM2`, Superhero Arena v5.9 in `copperpoppercms-sys/Rift-Hub-Superhero-Arena`, and Survive The Hulk in `copperpoppercms-sys/Rift-Hub-Survive-The-Hulk`.

Run the universal hub:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub/main/main.lua"))()
```

The universal hub now opens **Rift Personal Space 2.2**: a graphite interface with violet accents, a searchable game library, pinned favorites and a compact layout for portrait phones. **Search Rift** opens a native command palette; desktop users can also press **Ctrl+K**. Search for a section, a tool such as fly or ESP, or a game. Selecting a result takes you to its controls without automatically enabling a feature.

The **Hub** tab includes **Murder Mystery 2**, **Superhero Arena** and **Survive The Hulk**, with small icons, Execute buttons and a badge on the game you are currently playing. Filter by **All**, **Favorites** or **This game**. Cards adapt between one and two columns. Home links to the library and the last successfully opened script. Favorites, launch history and reduced-motion preference are stored in `RiftHub/library.json` when executor file APIs are available; otherwise they work for the current session.

Execute opens that game’s separate script and closes the universal hub. Join the selected game first; failed downloads leave the main hub open, and failed startup restores it. The last-opened entry updates only after the new window is validated. This update changes the universal interface, not the separate games’ gameplay controllers.

The **Hero / Villain** section starts with a compact **Hulk** card, a standalone Hulk comic portrait, the description **huge rage**, and an **Exterminate** button. Exterminate enables a floating **Hulk Leap** control and minimizes the hub. Hold **LEAP** to fill the adjacent power bar over 2.2 seconds and progressively scrub the squat animation; release to launch upward and forward. Full charge holds its pose until release. Search Rift can also open the section.

All four scripts use the uploaded Rift Hub logo. The original JPEG is retained in each repository; compact headers and minimized controls use its R emblem. An executor without custom-image support keeps a text fallback. The intro stays disabled and its saved files remain unchanged.

## Contents

- `main.lua` opens the universal hub immediately. The intro video and Welcome to Rift are temporarily disabled with `INTRO_ENABLED = false`; all media and code are retained. See `docs/IntroRestore.md` to restore them.
- `src/ui/Intro.lua` retains footage playback, a bottom-right skip button that skips only the footage, and the welcome screen tied to welcome audio. The native title now reads Welcome to Rift.
- `src/ui/HomeVideo.lua` retains the looping in-hub video and expanded player with a close control.
- `assets/` includes the saved video frame packs, audio, welcome background and source media.
- `src/ui/GameLibrary.lua` loads MM2, Superhero Arena and Survive The Hulk from their separate repositories. It verifies each game’s place/universe and returned window before completing the handoff.
- `games/mm2.lua` is a forwarding loader; the full MM2 implementation belongs only in the separate MM2 repo.
- `games/superhero-arena.lua` forwards to the separate Superhero Arena repository. The v5.9 implementation, full editable HTML, tests and game icon are maintained there. See `docs/SuperheroArena.md`.
- `games/survive-the-hulk.lua` forwards to the separate Hulk repository. Its Hub card has a small game icon, Execute button and “Opens Survive The Hulk and closes hub” caption.
- `src/ui/Brand.lua` handles shared logo loading and caching for the universal window and minimized island.
- `src/core/LibraryState.lua` validates UI-only preferences and implements library search, filters and ranking.
- `src/ui/LibraryView.lua` draws the responsive library and keeps the existing guarded Execute handoff.
- `src/ui/QuickSearch.lua` handles native touch/keyboard search, deep links, focus release and cleanup.
- `src/features/HulkLeap.lua` provides hold/release charging, the squat animation (`99086193071059`), launch animation (`74116059836265`), one launch impulse, a draggable control, ground checks, input cancellation, respawn handling and cleanup. It starts disabled and is cleared by Panic/unload. Other touch inputs, such as the joystick, do not release its charge. Flight must be off to use it.
- Settings includes **Reduce motion**, which remembers its state, and creator credit **N0VA_0100**.

## Validation

Set `LUAU_BIN` and `LUAU_COMPILE_BIN` to the native Luau executables, then run `python tests/run_features.py`, `python tests/run_game_library.py`, `python tests/run_superhero.py`, `python tests/run_branding.py` and `python tests/run_library_experience.py` and `python tests/run_hulk_leap.py`.

The squat clip is scrubbed from its beginning to its midpoint as power rises; `HulkLeap.Config.CrouchPoseFraction` can be adjusted if the supplied clip’s deepest squat occurs elsewhere. Roblox animation permissions and R6/R15 compatibility determine whether the supplied IDs play. Movement is a local physics request: game controllers or server movement rules may restrict it.

These checks verify compilation and simulated behavior. Playback, game controls and server behavior require live Roblox testing. Original third-party credits are preserved.

## Execute snippet

`execute.lua` contains the copy/paste execution snippet for this repository.

Hulk character portrait: [Marvel](https://cdn.marvel.com/content/1x/006hbb_com_crd_01.jpg). Original image bytes and source information are retained in `assets/hulk_portrait.jpg` and `assets/hulk_portrait_source.json`.
