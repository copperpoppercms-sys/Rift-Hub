# Rift Hub / Superhero Arena 3.0

Standalone Luau with five sections: Combat, Hero Skills, Movement, Visuals and Server. All automation starts off. RightShift or the minus button minimizes to a draggable R button; the close button unloads and restores modified settings. Minimize to run combat, skill rotation and auto dash. They pause during typing, focus loss, death or an anchored local character.

## Combat & Targeting

Kill Aura attempts normal nearby attacks using a detected game Attack/Punch/M1 control, an equipped tool or a desktop primary-mouse input. Burst Hits sends three spaced inputs, not three guaranteed hits. Auto Face rotates toward the nearest living player without changing position. Auto Chase uses ordinary walking; Aura Range controls attack attempts and Chase Range limits pursuit and skill targeting. Nearest Target selects the nearest player within those ranges. Big Hitbox changes local root-part sizes and restores original sizes/collision flags on disable, death, respawn, removal or unload. Server validation still decides hits and damage.

## Hero Skills & Abilities

Hero Selection includes Iron Man and requests selection through the game's visible hero-menu control. Open that menu first. Equipped-hero detection reads the previously confirmed MorphCurrent/power attributes. Iron Man's supplied profile contains Primary: Repulsor Blast and Tertiary: Unibeam; Secondary and Quaternary are unavailable. Other heroes' skill names/slots are read only from explicit game HUD metadata. Skill interval and Use All Available Skills control rotation. Hidden, ambiguous or unreadable controls cannot be activated; no ability remote or key binding is invented.

Dash Now requests the visible native Dash/Dodge control. Auto Dash repeats native requests at the selected interval and preserves known cooldown states. **Infinite Dash is explicitly unavailable:** the supplied data has no verified mechanism for removing the server cooldown. Its control explains that limitation; it is not a working cooldown bypass.

## Movement, visuals and server

Infinite Jump requests the native humanoid jumping state. WalkSpeed saves/restores the original speed. Player ESP shows names and detected heroes; Player Highlights is independent. Fullbright saves/restores affected lighting settings. Rejoin Server requests the current server instance through TeleportService.

Removed: overview/dashboard, farming, camera lock-on, prediction/FOV panels, player browser, utility/configuration tabs, tracers/boxes, noclip, custom jump-strength and fog controls. Internal hero detection remains for skill/ESP correctness.

## Run

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub/main/games/superhero-arena.lua"))()
```

`SuperheroArena_Editor.html` contains the complete editable source with copy/download controls. The local persistent editor also remains available at `XenoHub_SuperheroArena_Editor.html`.

## Validation and limits

`python tests/run_superhero.py` from the repository root compiles the full script and runs simulated UI, targeting, attack/burst, skill discovery/rotation, native dash, hitbox, movement, lighting, rejoin and cleanup checks. Set LUAU_BIN and LUAU_COMPILE_BIN to the native Luau tools if needed. Live Roblox/Delta integration has not been tested. Control activation, local hitbox effectiveness, movement limits and native cooldowns depend on the game and executor. A working game's script/loader is still needed to verify its actual attack, skill and dash bindings.
