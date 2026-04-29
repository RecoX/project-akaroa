## Crafting_System — manages crafting disciplines and resource gathering.
##
## Reads recipes from MockDataProvider. Checks material availability in
## inventory, consumes materials, and produces result items based on mock
## success/failure logic using success_base_chance from recipes.
##
## Requirements: 16.3, 16.4, 16.6
extends Node


const TAG := "CraftingSystem"

## Supported crafting disciplines.
const DISCIPLINES: Array = ["blacksmithing", "carpentry", "alchemy", "tailoring"]

## Emitted when a craft attempt completes.
signal craft_completed(success: bool, result_item: Dictionary, recipe_id: String)

## Emitted when a gathering activity starts.
signal gathering_started(activity: String)

## Emitted when a gathering activity produces a result.
signal gathering_completed(activity: String, items: Array)

## Whether the player is currently gathering.
var _is_gathering: bool = false
var _gathering_activity: String = ""


func _ready() -> void:
	Log.info(TAG, "Crafting_System ready — disciplines: %s" % str(DISCIPLINES))


# ---------------------------------------------------------------------------
# Crafting
# ---------------------------------------------------------------------------


## Attempts to craft an item using the given recipe.
## Returns a dictionary: {success: bool, item: Dictionary, message: String}
func craft(recipe_id: String) -> Dictionary:
	var recipe := _get_recipe(recipe_id)
	if recipe.is_empty():
		Log.warning(TAG, "Recipe '%s' not found" % recipe_id)
		return {"success": false, "item": {}, "message": "Recipe not found"}

	# Check skill requirement.
	var discipline: String = recipe.get("discipline", "")
	var skill_req: int = recipe.get("skill_requirement", 0)
	var player_skill: int = StateManager.player_skills.get(discipline, 0)
	if player_skill < skill_req:
		Log.info(TAG, "Skill too low for recipe '%s' (need %d %s, have %d)" % [
			recipe_id, skill_req, discipline, player_skill])
		return {"success": false, "item": {}, "message": "Skill too low (%d/%d %s)" % [
			player_skill, skill_req, discipline]}

	# Check material availability.
	var materials: Array = recipe.get("materials", [])
	var missing := _check_materials(materials)
	if not missing.is_empty():
		Log.info(TAG, "Missing materials for recipe '%s': %s" % [recipe_id, str(missing)])
		return {"success": false, "item": {}, "message": "Missing materials: %s" % str(missing)}

	# Consume materials.
	_consume_materials(materials)

	# Roll for success.
	var base_chance: float = recipe.get("success_base_chance", 0.8)
	var roll: float = randf()
	var success: bool = roll <= base_chance

	var result := {"success": success, "item": {}, "message": ""}

	if success:
		var result_item_id: String = recipe.get("result_item", "")
		var result_item: Dictionary = MockDataProvider.get_item(result_item_id)
		if result_item.is_empty():
			# Create a placeholder item.
			result_item = {"id": result_item_id, "name": recipe.get("name", "Crafted Item"), "type": "misc", "value": 10}

		var inv_manager: Node = _get_inventory_manager()
		if inv_manager:
			var slot: int = inv_manager.add_item(result_item.duplicate())
			if slot >= 0:
				result["item"] = result_item
				result["message"] = "Crafted '%s' successfully!" % result_item.get("name", "?")
				Log.info(TAG, "Craft success: '%s'" % result_item.get("name", "?"))
			else:
				result["message"] = "Crafted '%s' but inventory is full!" % result_item.get("name", "?")
				Log.info(TAG, "Craft success but inventory full")
		else:
			result["message"] = "Crafted item but no inventory manager found"
	else:
		result["message"] = "Crafting failed! Materials consumed."
		Log.info(TAG, "Craft failed for recipe '%s' (roll %.2f > chance %.2f)" % [
			recipe_id, roll, base_chance])

	craft_completed.emit(success, result.get("item", {}), recipe_id)
	return result


## Returns all recipes for a given discipline.
func get_recipes(discipline: String) -> Array:
	return MockDataProvider.get_recipes_for_discipline(discipline)


## Returns all available disciplines.
func get_disciplines() -> Array:
	return DISCIPLINES.duplicate()


# ---------------------------------------------------------------------------
# Resource Gathering
# ---------------------------------------------------------------------------


## Starts a fishing activity. Emits gathering_started signal.
func start_fishing() -> void:
	if _is_gathering:
		Log.info(TAG, "Already gathering — cannot start fishing")
		return
	_is_gathering = true
	_gathering_activity = "fishing"
	gathering_started.emit("fishing")
	Log.info(TAG, "Fishing started")


## Starts a mining activity. Processes result locally.
func start_mining() -> void:
	if _is_gathering:
		Log.info(TAG, "Already gathering — cannot start mining")
		return
	_is_gathering = true
	_gathering_activity = "mining"
	gathering_started.emit("mining")
	Log.info(TAG, "Mining started")

	# Auto-complete after a mock delay.
	_complete_gathering_mock("mining", ["iron_ore"])


## Starts a woodcutting activity. Processes result locally.
func start_woodcutting() -> void:
	if _is_gathering:
		Log.info(TAG, "Already gathering — cannot start woodcutting")
		return
	_is_gathering = true
	_gathering_activity = "woodcutting"
	gathering_started.emit("woodcutting")
	Log.info(TAG, "Woodcutting started")

	# Auto-complete after a mock delay.
	_complete_gathering_mock("woodcutting", ["wood_plank"])


## Completes the current fishing activity with a result.
## Called by the fishing minigame UI on success.
func complete_fishing(success: bool) -> void:
	if _gathering_activity != "fishing":
		return

	_is_gathering = false
	_gathering_activity = ""

	if success:
		# Give a random fish item (mock).
		var fish_item := {
			"id": "raw_fish",
			"name": "Raw Fish",
			"type": "consumable",
			"value": 5,
			"effect": "heal_hp",
			"effect_value": 15,
		}
		var inv_manager: Node = _get_inventory_manager()
		if inv_manager:
			inv_manager.add_item(fish_item)
		gathering_completed.emit("fishing", [fish_item])
		Log.info(TAG, "Fishing success — caught a fish!")
	else:
		gathering_completed.emit("fishing", [])
		Log.info(TAG, "Fishing failed — the fish got away!")


## Cancels the current gathering activity.
func cancel_gathering() -> void:
	if not _is_gathering:
		return
	Log.info(TAG, "Gathering cancelled: %s" % _gathering_activity)
	_is_gathering = false
	_gathering_activity = ""


## Returns whether the player is currently gathering.
func is_gathering() -> bool:
	return _is_gathering


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------


## Finds a recipe by ID from MockDataProvider.
func _get_recipe(recipe_id: String) -> Dictionary:
	# Search all disciplines for the recipe.
	for discipline in DISCIPLINES:
		var recipes: Array = MockDataProvider.get_recipes_for_discipline(discipline)
		for recipe in recipes:
			if recipe.get("id", recipe.get("recipe_id", "")) == recipe_id:
				return recipe
	return {}


## Checks if the player has all required materials.
## Returns an array of missing material descriptions, or empty if all present.
func _check_materials(materials: Array) -> Array:
	var missing: Array = []
	for mat in materials:
		var item_id: String = mat.get("item_id", "")
		var needed: int = mat.get("quantity", 1)
		var have: int = _count_item_in_inventory(item_id)
		if have < needed:
			missing.append("%s (%d/%d)" % [item_id, have, needed])
	return missing


## Consumes the required materials from inventory.
func _consume_materials(materials: Array) -> void:
	for mat in materials:
		var item_id: String = mat.get("item_id", "")
		var quantity: int = mat.get("quantity", 1)
		_remove_items_from_inventory(item_id, quantity)


## Counts how many of a specific item the player has.
func _count_item_in_inventory(item_id: String) -> int:
	var count := 0
	for item in StateManager.player_inventory:
		if item is Dictionary and not item.is_empty():
			if item.get("id", item.get("item_id", "")) == item_id:
				count += item.get("count", 1)
	return count


## Removes a quantity of items from inventory.
func _remove_items_from_inventory(item_id: String, quantity: int) -> void:
	var remaining := quantity
	var inv_manager: Node = _get_inventory_manager()
	if inv_manager == null:
		return

	for i in range(StateManager.player_inventory.size()):
		if remaining <= 0:
			break
		var item: Variant = StateManager.player_inventory[i]
		if item is Dictionary and not item.is_empty():
			if item.get("id", item.get("item_id", "")) == item_id:
				var stack: int = item.get("count", 1)
				if stack <= remaining:
					remaining -= stack
					inv_manager.drop_item(i)
				else:
					item["count"] = stack - remaining
					remaining = 0
					StateManager.inventory_slot_updated.emit(i, item)


## Mock gathering completion — adds items to inventory.
func _complete_gathering_mock(activity: String, item_ids: Array) -> void:
	_is_gathering = false
	_gathering_activity = ""

	var gathered_items: Array = []
	var inv_manager: Node = _get_inventory_manager()

	for item_id in item_ids:
		var item_data: Dictionary = MockDataProvider.get_item(item_id)
		if item_data.is_empty():
			# Create a placeholder resource item.
			item_data = {"id": item_id, "name": item_id.capitalize(), "type": "material", "value": 2}
		if inv_manager:
			inv_manager.add_item(item_data.duplicate())
		gathered_items.append(item_data)

	gathering_completed.emit(activity, gathered_items)
	Log.info(TAG, "Gathering complete: %s — %d items" % [activity, gathered_items.size()])


## Finds the InventoryManager node.
func _get_inventory_manager() -> Node:
	var parent := get_parent()
	if parent:
		for child in parent.get_children():
			if child.name == "Inventory_Manager":
				return child
	return null
