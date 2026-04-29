## Inventory Panel — 42-slot grid with item icons, stacks, tooltips, and interactions.
##
## Supports double-click to use, hover tooltips, drag-and-drop stubs, and
## equipped item indicators. Connects to StateManager.inventory_slot_updated.
## Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6, 10.7
extends Control


const _TAG := "InventoryPanel"
const SLOT_COUNT: int = 42
const SLOTS_PER_ROW: int = 7


# --- Node references ---
var _grid: GridContainer
var _tooltip_panel: PanelContainer
var _tooltip_name: Label
var _tooltip_type: Label
var _tooltip_stats: Label

## Slot node references.
var _slots: Array = []

## Tracks the last click time per slot for double-click detection.
var _last_click_time: Dictionary = {}
const DOUBLE_CLICK_THRESHOLD: float = 0.4


func _ready() -> void:
	_grid = $MarginContainer/VBoxContainer/ScrollContainer/GridContainer
	_tooltip_panel = $TooltipPanel
	_tooltip_name = $TooltipPanel/VBoxContainer/NameLabel
	_tooltip_type = $TooltipPanel/VBoxContainer/TypeLabel
	_tooltip_stats = $TooltipPanel/VBoxContainer/StatsLabel

	_grid.columns = SLOTS_PER_ROW
	_tooltip_panel.visible = false

	_create_slots()

	# Connect to StateManager signals
	StateManager.inventory_slot_updated.connect(_on_slot_updated)

	# Start hidden
	visible = false

	Log.info(_TAG, "InventoryPanel initialized with %d slots" % SLOT_COUNT)


## Creates all inventory slot UI nodes inside the grid.
func _create_slots() -> void:
	for i in range(SLOT_COUNT):
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(48, 48)
		slot.name = "Slot%d" % i
		slot.mouse_filter = Control.MOUSE_FILTER_STOP

		# Store slot index as metadata for event handling.
		slot.set_meta("slot_index", i)

		var margin := MarginContainer.new()
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_theme_constant_override("margin_left", 2)
		margin.add_theme_constant_override("margin_top", 2)
		margin.add_theme_constant_override("margin_right", 2)
		margin.add_theme_constant_override("margin_bottom", 2)

		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.custom_minimum_size = Vector2(32, 32)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(icon)

		var stack_label := Label.new()
		stack_label.name = "StackLabel"
		stack_label.text = ""
		stack_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		stack_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		stack_label.add_theme_font_size_override("font_size", 10)
		stack_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Position at bottom-right of the slot.
		stack_label.anchors_preset = Control.PRESET_BOTTOM_RIGHT
		margin.add_child(stack_label)

		var equipped_indicator := Label.new()
		equipped_indicator.name = "EquippedIndicator"
		equipped_indicator.text = ""
		equipped_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		equipped_indicator.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		equipped_indicator.add_theme_font_size_override("font_size", 10)
		equipped_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(equipped_indicator)

		slot.add_child(margin)

		# Connect mouse events
		slot.gui_input.connect(_on_slot_gui_input.bind(i))
		slot.mouse_entered.connect(_on_slot_mouse_entered.bind(i))
		slot.mouse_exited.connect(_on_slot_mouse_exited.bind(i))

		_grid.add_child(slot)
		_slots.append(slot)


## Called when StateManager emits inventory_slot_updated.
func _on_slot_updated(slot_index: int, item_data: Dictionary) -> void:
	if slot_index < 0 or slot_index >= _slots.size():
		return
	_set_slot_data(slot_index, item_data)


## Updates a slot's visual state from item data.
func _set_slot_data(index: int, item_data: Dictionary) -> void:
	var slot: PanelContainer = _slots[index]
	var margin: MarginContainer = slot.get_child(0)
	var icon: TextureRect = margin.get_node("Icon")
	var stack_label: Label = margin.get_node("StackLabel")
	var equipped_indicator: Label = margin.get_node("EquippedIndicator")

	slot.set_meta("item_data", item_data)

	if item_data.is_empty():
		icon.texture = null
		stack_label.text = ""
		equipped_indicator.text = ""
		slot.tooltip_text = ""
	else:
		# Placeholder icon — real implementation would load from asset path.
		icon.texture = null
		var stack_count: int = item_data.get("stack_count", 1)
		stack_label.text = str(stack_count) if stack_count > 1 else ""
		equipped_indicator.text = "E" if item_data.get("equipped", false) else ""
		slot.tooltip_text = item_data.get("name", "Unknown Item")


## Handles input events on a slot (double-click to use).
func _on_slot_gui_input(event: InputEvent, slot_index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var now := Time.get_ticks_msec() / 1000.0
		var last: float = _last_click_time.get(slot_index, 0.0)

		if now - last < DOUBLE_CLICK_THRESHOLD:
			# Double-click — use item
			_use_item(slot_index)
			_last_click_time[slot_index] = 0.0
		else:
			_last_click_time[slot_index] = now


## Uses the item in the given slot via StateManager.
func _use_item(slot_index: int) -> void:
	var slot: PanelContainer = _slots[slot_index]
	var item_data: Dictionary = slot.get_meta("item_data") if slot.has_meta("item_data") else {}
	if item_data.is_empty():
		return
	StateManager.process_item_use(slot_index)
	Log.debug(_TAG, "Used item in slot %d: %s" % [slot_index, item_data.get("name", "?")])


## Shows the tooltip when hovering over a slot.
func _on_slot_mouse_entered(slot_index: int) -> void:
	var slot: PanelContainer = _slots[slot_index]
	var item_data: Dictionary = slot.get_meta("item_data") if slot.has_meta("item_data") else {}
	if item_data.is_empty():
		_tooltip_panel.visible = false
		return

	_tooltip_name.text = item_data.get("name", "Unknown")
	_tooltip_type.text = item_data.get("type", "Misc")

	# Build stats text
	var stats_parts: Array = []
	if item_data.has("defense"):
		stats_parts.append("Defense: %d" % item_data["defense"])
	if item_data.has("damage_min") and item_data.has("damage_max"):
		stats_parts.append("Damage: %d-%d" % [item_data["damage_min"], item_data["damage_max"]])
	if item_data.has("element"):
		stats_parts.append("Element: %s" % item_data["element"])
	if item_data.has("description"):
		stats_parts.append(item_data["description"])
	_tooltip_stats.text = "\n".join(stats_parts) if stats_parts.size() > 0 else ""

	_tooltip_panel.visible = true
	# Position tooltip near the mouse
	_tooltip_panel.global_position = get_global_mouse_position() + Vector2(16, 16)


## Hides the tooltip when the mouse leaves a slot.
func _on_slot_mouse_exited(_slot_index: int) -> void:
	_tooltip_panel.visible = false


## Drag-and-drop stub — get_drag_data for dragging items out of inventory.
func _get_drag_data_for_slot(slot_index: int) -> Variant:
	var slot: PanelContainer = _slots[slot_index]
	var item_data: Dictionary = slot.get_meta("item_data") if slot.has_meta("item_data") else {}
	if item_data.is_empty():
		return null
	return {"type": "item", "id": item_data.get("id", ""), "slot_index": slot_index}


## Updates tooltip position while visible.
func _process(_delta: float) -> void:
	if _tooltip_panel.visible:
		_tooltip_panel.global_position = get_global_mouse_position() + Vector2(16, 16)
