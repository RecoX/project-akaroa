## Trade Panel — two-column layout for player-to-player trading.
##
## Shows both players' offer slots and gold amounts with confirm/cancel buttons.
## Requirements: 15.2, 15.3, 15.4, 15.5
extends Control


const TAG := "TradePanel"
const TRADE_SLOTS := 6

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var player_slots: VBoxContainer = $MarginContainer/VBoxContainer/TradeColumns/PlayerColumn/PlayerSlots
@onready var partner_slots: VBoxContainer = $MarginContainer/VBoxContainer/TradeColumns/PartnerColumn/PartnerSlots
@onready var player_gold_label: Label = $MarginContainer/VBoxContainer/TradeColumns/PlayerColumn/PlayerGoldLabel
@onready var partner_gold_label: Label = $MarginContainer/VBoxContainer/TradeColumns/PartnerColumn/PartnerGoldLabel
@onready var confirm_button: Button = $MarginContainer/VBoxContainer/ButtonBar/ConfirmButton
@onready var cancel_button: Button = $MarginContainer/VBoxContainer/ButtonBar/CancelButton

var _player_slot_labels: Array[Label] = []
var _partner_slot_labels: Array[Label] = []


func _ready() -> void:
	visible = false

	# Create slot labels for both columns.
	for i in range(TRADE_SLOTS):
		var p_label := Label.new()
		p_label.text = "[Empty Slot %d]" % (i + 1)
		p_label.custom_minimum_size = Vector2(0, 28)
		player_slots.add_child(p_label)
		_player_slot_labels.append(p_label)

		var t_label := Label.new()
		t_label.text = "[Empty Slot %d]" % (i + 1)
		t_label.custom_minimum_size = Vector2(0, 28)
		partner_slots.add_child(t_label)
		_partner_slot_labels.append(t_label)

	if confirm_button:
		confirm_button.pressed.connect(_on_confirm_pressed)
	if cancel_button:
		cancel_button.pressed.connect(_on_cancel_pressed)

	# Connect to trade signals.
	StateManager.trade_opened.connect(_on_trade_opened)
	StateManager.trade_slot_updated.connect(_on_trade_slot_updated)
	StateManager.trade_closed.connect(_on_trade_closed)

	Log.info(TAG, "TradePanel ready")


func _on_trade_opened(partner_data: Dictionary) -> void:
	title_label.text = "Trade with %s" % partner_data.get("name", "Unknown")
	_clear_slots()
	player_gold_label.text = "Gold: 0"
	partner_gold_label.text = "Gold: 0"
	visible = true


func _on_trade_slot_updated(is_player: bool, slot_index: int, item_data: Dictionary) -> void:
	if slot_index < 0 or slot_index >= TRADE_SLOTS:
		return
	var label_array := _player_slot_labels if is_player else _partner_slot_labels
	if item_data.is_empty():
		label_array[slot_index].text = "[Empty Slot %d]" % (slot_index + 1)
	else:
		label_array[slot_index].text = item_data.get("name", "Unknown")


func _on_trade_closed() -> void:
	visible = false
	_clear_slots()


func _on_confirm_pressed() -> void:
	var trade_system: Node = _get_trade_system()
	if trade_system and trade_system.has_method("confirm_trade"):
		trade_system.confirm_trade()


func _on_cancel_pressed() -> void:
	var trade_system: Node = _get_trade_system()
	if trade_system and trade_system.has_method("cancel_trade"):
		trade_system.cancel_trade()


func _clear_slots() -> void:
	for i in range(TRADE_SLOTS):
		if i < _player_slot_labels.size():
			_player_slot_labels[i].text = "[Empty Slot %d]" % (i + 1)
		if i < _partner_slot_labels.size():
			_partner_slot_labels[i].text = "[Empty Slot %d]" % (i + 1)


func _get_trade_system() -> Node:
	var gameplay := get_tree().current_scene
	if gameplay:
		for child in gameplay.get_children():
			if child.name == "Trade_System":
				return child
		var gs := gameplay.get_node_or_null("GameplayScene")
		if gs:
			for child in gs.get_children():
				if child.name == "Trade_System":
					return child
	return null
