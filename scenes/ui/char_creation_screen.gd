## Character Creation screen — race, class, gender, name, and attribute allocation.
##
## Displays racial attribute modifiers and class-specific info from MockDataProvider.
## Stores created character locally via MockDataProvider.save_character_locally().
## Requirements: 9.4, 23.1, 23.2, 23.3, 23.4
extends Control


const TAG := "CharCreation"

## Total free attribute points to distribute.
const FREE_POINTS: int = 10

## Attribute names in display order.
const ATTRIBUTE_NAMES: Array = ["strength", "agility", "intelligence", "constitution", "charisma"]

## Emitted when a character is successfully created and saved.
signal character_created()

## Emitted when the player cancels creation.
signal creation_cancelled()

@onready var name_input: LineEdit = %NameInput
@onready var race_option: OptionButton = %RaceOption
@onready var class_option: OptionButton = %ClassOption
@onready var gender_button: Button = %GenderButton
@onready var race_info_label: RichTextLabel = %RaceInfoLabel
@onready var class_info_label: RichTextLabel = %ClassInfoLabel
@onready var attr_container: VBoxContainer = %AttrContainer
@onready var free_points_label: Label = %FreePointsLabel
@onready var create_button: Button = %CreateButton
@onready var cancel_button: Button = %CancelButton
@onready var status_label: Label = %StatusLabel

## Cached race/class data arrays.
var _races: Array = []
var _classes: Array = []

## Current gender toggle state.
var _gender: String = "male"

## Allocated bonus points per attribute (index matches ATTRIBUTE_NAMES).
var _allocated: Array = [0, 0, 0, 0, 0]

## Remaining free points.
var _free_points: int = FREE_POINTS

## References to the +/- buttons and value labels per attribute.
var _attr_labels: Array = []
var _minus_buttons: Array = []
var _plus_buttons: Array = []


func _ready() -> void:
	_load_race_class_data()
	_populate_race_options()
	_populate_class_options()
	_build_attribute_ui()
	_update_free_points_display()

	race_option.item_selected.connect(_on_race_selected)
	class_option.item_selected.connect(_on_class_selected)
	gender_button.pressed.connect(_on_gender_toggled)
	create_button.pressed.connect(_on_create_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)

	# Trigger initial info display.
	_on_race_selected(0)
	_on_class_selected(0)

	status_label.text = ""
	Log.info(TAG, "Character creation screen ready")


## Loads race and class data from MockDataProvider caches.
func _load_race_class_data() -> void:
	# Build arrays from the internal DB dictionaries.
	for race_id in ["human", "elf", "dark_elf", "dwarf", "gnome", "orc"]:
		var data: Dictionary = MockDataProvider.get_race_data(race_id)
		if not data.is_empty():
			_races.append(data)
	for class_id in ["warrior", "mage", "paladin", "assassin", "cleric", "hunter"]:
		var data: Dictionary = MockDataProvider.get_class_data(class_id)
		if not data.is_empty():
			_classes.append(data)
	Log.info(TAG, "Loaded %d races, %d classes" % [_races.size(), _classes.size()])


func _populate_race_options() -> void:
	race_option.clear()
	for race in _races:
		race_option.add_item(race.get("name", "Unknown"))


func _populate_class_options() -> void:
	class_option.clear()
	for cls in _classes:
		class_option.add_item(cls.get("name", "Unknown"))


## Builds the attribute allocation rows with +/- buttons.
func _build_attribute_ui() -> void:
	# Clear any existing children.
	for child in attr_container.get_children():
		child.queue_free()

	_attr_labels.clear()
	_minus_buttons.clear()
	_plus_buttons.clear()

	for i in range(ATTRIBUTE_NAMES.size()):
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_label := Label.new()
		name_label.text = ATTRIBUTE_NAMES[i].capitalize()
		name_label.custom_minimum_size = Vector2(120, 0)
		row.add_child(name_label)

		var minus_btn := Button.new()
		minus_btn.text = "-"
		minus_btn.custom_minimum_size = Vector2(30, 30)
		minus_btn.pressed.connect(_on_attr_minus.bind(i))
		row.add_child(minus_btn)
		_minus_buttons.append(minus_btn)

		var value_label := Label.new()
		value_label.text = "0"
		value_label.custom_minimum_size = Vector2(40, 0)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(value_label)
		_attr_labels.append(value_label)

		var plus_btn := Button.new()
		plus_btn.text = "+"
		plus_btn.custom_minimum_size = Vector2(30, 30)
		plus_btn.pressed.connect(_on_attr_plus.bind(i))
		row.add_child(plus_btn)
		_plus_buttons.append(plus_btn)

		attr_container.add_child(row)


func _on_race_selected(index: int) -> void:
	if index < 0 or index >= _races.size():
		return
	var race: Dictionary = _races[index]
	var info := "[b]%s[/b]\n%s\n\n[b]Attribute Modifiers[/b]\n" % [
		race.get("name", ""), race.get("description", ""),
	]
	var mods: Dictionary = race.get("attribute_modifiers", {})
	for attr_name in ATTRIBUTE_NAMES:
		var val: int = mods.get(attr_name, 0)
		var sign_str := "+" if val >= 0 else ""
		info += "  %s: %s%d\n" % [attr_name.capitalize(), sign_str, val]
	race_info_label.text = info
	_update_attribute_display()


func _on_class_selected(index: int) -> void:
	if index < 0 or index >= _classes.size():
		return
	var cls: Dictionary = _classes[index]
	var info := "[b]%s[/b]\n%s\n\n" % [cls.get("name", ""), cls.get("description", "")]
	info += "[b]Primary Attribute:[/b] %s\n" % cls.get("primary_attribute", "").capitalize()

	var profs: Array = cls.get("equipment_proficiencies", [])
	if profs.size() > 0:
		info += "[b]Equipment:[/b] %s\n" % ", ".join(profs)

	var schools: Array = cls.get("spell_schools", [])
	if schools.size() > 0:
		info += "[b]Spell Schools:[/b] %s\n" % ", ".join(schools)

	var skills: Dictionary = cls.get("starting_skills", {})
	if not skills.is_empty():
		info += "[b]Starting Skills:[/b]\n"
		for skill_name in skills.keys():
			info += "  %s: %d\n" % [skill_name.capitalize(), skills[skill_name]]

	class_info_label.text = info


func _on_gender_toggled() -> void:
	if _gender == "male":
		_gender = "female"
	else:
		_gender = "male"
	gender_button.text = "Gender: %s" % _gender.capitalize()


func _on_attr_minus(attr_index: int) -> void:
	if _allocated[attr_index] <= 0:
		return
	_allocated[attr_index] -= 1
	_free_points += 1
	_update_attribute_display()
	_update_free_points_display()


func _on_attr_plus(attr_index: int) -> void:
	if _free_points <= 0:
		return
	_allocated[attr_index] += 1
	_free_points -= 1
	_update_attribute_display()
	_update_free_points_display()


## Updates the displayed attribute values (base from class + race modifier + allocated).
func _update_attribute_display() -> void:
	var race_index := race_option.selected
	var class_index := class_option.selected
	var race_mods: Dictionary = {}
	var class_attrs: Dictionary = {}

	if race_index >= 0 and race_index < _races.size():
		race_mods = _races[race_index].get("attribute_modifiers", {})
	if class_index >= 0 and class_index < _classes.size():
		class_attrs = _classes[class_index].get("starting_attributes", {})

	for i in range(ATTRIBUTE_NAMES.size()):
		var attr_name: String = ATTRIBUTE_NAMES[i]
		var base: int = class_attrs.get(attr_name, 10)
		var race_mod: int = race_mods.get(attr_name, 0)
		var total: int = base + race_mod + _allocated[i]
		if i < _attr_labels.size():
			_attr_labels[i].text = str(total)


func _update_free_points_display() -> void:
	free_points_label.text = "Free Points: %d" % _free_points
	# Disable minus buttons where allocation is 0.
	for i in range(_minus_buttons.size()):
		_minus_buttons[i].disabled = _allocated[i] <= 0
	# Disable plus buttons when no free points remain.
	for btn in _plus_buttons:
		btn.disabled = _free_points <= 0


func _on_create_pressed() -> void:
	var char_name := name_input.text.strip_edges()
	if char_name == "":
		status_label.text = "Please enter a character name."
		return

	var race_index := race_option.selected
	var class_index := class_option.selected
	if race_index < 0 or class_index < 0:
		status_label.text = "Please select a race and class."
		return

	var race_data: Dictionary = _races[race_index]
	var class_data: Dictionary = _classes[class_index]
	var race_mods: Dictionary = race_data.get("attribute_modifiers", {})
	var class_attrs: Dictionary = class_data.get("starting_attributes", {})

	# Build final attributes.
	var final_attrs: Dictionary = {}
	for i in range(ATTRIBUTE_NAMES.size()):
		var attr_name: String = ATTRIBUTE_NAMES[i]
		final_attrs[attr_name] = class_attrs.get(attr_name, 10) + race_mods.get(attr_name, 0) + _allocated[i]

	var char_data: Dictionary = {
		"id": "player_%s" % char_name.to_lower().replace(" ", "_"),
		"name": char_name,
		"guild_tag": "",
		"race": race_data.get("id", "human"),
		"class": class_data.get("id", "warrior"),
		"gender": _gender,
		"level": 1,
		"xp": 0,
		"xp_to_next": 1000,
		"hp": 100 + final_attrs.get("constitution", 10) * 5,
		"max_hp": 100 + final_attrs.get("constitution", 10) * 5,
		"mana": 50 + final_attrs.get("intelligence", 10) * 3,
		"max_mana": 50 + final_attrs.get("intelligence", 10) * 3,
		"gold": 100,
		"position": {"x": 512, "y": 512},
		"heading": "south",
		"alignment": "citizen",
		"faction": "",
		"attributes": final_attrs,
		"equipment": {"weapon": "", "shield": "", "helmet": "", "armor": "", "backpack": ""},
		"inventory": [],
		"learned_spells": class_data.get("starting_spells", []),
		"skills": class_data.get("starting_skills", {}),
	}

	MockDataProvider.save_character_locally(char_data)
	Log.info(TAG, "Character '%s' created and saved" % char_name)
	character_created.emit()


func _on_cancel_pressed() -> void:
	creation_cancelled.emit()
