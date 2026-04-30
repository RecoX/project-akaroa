## Hotkey Bar — 10 configurable slots activated by keys 1-0.
##
## Each slot can be bound to an inventory item or spell for quick activation.
## Supports keyboard activation and drag-and-drop binding stubs.
## Requirements: 10.8
extends HBoxContainer


const _TAG := "HotkeyBar"
const SLOT_COUNT: int = 10

## Key labels displayed on each slot (1 through 0).
const KEY_LABELS: Array = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]

## Godot keycodes for keys 1-9 and 0.
const SLOT_KEYCODES: Array = [
	KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0,
]

## Bindings array — each entry is a Dictionary with "type" and "id" keys,
## or an empty Dictionary if unbound.
## type: "item" | "spell"
## id: the item or spell identifier string
var _bindings: Array = []

## References to the slot PanelContainer nodes.
var _slot_nodes: Array = []

## Maps cooldown category -> Array of slot indices currently on cooldown.
var _cooldown_slots: Dictionary = {}


func _ready() -> void:
	_bindings.resize(SLOT_COUNT)
	for i in range(SLOT_COUNT):
		_bindings[i] = {}

	_create_slots()

	# Connect cooldown signals for visual dimming (Task 14.3).
	StateManager.cooldown_started.connect(_on_cooldown_started)
	StateManager.cooldown_finished.connect(_on_cooldown_finished)

	# Auto-populate hotkey bar with learned spells after a short delay
	# (player data may not be set yet during _ready).
	StateManager.app_state_changed.connect(_on_app_state_changed)

	Log.info(_TAG, "HotkeyBar initialized with %d slots" % SLOT_COUNT)


## When entering gameplay, auto-bind learned spells to the first available slots.
func _on_app_state_changed(new_state: StateManager.AppState) -> void:
	if new_state == StateManager.AppState.GAMEPLAY:
		_auto_bind_spells()


## Binds learned spells to the first empty hotkey slots.
func _auto_bind_spells() -> void:
	var spells: Array = StateManager.player_spells
	var slot_index := 0
	for spell_id in spells:
		if slot_index >= SLOT_COUNT:
			break
		var id: String = spell_id if spell_id is String else str(spell_id)
		bind_slot(slot_index, "spell", id)
		slot_index += 1
	if slot_index > 0:
		Log.info(_TAG, "Auto-bound %d spells to hotkey bar" % slot_index)


## Binds a slot to an item or spell.
func bind_slot(index: int, type: String, id: String) -> void:
	if index < 0 or index >= SLOT_COUNT:
		Log.warning(_TAG, "bind_slot: index %d out of range" % index)
		return
	_bindings[index] = {"type": type, "id": id}
	_update_slot_visual(index)
	Log.debug(_TAG, "Slot %d bound to %s:%s" % [index, type, id])


## Clears a slot binding.
func clear_slot(index: int) -> void:
	if index < 0 or index >= SLOT_COUNT:
		return
	_bindings[index] = {}
	_update_slot_visual(index)


## Processes keyboard input for slot activation (keys 1-0).
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# Don't process hotkeys when a text input has focus.
		var focused := get_viewport().gui_get_focus_owner()
		if focused is LineEdit or focused is TextEdit:
			return

		var slot_index := _keycode_to_slot(event.keycode)
		if slot_index >= 0:
			_activate_slot(slot_index)
			get_viewport().set_input_as_handled()


## Activates the binding in the given slot.
func _activate_slot(index: int) -> void:
	var binding: Dictionary = _bindings[index]
	if binding.is_empty():
		Log.debug(_TAG, "Slot %d is empty — nothing to activate" % index)
		return

	var type: String = binding.get("type", "")
	var id: String = binding.get("id", "")

	match type:
		"item":
			# Find the inventory slot index for this item and use it.
			var inv_index := _find_inventory_slot(id)
			if inv_index >= 0:
				StateManager.process_item_use(inv_index)
				Log.debug(_TAG, "Activated item '%s' from slot %d" % [id, index])
			else:
				Log.warning(_TAG, "Item '%s' not found in inventory" % id)
		"spell":
			# Get the current target from StateManager for spell casting.
			var target_id: String = StateManager.current_target_id
			StateManager.process_spell_cast(id, target_id)
			Log.debug(_TAG, "Activated spell '%s' from slot %d (target: '%s')" % [id, index, target_id])
		_:
			Log.warning(_TAG, "Unknown binding type '%s' in slot %d" % [type, index])


## Creates the visual slot nodes.
func _create_slots() -> void:
	for i in range(SLOT_COUNT):
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(48, 48)
		slot.name = "Slot%d" % i

		var vbox := VBoxContainer.new()
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.custom_minimum_size = Vector2(32, 32)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(icon)

		var key_label := Label.new()
		key_label.name = "KeyLabel"
		key_label.text = KEY_LABELS[i]
		key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key_label.add_theme_font_size_override("font_size", 10)
		key_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(key_label)

		slot.add_child(vbox)
		add_child(slot)
		_slot_nodes.append(slot)


## Updates the visual appearance of a slot based on its binding.
func _update_slot_visual(index: int) -> void:
	if index < 0 or index >= _slot_nodes.size():
		return
	var slot: PanelContainer = _slot_nodes[index]
	var icon: TextureRect = slot.get_node("VBoxContainer/Icon")
	var binding: Dictionary = _bindings[index]

	if binding.is_empty():
		icon.texture = null
		slot.tooltip_text = ""
	else:
		# Placeholder — real icons would be loaded from item/spell data.
		slot.tooltip_text = "%s: %s" % [binding.get("type", ""), binding.get("id", "")]


## Converts a keycode to a slot index (0-9), or -1 if not a slot key.
func _keycode_to_slot(keycode: int) -> int:
	for i in range(SLOT_KEYCODES.size()):
		if SLOT_KEYCODES[i] == keycode:
			return i
	return -1


## Finds the first inventory slot containing the item with the given id.
func _find_inventory_slot(item_id: String) -> int:
	for i in range(StateManager.player_inventory.size()):
		var slot_data = StateManager.player_inventory[i]
		if slot_data is Dictionary and slot_data.get("id", "") == item_id:
			return i
	return -1


## Drag-and-drop support stub — can_drop_data for receiving dragged items/spells.
func _can_drop_data(_at_position: Vector2, data) -> bool:
	if data is Dictionary:
		return data.has("type") and data.has("id")
	return false


## Drag-and-drop support stub — drop_data to bind a dragged item/spell to a slot.
func _drop_data(at_position: Vector2, data) -> void:
	if not data is Dictionary:
		return
	# Determine which slot was dropped on based on position.
	var slot_index := _position_to_slot(at_position)
	if slot_index >= 0:
		bind_slot(slot_index, data.get("type", ""), data.get("id", ""))


## Converts a local position to a slot index.
func _position_to_slot(pos: Vector2) -> int:
	for i in range(_slot_nodes.size()):
		var slot: PanelContainer = _slot_nodes[i]
		var rect := slot.get_rect()
		if rect.has_point(pos):
			return i
	return -1


# ---------------------------------------------------------------------------
# Cooldown indicators  (Task 14.3)
# ---------------------------------------------------------------------------

## Category-to-binding-type mapping for matching cooldowns to slots.
const _COOLDOWN_TYPE_MAP: Dictionary = {
	"magic": "spell",
	"melee": "item",
	"ranged": "item",
	"consumable": "item",
}


## Handles StateManager.cooldown_started — dims slots matching the cooldown category.
func _on_cooldown_started(category: String, _duration: float) -> void:
	var binding_type: String = _COOLDOWN_TYPE_MAP.get(category, "")
	var affected_slots: Array = []

	for i in range(SLOT_COUNT):
		var binding: Dictionary = _bindings[i]
		if binding.is_empty():
			continue
		var slot_type: String = binding.get("type", "")
		if slot_type == binding_type:
			_dim_slot(i)
			affected_slots.append(i)

	if not affected_slots.is_empty():
		_cooldown_slots[category] = affected_slots
		Log.debug(_TAG, "Cooldown started '%s' — dimmed slots: %s" % [category, str(affected_slots)])


## Handles StateManager.cooldown_finished — restores slots matching the cooldown category.
func _on_cooldown_finished(category: String) -> void:
	var affected_slots: Array = _cooldown_slots.get(category, [])
	for i in affected_slots:
		_restore_slot(i)

	_cooldown_slots.erase(category)
	Log.debug(_TAG, "Cooldown finished '%s' — restored slots" % category)


## Visually dims a slot by reducing its modulate alpha to indicate cooldown.
func _dim_slot(index: int) -> void:
	if index < 0 or index >= _slot_nodes.size():
		return
	var slot: PanelContainer = _slot_nodes[index]
	slot.modulate = Color(0.5, 0.5, 0.5, 0.5)


## Restores a slot's visual appearance after cooldown expires.
func _restore_slot(index: int) -> void:
	if index < 0 or index >= _slot_nodes.size():
		return
	var slot: PanelContainer = _slot_nodes[index]
	slot.modulate = Color(1.0, 1.0, 1.0, 1.0)
