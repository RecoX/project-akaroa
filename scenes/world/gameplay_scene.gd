## GameplayScene — the main 3D gameplay scene containing all game systems.
##
## On _ready: spawns the player character from StateManager.player_data and
## mock NPCs/enemies from MockDataProvider. Wires signal connections between
## combat, rendering, audio, reputation, guild, quest, and all other systems.
## Requirements: 1.4, 1.5, 12.3, 12.4, 12.5, 12.6, 12.7
extends Node3D


const TAG := "GameplayScene"

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


## Handles target_killed signal — plays death animation.
func _on_target_killed(target_id: String, _loot: Array) -> void:
	var char_renderer: Node = $CharacterRenderer
	char_renderer.play_animation(target_id, "death")
	char_renderer.swap_to_ghost_model(target_id)
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
				var enemy_id: String = enemy.get("id", "enemy_%d_%d" % [cx, cy])
				var pos_x: int = enemy.get("position_x", cx * 32 + 16)
				var pos_y: int = enemy.get("position_y", cy * 32 + 16)
				var spawn_data: Dictionary = enemy.duplicate()
				spawn_data["position_x"] = pos_x
				spawn_data["position_y"] = pos_y
				if not spawn_data.has("name"):
					spawn_data["name"] = enemy.get("display_name", "Enemy")
				if not spawn_data.has("hp"):
					spawn_data["hp"] = enemy.get("max_hp", 50)
				if not spawn_data.has("max_hp"):
					spawn_data["max_hp"] = 50
				if not spawn_data.has("reputation"):
					spawn_data["reputation"] = "criminal"
				StateManager.character_spawned.emit(enemy_id, spawn_data)

	Log.info(TAG, "Mock entities spawned")
