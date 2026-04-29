## Combat_System — local mock combat loop with cooldowns, damage calculation,
## and presentation hooks.
##
## Manages melee, ranged, and spell attacks with separate cooldown timers,
## mock damage formulas, target HP tracking, and death detection.
## Lives as a child of GameplayScene.
##
## Requirements: 12.1, 12.2, 12.3, 12.4, 12.7, 12.8
extends Node


const TAG := "CombatSystem"

## Base melee damage range.
const MELEE_BASE_MIN: int = 5
const MELEE_BASE_MAX: int = 15

## Base ranged damage range.
const RANGED_BASE_MIN: int = 4
const RANGED_BASE_MAX: int = 12

## Critical hit chance (0.0 – 1.0).
const CRIT_CHANCE: float = 0.15

## Critical hit damage multiplier.
const CRIT_MULTIPLIER: float = 2.0

## Default cooldown durations (seconds).
const DEFAULT_MELEE_COOLDOWN: float = 1.0
const DEFAULT_RANGED_COOLDOWN: float = 1.5
const DEFAULT_MAGIC_COOLDOWN: float = 1.0
const DEFAULT_CONSUMABLE_COOLDOWN: float = 0.5


# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted when damage is dealt to a target.
signal damage_result(target_id: String, amount: int, type: String, is_critical: bool)

## Emitted when a cooldown timer starts for a category.
signal cooldown_started(category: String, duration: float)

## Emitted when a cooldown timer expires for a category.
signal cooldown_expired(category: String)

## Emitted when a target is killed, with its loot table.
signal target_killed(target_id: String, loot: Array)


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

## Active cooldown timers. Maps category name -> remaining seconds.
var _cooldowns: Dictionary = {}

## Currently selected target character ID.
var _target_id: String = ""

## Tracks HP for non-player characters locally. Maps char_id -> current_hp.
var _target_hp: Dictionary = {}


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------


func _process(delta: float) -> void:
	_update_cooldowns(delta)


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------


## Sets the current combat target.
func set_target(target_id: String) -> void:
	_target_id = target_id
	Log.debug(TAG, "Target set to '%s'" % target_id)


## Returns the current combat target ID.
func get_target() -> String:
	return _target_id


## Attempts a melee attack against [param target_id].
## Checks cooldown, calculates damage, emits signals, updates target HP.
func attempt_melee_attack(target_id: String) -> void:
	if _is_on_cooldown("melee"):
		Log.debug(TAG, "Melee attack on cooldown")
		return

	var damage_data := _calculate_melee_damage(target_id)
	_apply_damage(target_id, damage_data, "melee")
	_start_cooldown("melee", _get_melee_cooldown())


## Attempts a ranged attack against [param target_id].
## Checks cooldown, consumes ammo stub, calculates damage, emits signals.
func attempt_ranged_attack(target_id: String) -> void:
	if _is_on_cooldown("ranged"):
		Log.debug(TAG, "Ranged attack on cooldown")
		return

	if not _consume_ammo():
		Log.info(TAG, "No ammo available for ranged attack")
		return

	var damage_data := _calculate_ranged_damage(target_id)
	_apply_damage(target_id, damage_data, "ranged")
	_start_cooldown("ranged", _get_ranged_cooldown())


## Attempts to cast a spell on [param target_id].
## Checks cooldown, validates mana, deducts mana, applies spell effect.
func attempt_spell_cast(spell_id: String, target_id: String) -> void:
	if _is_on_cooldown("magic"):
		Log.debug(TAG, "Magic on cooldown")
		return

	var spell: Dictionary = MockDataProvider.get_spell(spell_id)
	if spell.is_empty():
		Log.warning(TAG, "Spell '%s' not found" % spell_id)
		return

	var mana_cost: int = spell.get("mana_cost", 0)
	var current_mana: int = StateManager.player_data.get("mana", 0)
	if current_mana < mana_cost:
		Log.info(TAG, "Not enough mana for '%s' (need %d, have %d)" % [spell_id, mana_cost, current_mana])
		return

	_apply_spell(spell, target_id)
	var spell_cooldown: float = spell.get("cooldown", DEFAULT_MAGIC_COOLDOWN)
	_start_cooldown("magic", spell_cooldown)


# ---------------------------------------------------------------------------
# Damage calculation
# ---------------------------------------------------------------------------


## Calculates melee damage using mock formula:
## base (5-15) + weapon bonus + random variance, with 15% crit chance.
## Returns { "amount": int, "is_critical": bool }.
func _calculate_melee_damage(_target_id: String) -> Dictionary:
	var base_damage: int = randi_range(MELEE_BASE_MIN, MELEE_BASE_MAX)

	# Add weapon bonus from equipped weapon.
	var weapon: Dictionary = StateManager.player_equipment.get("weapon", {})
	var weapon_bonus: int = weapon.get("damage", 0)
	if weapon_bonus == 0:
		# Try damage_max / damage_min range from item data.
		var dmg_min: int = weapon.get("damage_min", 0)
		var dmg_max: int = weapon.get("damage_max", 0)
		if dmg_max > 0:
			weapon_bonus = randi_range(dmg_min, dmg_max)

	var total: int = base_damage + weapon_bonus

	# Critical hit check.
	var is_critical: bool = randf() < CRIT_CHANCE
	if is_critical:
		total = int(total * CRIT_MULTIPLIER)

	return {"amount": maxi(1, total), "is_critical": is_critical}


## Calculates ranged damage using mock formula.
## Returns { "amount": int, "is_critical": bool }.
func _calculate_ranged_damage(_target_id: String) -> Dictionary:
	var base_damage: int = randi_range(RANGED_BASE_MIN, RANGED_BASE_MAX)

	# Add ranged weapon bonus.
	var weapon: Dictionary = StateManager.player_equipment.get("weapon", {})
	var weapon_bonus: int = weapon.get("damage", 0)
	if weapon_bonus == 0:
		var dmg_min: int = weapon.get("damage_min", 0)
		var dmg_max: int = weapon.get("damage_max", 0)
		if dmg_max > 0:
			weapon_bonus = randi_range(dmg_min, dmg_max)

	var total: int = base_damage + weapon_bonus

	var is_critical: bool = randf() < CRIT_CHANCE
	if is_critical:
		total = int(total * CRIT_MULTIPLIER)

	return {"amount": maxi(1, total), "is_critical": is_critical}


# ---------------------------------------------------------------------------
# Damage application
# ---------------------------------------------------------------------------


## Applies damage to a target, emits signals, updates HP, checks for death.
func _apply_damage(target_id: String, damage_data: Dictionary, type: String) -> void:
	var amount: int = damage_data.get("amount", 0)
	var is_critical: bool = damage_data.get("is_critical", false)

	# Emit damage result signal.
	damage_result.emit(target_id, amount, type, is_critical)

	# Also emit through StateManager for broader consumption.
	StateManager.damage_dealt.emit(target_id, amount, type, is_critical)
	StateManager.character_attacked.emit(
		StateManager.player_data.get("id", "player"),
		target_id, amount, is_critical
	)

	# Update target HP.
	var player_id: String = StateManager.player_data.get("id", "player")
	if target_id == player_id:
		_apply_damage_to_player(amount)
	else:
		_apply_damage_to_npc(target_id, amount)

	Log.info(TAG, "%s hit '%s' for %d damage%s" % [
		type.capitalize(), target_id, amount,
		" (CRITICAL)" if is_critical else ""
	])


## Applies spell effect: deducts mana, calculates spell damage, emits signals.
func _apply_spell(spell: Dictionary, target_id: String) -> void:
	var mana_cost: int = spell.get("mana_cost", 0)
	var current_mana: int = StateManager.player_data.get("mana", 0)

	# Deduct mana.
	var new_mana: int = maxi(0, current_mana - mana_cost)
	StateManager.player_data["mana"] = new_mana
	StateManager.player_mana_changed.emit(new_mana, StateManager.player_data.get("max_mana", 50))

	# Calculate spell damage.
	var spell_damage: int = spell.get("damage", 0)
	if spell_damage <= 0:
		# Healing or utility spell — no damage to apply.
		var heal_amount: int = spell.get("heal", 0)
		if heal_amount > 0:
			_apply_healing(target_id, heal_amount)
		Log.info(TAG, "Cast '%s' (utility/heal)" % spell.get("name", spell.get("id", "?")))
		return

	# Add random variance to spell damage.
	var variance: int = randi_range(-2, 2)
	spell_damage = maxi(1, spell_damage + variance)

	var is_critical: bool = randf() < CRIT_CHANCE
	if is_critical:
		spell_damage = int(spell_damage * CRIT_MULTIPLIER)

	var damage_data := {"amount": spell_damage, "is_critical": is_critical}
	_apply_damage(target_id, damage_data, "magic")

	# Emit spell effect for visual presentation.
	StateManager.character_effect_played.emit(target_id, spell.get("id", ""))

	Log.info(TAG, "Cast '%s' on '%s' for %d damage (cost %d mana)" % [
		spell.get("name", "?"), target_id, spell_damage, mana_cost
	])


## Applies healing to a target.
func _apply_healing(target_id: String, amount: int) -> void:
	var player_id: String = StateManager.player_data.get("id", "player")
	if target_id == player_id or target_id == "":
		var current_hp: int = StateManager.player_data.get("hp", 100)
		var max_hp: int = StateManager.player_data.get("max_hp", 100)
		var new_hp: int = mini(max_hp, current_hp + amount)
		StateManager.player_data["hp"] = new_hp
		StateManager.player_hp_changed.emit(new_hp, max_hp)
		Log.info(TAG, "Healed player for %d HP (%d/%d)" % [amount, new_hp, max_hp])


## Applies damage to the player character.
func _apply_damage_to_player(amount: int) -> void:
	var current_hp: int = StateManager.player_data.get("hp", 100)
	var max_hp: int = StateManager.player_data.get("max_hp", 100)
	var new_hp: int = maxi(0, current_hp - amount)
	StateManager.player_data["hp"] = new_hp
	StateManager.player_hp_changed.emit(new_hp, max_hp)

	if new_hp <= 0:
		_handle_player_death()


## Applies damage to a non-player character (NPC/enemy).
func _apply_damage_to_npc(target_id: String, amount: int) -> void:
	# Initialize HP tracking if not already tracked.
	if target_id not in _target_hp:
		# Try to get max HP from the character data via MockDataProvider.
		var enemies := _find_enemy_data(target_id)
		var max_hp: int = enemies.get("max_hp", 50)
		var current_hp: int = enemies.get("hp", max_hp)
		_target_hp[target_id] = current_hp

	var current_hp: int = _target_hp[target_id]
	var new_hp: int = maxi(0, current_hp - amount)
	_target_hp[target_id] = new_hp

	if new_hp <= 0:
		_handle_target_death(target_id)


## Finds enemy data from MockDataProvider for HP initialization.
func _find_enemy_data(target_id: String) -> Dictionary:
	# Check nearby chunks for enemy data.
	var px: int = StateManager.player_position.x / 32
	var py: int = StateManager.player_position.y / 32
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var enemies: Array = MockDataProvider.get_enemies_in_chunk(px + dx, py + dy)
			for enemy in enemies:
				if enemy.get("id", "") == target_id:
					return enemy
	return {}


# ---------------------------------------------------------------------------
# Death handling
# ---------------------------------------------------------------------------


## Handles player character death — emits signals, restricts actions.
func _handle_player_death() -> void:
	Log.info(TAG, "Player has died!")
	StateManager.player_died.emit()
	StateManager.character_died.emit(StateManager.player_data.get("id", "player"))


## Handles NPC/enemy death — emits signals with loot.
func _handle_target_death(target_id: String) -> void:
	var enemy_data := _find_enemy_data(target_id)
	var loot: Array = enemy_data.get("loot_table", [])

	Log.info(TAG, "Target '%s' killed!" % target_id)
	target_killed.emit(target_id, loot)
	StateManager.character_died.emit(target_id)

	# Clean up HP tracking.
	_target_hp.erase(target_id)


# ---------------------------------------------------------------------------
# Cooldown management
# ---------------------------------------------------------------------------


## Returns true if the given category is currently on cooldown.
func _is_on_cooldown(category: String) -> bool:
	return _cooldowns.get(category, 0.0) > 0.0


## Starts a cooldown timer for the given category.
func _start_cooldown(category: String, duration: float) -> void:
	_cooldowns[category] = duration
	cooldown_started.emit(category, duration)
	StateManager.cooldown_started.emit(category, duration)
	Log.debug(TAG, "Cooldown started: %s (%.1fs)" % [category, duration])


## Ticks all active cooldowns and emits expiry signals.
func _update_cooldowns(delta: float) -> void:
	for category in _cooldowns.keys():
		if _cooldowns[category] <= 0.0:
			continue
		_cooldowns[category] -= delta
		if _cooldowns[category] <= 0.0:
			_cooldowns[category] = 0.0
			cooldown_expired.emit(category)
			StateManager.cooldown_finished.emit(category)
			Log.debug(TAG, "Cooldown expired: %s" % category)


## Returns the remaining cooldown time for a category, or 0.0 if not on cooldown.
func get_cooldown_remaining(category: String) -> float:
	return maxf(0.0, _cooldowns.get(category, 0.0))


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


## Returns the melee attack cooldown duration based on equipped weapon.
func _get_melee_cooldown() -> float:
	var weapon: Dictionary = StateManager.player_equipment.get("weapon", {})
	return weapon.get("attack_speed", DEFAULT_MELEE_COOLDOWN)


## Returns the ranged attack cooldown duration.
func _get_ranged_cooldown() -> float:
	var weapon: Dictionary = StateManager.player_equipment.get("weapon", {})
	return weapon.get("attack_speed", DEFAULT_RANGED_COOLDOWN)


## Stub for ammo consumption. Returns true if ammo is available.
## In a full implementation, this would check and decrement ammo in inventory.
func _consume_ammo() -> bool:
	# Check if player has any ammo-type items in inventory.
	for item in StateManager.player_inventory:
		if item is Dictionary and item.get("type", "") == "ammo":
			var count: int = item.get("count", 0)
			if count > 0:
				item["count"] = count - 1
				if item["count"] <= 0:
					# Remove empty ammo stack.
					var idx: int = StateManager.player_inventory.find(item)
					if idx >= 0:
						StateManager.player_inventory[idx] = {}
						StateManager.inventory_slot_updated.emit(idx, {})
				Log.debug(TAG, "Consumed 1 ammo")
				return true
	# If no ammo found, allow ranged attack anyway for demo purposes.
	Log.debug(TAG, "No ammo found — allowing ranged attack for demo")
	return true
