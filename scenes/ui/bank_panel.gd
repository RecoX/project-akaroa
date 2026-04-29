## Bank Panel — grid of bank slots for item deposit and withdrawal.
##
## Provides a mock bank storage system where players can deposit items from
## their inventory and withdraw them later.
## Requirements: 14.5
extends Control


const TAG := "BankPanel"

## Number of bank storage slots.
const BANK_SLOTS := 24
const SLOTS_PER_ROW := 6

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var grid: GridContainer = $MarginContainer/VBoxContainer/ScrollContainer/GridContainer
@onready var close_button: Button = $MarginContainer/VBoxContainer/BottomBar/CloseButton

## Mock bank storage — array of item dictionaries.
var _bank_storage: Array = []

## Button references for updating display.
var _slot_buttons: Array[Button] = []


func _ready() -> void:
	visible = false
	_bank_storage.resize(BANK_SLOTS)
	for i in range(BANK_SLOTS):
		_bank_storage[i] = {}

	_create_bank_slots()

	if close_button:
		close_button.pressed.connect(_on_close_pressed)

	Log.info(TAG, "BankPanel ready — %d slots" % BANK_SLOTS)


## Opens the bank panel.
func open_bank() -> void:
	_refresh_display()
	visible = true
	Log.info(TAG, "Bank opened")


## Deposits an item from inventory into the first empty bank slot.
## Returns true on success.
func deposit_item(inventory_slot: int) -> bool:
	var inv_manager: Node = _get_inventory_manager()
	if inv_manager == null:
		return false

	var item: Dictionary = inv_manager.get_slot(inventory_slot)
	if item.is_empty():
		Log.info(TAG, "Inventory slot %d is empty" % inventory_slot)
		return false

	# Find empty bank slot.
	var bank_slot := _find_empty_bank_slot()
	if bank_slot < 0:
		Log.info(TAG, "Bank is full")
		return false

	# Move item: remove from inventory, add to bank.
	_bank_storage[bank_slot] = item.duplicate()
	inv_manager.drop_item(inventory_slot)

	_refresh_display()
	Log.info(TAG, "Deposited '%s' into bank slot %d" % [item.get("name", "?"), bank_slot])
	return true


## Withdraws an item from a bank slot into the player's inventory.
## Returns true on success.
func withdraw_item(bank_slot: int) -> bool:
	if bank_slot < 0 or bank_slot >= BANK_SLOTS:
		return false

	var item: Dictionary = _bank_storage[bank_slot]
	if item.is_empty():
		Log.info(TAG, "Bank slot %d is empty" % bank_slot)
		return false

	var inv_manager: Node = _get_inventory_manager()
	if inv_manager == null:
		return false

	var inv_slot: int = inv_manager.add_item(item.duplicate())
	if inv_slot < 0:
		Log.info(TAG, "Inventory full — cannot withdraw")
		return false

	_bank_storage[bank_slot] = {}
	_refresh_display()
	Log.info(TAG, "Withdrew '%s' from bank slot %d" % [item.get("name", "?"), bank_slot])
	return true


## Creates the grid of bank slot buttons.
func _create_bank_slots() -> void:
	for i in range(BANK_SLOTS):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(56, 56)
		btn.text = ""
		btn.pressed.connect(_on_bank_slot_pressed.bind(i))
		grid.add_child(btn)
		_slot_buttons.append(btn)


## Refreshes the visual display of all bank slots.
func _refresh_display() -> void:
	for i in range(BANK_SLOTS):
		if i >= _slot_buttons.size():
			break
		var item: Dictionary = _bank_storage[i]
		if item.is_empty():
			_slot_buttons[i].text = ""
			_slot_buttons[i].tooltip_text = "Empty"
		else:
			# Show first 3 chars of item name as icon placeholder.
			var name_str: String = item.get("name", "?")
			_slot_buttons[i].text = name_str.substr(0, 4)
			_slot_buttons[i].tooltip_text = name_str


## Handles clicking a bank slot — withdraw the item.
func _on_bank_slot_pressed(slot_index: int) -> void:
	var item: Dictionary = _bank_storage[slot_index]
	if not item.is_empty():
		withdraw_item(slot_index)


func _on_close_pressed() -> void:
	visible = false


func _find_empty_bank_slot() -> int:
	for i in range(BANK_SLOTS):
		if _bank_storage[i].is_empty():
			return i
	return -1


func _get_inventory_manager() -> Node:
	var gameplay := get_tree().current_scene
	if gameplay:
		for child in gameplay.get_children():
			if child.name == "Inventory_Manager":
				return child
		var gs := gameplay.get_node_or_null("GameplayScene")
		if gs:
			for child in gs.get_children():
				if child.name == "Inventory_Manager":
					return child
	return null
