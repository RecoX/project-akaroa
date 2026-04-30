# Project Akaroa

A 2D top-down MMO-style game built with Godot 4.6 and GDScript. Features tile-based movement, real-time combat, spell casting, NPC interactions, chunk-streamed world, and a full HUD with inventory, quests, crafting, and more.

## Prerequisites

- [Godot Engine 4.6](https://godotengine.org/download/) (standard or .NET build)
- Windows x86_64 (primary target platform)

Make sure the `godot` binary is on your PATH, or substitute the full path in the commands below. On Windows the binary is typically named `Godot_v4.6-stable_win64.exe` or similar.

## Opening the Project

```bash
# Launch the editor
godot --editor --path .
```

Or open Godot, click **Import**, and select the `project.godot` file.

## Running the Game

```bash
# Run the main scene from the command line
godot --path .
```

This launches `scenes/main.tscn`, the default main scene.

## Compiling / Exporting from CLI

A Windows Desktop export preset is already configured in `export_presets.cfg`.

```bash
# Export a debug build
godot --headless --path . --export-debug "Windows Desktop"

# Export a release build
godot --headless --path . --export-release "Windows Desktop"
```

Both produce `Project Akaroa.exe` (and a `.pck` file) in the project root. The `--headless` flag lets the export run without opening a window.

## Running Unit Tests

Tests live in the `tests/` directory as Godot scene files. Each test scene has a GDScript that runs automatically on `_ready()` and prints results to the Output console.

| Test scene | What it covers |
|---|---|
| `tests/test_combat_system.tscn` | Property-based tests for combat math, range validation, collision, mana, healing, damage, XP, critical hits, NPC colors, entity integrity |
| `tests/test_target_selection.tscn` | Property-based tests for target selection via StateManager |
| `tests/test_mock_data_provider.tscn` | Data loading and lookup tests for MockDataProvider |
| `tests/test_integration.tscn` | Integration tests across multiple systems |

### From the editor

Open any test `.tscn` file and press **F5** (or **Run Current Scene**). Results print to the **Output** panel at the bottom.

### From the command line

```bash
# Run a single test scene headlessly (exits after one frame cycle)
godot --headless --path . --run-scene tests/test_combat_system.tscn

# Run all test scenes sequentially
godot --headless --path . --run-scene tests/test_combat_system.tscn
godot --headless --path . --run-scene tests/test_target_selection.tscn
godot --headless --path . --run-scene tests/test_mock_data_provider.tscn
godot --headless --path . --run-scene tests/test_integration.tscn
```

Tests use deterministic seeds so results are reproducible. A non-zero exit code or `push_error` output indicates failures.

## Project Structure

```
project.godot          # Godot project config, autoloads, display settings
scenes/                # All .tscn scene files
  main.tscn            # Entry point scene
  world/               # Gameplay scene, world manager
  ui/                  # HUD, hotkey bar, panels (shop, bank, quest, etc.)
  characters/          # Character scene template
  effects/             # Spell effect scenes (fireball, heal, ice shard)
scripts/               # All GDScript source files
  state_manager.gd     # Autoload — central game state and signal hub
  mock_data_provider.gd# Autoload — loads JSON game data
  combat_system.gd     # Melee, ranged, spell damage and cooldowns
  spell_manager.gd     # Spell casting, range/mana validation
  tile_engine.gd       # Tile-based movement and collision
  character_renderer.gd# 3D character models, overhead UI, highlights
  network_client.gd    # Autoload — network stub
  audio_manager.gd     # Autoload — SFX playback
  logger.gd            # Autoload — tagged logging utility
data/                  # JSON game data
  chunks/              # World chunk definitions (32×32 tile regions)
  enemies/             # Enemy definitions (enemies.json)
  npcs/                # NPC definitions (npcs.json)
  spells/              # Spell definitions
  items/               # Item definitions
tests/                 # Test scenes and scripts
assets/                # Art, audio, and other assets
build/                 # Build artifacts
```

## Autoloads

These singletons are available globally in any script:

| Name | Script | Purpose |
|---|---|---|
| `Log` | `scripts/logger.gd` | Tagged logging (`Log.info`, `Log.debug`, `Log.error`) |
| `StateManager` | `scripts/state_manager.gd` | Central game state, player data, all inter-system signals |
| `NetworkClient` | `scripts/network_client.gd` | Network communication stub |
| `AudioManager` | `scripts/audio_manager.gd` | Sound effect playback |
| `MockDataProvider` | `scripts/mock_data_provider.gd` | Loads and serves JSON game data |

## License

See project files for license details.
