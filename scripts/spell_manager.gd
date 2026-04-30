## Spell_Manager — manages the player's learned spells, casting modes,
## cooldown display, and spell casting delegation to Combat_System.
##
## Loads learned spells from MockDataProvider based on StateManager.player_spells
## at gameplay start. Validates mana and delegates actual damage/effect
## application to Combat_System.attempt_spell_cast().
##
## Lives as a child of GameplayScene.
## Requirements: 11.1, 11.3, 11.4, 11.5, 11.6
extends Node


const TAG := "SpellManager"

## Preloaded CombatSystem script for static method access (manhattan_distance).
const _CombatSystemScript := preload("res://scripts/combat_system.gd")


## Casting mode determines how spells are targeted and activated.
enum CastMode {
	CLICK_TO_RELEASE,  ## Hold click to aim, release to cast.
	CLICK_TO_CAST,     ## Click target to cast immediately.
	FREE_TARGET,       ## Click ground position for area spells.
}


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

## Current casting mode preference.
var cast_mode: CastMode = CastMode.CLICK_TO_CAST

## Learned spells loaded from MockDataProvider. Array of spell dictionaries.
var _learned_spells: Array = []


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------


func _ready() -> void:
	_load_learned_spells()
	Log.info(TAG, "Spell_Manager ready — %d spells loaded, mode: %s" % [
		_learned_spells.size(), CastMode.keys()[cast_mode]
	])


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------


## Casts a spell on [param target_id]. Validates range and mana availability,
## then delegates to Combat_System for damage/effect application.
func cast_spell(spell_id: String, target_id: String) -> void:
	# Find the spell in learned spells.
	var spell := _find_learned_spell(spell_id)
	if spell.is_empty():
		Log.warning(TAG, "Spell '%s' not learned or not found" % spell_id)
		return

	# Validate range — get spell range and calculate Manhattan distance.
	var spell_range: int = spell.get("range", 0)
	if spell_range > 0 and target_id != "":
		var target_pos := _get_target_position(target_id)
		var distance: int = _CombatSystemScript.manhattan_distance(
			StateManager.player_position, target_pos
		)
		if distance > spell_range:
			StateManager.feedback_message.emit("Out of range")
			Log.info(TAG, "Spell '%s' out of range — distance %d > range %d" % [
				spell.get("name", spell_id), distance, spell_range
			])
			return

	# Validate mana.
	var mana_cost: int = spell.get("mana_cost", 0)
	var current_mana: int = StateManager.player_data.get("mana", 0)
	if current_mana < mana_cost:
		StateManager.feedback_message.emit("Not enough mana")
		Log.info(TAG, "Not enough mana for '%s' (need %d, have %d)" % [
			spell.get("name", spell_id), mana_cost, current_mana
		])
		return

	# Delegate to Combat_System for actual spell application.
	var combat_system: Node = get_parent().get_node_or_null("CombatSystem")
	if combat_system and combat_system.has_method("attempt_spell_cast"):
		combat_system.attempt_spell_cast(spell_id, target_id)
	else:
		Log.warning(TAG, "CombatSystem not found — cannot cast spell")

	Log.info(TAG, "Cast spell '%s' on '%s'" % [spell.get("name", spell_id), target_id])


## Returns the array of learned spell dictionaries.
func get_learned_spells() -> Array:
	return _learned_spells


## Returns a specific learned spell by ID, or empty dict if not learned.
func get_spell(spell_id: String) -> Dictionary:
	return _find_learned_spell(spell_id)


## Sets the casting mode.
func set_cast_mode(mode: CastMode) -> void:
	cast_mode = mode
	Log.info(TAG, "Cast mode set to %s" % CastMode.keys()[mode])


## Returns the current casting mode.
func get_cast_mode() -> CastMode:
	return cast_mode


# ---------------------------------------------------------------------------
# Spell loading
# ---------------------------------------------------------------------------


## Loads learned spells from MockDataProvider based on the spell IDs
## stored in StateManager.player_spells.
func _load_learned_spells() -> void:
	_learned_spells.clear()

	var spell_ids: Array = StateManager.player_spells
	if spell_ids.is_empty():
		Log.info(TAG, "No spells in player data — loading defaults")
		# Load a few default spells for demo purposes.
		_load_default_spells()
		return

	for spell_id in spell_ids:
		if spell_id is String:
			var spell_data: Dictionary = MockDataProvider.get_spell(spell_id)
			if not spell_data.is_empty():
				_learned_spells.append(spell_data)
			else:
				Log.warning(TAG, "Spell '%s' not found in MockDataProvider" % spell_id)
		elif spell_id is Dictionary:
			# Already a spell dictionary.
			_learned_spells.append(spell_id)

	Log.info(TAG, "Loaded %d learned spells from player data" % _learned_spells.size())


## Loads a set of default spells for demo when player has no spells defined.
func _load_default_spells() -> void:
	# Try to load all spells from MockDataProvider as defaults.
	var all_spell_ids: Array = ["fireball", "heal", "ice_shard", "lightning_bolt", "shield_buff"]
	for spell_id in all_spell_ids:
		var spell_data: Dictionary = MockDataProvider.get_spell(spell_id)
		if not spell_data.is_empty():
			_learned_spells.append(spell_data)

	if _learned_spells.is_empty():
		Log.warning(TAG, "No default spells found in MockDataProvider")
	else:
		Log.info(TAG, "Loaded %d default spells" % _learned_spells.size())


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


## Finds a learned spell by its ID.
func _find_learned_spell(spell_id: String) -> Dictionary:
	for spell in _learned_spells:
		if spell.get("id", "") == spell_id:
			return spell
	return {}


## Returns the tile position of the target character.
## Looks up position from StateManager.current_target_data first, then falls
## back to searching spawned characters via CharacterRenderer.
func _get_target_position(target_id: String) -> Vector2i:
	# Try StateManager.current_target_data (set during target selection).
	if StateManager.current_target_id == target_id and not StateManager.current_target_data.is_empty():
		var px: int = StateManager.current_target_data.get("position_x", 0)
		var py: int = StateManager.current_target_data.get("position_y", 0)
		return Vector2i(px, py)

	# Fallback: try to find the character via CharacterRenderer on the parent.
	var gameplay_scene: Node = get_parent()
	if gameplay_scene:
		var char_renderer: Node = gameplay_scene.get_node_or_null("CharacterRenderer")
		if char_renderer and char_renderer.get("_characters") != null:
			var characters: Dictionary = char_renderer._characters
			if characters.has(target_id):
				var instance: Node3D = characters[target_id]
				if is_instance_valid(instance):
					@warning_ignore("integer_division")
					var tx: int = int(instance.position.x / 32.0)
					@warning_ignore("integer_division")
					var ty: int = int(instance.position.z / 32.0)
					return Vector2i(tx, ty)

	Log.warning(TAG, "Could not determine position for target '%s'" % target_id)
	return Vector2i.ZERO
