## Crafting Panel — shows recipes per discipline with materials and result preview.
##
## Supports blacksmithing, carpentry, alchemy, and tailoring disciplines.
## Each recipe shows required materials, quantities, skill requirement,
## and result item preview.
## Requirements: 16.1, 16.2
extends Control


const TAG := "CraftingPanel"

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var discipline_tabs: HBoxContainer = $MarginContainer/VBoxContainer/DisciplineTabs
@onready var recipe_list: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/RecipeList
@onready var close_button: Button = $MarginContainer/VBoxContainer/BottomBar/CloseButton

var _current_discipline: String = "blacksmithing"
var _tab_buttons: Dictionary = {}  # discipline -> Button


func _ready() -> void:
	visible = false

	# Create discipline tab buttons.
	var disciplines := ["blacksmithing", "carpentry", "alchemy", "tailoring"]
	for disc in disciplines:
		var btn := Button.new()
		btn.text = disc.capitalize()
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(90, 28)
		btn.pressed.connect(_on_discipline_selected.bind(disc))
		discipline_tabs.add_child(btn)
		_tab_buttons[disc] = btn

	# Select first tab.
	if _tab_buttons.has("blacksmithing"):
		_tab_buttons["blacksmithing"].button_pressed = true

	if close_button:
		close_button.pressed.connect(_on_close_pressed)

	Log.info(TAG, "CraftingPanel ready")


## Refreshes the recipe list for the current discipline.
func refresh() -> void:
	# Clear existing recipes.
	for child in recipe_list.get_children():
		child.queue_free()

	var recipes: Array = MockDataProvider.get_recipes_for_discipline(_current_discipline)

	if recipes.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No recipes available for %s." % _current_discipline.capitalize()
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.modulate = Color(0.6, 0.6, 0.6)
		recipe_list.add_child(empty_label)
		return

	for recipe in recipes:
		_create_recipe_entry(recipe)


## Creates a visual entry for a single recipe.
func _create_recipe_entry(recipe: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 2)

	# Recipe name and skill requirement.
	var header := HBoxContainer.new()
	var name_label := Label.new()
	name_label.text = recipe.get("name", "Unknown Recipe")
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 15)
	header.add_child(name_label)

	var skill_label := Label.new()
	var skill_req: int = recipe.get("skill_requirement", 0)
	var player_skill: int = StateManager.player_skills.get(_current_discipline, 0)
	skill_label.text = "Skill: %d/%d" % [player_skill, skill_req]
	if player_skill >= skill_req:
		skill_label.modulate = Color(0.5, 1.0, 0.5)
	else:
		skill_label.modulate = Color(1.0, 0.4, 0.4)
	header.add_child(skill_label)
	container.add_child(header)

	# Materials list.
	var materials: Array = recipe.get("materials", [])
	for mat in materials:
		var mat_label := Label.new()
		var item_id: String = mat.get("item_id", "?")
		var quantity: int = mat.get("quantity", 1)
		var item_data: Dictionary = MockDataProvider.get_item(item_id)
		var item_name: String = item_data.get("name", item_id) if not item_data.is_empty() else item_id
		var have: int = _count_item(item_id)
		mat_label.text = "  • %s x%d (have: %d)" % [item_name, quantity, have]
		if have >= quantity:
			mat_label.modulate = Color(0.7, 1.0, 0.7)
		else:
			mat_label.modulate = Color(1.0, 0.6, 0.6)
		container.add_child(mat_label)

	# Result preview and success chance.
	var result_row := HBoxContainer.new()
	var result_item_id: String = recipe.get("result_item", "")
	var result_item: Dictionary = MockDataProvider.get_item(result_item_id)
	var result_name: String = result_item.get("name", result_item_id) if not result_item.is_empty() else result_item_id

	var result_label := Label.new()
	result_label.text = "  → %s (%.0f%% chance)" % [
		result_name, recipe.get("success_base_chance", 0.8) * 100.0]
	result_label.modulate = Color(1.0, 0.85, 0.4)
	result_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result_row.add_child(result_label)

	# Craft button.
	var craft_btn := Button.new()
	craft_btn.text = "Craft"
	craft_btn.custom_minimum_size = Vector2(60, 0)
	var recipe_id: String = recipe.get("id", recipe.get("recipe_id", ""))
	craft_btn.pressed.connect(_on_craft_pressed.bind(recipe_id))
	result_row.add_child(craft_btn)
	container.add_child(result_row)

	# Separator.
	var sep := HSeparator.new()
	container.add_child(sep)

	recipe_list.add_child(container)


func _on_discipline_selected(discipline: String) -> void:
	_current_discipline = discipline
	# Update tab button states.
	for disc in _tab_buttons:
		_tab_buttons[disc].button_pressed = (disc == discipline)
	refresh()


func _on_craft_pressed(recipe_id: String) -> void:
	var crafting_system: Node = _get_crafting_system()
	if crafting_system and crafting_system.has_method("craft"):
		var result: Dictionary = crafting_system.craft(recipe_id)
		Log.info(TAG, "Craft result: %s" % result.get("message", ""))
		# Refresh to update material counts.
		refresh()


func _on_close_pressed() -> void:
	visible = false


func _count_item(item_id: String) -> int:
	var count := 0
	for item in StateManager.player_inventory:
		if item is Dictionary and not item.is_empty():
			if item.get("id", item.get("item_id", "")) == item_id:
				count += item.get("count", 1)
	return count


func _get_crafting_system() -> Node:
	var gameplay := get_tree().current_scene
	if gameplay:
		for child in gameplay.get_children():
			if child.name == "Crafting_System":
				return child
		var gs := gameplay.get_node_or_null("GameplayScene")
		if gs:
			for child in gs.get_children():
				if child.name == "Crafting_System":
					return child
	return null


## Refresh when shown.
func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible:
		refresh()
