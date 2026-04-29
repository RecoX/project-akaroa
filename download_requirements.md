# Asset Download Requirements — Project Akaroa

Everything you need to download or create before the code can render properly.
Paths listed are where the code expects to find each file.

---

## 1. 3D Models (`.glb` or `.gltf`)

### Characters (rigged with Skeleton3D + animations)

You need **one base humanoid model** with a skeleton that supports bone attachments.
Ideally from Mixamo or similar, exported as `.glb`.

| # | Asset | Path | Notes |
|---|-------|------|-------|
| 1 | Human male body | `assets/models/characters/human_male.glb` | Base character mesh. Needs Skeleton3D with bones for weapon_slot, shield_slot, helmet_slot. |
| 2 | Human female body | `assets/models/characters/human_female.glb` | Optional second body variant. |
| 3 | Ghost / spirit model | `assets/models/characters/ghost.glb` | Translucent spirit for death state. Can be a simple glowing humanoid shape. |
| 4 | Mounted character | `assets/models/characters/mounted.glb` | Character on horse. Could be a single combined mesh. |
| 5 | Boat model | `assets/models/characters/boat.glb` | Small rowboat / skiff for water navigation. |

**Animations needed on the base character model (can be separate `.glb` files or embedded):**

| Animation | Variants |
|-----------|----------|
| idle | idle_north, idle_east, idle_south, idle_west |
| walk | walk_north, walk_east, walk_south, walk_west |
| attack_melee | 1 animation (plays from any facing) |
| attack_ranged | 1 animation |
| cast_spell | 1 animation |
| hit | 1 animation (receive damage) |
| death | 1 animation |

That's **15 animations** total. Mixamo has all of these — download for the same character rig.

### Equipment (attach to skeleton bone slots)

| # | Asset | Path | Notes |
|---|-------|------|-------|
| 6 | Iron sword | `assets/models/weapons/iron_sword.glb` | Melee weapon mesh |
| 7 | Steel sword | `assets/models/weapons/steel_sword.glb` | Higher-tier melee weapon |
| 8 | Wooden bow | `assets/models/weapons/wooden_bow.glb` | Ranged weapon mesh |
| 9 | Staff | `assets/models/weapons/staff.glb` | Magic weapon mesh |
| 10 | Wooden shield | `assets/models/weapons/wooden_shield.glb` | Shield mesh |
| 11 | Steel shield | `assets/models/weapons/steel_shield.glb` | Higher-tier shield |
| 12 | Iron helmet | `assets/models/weapons/iron_helmet.glb` | Helmet mesh |
| 13 | Leather armor | `assets/models/weapons/leather_armor.glb` | Body armor overlay (optional — can skip if using color tinting) |

### NPCs

| # | Asset | Path | Notes |
|---|-------|------|-------|
| 14 | Blacksmith NPC | `assets/models/npcs/blacksmith.glb` | Can reuse base humanoid with different texture/color |
| 15 | Merchant NPC | `assets/models/npcs/merchant.glb` | Can reuse base humanoid |
| 16 | Quest giver NPC | `assets/models/npcs/quest_giver.glb` | Can reuse base humanoid |

### Enemies

| # | Asset | Path | Notes |
|---|-------|------|-------|
| 17 | Goblin | `assets/models/enemies/goblin.glb` | Small humanoid enemy. Needs idle + walk + attack + death anims. |
| 18 | Skeleton warrior | `assets/models/enemies/skeleton.glb` | Undead enemy variant |
| 19 | Wolf | `assets/models/enemies/wolf.glb` | Animal enemy variant |

**3D Models total: ~19 model files** (many can be recolored/resized variants of the same base)

---

## 2. Textures / Tile Graphics (`.png`)

### Ground Tiles (used as quad textures on the 3D plane)

| # | Asset | Path | Notes |
|---|-------|------|-------|
| 1 | Grass tile | `assets/tiles/grass_01.png` | 32x32 or 64x64 px, tileable |
| 2 | Dirt tile | `assets/tiles/dirt_01.png` | |
| 3 | Stone tile | `assets/tiles/stone_01.png` | |
| 4 | Sand tile | `assets/tiles/sand_01.png` | |
| 5 | Water tile | `assets/tiles/water_01.png` | Animated: 3-4 frames for water_01, water_02, water_03 |
| 6 | Snow tile | `assets/tiles/snow_01.png` | |
| 7 | Wood floor | `assets/tiles/wood_01.png` | Interior floor |
| 8 | Dungeon floor | `assets/tiles/dungeon_01.png` | |
| 9 | Road/path tile | `assets/tiles/road_01.png` | |

### Object / Wall Tiles

| # | Asset | Path | Notes |
|---|-------|------|-------|
| 10 | Stone wall | `assets/tiles/wall_stone_01.png` | |
| 11 | Wood wall | `assets/tiles/wall_wood_01.png` | |
| 12 | Tree | `assets/tiles/tree_01.png` | |
| 13 | Bush | `assets/tiles/bush_01.png` | |
| 14 | Roof tile | `assets/tiles/roof_01.png` | For building rooftops (fades when player enters) |

### Animated Object Tiles

| # | Asset | Path | Notes |
|---|-------|------|-------|
| 15 | Campfire | `assets/tiles/campfire_01.png` through `campfire_04.png` | 4 frames |
| 16 | Fountain | `assets/tiles/fountain_01.png` through `fountain_03.png` | 3 frames |

**Tile textures total: ~20-25 image files**

---

## 3. UI Icons (`.png`)

| # | Asset | Path | Notes |
|---|-------|------|-------|
| 1 | Iron sword icon | `assets/icons/iron_sword.png` | 32x32 or 64x64 inventory icon |
| 2 | Steel sword icon | `assets/icons/steel_sword.png` | |
| 3 | Wooden bow icon | `assets/icons/wooden_bow.png` | |
| 4 | Staff icon | `assets/icons/staff.png` | |
| 5 | Wooden shield icon | `assets/icons/wooden_shield.png` | |
| 6 | Steel shield icon | `assets/icons/steel_shield.png` | |
| 7 | Iron helmet icon | `assets/icons/iron_helmet.png` | |
| 8 | Leather armor icon | `assets/icons/leather_armor.png` | |
| 9 | Health potion icon | `assets/icons/health_potion.png` | |
| 10 | Mana potion icon | `assets/icons/mana_potion.png` | |
| 11 | Iron ore icon | `assets/icons/iron_ore.png` | Crafting material |
| 12 | Wood plank icon | `assets/icons/wood_plank.png` | Crafting material |
| 13 | Gold coins icon | `assets/icons/gold_coins.png` | |
| 14 | Goblin ear icon | `assets/icons/goblin_ear.png` | Quest drop |
| 15 | Fireball spell icon | `assets/icons/fireball.png` | |
| 16 | Heal spell icon | `assets/icons/heal.png` | |
| 17 | Ice shard spell icon | `assets/icons/ice_shard.png` | |
| 18 | Lightning spell icon | `assets/icons/lightning.png` | |
| 19 | Mount item icon | `assets/icons/mount_horse.png` | |
| 20 | Boat item icon | `assets/icons/boat.png` | |

### Minimap POI Icons

| # | Asset | Path | Notes |
|---|-------|------|-------|
| 21 | Coin (shopkeeper) | `assets/icons/poi_shop.png` | 12x12 minimap marker |
| 22 | Exclamation (quest) | `assets/icons/poi_quest.png` | |
| 23 | Door (zone exit) | `assets/icons/poi_exit.png` | |
| 24 | Shield (safe zone) | `assets/icons/poi_safe.png` | |
| 25 | Portal (teleporter) | `assets/icons/poi_portal.png` | |
| 26 | Skull (dungeon) | `assets/icons/poi_dungeon.png` | |

**UI icons total: ~26 image files**

---

## 4. Music (`.ogg`)

| # | Asset | Path | Notes |
|---|-------|------|-------|
| 1 | Login / menu theme | `assets/audio/music/menu_theme.ogg` | Loopable, calm medieval |
| 2 | Verdant Plains | `assets/audio/music/verdant_plains.ogg` | Outdoor exploration, referenced in zone data |
| 3 | Town / safe zone | `assets/audio/music/town.ogg` | Peaceful town ambiance |
| 4 | Dungeon | `assets/audio/music/dungeon.ogg` | Dark, tense |
| 5 | Combat (optional) | `assets/audio/music/combat.ogg` | Upbeat battle music |

**Music total: 4-5 tracks**

---

## 5. Sound Effects (`.ogg`)

### Combat SFX

| # | Asset | Path | Notes |
|---|-------|------|-------|
| 1 | Sword hit 1 | `assets/audio/sfx/sword_hit_01.ogg` | Melee impact |
| 2 | Sword hit 2 | `assets/audio/sfx/sword_hit_02.ogg` | Variant |
| 3 | Sword swing | `assets/audio/sfx/sword_swing.ogg` | Melee attack |
| 4 | Bow shot | `assets/audio/sfx/bow_shot.ogg` | Ranged attack |
| 5 | Arrow hit | `assets/audio/sfx/arrow_hit.ogg` | Ranged impact |
| 6 | Fireball cast | `assets/audio/sfx/fireball_cast.ogg` | Spell cast |
| 7 | Fireball impact | `assets/audio/sfx/fireball_impact.ogg` | Spell hit |
| 8 | Heal cast | `assets/audio/sfx/heal_cast.ogg` | Healing spell |
| 9 | Ice shard cast | `assets/audio/sfx/ice_shard_cast.ogg` | Ice spell |
| 10 | Critical hit | `assets/audio/sfx/critical_hit.ogg` | Extra impact sound |
| 11 | Death sound | `assets/audio/sfx/death.ogg` | Character death |

### Footsteps (one per terrain type)

| # | Asset | Path | Notes |
|---|-------|------|-------|
| 12 | Grass footstep | `assets/audio/sfx/footstep_grass.ogg` | |
| 13 | Stone footstep | `assets/audio/sfx/footstep_stone.ogg` | |
| 14 | Sand footstep | `assets/audio/sfx/footstep_sand.ogg` | |
| 15 | Snow footstep | `assets/audio/sfx/footstep_snow.ogg` | |
| 16 | Wood footstep | `assets/audio/sfx/footstep_wood.ogg` | |
| 17 | Water footstep | `assets/audio/sfx/footstep_water.ogg` | Splashing |
| 18 | Dungeon footstep | `assets/audio/sfx/footstep_dungeon.ogg` | Echoing stone |

### UI / Misc SFX

| # | Asset | Path | Notes |
|---|-------|------|-------|
| 19 | UI click | `assets/audio/sfx/ui_click.ogg` | Button press |
| 20 | Item pickup | `assets/audio/sfx/item_pickup.ogg` | |
| 21 | Item equip | `assets/audio/sfx/item_equip.ogg` | |
| 22 | Gold coins | `assets/audio/sfx/gold_coins.ogg` | Buy/sell |
| 23 | Level up | `assets/audio/sfx/level_up.ogg` | Fanfare |
| 24 | Quest complete | `assets/audio/sfx/quest_complete.ogg` | |
| 25 | Craft success | `assets/audio/sfx/craft_success.ogg` | |
| 26 | Craft fail | `assets/audio/sfx/craft_fail.ogg` | |

**SFX total: ~26 files**

---

## 6. Ambient Audio (`.ogg`, loopable)

| # | Asset | Path | Notes |
|---|-------|------|-------|
| 1 | Plains wind | `assets/audio/ambient/plains_wind.ogg` | Referenced in zone data |
| 2 | Campfire crackle | `assets/audio/ambient/campfire.ogg` | Positional, near campfire tiles |
| 3 | Waterfall / river | `assets/audio/ambient/waterfall.ogg` | Positional |
| 4 | Rain | `assets/audio/ambient/rain.ogg` | Weather system |
| 5 | Wind (storm) | `assets/audio/ambient/wind_storm.ogg` | Weather system |
| 6 | Forge / anvil | `assets/audio/ambient/forge.ogg` | Near blacksmith NPC |
| 7 | Sailing / waves | `assets/audio/ambient/sailing.ogg` | Boat navigation |
| 8 | Dungeon drips | `assets/audio/ambient/dungeon_drips.ogg` | Dungeon zones |

**Ambient total: ~8 files**

---

## Grand Total Summary

| Category | File Count |
|----------|-----------|
| 3D Models (`.glb`) | ~19 |
| Character Animations | ~15 (can be embedded in model files) |
| Tile Textures (`.png`) | ~25 |
| UI Icons (`.png`) | ~26 |
| Music (`.ogg`) | 4-5 |
| Sound Effects (`.ogg`) | ~26 |
| Ambient Audio (`.ogg`) | ~8 |
| **TOTAL** | **~120-125 files** |

---

## Recommended Free Sources

| Source | What to get | License |
|--------|------------|---------|
| [Mixamo](https://www.mixamo.com) | Rigged humanoid character + all 15 animations | Free (Adobe account) |
| [Kenney.nl](https://kenney.nl) | Tile textures, UI icons, some 3D models | CC0 (public domain) |
| [OpenGameArt.org](https://opengameart.org) | Medieval fantasy tiles, icons, SFX, music | Various (check per asset) |
| [Freesound.org](https://freesound.org) | All SFX and ambient audio | CC0 / CC-BY |
| [Incompetech](https://incompetech.com) | Royalty-free medieval music | CC-BY |
| [Quaternius](https://quaternius.com) | Low-poly 3D models (characters, weapons, enemies) | CC0 |
| [Kay Lousberg](https://kaylousberg.itch.io) | Free low-poly 3D asset packs | CC0 |

---

## Minimum Viable Set (to get the demo running)

If you want to start fast, you only strictly need:

1. **1 humanoid `.glb`** with skeleton (from Mixamo) + idle/walk/attack animations
2. **1 enemy `.glb`** (goblin or skeleton — Quaternius has free ones)
3. **5-6 tile textures** (grass, dirt, stone, water, wall, tree)
4. **5-6 item/spell icons** (sword, shield, potion, fireball, heal)
5. **1 music track** (any medieval loop)
6. **5-6 SFX** (hit, swing, footstep, UI click, level up)

That's about **20 files** to get the core loop visible. Everything else can use Godot's built-in primitives (colored BoxMesh, CapsuleMesh) as placeholders — the code has fallback handling for missing assets.
