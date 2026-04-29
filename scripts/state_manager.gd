## Central game state coordinator. All state mutations flow through here.
##
## State_Manager is the single source of truth for player state, application
## state, and acts as a mediator between game systems using signal-based
## communication. All game systems read from and write to State_Manager
## rather than communicating directly with each other.
extends Node


## Application lifecycle states.
enum AppState { LOGIN, CHARACTER_SELECT, GAMEPLAY, DISCONNECTED }

## Cardinal directions for character facing and movement.
enum Heading { NORTH, EAST, SOUTH, WEST }


const _TAG := "StateManager"


# --- Application state ---

## Emitted when the application transitions between states.
signal app_state_changed(new_state: AppState)

## The current application state.
var current_app_state: AppState = AppState.LOGIN


# --- Player state signals ---

## Emitted when the player's HP changes.
signal player_hp_changed(current_hp: int, max_hp: int)

## Emitted when the player's mana changes.
signal player_mana_changed(current_mana: int, max_mana: int)

## Emitted when the player's XP changes.
signal player_xp_changed(current_xp: int, xp_to_next: int, level: int)

## Emitted when the player's gold amount changes.
signal player_gold_changed(gold: int)

## Emitted when the player moves to a new tile.
signal player_position_changed(tile_x: int, tile_y: int)

## Emitted when the player changes facing direction.
signal player_heading_changed(heading: Heading)

## Emitted when the player character dies.
signal player_died()

## Emitted when the player gains a level.
signal player_leveled_up(new_level: int)

## Emitted when the player's active status effects change.
signal player_status_effect_changed(effects: Array)


# --- Character events ---

## Emitted when a character (player, NPC, or enemy) spawns in the world.
signal character_spawned(char_id: String, char_data: Dictionary)

## Emitted when a character is removed from the world.
signal character_despawned(char_id: String)

## Emitted when a character moves between tiles.
signal character_moved(char_id: String, from_tile: Vector2i, to_tile: Vector2i)

## Emitted when a character attacks another character.
signal character_attacked(attacker_id: String, target_id: String, damage: int, is_critical: bool)

## Emitted when a visual effect should play on a character.
signal character_effect_played(char_id: String, effect_id: String)

## Emitted when a character dies.
signal character_died(char_id: String)


# --- Inventory signals ---

## Emitted when an inventory slot is updated.
signal inventory_slot_updated(slot_index: int, item_data: Dictionary)

## Emitted when an equipment slot changes.
signal equipment_changed(slot_name: String, item_data: Dictionary)


# --- Combat signals ---

## Emitted when damage is dealt to a target.
signal damage_dealt(target_id: String, amount: int, damage_type: String, is_critical: bool)

## Emitted when a cooldown begins.
signal cooldown_started(category: String, duration: float)

## Emitted when a cooldown expires.
signal cooldown_finished(category: String)


# --- Chat signals ---

## Emitted when a chat message is received or sent.
signal chat_message(channel: String, sender: String, message: String, color: Color)

## Emitted when a chat bubble should appear above a character.
signal chat_bubble(char_id: String, message: String, duration: float)


# --- World signals ---

## Emitted when the player enters a new zone.
signal zone_changed(zone_data: Dictionary)

## Emitted when the weather changes.
signal weather_changed(weather_type: String)

## Emitted when the in-game time of day changes.
signal time_of_day_changed(hour: float)


# --- Quest signals ---

## Emitted when the player accepts a quest.
signal quest_accepted(quest_id: String)

## Emitted when a quest objective's progress updates.
signal quest_objective_updated(quest_id: String, objective_index: int, progress: int)

## Emitted when a quest is completed.
signal quest_completed(quest_id: String)


# --- Trade signals ---

## Emitted when a trade session opens.
signal trade_opened(partner_data: Dictionary)

## Emitted when a trade slot is updated.
signal trade_slot_updated(is_player: bool, slot_index: int, item_data: Dictionary)

## Emitted when a trade session closes.
signal trade_closed()


# --- Player data ---

## Full player character data dictionary (name, class, race, stats, etc.).
var player_data: Dictionary = {}

## Player's current tile position.
var player_position: Vector2i = Vector2i.ZERO

## Player's current facing direction.
var player_heading: Heading = Heading.SOUTH

## Inventory slots — array of item dictionaries indexed by slot number.
var player_inventory: Array = []

## Equipped items — slot_name (e.g. "weapon", "helmet") mapped to item dict.
var player_equipment: Dictionary = {}

## Learned spells list.
var player_spells: Array = []

## Skill values — skill_name -> value (0-100).
var player_skills: Dictionary = {}

## Active quests list.
var player_quests: Array = []

## Active buff effects.
var player_buffs: Array = []

## Active debuff effects.
var player_debuffs: Array = []

## Reputation and faction data.
var player_reputation: Dictionary = {"alignment": "citizen", "faction": "", "pvp_stats": {}}

## Guild membership data.
var player_guild: Dictionary = {}


# --- World state ---

## Current zone metadata.
var current_zone: Dictionary = {}

## In-game time of day (0.0 – 24.0).
var time_of_day: float = 12.0

## Current weather type string (e.g. "clear", "rain", "snow", "fog").
var current_weather: String = "clear"


# ---------------------------------------------------------------------------
# Methods
# ---------------------------------------------------------------------------


## Transitions the application to a new state and emits [signal app_state_changed].
## Guards against invalid transitions and logs unknown states.
func transition_to(state: AppState) -> void:
	if state == current_app_state:
		Log.debug(_TAG, "Already in state %s — ignoring transition" % AppState.keys()[state])
		return

	# Validate transition is known.
	if state < 0 or state > AppState.DISCONNECTED:
		Log.error(_TAG, "Invalid state transition requested: %d — ignoring" % state)
		return

	var old_state := current_app_state
	current_app_state = state
	Log.info(_TAG, "State transition: %s -> %s" % [AppState.keys()[old_state], AppState.keys()[state]])
	app_state_changed.emit(state)


## Initialises player state from a character data dictionary.
## Expected keys: hp, max_hp, mana, max_mana, xp, xp_to_next, level, gold,
## position_x, position_y, heading, inventory, equipment, spells, skills,
## quests, buffs, debuffs, reputation, guild.
func set_player_data(data: Dictionary) -> void:
	player_data = data

	# Position
	player_position = Vector2i(
		data.get("position_x", 0),
		data.get("position_y", 0)
	)
	player_heading = data.get("heading", Heading.SOUTH) as Heading

	# Collections
	player_inventory = data.get("inventory", [])
	player_equipment = data.get("equipment", {})
	player_spells = data.get("spells", [])
	player_skills = data.get("skills", {})
	player_quests = data.get("quests", [])
	player_buffs = data.get("buffs", [])
	player_debuffs = data.get("debuffs", [])
	player_reputation = data.get("reputation", {"alignment": "citizen", "faction": "", "pvp_stats": {}})
	player_guild = data.get("guild", {})

	# Emit initial state signals so UI elements can sync
	player_hp_changed.emit(data.get("hp", 100), data.get("max_hp", 100))
	player_mana_changed.emit(data.get("mana", 50), data.get("max_mana", 50))
	player_xp_changed.emit(data.get("xp", 0), data.get("xp_to_next", 100), data.get("level", 1))
	player_gold_changed.emit(data.get("gold", 0))
	player_position_changed.emit(player_position.x, player_position.y)
	player_heading_changed.emit(player_heading)
	player_status_effect_changed.emit(player_buffs + player_debuffs)

	Log.info(_TAG, "Player data set for '%s'" % data.get("name", "unknown"))


## Attempts to move the player one tile in the given [param heading].
## Returns [code]true[/code] if the movement was accepted.
## Actual collision and validation logic will be implemented by the Tile_Engine;
## this method updates state and emits signals.
func move_player(heading: Heading) -> bool:
	var direction := _heading_to_vector(heading)
	var old_position := player_position
	var new_position := player_position + direction

	# Update state
	player_position = new_position
	player_heading = heading

	# Emit signals
	player_position_changed.emit(new_position.x, new_position.y)
	player_heading_changed.emit(heading)
	character_moved.emit(player_data.get("id", "player"), old_position, new_position)

	Log.debug(_TAG, "Player moved %s to (%d, %d)" % [Heading.keys()[heading], new_position.x, new_position.y])
	return true


## Processes a melee/ranged attack against [param target_id].
## Delegates to Combat_System; this is the entry point for attack requests.
func process_attack(target_id: String) -> void:
	Log.info(_TAG, "process_attack called — target_id: %s" % target_id)
	# TODO: Delegate to Combat_System when implemented


## Processes a spell cast of [param spell_id] on [param target_id].
## Delegates to Spell_Manager; this is the entry point for spell cast requests.
func process_spell_cast(spell_id: String, target_id: String) -> void:
	Log.info(_TAG, "process_spell_cast called — spell_id: %s, target_id: %s" % [spell_id, target_id])
	# TODO: Delegate to Spell_Manager when implemented


## Processes using the item in inventory [param slot_index].
## Delegates to Inventory_Manager; this is the entry point for item use requests.
func process_item_use(slot_index: int) -> void:
	Log.info(_TAG, "process_item_use called — slot_index: %d" % slot_index)
	# TODO: Delegate to Inventory_Manager when implemented


## Processes equipping the item in inventory [param slot_index].
## Delegates to Inventory_Manager; this is the entry point for equip requests.
func process_equip(slot_index: int) -> void:
	Log.info(_TAG, "process_equip called — slot_index: %d" % slot_index)
	# TODO: Delegate to Inventory_Manager when implemented


## Processes dropping the item in inventory [param slot_index].
## Delegates to Inventory_Manager; this is the entry point for drop requests.
func process_drop_item(slot_index: int) -> void:
	Log.info(_TAG, "process_drop_item called — slot_index: %d" % slot_index)
	# TODO: Delegate to Inventory_Manager when implemented


## Emitted when an NPC interaction should open a specific panel.
## [param npc_id] The NPC being interacted with.
## [param panel_type] One of: "shop", "quest", "bank", "dialogue".
## [param npc_data] The full NPC data dictionary.
signal npc_interaction_requested(npc_id: String, panel_type: String, npc_data: Dictionary)


## Processes interaction with the NPC identified by [param npc_id].
## Reads the NPC definition from Mock_Data_Provider and opens the appropriate
## panel (shop, quest, bank, dialogue).
func process_npc_interaction(npc_id: String) -> void:
	Log.info(_TAG, "process_npc_interaction called — npc_id: %s" % npc_id)

	var npc_data: Dictionary = MockDataProvider.get_npc(npc_id)
	if npc_data.is_empty():
		Log.warning(_TAG, "NPC '%s' not found in MockDataProvider" % npc_id)
		return

	var npc_type: String = npc_data.get("type", "dialogue")
	var panel_type: String

	match npc_type:
		"shopkeeper":
			panel_type = "shop"
		"quest_giver":
			panel_type = "quest"
		"banker":
			panel_type = "bank"
		_:
			panel_type = "dialogue"

	Log.info(_TAG, "NPC '%s' (type: %s) -> opening '%s' panel" % [
		npc_data.get("name", "?"), npc_type, panel_type])

	npc_interaction_requested.emit(npc_id, panel_type, npc_data)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


## Converts a [enum Heading] value to a [Vector2i] direction offset.
func _heading_to_vector(heading: Heading) -> Vector2i:
	match heading:
		Heading.NORTH:
			return Vector2i(0, -1)
		Heading.EAST:
			return Vector2i(1, 0)
		Heading.SOUTH:
			return Vector2i(0, 1)
		Heading.WEST:
			return Vector2i(-1, 0)
	return Vector2i.ZERO
