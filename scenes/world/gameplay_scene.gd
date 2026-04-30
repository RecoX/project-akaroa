## GameplayScene — the main 3D gameplay scene containing all game systems.
##
## On _ready: spawns the player character from StateManager.player_data and
## mock NPCs/enemies from MockDataProvider. Wires signal connections between
## combat, rendering, audio, reputation, guild, quest, and all other systems.
## Requirements: 1.4, 1.5, 12.3, 12.4, 12.5, 12.6, 12.7
extends Node3D


const TAG := "GameplayScene"

## Tracks opened chests by tile key "chunkX_chunkY_tileX_tileY" to prevent re-looting.
var _opened_chests: Dictionary = {}

## Stores spawned enemy data keyed by enemy instance ID for XP lookup on kill.
var _spawned_enemies: Dictionary = {}

## Stores the current interaction trigger data for the tile the player is standing on.
## Empty when the player is not on an interaction tile.
var _current_interaction_trigger: Dictionary = {}

## Preloaded CombatSystem script for static method access.
const _CombatSystemScript := preload("res://scripts/combat_system.gd")

## Spell effect scene mapping.
const SPELL_EFFECTS: Dictionary = {
	"fireball": "res://scenes/effects/fireball_impact.tscn",
	"fireball_01": "res://scenes/effects/fireball_impact.tscn",
	"heal": "res://scenes/effects/heal_glow.tscn",
	"heal_01": "res://scenes/effects/heal_glow.tscn",
	"ice_shard": "res://scenes/effects/ice_shard.tscn",
	"ice_shard_01": "res://scenes/effects/ice_shard.tscn",
}

## Damage number colors.
const DAMAGE_COLOR_NORMAL := Color(1.0, 0.3, 0.2)
const DAMAGE_COLOR_CRITICAL := Color(1.0, 0.85, 0.0)
const DAMAGE_COLOR_MAGIC := Color(0.5, 0.3, 1.0)
const DAMAGE_COLOR_HEAL := Color(0.2, 1.0, 0.3)


func _ready() -> void:
	Log.info(TAG, "GameplayScene initializing...")
	_wire_combat_presentation()
	_wire_spell_effects()
	_wire_reputation_system()
	_wire_guild_system()
	_wire_quest_system()
	_wire_npc_interactions()
	_spawn_player()
	_spawn_mock_entities()

	# Wire interaction trigger check to player movement (Task 10.1).
	StateManager.player_position_changed.connect(_check_interaction_trigger)

	Log.info(TAG, "GameplayScene ready — all systems wired")


# ---------------------------------------------------------------------------
# Combat presentation wiring  (Task 11.2)
# ---------------------------------------------------------------------------


## Wires combat system signals to character renderer and audio manager
## for visual and audio presentation of combat events.
func _wire_combat_presentation() -> void:
	var combat_system: Node = $CombatSystem
	var char_renderer: Node = $CharacterRenderer

	# Connect damage_result to floating text display.
	combat_system.damage_result.connect(_on_damage_result)

	# Connect healing_applied to floating heal text display (Task 14.1).
	combat_system.healing_applied.connect(_on_healing_applied)

	# Connect target_killed for death handling.
	combat_system.target_killed.connect(_on_target_killed)

	# Connect player death for ghost state transition.
	StateManager.player_died.connect(_on_player_died)

	Log.info(TAG, "Combat presentation wired")


## Handles damage_result signal — shows floating damage numbers and plays
## hit animation + SFX on the target.
func _on_damage_result(target_id: String, amount: int, type: String, is_critical: bool) -> void:
	var char_renderer: Node = $CharacterRenderer

	# Determine color based on damage type and critical status.
	var color: Color
	if type == "magic":
		color = DAMAGE_COLOR_MAGIC
	elif is_critical:
		color = DAMAGE_COLOR_CRITICAL
	else:
		color = DAMAGE_COLOR_NORMAL

	# Show floating damage number.
	var text: String = str(amount)
	if is_critical:
		text += "!"
	char_renderer.show_floating_text(target_id, text, color, 1.5)

	# Play hit animation on target.
	char_renderer.play_animation(target_id, "hit")

	# Play attack animation on the player (attacker).
	var player_id: String = StateManager.player_data.get("id", "player")
	var attack_anim: String = "attack_melee" if type == "melee" else "attack_ranged" if type == "ranged" else "cast_spell"
	char_renderer.play_animation(player_id, attack_anim)

	# Play hit SFX via AudioManager.
	AudioManager.play_sfx("res://audio/sfx/hit_%s.ogg" % type)


## Handles healing_applied signal — shows floating green heal numbers (Task 14.1).
func _on_healing_applied(target_id: String, amount: int) -> void:
	var char_renderer: Node = $CharacterRenderer
	var text: String = "+%d" % amount
	char_renderer.show_floating_text(target_id, text, DAMAGE_COLOR_HEAL, 1.5)
	Log.info(TAG, "Healing feedback: +%d on '%s'" % [amount, target_id])


## Handles target_killed signal — plays death animation and grants XP.
func _on_target_killed(target_id: String, _loot: Array) -> void:
	var char_renderer: Node = $CharacterRenderer
	char_renderer.play_animation(target_id, "death")
	char_renderer.swap_to_ghost_model(target_id)

	# Grant XP from the killed enemy's xp_reward field.
	var enemy_data: Dictionary = _spawned_enemies.get(target_id, {})
	var xp_reward: int = enemy_data.get("xp_reward", 0)
	if xp_reward > 0:
		var current_xp: int = StateManager.player_data.get("xp", 0)
		var new_xp: int = current_xp + xp_reward
		StateManager.player_data["xp"] = new_xp
		var xp_to_next: int = StateManager.player_data.get("xp_to_next", 100)
		var level: int = StateManager.player_data.get("level", 1)
		StateManager.player_xp_changed.emit(new_xp, xp_to_next, level)
		Log.info(TAG, "Granted %d XP for killing '%s' (total: %d)" % [xp_reward, target_id, new_xp])

	Log.info(TAG, "Target '%s' killed — death animation triggered" % target_id)


## Handles player death — transitions to ghost state and restricts actions.
func _on_player_died() -> void:
	var char_renderer: Node = $CharacterRenderer
	var player_id: String = StateManager.player_data.get("id", "player")
	char_renderer.play_animation(player_id, "death")
	char_renderer.swap_to_ghost_model(player_id)
	AudioManager.play_sfx("res://audio/sfx/player_death.ogg")
	Log.info(TAG, "Player died — ghost state activated")


# ---------------------------------------------------------------------------
# Spell effect wiring  (Task 22.1)
# ---------------------------------------------------------------------------


## Wires spell effect signals to spawn particle effects.
func _wire_spell_effects() -> void:
	StateManager.character_effect_played.connect(_on_spell_effect)
	Log.info(TAG, "Spell effects wired")


## Spawns a spell effect at the target character's position.
func _on_spell_effect(char_id: String, effect_id: String) -> void:
	var effect_path: String = SPELL_EFFECTS.get(effect_id, "")
	if effect_path.is_empty():
		Log.debug(TAG, "No spell effect scene for '%s'" % effect_id)
		return

	if not ResourceLoader.exists(effect_path):
		Log.debug(TAG, "Spell effect scene not found: %s" % effect_path)
		return

	var effect_scene: PackedScene = load(effect_path)
	if effect_scene == null:
		return

	# Spawn at the target's tile position.
	var tile_pos := StateManager.player_position  # Default to player.
	# Try to find the character's position from the renderer.
	var char_renderer: Node = $CharacterRenderer
	if char_renderer and char_renderer._characters.has(char_id):
		var instance: Node3D = char_renderer._characters[char_id]
		if is_instance_valid(instance):
			var world_manager: Node = $WorldManager
			if world_manager and world_manager.has_method("spawn_ground_effect"):
				# Convert world position back to tile.
				@warning_ignore("integer_division")
				var tx: int = int(instance.position.x / 32.0)
				@warning_ignore("integer_division")
				var ty: int = int(instance.position.z / 32.0)
				tile_pos = Vector2i(tx, ty)

	var world_manager: Node = $WorldManager
	if world_manager and world_manager.has_method("spawn_ground_effect"):
		world_manager.spawn_ground_effect(tile_pos, effect_scene)


# ---------------------------------------------------------------------------
# Reputation system wiring  (Task 26.1)
# ---------------------------------------------------------------------------


## Wires reputation system to update name colors on characters.
func _wire_reputation_system() -> void:
	var rep_system: Node = $ReputationSystem
	if rep_system and rep_system.has_signal("alignment_changed"):
		rep_system.alignment_changed.connect(_on_alignment_changed)
	Log.info(TAG, "Reputation system wired")


func _on_alignment_changed(new_alignment: String) -> void:
	var char_renderer: Node = $CharacterRenderer
	var player_id: String = StateManager.player_data.get("id", "player")
	char_renderer.update_overhead_ui(player_id, {"reputation": new_alignment})
	Log.info(TAG, "Player alignment changed to '%s' — name color updated" % new_alignment)


# ---------------------------------------------------------------------------
# Guild system wiring  (Task 26.1)
# ---------------------------------------------------------------------------


## Wires guild system to display guild tags on characters.
func _wire_guild_system() -> void:
	var guild_manager: Node = $GuildManager
	if guild_manager and guild_manager.has_signal("guild_data_changed"):
		guild_manager.guild_data_changed.connect(_on_guild_data_changed)
	Log.info(TAG, "Guild system wired")


func _on_guild_data_changed(guild_data: Dictionary) -> void:
	var char_renderer: Node = $CharacterRenderer
	var player_id: String = StateManager.player_data.get("id", "player")
	var tag: String = guild_data.get("tag", "")
	char_renderer.update_overhead_ui(player_id, {"guild_tag": tag})
	Log.info(TAG, "Guild tag updated to '<%s>'" % tag)


# ---------------------------------------------------------------------------
# Quest system wiring  (Task 26.1)
# ---------------------------------------------------------------------------


## Wires quest completion to grant rewards and update UI.
func _wire_quest_system() -> void:
	StateManager.quest_completed.connect(_on_quest_completed)
	Log.info(TAG, "Quest system wired")


func _on_quest_completed(quest_id: String) -> void:
	Log.info(TAG, "Quest '%s' completed — rewards granted" % quest_id)
	AudioManager.play_sfx("res://audio/sfx/quest_complete.ogg")


# ---------------------------------------------------------------------------
# NPC interaction wiring  (Task 26.1)
# ---------------------------------------------------------------------------


## Wires NPC interaction to open correct panels.
func _wire_npc_interactions() -> void:
	StateManager.npc_interaction_requested.connect(_on_npc_interaction)
	Log.info(TAG, "NPC interactions wired")


func _on_npc_interaction(npc_id: String, panel_type: String, npc_data: Dictionary) -> void:
	var ui_layer: Node = $UILayer
	match panel_type:
		"shop":
			var shop_panel: Node = ui_layer.get_node_or_null("ShopPanel")
			if shop_panel:
				shop_panel.visible = true
		"quest":
			var quest_log: Node = ui_layer.get_node_or_null("QuestLog")
			if quest_log:
				quest_log.visible = true
		"bank":
			var bank_panel: Node = ui_layer.get_node_or_null("BankPanel")
			if bank_panel:
				bank_panel.visible = true
		_:
			Log.info(TAG, "NPC '%s' dialogue interaction (no panel)" % npc_data.get("name", "?"))


# ---------------------------------------------------------------------------
# Entity spawning
# ---------------------------------------------------------------------------


## Spawns the player character using data from StateManager.
func _spawn_player() -> void:
	var data := StateManager.player_data
	if data.is_empty():
		Log.warning(TAG, "No player data in StateManager — skipping player spawn")
		return

	var char_id: String = data.get("id", "player")
	var tile_pos := StateManager.player_position

	# Emit character_spawned so CharacterRenderer picks it up.
	StateManager.character_spawned.emit(char_id, data)
	Log.info(TAG, "Player '%s' spawned at tile (%d, %d)" % [
		data.get("name", "Unknown"), tile_pos.x, tile_pos.y,
	])


## Spawns mock NPCs and enemies from MockDataProvider chunk data.
func _spawn_mock_entities() -> void:
	@warning_ignore("integer_division")
	var player_chunk_x: int = StateManager.player_position.x / 32
	@warning_ignore("integer_division")
	var player_chunk_y: int = StateManager.player_position.y / 32

	# Spawn enemies from nearby chunks.
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var cx := player_chunk_x + dx
			var cy := player_chunk_y + dy
			var enemies: Array = MockDataProvider.get_enemies_in_chunk(cx, cy)
			for enemy in enemies:
				var chunk_enemy_id: String = enemy.get("enemy_id", "")
				# Convert local tile coordinates to world tile coordinates.
				var local_tx: int = enemy.get("tile_x", 16)
				var local_ty: int = enemy.get("tile_y", 16)
				var pos_x: int = enemy.get("position_x", cx * 32 + local_tx)
				var pos_y: int = enemy.get("position_y", cy * 32 + local_ty)

				# Look up full enemy definition from MockDataProvider for xp_reward, loot_table, etc.
				var full_enemy_data: Dictionary = {}
				if chunk_enemy_id != "":
					full_enemy_data = MockDataProvider.get_enemy(chunk_enemy_id)

				# Build spawn data: start with chunk entry, merge full definition fields.
				var spawn_data: Dictionary = enemy.duplicate()
				if not full_enemy_data.is_empty():
					# Merge fields from the full enemy definition that aren't in chunk data.
					for key in full_enemy_data.keys():
						if not spawn_data.has(key):
							spawn_data[key] = full_enemy_data[key]
					# Always ensure xp_reward and loot_table come from the full definition.
					spawn_data["xp_reward"] = full_enemy_data.get("xp_reward", 0)
					spawn_data["loot_table"] = full_enemy_data.get("loot_table", [])

				# Generate a unique instance ID for this enemy spawn.
				var enemy_id: String = spawn_data.get("id", chunk_enemy_id if chunk_enemy_id != "" else "enemy_%d_%d" % [cx, cy])
				# Make instance ID unique by appending position.
				var instance_id: String = "%s_%d_%d" % [enemy_id, pos_x, pos_y]

				spawn_data["id"] = instance_id
				spawn_data["position_x"] = pos_x
				spawn_data["position_y"] = pos_y
				if not spawn_data.has("name"):
					spawn_data["name"] = full_enemy_data.get("name", enemy.get("display_name", "Enemy"))
				if not spawn_data.has("hp"):
					spawn_data["hp"] = full_enemy_data.get("max_hp", enemy.get("max_hp", 50))
				if not spawn_data.has("max_hp"):
					spawn_data["max_hp"] = full_enemy_data.get("max_hp", 50)
				if not spawn_data.has("reputation"):
					spawn_data["reputation"] = "criminal"

				# Store enemy data for XP lookup on kill.
				_spawned_enemies[instance_id] = spawn_data

				StateManager.character_spawned.emit(instance_id, spawn_data)

	# Spawn NPCs from nearby chunks (Task 11.2).
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var ncx := player_chunk_x + dx
			var ncy := player_chunk_y + dy
			var chunk_data: Dictionary = MockDataProvider.get_chunk(ncx, ncy)
			if not chunk_data.is_empty():
				_spawn_npcs_from_chunk(ncx, ncy, chunk_data)

	Log.info(TAG, "Mock entities spawned")


# ---------------------------------------------------------------------------
# NPC spawning from chunk data  (Task 11.1)
# ---------------------------------------------------------------------------


## Iterates through chunk tiles looking for npc_spawn triggers and spawns
## NPC characters at the corresponding world positions.
func _spawn_npcs_from_chunk(chunk_x: int, chunk_y: int, chunk_data: Dictionary) -> void:
	var tiles: Array = chunk_data.get("tiles", [])
	for tile in tiles:
		var trigger: Dictionary = tile.get("trigger", {})
		if trigger.get("type", "") != "npc_spawn":
			continue

		var npc_id: String = trigger.get("data", {}).get("npc_id", "")
		if npc_id == "":
			Log.warning(TAG, "npc_spawn trigger missing npc_id at chunk (%d, %d)" % [chunk_x, chunk_y])
			continue

		var npc_data: Dictionary = MockDataProvider.get_npc(npc_id)
		if npc_data.is_empty():
			Log.warning(TAG, "NPC '%s' not found in MockDataProvider — skipping spawn" % npc_id)
			continue

		# Calculate world tile position from chunk coordinates + tile local position.
		var tile_x: int = tile.get("x", 0)
		var tile_y: int = tile.get("y", 0)
		var world_tile_x: int = chunk_x * 32 + tile_x
		var world_tile_y: int = chunk_y * 32 + tile_y

		# Build spawn data dictionary for the NPC.
		var spawn_data: Dictionary = npc_data.duplicate()
		spawn_data["position_x"] = world_tile_x
		spawn_data["position_y"] = world_tile_y
		if not spawn_data.has("name"):
			spawn_data["name"] = npc_data.get("name", "NPC")
		if not spawn_data.has("hp"):
			spawn_data["hp"] = 100
		if not spawn_data.has("max_hp"):
			spawn_data["max_hp"] = 100
		if not spawn_data.has("reputation"):
			spawn_data["reputation"] = "citizen"

		StateManager.character_spawned.emit(npc_id, spawn_data)
		Log.info(TAG, "Spawned NPC '%s' (%s) at tile (%d, %d)" % [
			spawn_data.get("name", "?"), npc_id, world_tile_x, world_tile_y
		])


# ---------------------------------------------------------------------------
# Target selection input  (Task 3)
# ---------------------------------------------------------------------------


## Handles unprocessed input events for target selection via left mouse click
## and melee attack initiation.
## Left click on a character selects it as the current target; left click on
## empty ground clears the current target. If an enemy target is already
## selected, left click attempts a melee attack instead of re-selecting.
func _unhandled_input(event: InputEvent) -> void:
	# Interaction key (E) handling (Task 10.2, Task 12.1).
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		if not _current_interaction_trigger.is_empty():
			# Interaction triggers (signs, chests, campfires) take priority.
			_execute_interaction(_current_interaction_trigger)
		elif StateManager.current_target_id != "" and StateManager.current_target_data.get("reputation", "") != "criminal":
			# No interaction trigger, but an NPC is selected — open NPC panel.
			StateManager.process_npc_interaction(StateManager.current_target_id)
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# If an enemy target is already selected, attempt melee attack.
		var current_rep: String = StateManager.current_target_data.get("reputation", "")
		if StateManager.current_target_id != "" and current_rep == "criminal":
			# Check if clicking on a different character — if so, select it instead.
			var tile_pos := _screen_to_tile(event.position)
			var char_data := _find_character_at_tile(tile_pos)
			if not char_data.is_empty() and char_data.get("id", "") != StateManager.current_target_id:
				StateManager.set_target(char_data.get("id", ""), char_data)
			else:
				_attempt_melee_attack()
			return

		var tile_pos := _screen_to_tile(event.position)
		var char_data := _find_character_at_tile(tile_pos)
		if char_data.is_empty():
			StateManager.clear_target()
		else:
			StateManager.set_target(char_data.get("id", ""), char_data)


## Converts a screen-space position to tile coordinates by projecting a ray
## from the camera onto the ground plane (Y = 0).
func _screen_to_tile(screen_pos: Vector2) -> Vector2i:
	var camera: Camera3D = $GameCamera
	if camera == null:
		return Vector2i.ZERO

	var ray_origin := camera.project_ray_origin(screen_pos)
	var ray_dir := camera.project_ray_normal(screen_pos)

	# Intersect with the Y = 0 ground plane.
	if absf(ray_dir.y) < 0.0001:
		return Vector2i.ZERO
	var t := -ray_origin.y / ray_dir.y
	var world_pos := ray_origin + ray_dir * t

	# Convert world position to tile coordinates.
	@warning_ignore("integer_division")
	var tile_x: int = int(world_pos.x / 32.0)
	@warning_ignore("integer_division")
	var tile_y: int = int(world_pos.z / 32.0)
	return Vector2i(tile_x, tile_y)


## Searches all spawned characters to find one occupying the given tile position.
## Returns the character's spawn data dictionary (including "id"), or an empty
## dictionary if no character is at that tile.
func _find_character_at_tile(tile_pos: Vector2i) -> Dictionary:
	var char_renderer: Node = $CharacterRenderer
	if char_renderer == null:
		return {}

	for char_id in char_renderer._characters.keys():
		var instance: Node3D = char_renderer._characters[char_id]
		if not is_instance_valid(instance):
			continue
		# Convert the character's world position back to tile coordinates.
		@warning_ignore("integer_division")
		var tx: int = int(instance.position.x / 32.0)
		@warning_ignore("integer_division")
		var ty: int = int(instance.position.z / 32.0)
		if tx == tile_pos.x and ty == tile_pos.y:
			# Build a data dictionary from the character instance.
			var data: Dictionary = {
				"id": char_id,
				"name": instance.display_name if "display_name" in instance else "Unknown",
				"hp": instance.current_hp if "current_hp" in instance else 100,
				"max_hp": instance.max_hp if "max_hp" in instance else 100,
				"reputation": instance.reputation if "reputation" in instance else "citizen",
				"position_x": tile_pos.x,
				"position_y": tile_pos.y,
			}
			return data
	return {}


# ---------------------------------------------------------------------------
# Melee attack  (Task 6)
# ---------------------------------------------------------------------------


## Attempts a melee attack against the currently selected enemy target.
## Validates that a target is selected and is an enemy, checks Manhattan
## distance (max 2 tiles), and delegates to CombatSystem if in range.
func _attempt_melee_attack() -> void:
	# 1. Check current_target_id is set and is an enemy.
	if StateManager.current_target_id == "":
		return
	var rep: String = StateManager.current_target_data.get("reputation", "")
	if rep != "criminal":
		return

	# 2. Calculate Manhattan distance between player and target.
	var target_pos := Vector2i(
		StateManager.current_target_data.get("position_x", 0),
		StateManager.current_target_data.get("position_y", 0)
	)
	var distance: int = _CombatSystemScript.manhattan_distance(StateManager.player_position, target_pos)

	# 3. If distance > 2 tiles: emit feedback_message("Too far away").
	if distance > 2:
		StateManager.feedback_message.emit("Too far away")
		Log.info(TAG, "Melee attack rejected — target '%s' is %d tiles away (max 2)" % [
			StateManager.current_target_id, distance
		])
		return

	# 4. If distance <= 2: call CombatSystem.attempt_melee_attack(target_id).
	var combat_system: Node = $CombatSystem
	combat_system.attempt_melee_attack(StateManager.current_target_id)
	Log.info(TAG, "Melee attack initiated against '%s' (distance: %d)" % [
		StateManager.current_target_id, distance
	])


# ---------------------------------------------------------------------------
# Interactive world objects  (Task 10)
# ---------------------------------------------------------------------------


## Checks the tile at the player's current position for an interaction trigger.
## Called whenever the player moves to a new tile via player_position_changed.
## If the tile has trigger.type == "interaction", stores the trigger data and
## emits interaction_prompt. Otherwise clears the stored trigger and emits
## interaction_prompt_cleared.
func _check_interaction_trigger(tile_x: int, tile_y: int) -> void:
	var world_manager: Node = $WorldManager
	if world_manager == null:
		return

	var tile_data: Dictionary = world_manager.get_tile_data(tile_x, tile_y)
	var trigger: Dictionary = tile_data.get("trigger", {})
	var trigger_type: String = trigger.get("type", "none")

	if trigger_type == "interaction":
		# Store trigger data along with tile position for chest tracking.
		_current_interaction_trigger = trigger.duplicate(true)
		_current_interaction_trigger["_tile_x"] = tile_x
		_current_interaction_trigger["_tile_y"] = tile_y
		StateManager.interaction_prompt.emit("Press E to interact")
		Log.debug(TAG, "Interaction trigger found at (%d, %d): %s" % [
			tile_x, tile_y, trigger.get("data", {}).get("sub_type", "unknown")
		])
	else:
		if not _current_interaction_trigger.is_empty():
			_current_interaction_trigger = {}
			StateManager.interaction_prompt_cleared.emit()


## Executes the interaction defined by the given trigger data.
## Dispatches based on sub_type: "sign" shows text, "chest" adds loot,
## "campfire" shows flavor text.
func _execute_interaction(trigger_data: Dictionary) -> void:
	var data: Dictionary = trigger_data.get("data", {})
	var sub_type: String = data.get("sub_type", "")
	var tile_x: int = trigger_data.get("_tile_x", 0)
	var tile_y: int = trigger_data.get("_tile_y", 0)

	match sub_type:
		"sign":
			var text: String = data.get("text", "...")
			StateManager.feedback_message.emit(text)
			Log.info(TAG, "Sign interaction: '%s'" % text)

		"chest":
			# Build tile key for chest tracking.
			@warning_ignore("integer_division")
			var chunk_x: int = tile_x / 32 if tile_x >= 0 else (tile_x - 31) / 32
			@warning_ignore("integer_division")
			var chunk_y: int = tile_y / 32 if tile_y >= 0 else (tile_y - 31) / 32
			var local_tx: int = tile_x - chunk_x * 32
			var local_ty: int = tile_y - chunk_y * 32
			var chest_key: String = "%d_%d_%d_%d" % [chunk_x, chunk_y, local_tx, local_ty]

			# Check if chest already opened (Task 10.5).
			if _opened_chests.has(chest_key):
				StateManager.feedback_message.emit("This chest is empty")
				Log.info(TAG, "Chest at '%s' already opened" % chest_key)
				return

			# Add loot to inventory.
			var loot: Array = data.get("loot", [])
			var inv_manager: Node = _get_inventory_manager()
			for loot_item in loot:
				var item_data: Dictionary = {
					"id": loot_item.get("item_id", "unknown"),
					"name": loot_item.get("item_id", "Unknown Item"),
					"quantity": loot_item.get("quantity", 1),
				}
				if inv_manager:
					inv_manager.add_item(item_data)
				else:
					# Fallback: add directly to StateManager inventory.
					StateManager.player_inventory.append(item_data)

			# Mark chest as opened.
			_opened_chests[chest_key] = true
			StateManager.feedback_message.emit("You found loot!")
			Log.info(TAG, "Chest opened at '%s' — %d items looted" % [chest_key, loot.size()])

		"campfire":
			StateManager.feedback_message.emit("The warmth of the campfire is comforting.")
			Log.info(TAG, "Campfire interaction at (%d, %d)" % [tile_x, tile_y])

		_:
			Log.warning(TAG, "Unknown interaction sub_type: '%s'" % sub_type)


## Finds the Inventory_Manager node in the scene tree.
func _get_inventory_manager() -> Node:
	var inv: Node = get_node_or_null("Inventory_Manager")
	if inv:
		return inv
	# Fallback: search children.
	for child in get_children():
		if child.name == "Inventory_Manager":
			return child
	Log.warning(TAG, "Could not find Inventory_Manager node")
	return null
