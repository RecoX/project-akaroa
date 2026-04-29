## Quest_Manager — manages active quest tracking, objective progress, and
## completion logic.
##
## Reads quest definitions from MockDataProvider. Connects to combat and
## collection events to auto-update kill/collect objectives.
## Lives as a child of GameplayScene.
##
## Requirements: 21.1, 21.2, 21.4
extends Node


const TAG := "QuestManager"


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------


func _ready() -> void:
	# Connect to combat events for auto-updating kill objectives.
	StateManager.character_died.connect(_on_character_died)
	# Connect to inventory updates for auto-updating collect objectives.
	StateManager.inventory_slot_updated.connect(_on_inventory_updated)

	Log.info(TAG, "Quest_Manager ready")


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------


## Accepts a quest by ID and adds it to the player's active quest list.
func accept_quest(quest_id: String) -> void:
	# Check if already accepted.
	for quest in StateManager.player_quests:
		if quest.get("id", quest.get("quest_id", "")) == quest_id:
			Log.info(TAG, "Quest '%s' already accepted" % quest_id)
			return

	var quest_data: Dictionary = MockDataProvider.get_quest(quest_id)
	if quest_data.is_empty():
		Log.warning(TAG, "Quest '%s' not found" % quest_id)
		return

	# Check level requirement.
	var player_level: int = StateManager.player_data.get("level", 1)
	var required_level: int = quest_data.get("level_requirement", 1)
	if player_level < required_level:
		Log.info(TAG, "Level too low for quest '%s' (need %d, have %d)" % [
			quest_id, required_level, player_level])
		return

	# Deep copy the quest data so we can track progress independently.
	var active_quest := quest_data.duplicate(true)

	# Ensure objectives have a "current" field.
	var objectives: Array = active_quest.get("objectives", [])
	for i in range(objectives.size()):
		if not objectives[i].has("current"):
			objectives[i]["current"] = 0

	StateManager.player_quests.append(active_quest)
	StateManager.quest_accepted.emit(quest_id)

	Log.info(TAG, "Accepted quest: '%s' — %s" % [
		quest_id, active_quest.get("title", "?")])


## Updates a specific objective's progress for a quest.
## [param quest_id] The quest to update.
## [param obj_index] The objective index within the quest.
## [param progress] The new progress value.
func update_objective(quest_id: String, obj_index: int, progress: int) -> void:
	var quest := _find_active_quest(quest_id)
	if quest.is_empty():
		return

	var objectives: Array = quest.get("objectives", [])
	if obj_index < 0 or obj_index >= objectives.size():
		Log.warning(TAG, "Invalid objective index %d for quest '%s'" % [obj_index, quest_id])
		return

	var objective: Dictionary = objectives[obj_index]
	var quantity: int = objective.get("quantity", 1)
	objective["current"] = mini(progress, quantity)

	StateManager.quest_objective_updated.emit(quest_id, obj_index, objective["current"])
	Log.debug(TAG, "Quest '%s' objective %d: %d/%d" % [
		quest_id, obj_index, objective["current"], quantity])

	# Check if all objectives are complete.
	_check_quest_completion(quest_id)


## Returns the list of active quests.
func get_active_quests() -> Array:
	return StateManager.player_quests


## Returns a specific active quest by ID, or empty dict.
func get_quest(quest_id: String) -> Dictionary:
	return _find_active_quest(quest_id)


## Returns whether a quest is complete (all objectives met).
func is_quest_complete(quest_id: String) -> bool:
	var quest := _find_active_quest(quest_id)
	if quest.is_empty():
		return false
	return _all_objectives_met(quest)


## Completes a quest and grants rewards.
func complete_quest(quest_id: String) -> void:
	var quest := _find_active_quest(quest_id)
	if quest.is_empty():
		Log.warning(TAG, "Cannot complete quest '%s' — not found" % quest_id)
		return

	if not _all_objectives_met(quest):
		Log.info(TAG, "Quest '%s' objectives not yet met" % quest_id)
		return

	# Grant rewards.
	var rewards: Dictionary = quest.get("rewards", {})
	_grant_rewards(rewards)

	# Remove from active quests.
	StateManager.player_quests.erase(quest)
	StateManager.quest_completed.emit(quest_id)

	Log.info(TAG, "Quest completed: '%s' — %s" % [quest_id, quest.get("title", "?")])


# ---------------------------------------------------------------------------
# Auto-update handlers
# ---------------------------------------------------------------------------


## When a character dies, check if any active quest has a kill objective for it.
func _on_character_died(char_id: String) -> void:
	for quest in StateManager.player_quests:
		var quest_id: String = quest.get("id", quest.get("quest_id", ""))
		var objectives: Array = quest.get("objectives", [])
		for i in range(objectives.size()):
			var obj: Dictionary = objectives[i]
			if obj.get("type", "") == "kill" and obj.get("enemy_id", "") == char_id:
				var current: int = obj.get("current", 0)
				var quantity: int = obj.get("quantity", 1)
				if current < quantity:
					update_objective(quest_id, i, current + 1)


## When inventory updates, check collect objectives.
func _on_inventory_updated(slot_index: int, item_data: Dictionary) -> void:
	if item_data.is_empty():
		return
	var item_id: String = item_data.get("id", item_data.get("item_id", ""))
	if item_id.is_empty():
		return

	# Count total of this item in inventory.
	var total_count := _count_item_in_inventory(item_id)

	for quest in StateManager.player_quests:
		var quest_id: String = quest.get("id", quest.get("quest_id", ""))
		var objectives: Array = quest.get("objectives", [])
		for i in range(objectives.size()):
			var obj: Dictionary = objectives[i]
			if obj.get("type", "") == "collect" and obj.get("item_id", "") == item_id:
				var quantity: int = obj.get("quantity", 1)
				var new_progress: int = mini(total_count, quantity)
				if new_progress != obj.get("current", 0):
					update_objective(quest_id, i, new_progress)


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------


## Finds an active quest by ID.
func _find_active_quest(quest_id: String) -> Dictionary:
	for quest in StateManager.player_quests:
		if quest.get("id", quest.get("quest_id", "")) == quest_id:
			return quest
	return {}


## Checks if all objectives in a quest are met.
func _all_objectives_met(quest: Dictionary) -> bool:
	var objectives: Array = quest.get("objectives", [])
	for obj in objectives:
		if obj.get("current", 0) < obj.get("quantity", 1):
			return false
	return true


## Checks if a quest is complete and auto-completes it.
func _check_quest_completion(quest_id: String) -> void:
	var quest := _find_active_quest(quest_id)
	if quest.is_empty():
		return
	if _all_objectives_met(quest):
		Log.info(TAG, "All objectives met for quest '%s'" % quest_id)
		# Don't auto-complete — player must turn in to NPC.
		# But emit a signal so UI can show completion indicator.


## Grants quest rewards to the player.
func _grant_rewards(rewards: Dictionary) -> void:
	# XP reward.
	var xp_reward: int = rewards.get("xp", 0)
	if xp_reward > 0:
		var current_xp: int = StateManager.player_data.get("xp", 0)
		StateManager.player_data["xp"] = current_xp + xp_reward
		var xp_to_next: int = StateManager.player_data.get("xp_to_next", 100)
		var level: int = StateManager.player_data.get("level", 1)
		StateManager.player_xp_changed.emit(StateManager.player_data["xp"], xp_to_next, level)
		Log.info(TAG, "Granted %d XP" % xp_reward)

	# Gold reward.
	var gold_reward: int = rewards.get("gold", 0)
	if gold_reward > 0:
		var current_gold: int = StateManager.player_data.get("gold", 0)
		StateManager.player_data["gold"] = current_gold + gold_reward
		StateManager.player_gold_changed.emit(StateManager.player_data["gold"])
		Log.info(TAG, "Granted %d gold" % gold_reward)

	# Item rewards.
	var item_rewards: Array = rewards.get("items", [])
	var inv_manager: Node = _get_inventory_manager()
	if inv_manager:
		for item_id in item_rewards:
			var item_data: Dictionary = MockDataProvider.get_item(item_id)
			if not item_data.is_empty():
				inv_manager.add_item(item_data.duplicate())
				Log.info(TAG, "Granted item: '%s'" % item_data.get("name", "?"))


## Counts how many of a specific item the player has in inventory.
func _count_item_in_inventory(item_id: String) -> int:
	var count := 0
	for item in StateManager.player_inventory:
		if item is Dictionary and not item.is_empty():
			if item.get("id", item.get("item_id", "")) == item_id:
				count += item.get("count", 1)
	return count


## Finds the InventoryManager node.
func _get_inventory_manager() -> Node:
	var parent := get_parent()
	if parent:
		for child in parent.get_children():
			if child.name == "Inventory_Manager":
				return child
	return null
