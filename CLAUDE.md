# Voidcraft

2D top-down RTS/MOBA-style roguelite built in **Godot 4.6** with **GDScript**.

## Overview

The player manages a home base and ventures into procedural combat maps to gather resources. All graphics use basic 2D shapes (Polygon2D, ColorRect) — no art assets.

## Architecture

- **Autoloads** (`autoloads/`): `EventBus` (signal hub), `GameManager` (state machine: HOME/COMBAT/RESULTS), `ResourceManager` (currency tracking)
- **Scenes** (`scenes/`): `main/` (root), `player/`, `enemies/`, `projectiles/`, `buildings/`, `maps/`, `ui/`
- **Components** (`components/`): Reusable nodes — `HealthComponent`, `HitboxComponent`, `HurtboxComponent`
- **Resources** (`resources/`): Custom Resource classes + `.tres` data files for buildings/enemies

### Key design decisions
- Player persists as child of Main, not the map. Maps are swapped inside a `MapContainer` node.
- Navigation uses Godot's built-in NavigationAgent2D/NavigationRegion2D.
- Combat uses hitbox/hurtbox pattern with Area2D collision detection.
- Grid snap for building placement: 32px.

### Collision layers
| Layer | Name        | Used By            |
|-------|-------------|--------------------|
| 1     | Terrain     | Obstacles, walls   |
| 2     | Player      | Player body        |
| 3     | Enemy       | Enemy body         |
| 4     | PlayerProj  | Player projectiles |
| 5     | EnemyProj   | Enemy projectiles  |
| 6     | Building    | Buildings          |
| 7     | Interactable| Teleporter         |

## Running

Open in Godot 4.6 editor and press F5. Main scene: `res://scenes/main/main.tscn`.

## Input Map

- **Right-click**: Move / interact / attack
- **Left-click**: Select / confirm placement
- **Escape**: Cancel current action
- **B**: Toggle build menu (home base only)

## Conventions

- One script per scene, named to match the scene file.
- Signals for cross-system communication go through `EventBus`.
- Enemy/building stats defined as custom `Resource` `.tres` files.
- State machines use enums and match statements.


# Godot Project Instructions

## Build and Debug Commands
- **Check All Scripts:** `timeout 5 C:/Users/kamme/Desktop/repos/Games/Godot_v4.6.1-stable_win64_console.exe --headless --check-only --path "C:/Users/kamme/Desktop/repos/Games/voidcraft" --verbose`
- **Check Specific Script:** `timeout 5 C:/Users/kamme/Desktop/repos/Games/Godot_v4.6.1-stable_win64_console.exe --headless --check-only -s [FILE_PATH]`
- **Run Tests:** `timeout 5 C:/Users/kamme/Desktop/repos/Games/Godot_v4.6.1-stable_win64_console.exe --headless -s res://path/to/test_runner.gd`
- **Full Startup Check:** `timeout 5 C:/Users/kamme/Desktop/repos/Games/Godot_v4.6.1-stable_win64_console.exe --headless --path "C:/Users/kamme/Desktop/repos/Games/voidcraft" --quit --verbose --debug --no-debugger > debug_log.txt 2>&1; cat debug_log.txt`  // use this one whenever you're done making changes to find issues that crash the game immediately on startup
- **Fast Syntax Check:** `timeout 5 C:/Users/kamme/Desktop/repos/Games/Godot_v4.6.1-stable_win64_console.exe --headless --check-only --path "C:/Users/kamme/Desktop/repos/Games/voidcraft"`

Report to me if any of these scripts seem broken

## Guidelines
- Always use GDScript 2.0 (Godot 4) syntax.
- If a compilation error occurs, run the "Check All Scripts" command to see the full log.
- Add debug logs to the game in places that don't loop infinitely (eg. log all player input, log state changes etc.) to have an overview of what happened in a given run of the game
