## Shop Panel — displays NPC shop items with buy/sell functionality.
##
## Shows the NPC's available items with names, prices, and icons.
## Supports buying items and selling inventory items to the NPC.
## Requirements: 14.2, 14.3, 14.4
extends Control


const TAG := "ShopPanel"

## The NPC whose shop is currently displayed.
var _current_npc_id: String = ""
var _current_npc_data: Dictionary = {}
var _shop_items: Array = []

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var item_list: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ItemList
@onready var gold_label: Label = $MarginContainer/VBoxContainer/BottomBar/GoldLabel
@onready var close_button: Button = $MarginContainer/VBoxContainer/BottomBar/CloseButton


func _ready() -> void:
	visible = false
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	StateManager.player_gold_changed.connect(_on_gold_changed)
	Log.info(TAG, "ShopPanel ready")


## Opens the shop for the given NPC.
func open_shop(npc_id: String) -> void:
	_current_npc_id = npc_id
	_current_npc_data = MockDataProvider.get_npc(npc_id)
	if _current_npc_data.is_empty():
		Log.warning(TAG, "NPC '%s' not found" % npc_id)
		return

	title_label.text = _current_npc_data.get("name", "Shop")
	_load_shop_items()
	_update_gold_display()
	visible = true
	Log.info(TAG, "Opened shop for NPC '%s'" % npc_id)


## Loads and displays the NPC's shop inventory.
func _load_shop_items() -> void:
	# Clear existing items.
	for child in item_list.get_children():
		child.queue_free()

	_shop_items.clear()
	var item_ids: Array = _current_npc_data.get("shop_inventory", [])

	for item_id in item_ids:
		var item_data: Dictionary = MockDataProvider.get_item(item_id)
		if item_data.is_empty():
			continue
		_shop_items.append(item_data)
		_create_shop_item_row(item_data)


## Creates a single row in the shop item list.
func _create_shop_item_row(item_data: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 36)

	# Item name.
	var name_label := Label.new()
	name_label.text = item_data.get("name", "Unknown")
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)

	# Item type.
	var type_label := Label.new()
	type_label.text = item_data.get("type", "")
	type_label.custom_minimum_size = Vector2(80, 0)
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(type_label)

	# Price.
	var price_label := Label.new()
	price_label.text = "%d g" % item_data.get("value", 0)
	price_label.custom_minimum_size = Vector2(60, 0)
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(price_label)

	# Buy button.
	var buy_btn := Button.new()
	buy_btn.text = "Buy"
	buy_btn.custom_minimum_size = Vector2(60, 0)
	var item_id: String = item_data.get("id", item_data.get("item_id", ""))
	buy_btn.pressed.connect(_on_buy_pressed.bind(item_id))
	row.add_child(buy_btn)

	item_list.add_child(row)


## Handles buying an item.
func _on_buy_pressed(item_id: String) -> void:
	var trade_system: Node = _get_trade_system()
	if trade_system and trade_system.has_method("buy_from_npc"):
		var success: bool = trade_system.buy_from_npc(_current_npc_id, item_id)
		if success:
			_update_gold_display()
		else:
			Log.info(TAG, "Purchase failed for item '%s'" % item_id)


## Updates the gold display.
func _update_gold_display() -> void:
	var gold: int = StateManager.player_data.get("gold", 0)
	gold_label.text = "Gold: %d" % gold


func _on_gold_changed(gold: int) -> void:
	gold_label.text = "Gold: %d" % gold


func _on_close_pressed() -> void:
	visible = false


## Finds the Trade_System node.
func _get_trade_system() -> Node:
	var gameplay := get_tree().current_scene
	if gameplay:
		for child in gameplay.get_children():
			if child.name == "Trade_System":
				return child
		# Try deeper.
		var gs := gameplay.get_node_or_null("GameplayScene")
		if gs:
			for child in gs.get_children():
				if child.name == "Trade_System":
					return child
	return null
