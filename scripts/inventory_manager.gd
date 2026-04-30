## Inventory_Manager — manages the player's 42 inventory slots and equipment
## slots. Processes item use, equip, and drop actions locally through
## StateManager.
##
## Lives as a child of GameplayScene.
## Requirements: 10.1, 10.2, 10.4, 10.5, 10.6
extends Node


const TAG := "InventoryManager"

## Total number of inventory slots.
const SLOT_COUNT: int = 42

## Valid equipment slot names.
const EQUIPMENT_SLOTS: Array = [
	"weapon", "shield", "helmet", "body", "legs",
	"boots", "gloves", "ring_1", "ring_2", "amulet", "backpack",
]

## Item types that can be used (consumed).
const USABLE_TYPES: Array = ["potion", "food", "scroll", "consumable"]

## Item types that can be equipped.
const EQUIPPABLE_TYPES: Array = ["weapon", "shield", "helmet", "armor", "legs", "boots", "gloves", "ring", "amulet"]

## Maps item type to the equipment slot it occupies.
const TYPE_TO_SLOT: Dictionary = {
	"weapon": "weapon",
	"shield": "shield",
	"helmet": "helmet",
	"armor": "body",
	"legs": "legs",
	"boots": "boots",
	"gloves": "gloves",
	"ring": "ring_1",
	"amulet": "amulet",
}


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------


func _ready() -> void:
	_ensure_inventory_size()
	Log.info(TAG, "Inventory_Manager ready — %d slots" % SLOT_COUNT)


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------


## Returns the item dictionary at [param slot_index], or an empty dict.
func get_slot(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		Log.warning(TAG, "Invalid slot index: %d" % slot_index)
		return {}
	_ensure_inventory_size()
	var item: Variant = StateManager.player_inventory[slot_index]
	if item is Dictionary:
		return item
	return {}


## Uses the item at [param slot_index]. Applies effect based on item type
## (potions heal HP/mana, scrolls apply buffs, etc.).
func use_item(slot_index: int) -> void:
	var item := get_slot(slot_index)
	if item.is_empty():
		Log.info(TAG, "Slot %d is empty — nothing to use" % slot_index)
		return

	var item_type: String = item.get("type", "")
	if item_type not in USABLE_TYPES:
		# Check for mount/boat items.
		if item_type == "mount":
			_activate_mount(item)
			return
		if item_type == "boat":
			_activate_boat(item)
			return
		Log.info(TAG, "Item '%s' (type: %s) is not usable" % [item.get("name", "?"), item_type])
		return

	# Apply item effect.
	_apply_item_effect(item)

	# Consume the item (reduce stack or remove).
	var count: int = item.get("count", 1)
	if count > 1:
		item["count"] = count - 1
		StateManager.player_inventory[slot_index] = item
	else:
		StateManager.player_inventory[slot_index] = {}

	StateManager.inventory_slot_updated.emit(slot_index, StateManager.player_inventory[slot_index])
	Log.info(TAG, "Used item '%s' from slot %d" % [item.get("name", "?"), slot_index])


## Equips the item at [param slot_index], moving it to the appropriate
## equipment slot. If an item is already equipped in that slot, it swaps
## back to the inventory slot.
func equip_item(slot_index: int) -> void:
	var item := get_slot(slot_index)
	if item.is_empty():
		Log.info(TAG, "Slot %d is empty — nothing to equip" % slot_index)
		return

	var item_type: String = item.get("type", "")
	if item_type not in EQUIPPABLE_TYPES:
		Log.info(TAG, "Item '%s' (type: %s) is not equippable" % [item.get("name", "?"), item_type])
		return

	var equip_slot: String = TYPE_TO_SLOT.get(item_type, "")
	if equip_slot == "":
		Log.warning(TAG, "No equipment slot mapping for type '%s'" % item_type)
		return

	# Handle ring slot — use ring_2 if ring_1 is occupied.
	var ring_check = StateManager.player_equipment.get("ring_1", {})
	var ring_occupied: bool = false
	if ring_check is Dictionary:
		ring_occupied = not ring_check.is_empty()
	elif ring_check is String:
		ring_occupied = ring_check != ""
	if item_type == "ring" and ring_occupied:
		equip_slot = "ring_2"

	# Swap: move currently equipped item (if any) back to inventory slot.
	var equipped_raw = StateManager.player_equipment.get(equip_slot, {})
	var currently_equipped: Dictionary = {}
	if equipped_raw is Dictionary:
		currently_equipped = equipped_raw
	elif equipped_raw is String and equipped_raw != "":
		currently_equipped = MockDataProvider.get_item(equipped_raw)

	# Place new item in equipment slot.
	StateManager.player_equipment[equip_slot] = item

	# Put old equipped item (or empty) back in inventory slot.
	if currently_equipped.is_empty():
		StateManager.player_inventory[slot_index] = {}
	else:
		StateManager.player_inventory[slot_index] = currently_equipped

	# Emit signals.
	StateManager.inventory_slot_updated.emit(slot_index, StateManager.player_inventory[slot_index])
	StateManager.equipment_changed.emit(equip_slot, item)

	Log.info(TAG, "Equipped '%s' in slot '%s'" % [item.get("name", "?"), equip_slot])


## Drops the item at [param slot_index], removing it from inventory.
func drop_item(slot_index: int) -> void:
	var item := get_slot(slot_index)
	if item.is_empty():
		Log.info(TAG, "Slot %d is empty — nothing to drop" % slot_index)
		return

	var item_name: String = item.get("name", "Unknown")

	# Remove from inventory.
	StateManager.player_inventory[slot_index] = {}
	StateManager.inventory_slot_updated.emit(slot_index, {})

	Log.info(TAG, "Dropped '%s' from slot %d" % [item_name, slot_index])


## Returns the first empty slot index, or -1 if inventory is full.
func find_empty_slot() -> int:
	_ensure_inventory_size()
	for i in range(SLOT_COUNT):
		var item: Variant = StateManager.player_inventory[i]
		if not (item is Dictionary) or item.is_empty():
			return i
	return -1


## Adds an item to the first available inventory slot.
## Returns the slot index used, or -1 if inventory is full.
func add_item(item_data: Dictionary) -> int:
	var slot_index := find_empty_slot()
	if slot_index < 0:
		Log.warning(TAG, "Inventory full — cannot add '%s'" % item_data.get("name", "?"))
		return -1

	StateManager.player_inventory[slot_index] = item_data
	StateManager.inventory_slot_updated.emit(slot_index, item_data)
	Log.info(TAG, "Added '%s' to slot %d" % [item_data.get("name", "?"), slot_index])
	return slot_index


# ---------------------------------------------------------------------------
# Item effects
# ---------------------------------------------------------------------------


## Applies the effect of a consumable item.
func _apply_item_effect(item: Dictionary) -> void:
	var effect: String = item.get("effect", "")
	var value: int = item.get("effect_value", 0)

	match effect:
		"heal_hp":
			var current_hp: int = StateManager.player_data.get("hp", 100)
			var max_hp: int = StateManager.player_data.get("max_hp", 100)
			var new_hp: int = mini(max_hp, current_hp + value)
			StateManager.player_data["hp"] = new_hp
			StateManager.player_hp_changed.emit(new_hp, max_hp)
			Log.info(TAG, "Healed %d HP (%d/%d)" % [value, new_hp, max_hp])

		"heal_mana":
			var current_mana: int = StateManager.player_data.get("mana", 50)
			var max_mana: int = StateManager.player_data.get("max_mana", 50)
			var new_mana: int = mini(max_mana, current_mana + value)
			StateManager.player_data["mana"] = new_mana
			StateManager.player_mana_changed.emit(new_mana, max_mana)
			Log.info(TAG, "Restored %d mana (%d/%d)" % [value, new_mana, max_mana])

		"heal_both":
			# Heal both HP and mana.
			var current_hp: int = StateManager.player_data.get("hp", 100)
			var max_hp: int = StateManager.player_data.get("max_hp", 100)
			var new_hp: int = mini(max_hp, current_hp + value)
			StateManager.player_data["hp"] = new_hp
			StateManager.player_hp_changed.emit(new_hp, max_hp)

			var current_mana: int = StateManager.player_data.get("mana", 50)
			var max_mana: int = StateManager.player_data.get("max_mana", 50)
			var new_mana: int = mini(max_mana, current_mana + value)
			StateManager.player_data["mana"] = new_mana
			StateManager.player_mana_changed.emit(new_mana, max_mana)

		"buff":
			var buff_id: String = item.get("buff_id", "generic_buff")
			var duration: float = item.get("buff_duration", 30.0)
			StateManager.player_buffs.append({
				"id": buff_id,
				"name": item.get("name", "Buff"),
				"duration": duration,
			})
			StateManager.player_status_effect_changed.emit(
				StateManager.player_buffs + StateManager.player_debuffs
			)
			Log.info(TAG, "Applied buff '%s' for %.0fs" % [buff_id, duration])

		_:
			Log.info(TAG, "Item '%s' has no recognized effect '%s'" % [item.get("name", "?"), effect])


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


## Ensures the player_inventory array has exactly SLOT_COUNT entries.
func _ensure_inventory_size() -> void:
	while StateManager.player_inventory.size() < SLOT_COUNT:
		StateManager.player_inventory.append({})


# ---------------------------------------------------------------------------
# Mount and boat activation  (Task 25.1)
# ---------------------------------------------------------------------------


## Activates a mount item — notifies Character_Renderer to swap to mounted
## model and increases movement animation speed.
func _activate_mount(item: Dictionary) -> void:
	var player_id: String = StateManager.player_data.get("id", "player")
	var mount_type: String = item.get("mount_type", "horse")

	# Find Character_Renderer in the scene tree.
	var char_renderer: Node = _find_sibling("CharacterRenderer")
	if char_renderer and char_renderer.has_method("swap_to_mounted_model"):
		char_renderer.swap_to_mounted_model(player_id, mount_type)
		Log.info(TAG, "Mount activated: %s (%s)" % [item.get("name", "?"), mount_type])
	else:
		Log.warning(TAG, "CharacterRenderer not found — cannot activate mount")


## Activates a boat item near water tiles — notifies Character_Renderer to
## swap to boat model and connects sailing ambient sounds.
func _activate_boat(item: Dictionary) -> void:
	var player_id: String = StateManager.player_data.get("id", "player")

	# Find Character_Renderer in the scene tree.
	var char_renderer: Node = _find_sibling("CharacterRenderer")
	if char_renderer and char_renderer.has_method("swap_to_boat_model"):
		char_renderer.swap_to_boat_model(player_id)
		# Play sailing ambient sound.
		AudioManager.play_ambient("sailing", "res://audio/ambient/sailing.ogg", Vector3.ZERO)
		Log.info(TAG, "Boat activated: %s" % item.get("name", "?"))
	else:
		Log.warning(TAG, "CharacterRenderer not found — cannot activate boat")


## Finds a sibling node by name.
func _find_sibling(node_name: String) -> Node:
	var parent := get_parent()
	if parent:
		return parent.get_node_or_null(node_name)
	return null
