## Mock_Data_Provider — Autoload Singleton.
##
## The single source of all demo data. All game systems read from this instead
## of a server. Loads JSON resource files at startup into GDScript dictionaries.
##
## Usage:
##   var chunk := MockDataProvider.get_chunk(0, 0)
##   var item := MockDataProvider.get_item("sword_01")
##   var characters := MockDataProvider.get_mock_characters()
extends Node


const _TAG := "MockDataProvider"


# ---------------------------------------------------------------------------
# Signals — game systems connect to these for data events
# ---------------------------------------------------------------------------

## Emitted when an inventory slot is updated with new item data.
signal inventory_updated(slot_index: int, item_data: Dictionary)

## Emitted when a character's data changes.
signal character_updated(char_id: String, char_data: Dictionary)

## Emitted when a quest becomes available from an NPC.
signal quest_available(npc_id: String, quest_data: Dictionary)

## Emitted when a combat event occurs.
signal combat_event(event_data: Dictionary)

## Emitted when a chat message is received.
signal chat_message_received(channel: String, sender: String, message: String)

## Emitted when the weather changes.
signal weather_changed(weather_type: String)

## Emitted when the player enters a new zone.
signal zone_entered(zone_data: Dictionary)


# ---------------------------------------------------------------------------
# Data caches — populated on _ready from JSON files
# ---------------------------------------------------------------------------

## Chunk data keyed by "x_y" string.
var _chunks_cache: Dictionary = {}

## Item definitions keyed by item_id.
var _items_db: Dictionary = {}

## Spell definitions keyed by spell_id.
var _spells_db: Dictionary = {}

## NPC definitions keyed by npc_id.
var _npcs_db: Dictionary = {}

## Quest definitions keyed by quest_id.
var _quests_db: Dictionary = {}

## Recipe definitions keyed by recipe_id.
var _recipes_db: Dictionary = {}

## Enemy definitions keyed by enemy_id.
var _enemies_db: Dictionary = {}

## Class definitions keyed by class_id.
var _classes_db: Dictionary = {}

## Race definitions keyed by race_id.
var _races_db: Dictionary = {}

## Zone metadata keyed by zone_id.
var _zones_db: Dictionary = {}

## Array of mock character dictionaries for character selection.
var _mock_characters: Array = []

## Mock guild data.
var _guild_data: Dictionary = {}

## Faction definitions keyed by faction_id.
var _factions_db: Dictionary = {}


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------


func _ready() -> void:
	_load_all_data()


# ---------------------------------------------------------------------------
# Getter methods
# ---------------------------------------------------------------------------


## Returns chunk data for the given chunk coordinates, or an empty dictionary
## if the chunk is not loaded.
func get_chunk(chunk_x: int, chunk_y: int) -> Dictionary:
	var key := "%d_%d" % [chunk_x, chunk_y]
	if key in _chunks_cache:
		return _chunks_cache[key]
	Log.warning(_TAG, "Chunk %s not found in cache" % key)
	return {}


## Returns item data for the given item ID, or a fallback dictionary if not found.
func get_item(item_id: String) -> Dictionary:
	if item_id in _items_db:
		return _items_db[item_id]
	Log.warning(_TAG, "Item '%s' not found — returning fallback" % item_id)
	return {"id": item_id, "name": "Unknown Item", "type": "misc", "description": "Item data not found."}


## Returns spell data for the given spell ID, or a fallback dictionary if not found.
func get_spell(spell_id: String) -> Dictionary:
	if spell_id in _spells_db:
		return _spells_db[spell_id]
	Log.warning(_TAG, "Spell '%s' not found — returning fallback" % spell_id)
	return {"id": spell_id, "name": "Unknown Spell", "mana_cost": 0, "damage": 0}


## Returns NPC data for the given NPC ID, or a fallback dictionary if not found.
func get_npc(npc_id: String) -> Dictionary:
	if npc_id in _npcs_db:
		return _npcs_db[npc_id]
	Log.warning(_TAG, "NPC '%s' not found — returning fallback" % npc_id)
	return {"id": npc_id, "name": "Unknown NPC", "type": "dialogue"}


## Returns quest data for the given quest ID, or an empty dictionary if not found.
func get_quest(quest_id: String) -> Dictionary:
	if quest_id in _quests_db:
		return _quests_db[quest_id]
	Log.warning(_TAG, "Quest '%s' not found" % quest_id)
	return {}


## Returns an array of recipes for the given crafting discipline, or an empty
## array if no recipes exist for that discipline.
func get_recipes_for_discipline(discipline: String) -> Array:
	var results: Array = []
	for recipe in _recipes_db.values():
		if recipe.get("discipline", "") == discipline:
			results.append(recipe)
	return results


## Returns the array of mock characters for character selection.
func get_mock_characters() -> Array:
	return _mock_characters


## Returns zone metadata for the given zone ID, or a fallback dictionary if not found.
func get_zone_metadata(zone_id: String) -> Dictionary:
	if zone_id in _zones_db:
		return _zones_db[zone_id]
	Log.warning(_TAG, "Zone '%s' not found — returning fallback" % zone_id)
	return {"id": zone_id, "name": "Unknown Zone", "music_track": "", "ambient_sound": "", "weather_default": "clear"}


## Returns an array of enemy data dictionaries for enemies in the given chunk,
## or an empty array if the chunk has no enemies or is not loaded.
func get_enemies_in_chunk(chunk_x: int, chunk_y: int) -> Array:
	var key := "%d_%d" % [chunk_x, chunk_y]
	if key in _chunks_cache:
		return _chunks_cache[key].get("enemies", [])
	return []


## Returns class data for the given class ID, or an empty dictionary if not found.
func get_class_data(class_id: String) -> Dictionary:
	if class_id in _classes_db:
		return _classes_db[class_id]
	Log.warning(_TAG, "Class '%s' not found" % class_id)
	return {}


## Returns race data for the given race ID, or an empty dictionary if not found.
func get_race_data(race_id: String) -> Dictionary:
	if race_id in _races_db:
		return _races_db[race_id]
	Log.warning(_TAG, "Race '%s' not found" % race_id)
	return {}


## Returns mock guild data.
func get_guild_data() -> Dictionary:
	return _guild_data


## Persists a character data dictionary locally for character creation.
## Saves to user://characters/ and appends to the mock characters list.
func save_character_locally(char_data: Dictionary) -> void:
	_mock_characters.append(char_data)
	var dir_path := "user://characters"
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)
	var char_name: String = char_data.get("name", "unnamed")
	var file_path := "%s/%s.json" % [dir_path, char_name.to_lower().replace(" ", "_")]
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(char_data, "\t"))
		file.close()
		Log.info(_TAG, "Character '%s' saved to %s" % [char_name, file_path])
	else:
		Log.error(_TAG, "Failed to save character '%s' to %s" % [char_name, file_path])


# ---------------------------------------------------------------------------
# Data loading
# ---------------------------------------------------------------------------


## Loads all JSON data files into their respective caches.
## Gracefully handles missing files by logging warnings and continuing.
func _load_all_data() -> void:
	Log.info(_TAG, "Loading all mock data...")

	# Items
	var items_data: Variant = _load_json("res://data/items/items.json")
	if items_data is Array:
		for item in items_data:
			var item_id: String = item.get("id", "")
			if item_id != "":
				_items_db[item_id] = item
		Log.info(_TAG, "Loaded %d items" % _items_db.size())

	# Spells
	var spells_data: Variant = _load_json("res://data/spells/spells.json")
	if spells_data is Array:
		for spell in spells_data:
			var spell_id: String = spell.get("id", "")
			if spell_id != "":
				_spells_db[spell_id] = spell
		Log.info(_TAG, "Loaded %d spells" % _spells_db.size())

	# NPCs
	var npcs_data: Variant = _load_json("res://data/npcs/npcs.json")
	if npcs_data is Array:
		for npc in npcs_data:
			var npc_id: String = npc.get("id", "")
			if npc_id != "":
				_npcs_db[npc_id] = npc
		Log.info(_TAG, "Loaded %d NPCs" % _npcs_db.size())

	# Quests
	var quests_data: Variant = _load_json("res://data/quests/quests.json")
	if quests_data is Array:
		for quest in quests_data:
			var quest_id: String = quest.get("id", "")
			if quest_id != "":
				_quests_db[quest_id] = quest
		Log.info(_TAG, "Loaded %d quests" % _quests_db.size())

	# Recipes
	var recipes_data: Variant = _load_json("res://data/recipes/recipes.json")
	if recipes_data is Array:
		for recipe in recipes_data:
			var recipe_id: String = recipe.get("id", "")
			if recipe_id != "":
				_recipes_db[recipe_id] = recipe
		Log.info(_TAG, "Loaded %d recipes" % _recipes_db.size())

	# Enemies
	var enemies_data: Variant = _load_json("res://data/enemies/enemies.json")
	if enemies_data is Array:
		for enemy in enemies_data:
			var enemy_id: String = enemy.get("id", "")
			if enemy_id != "":
				_enemies_db[enemy_id] = enemy
		Log.info(_TAG, "Loaded %d enemies" % _enemies_db.size())

	# Classes
	var classes_data: Variant = _load_json("res://data/classes/classes.json")
	if classes_data is Array:
		for cls in classes_data:
			var class_id: String = cls.get("id", "")
			if class_id != "":
				_classes_db[class_id] = cls
		Log.info(_TAG, "Loaded %d classes" % _classes_db.size())

	# Races
	var races_data: Variant = _load_json("res://data/races/races.json")
	if races_data is Array:
		for race in races_data:
			var race_id: String = race.get("id", "")
			if race_id != "":
				_races_db[race_id] = race
		Log.info(_TAG, "Loaded %d races" % _races_db.size())

	# Zones
	var zones_data: Variant = _load_json("res://data/zones/zones.json")
	if zones_data is Array:
		for zone in zones_data:
			var zone_id: String = zone.get("id", "")
			if zone_id != "":
				_zones_db[zone_id] = zone
		Log.info(_TAG, "Loaded %d zones" % _zones_db.size())

	# Factions
	var factions_data: Variant = _load_json("res://data/factions/factions.json")
	if factions_data is Array:
		for faction in factions_data:
			var faction_id: String = faction.get("id", "")
			if faction_id != "":
				_factions_db[faction_id] = faction
		Log.info(_TAG, "Loaded %d factions" % _factions_db.size())

	# Mock characters
	var chars_data: Variant = _load_json("res://data/characters/mock_characters.json")
	if chars_data is Array:
		_mock_characters = chars_data
		Log.info(_TAG, "Loaded %d mock characters" % _mock_characters.size())

	# Guild data
	var guild_data: Variant = _load_json("res://data/guilds/guilds.json")
	if guild_data is Dictionary:
		_guild_data = guild_data
	elif guild_data is Array and guild_data.size() > 0:
		_guild_data = guild_data[0]
	if not _guild_data.is_empty():
		Log.info(_TAG, "Loaded guild data")

	# Chunks — load all chunk files found in the chunks directory
	_load_chunks()

	Log.info(_TAG, "Mock data loading complete")


## Scans the chunks directory and loads all chunk JSON files into the cache.
func _load_chunks() -> void:
	var chunks_dir := "res://data/chunks"
	var dir := DirAccess.open(chunks_dir)
	if dir == null:
		Log.warning(_TAG, "Chunks directory not found: %s" % chunks_dir)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var chunk_data: Variant = _load_json("%s/%s" % [chunks_dir, file_name])
			if chunk_data is Dictionary:
				var cx: int = chunk_data.get("chunk_x", 0)
				var cy: int = chunk_data.get("chunk_y", 0)
				var key := "%d_%d" % [cx, cy]
				_chunks_cache[key] = chunk_data
		file_name = dir.get_next()
	dir.list_dir_end()
	Log.info(_TAG, "Loaded %d chunks" % _chunks_cache.size())


## Loads and parses a JSON file at the given path.
## Returns the parsed Variant (Array or Dictionary), or null on error.
func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		Log.warning(_TAG, "JSON file not found: %s" % path)
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		Log.error(_TAG, "Failed to open JSON file: %s" % path)
		return null
	var content := file.get_as_text()
	file.close()
	var json := JSON.new()
	var error := json.parse(content)
	if error != OK:
		Log.error(_TAG, "Failed to parse JSON file: %s (line %d: %s)" % [path, json.get_error_line(), json.get_error_message()])
		return null
	return json.data
