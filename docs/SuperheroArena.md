# Rift Hub · Superhero Arena

The current v5.9 script is maintained in [Rift-Hub-Superhero-Arena](https://github.com/copperpoppercms-sys/Rift-Hub-Superhero-Arena). The main hub’s game catalogue fetches that repository’s `main.lua`; `games/superhero-arena.lua` is a compatibility loader.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub-Superhero-Arena/main/main.lua"))()
```

Game: [Superhero Arena by The Duelists](https://www.roblox.com/games/78710221869926/Superhero-Arena), place ID `78710221869926`, universe ID `10765491459` (verified against Roblox’s game listing).

The Hub card uses Roblox’s published game icon and the same compact card style as MM2. Execute closes the universal hub and opens the animated Combat, Visuals and Settings interface. Auto Farm lives under Combat; ESP shows hero-colored chams and a role above the username under Visuals. Ultra Instinct now defaults to a single local teleport request on a detected nearby attack, capped at 12 studs with clearance/ground checks. It preserves normal inputs, facing, speed and velocity. Native/walking mode remains available by turning Teleport dodge off. Both combat automations start off. Hidden server attacks and unknown animation cues cannot be predicted.

Download [the editable HTML](https://github.com/copperpoppercms-sys/Rift-Hub-Superhero-Arena/blob/main/docs/SuperheroArena_Editor.html) and open it in a browser to copy or edit the complete code. Standalone behavior checks live in that repository’s `tests/`. This repository checks the catalogue handoff and forwarding loader.

v5.9 adds the requested teleport mode and Test teleport. Hidden damage bounds remain estimates; the server may correct local movement, and avoiding every ability is not guaranteed. Raw game lock fields are never rewritten. Automatic avoidance still needs live verification.
