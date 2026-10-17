# Rift Hub — Superhero Arena

Standalone Luau for Superhero Arena by The Duelists. No repository or downloaded UI library is required. Nothing in this folder has been published to GitHub.

Open **XenoHub_SuperheroArena_Editor.html** to edit the entire script, copy it into Delta, or download your edited Lua file. Edits in that HTML page are not saved automatically. The Lua source is **XenoHub_SuperheroArena.lua**.

## Interface

Charcoal surfaces, warm amber accents, animated buttons and navigation, avatar headshots, and a searchable player list. Drag the header to move the window. RightShift or minus minimizes to a draggable X logo. Tap X to restore; × unloads the hub and all its features. Navigation contains Overview, Combat, Abilities, Farming, Visuals, Movement, World, Players, Utility and Settings, with a scrolling sidebar.

If Claude's original script is still running, rejoin once before trying this version. This version unloads itself when rerun.

## Combat and farming — v2.13

All automation starts off. Combat supports mutually exclusive **Kill aura · nearby attacks** (no pursuit), **Auto fight · pursue players** and **Auto farm NPCs** modes. They select living humanoid targets and use normal game controls. These features do not grant instant kills, range bypasses, rewards or server damage authority.

Choose an attack method in Combat:

- **HUD attack** detects an unambiguous, visible Attack/Punch/M1 button in the game's PlayerGui and attempts its connected activation/click signal. Requires executor GUI signal support. Ambiguous or missing controls stop automation with an actionable status.
- **Equipped tool** calls the currently equipped tool's normal Activate method. Equip an actual weapon tool first.
- **Keyboard key** sends the key assigned by the user, requiring VirtualInputManager support. No attack key is guessed.

Configure attack interval and melee activation range, team/wall checks, nearest/lowest-health priority and a low-health pause threshold. Search range controls pursuit. Ability key rotation uses only a user-entered list of actual game keys and an adjustable interval. L, T, F8 and RightShift are reserved for the hub. Inputs are released after each pulse and on pause/disable/unload.

**Minimize the hub to run automation.** It pauses while the menu is open, typing, unfocused, dead, anchored or at/below the health threshold. It does not act on a missing target. Attack input failures turn the mode off. Inputs sent are counted; hits or kills are not inferred from input attempts.

NPC farming scans living humanoid models on a bounded two-second scan, excludes player bodies and supports an optional NPC name filter. Pursuit uses ordinary Humanoid MoveTo toward eligible visible targets, with no teleporting or pathfinding around obstacles. A game without attackable humanoid NPCs has nothing for this mode to farm. Native hit validation, attack cooldowns, damage and rewards still apply.

The current game data supplied by the user identifies heroes but does not identify the game's attack handlers or verify NPC availability. **The adapters and loops pass simulated checks; live Superhero Arena compatibility remains unverified.** Use Utility → Copy attack setup report to help identify a missing control. No damage/currency remotes are fabricated.

## Abilities

Camera lock-on starts **off**. Enable **Abilities → Auto lock-on**, or press **L**. Press **T** or select **Next target** to cycle eligible players. Hold mode supports right mouse and a separate on-screen **HOLD LOCK** button; touch ownership prevents another finger from releasing the lock.

- Sticky target retention, with automatic reacquisition after invalidation.
- Crosshair, nearest or lowest-health priority; head or body aim.
- Screen radius, character distance, optional wall checks and replicated team filtering. Dead, missing and off-screen targets are excluded.
- Adjustable camera response and optional linear movement prediction, capped at 25 studs. Prediction defaults to zero; it is not a hero-specific projectile model.
- Acquisition circle, a target outline independent of ESP, and a live username/hero/health/distance panel.

The camera updates after Roblox's camera step, preserving its position. It pauses during typing, focus loss, death and Scriptable cutscene cameras. Unloading and rerunning remove its render binding, overlays and input connections.

**This controls camera aim.** Native abilities may use camera direction, cursor position, a target ID or server logic. The game integration has not been tested live, so universal ability targeting or automatic casting is not claimed. The script does not fabricate ability remotes or change server cooldowns.

## Simple movement

Movement includes **Noclip**, custom walk speed, custom jump strength and air jump, all off by default. The custom dash, invisible dash-button cover, animation discovery, auto leap and input-binding tools have been removed.

Noclip disables `CanCollide` on the local character's parts before each physics simulation step. Each part's original value is saved, including parts that were already noncolliding. Newly added parts are included; parts leaving the character are restored. Turning the toggle off, death, character replacement, unloading or rerunning the hub restores the affected parts. If enabled across a respawn, noclip resumes on the new character. World geometry, other players and other physics settings are unchanged.

The game can still constrain client movement. Live Roblox/Delta testing is needed to assess that behavior.

## World and utility

World contains Fullbright, clear fog/haze, a custom field-of-view toggle and FOV slider. Movement supports both JumpPower and JumpHeight. Only modified properties are saved/restored; disabling, death/respawn, camera replacement and unload restore the relevant settings. Server movement corrections can still apply.

**F8 / Utility → Stop all features** stops automation and camera lock, disables ESP/noclip and restores extra world/movement settings. Utility also contains a world/movement reset, a rotation clear and the attack setup report.

## Other features

- Visuals: per-hero highlights, usernames, hero labels, model bounds boxes, tracers, camera distance, fill opacity and range.
- Hero detection reads the confirmed character attributes `MorphCurrent` and `power` first. User-confirmed aliases include Water → Aquaman, Earth → Hulk, Knight → Thor, Samurai → Deadpool and Nature → Groot.
- The user's requested estimates (for example Ice → Frozone, Wind → Storm, Fire → Ghost Rider and Angel → Superman) show **(guess)**. Visuals can disable these estimates. All 25 supplied hero names resolve directly.
- When a hero menu exposes explicit ID fields next to one recognized hero label, the script can learn the pair. Ambiguous/shared containers and conflicting IDs are rejected. User-confirmed mappings have priority.
- Player inspection and hero/menu reports remain available for missing or incorrect role names.

## Validation

Set `LUAU_BIN` and `LUAU_COMPILE_BIN` to the native Luau tools, then run:

```sh
python tests/run_checks.py
```

The checks compile the entire file and exercise it in a mocked Roblox client. They cover normal tool/HUD/key attacks, NPC filtering, pursuit/stop behavior, ability rotation, focus/health/menu/wall/team pauses, missing input adapters, key releases, stale callbacks, F8, lighting/fog/atmosphere/FOV/jump restoration, and target eligibility, priorities, sticky/cycling behavior, prediction, hold inputs, camera pausing, render cleanup and noclip's toggle, original true/false collision states, added/removed parts, death, respawn, character replacement, re-execution and unload, alongside hero detection, ESP, navigation, reports and signal cleanup. These checks do not reproduce live Roblox physics or server behavior.
