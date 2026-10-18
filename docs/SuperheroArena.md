# Rift Hub · Superhero Arena

The current v5.8 script is maintained in [Rift-Hub-Superhero-Arena](https://github.com/copperpoppercms-sys/Rift-Hub-Superhero-Arena). The main hub’s game catalogue fetches that repository’s `main.lua`; `games/superhero-arena.lua` is a compatibility loader.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub-Superhero-Arena/main/main.lua"))()
```

Game: [Superhero Arena by The Duelists](https://www.roblox.com/games/78710221869926/Superhero-Arena), place ID `78710221869926`, universe ID `10765491459` (verified against Roblox’s game listing).

The Hub card uses Roblox’s published game icon and the same compact card style as MM2. Execute closes the universal hub and opens the animated Combat, Visuals and Settings interface. Auto Farm lives under Combat; ESP shows hero-colored chams and a role above the username under Visuals. Ultra Instinct requests a native dash when available and otherwise uses the configured short sidestep burst. It no longer changes position directly. Normal controls stay enabled. Ultra Instinct can assist briefly while you run, then restores your current joystick or keyboard input. Both combat automations start off. Hidden server attacks and unknown animation cues cannot be predicted.

Download [the editable HTML](https://github.com/copperpoppercms-sys/Rift-Hub-Superhero-Arena/blob/main/docs/SuperheroArena_Editor.html) and open it in a browser to copy or edit the complete code. Standalone behavior checks live in that repository’s `tests/`. This repository checks the catalogue handoff and forwarding loader.

v5.8 continues sidestepping at game-controlled speed after a burst override, reports actual input/ability locks, removes an Auto Farm planner delay from otherwise legal defensive dash requests, and yields new attacks to a fresh threat. Test game dash isolates native input without a speed burst; automatic dash diagnostics stay separate from manual tests. Locked abilities and game-replaced speed remain actual limitations, not established bypasses.
