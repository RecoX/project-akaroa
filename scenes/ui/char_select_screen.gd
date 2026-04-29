## Character Selection screen — displays mock characters from MockDataProvider
## and allows the player to select one or create a new character.
##
## On confirm: calls StateManager.set_player_data() and transitions to GAMEPLAY.
## Requirements: 9.2, 9.3, 9.5
extends Control


const TAG := "CharSelectScreen"

## Packed scene for character creation flow.
const CHAR_CREATION_SCENE := preload("res://scenes/ui/char_creation_screen.tscn")

@onready var character_list: ItemList = %CharacterList
@onready var detail_label: RichTextLabel = %DetailLabel
@onready var enter_world_button: Button = %EnterWorldButton
@onready var create_new_button: Button = %CreateNewButton
@onready var back_button: Button = %BackButton

## Cached character data array from MockDataProvider.
var _characters: Array = []

## Index of the currently selected character in the list.
var _selected_index: int = -1

## Active character creation screen instance (if open).
var _creation_screen: Control = null


func _ready() -> void:
	enter_world_button.pressed.connect(_on_enter_world_pressed)
	create_new_button.pressed.connect(_on_create_new_pressed)
	back_button.pressed.connect(_on_back_pressed)
	character_list.item_selected.connect(_on_character_selected)

	# TODO: Signal hook for future server integration.
	# NetworkClient.character_list_received would go here.

	_refresh_character_list()
	enter_world_button.disabled = true
	Log.info(TAG, "Character select screen ready")


## Populates the character list from MockDataProvider.
func _refresh_character_list() -> void:
	character_list.clear()
	_characters = MockDataProvider.get_mock_characters()
	_selected_index = -1
	enter_world_button.disabled = true
	detail_label.text = "Select a character to view details."

	for character in _characters:
		var name_str: String = character.get("name", "Unknown")
		var level: int = character.get("level", 1)
		var char_class: String = character.get("class", "unknown").capitalize()
		var race: String = character.get("race", "unknown").capitalize()
		var display := "%s — Lv.%d %s %s" % [name_str, level, race, char_class]
		character_list.add_item(display)

	Log.info(TAG, "Loaded %d characters into list" % _characters.size())


## Called when a character is selected in the list.
func _on_character_selected(index: int) -> void:
	_selected_index = index
	enter_world_button.disabled = false

	if index < 0 or index >= _characters.size():
		detail_label.text = ""
		return

	var c: Dictionary = _characters[index]
	var details := "[b]%s[/b]\n" % c.get("name", "Unknown")
	details += "Level %d %s %s\n" % [
		c.get("level", 1),
		c.get("race", "unknown").capitalize(),
		c.get("class", "unknown").capitalize(),
	]
	details += "HP: %d/%d  |  Mana: %d/%d\n" % [
		c.get("hp", 0), c.get("max_hp", 0),
		c.get("mana", 0), c.get("max_mana", 0),
	]
	details += "Gold: %d\n" % c.get("gold", 0)

	var attrs: Dictionary = c.get("attributes", {})
	if not attrs.is_empty():
		details += "\n[b]Attributes[/b]\n"
		for attr_name in attrs.keys():
			details += "  %s: %d\n" % [attr_name.capitalize(), attrs[attr_name]]

	detail_label.text = details


## Called when the player presses "Enter World".
func _on_enter_world_pressed() -> void:
	if _selected_index < 0 or _selected_index >= _characters.size():
		return

	var char_data: Dictionary = _characters[_selected_index]

	# Map position dict to flat keys expected by StateManager.set_player_data().
	var player_data := char_data.duplicate(true)
	var pos: Dictionary = char_data.get("position", {})
	player_data["position_x"] = pos.get("x", 0)
	player_data["position_y"] = pos.get("y", 0)

	# Map heading string to enum.
	var heading_str: String = char_data.get("heading", "south")
	match heading_str:
		"north":
			player_data["heading"] = StateManager.Heading.NORTH
		"east":
			player_data["heading"] = StateManager.Heading.EAST
		"west":
			player_data["heading"] = StateManager.Heading.WEST
		_:
			player_data["heading"] = StateManager.Heading.SOUTH

	StateManager.set_player_data(player_data)
	Log.info(TAG, "Entering world with character: %s" % char_data.get("name", "Unknown"))
	StateManager.transition_to(StateManager.AppState.GAMEPLAY)


## Called when the player presses "Create New".
func _on_create_new_pressed() -> void:
	if _creation_screen != null:
		return
	_creation_screen = CHAR_CREATION_SCENE.instantiate()
	_creation_screen.character_created.connect(_on_character_created)
	_creation_screen.creation_cancelled.connect(_on_creation_cancelled)
	add_child(_creation_screen)
	Log.info(TAG, "Opened character creation screen")


## Called when a new character is created and saved.
func _on_character_created() -> void:
	_close_creation_screen()
	_refresh_character_list()


## Called when character creation is cancelled.
func _on_creation_cancelled() -> void:
	_close_creation_screen()


## Removes the character creation screen.
func _close_creation_screen() -> void:
	if _creation_screen != null:
		_creation_screen.queue_free()
		_creation_screen = null


## Called when the player presses "Back" to return to login.
func _on_back_pressed() -> void:
	StateManager.transition_to(StateManager.AppState.LOGIN)
