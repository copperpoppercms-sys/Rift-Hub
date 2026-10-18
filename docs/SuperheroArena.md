# Rift Hub · Superhero Arena

The current v5.7 script is maintained in [Rift-Hub-Superhero-Arena](https://github.com/copperpoppercms-sys/Rift-Hub-Superhero-Arena). The main hub’s game catalogue fetches that repository’s `main.lua`; `games/superhero-arena.lua` is a compatibility loader.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub-Superhero-Arena/main/main.lua"))()
```

Game: [Superhero Arena by The Duelists](https://www.roblox.com/games/78710221869926/Superhero-Arena), place ID `78710221869926`, universe ID `10765491459` (verified against Roblox’s game listing).

The Hub card uses Roblox’s published game icon and the same compact card style as MM2. Execute closes the universal hub and opens the animated Combat, Visuals and Settings interface. Auto Farm lives under Combat; ESP shows hero-colored chams and a role above the username under Visuals. Ultra Instinct requests a native dash when available and otherwise uses the configured short sidestep burst. It no longer changes position directly. Normal controls stay enabled. Ultra Instinct can assist briefly while you run, then restores your current joystick or keyboard input. Both combat automations start off. Hidden server attacks and unknown animation cues cannot be predicted.

Download [the editable HTML](https://github.com/copperpoppercms-sys/Rift-Hub-Superhero-Arena/blob/main/docs/SuperheroArena_Editor.html) and open it in a browser to copy or edit the complete code. Standalone behavior checks live in that repository’s `tests/`. This repository checks the catalogue handoff and forwarding loader.

v5.7 adds Fast sidestep, on by default at speed 64 (adjustable 24–96). The temporary local speed request restores the previous value when it ends and preserves speed changes made by the game. Burst duration and travel remain capped. The server may reject/correct the speed request; live attack avoidance remains unverified. Mobile controls retain touch dispatch and changed manual input takes control immediately.
