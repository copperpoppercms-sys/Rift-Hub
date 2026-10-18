# Rift Hub · Superhero Arena

The current v4.6 script is maintained in [Rift-Hub-Superhero-Arena](https://github.com/copperpoppercms-sys/Rift-Hub-Superhero-Arena). The main hub’s game catalogue fetches that repository’s `main.lua`; `games/superhero-arena.lua` is a compatibility loader.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub-Superhero-Arena/main/main.lua"))()
```

Game: [Superhero Arena by The Duelists](https://www.roblox.com/games/78710221869926/Superhero-Arena), place ID `78710221869926`, universe ID `10765491459` (verified against Roblox’s game listing).

The Hub card uses Roblox’s published game icon and the same compact card style as MM2. Execute closes the universal hub and opens the current PLAY/STOP panel. Tap PLAY to start. A full game UI can be added later.

Download [the editable HTML](https://github.com/copperpoppercms-sys/Rift-Hub-Superhero-Arena/blob/main/docs/SuperheroArena_Editor.html) and open it in a browser to copy or edit the complete code. Standalone behavior checks live in that repository’s `tests/`. This repository checks the catalogue handoff and forwarding loader.
