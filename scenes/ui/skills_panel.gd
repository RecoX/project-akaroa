## Skills Panel — displays all skills grouped by category with values and
## progress indicators, plus core attributes.
##
## Starts hidden. Toggle via UI_Manager.
## Requirements: 22.2, 22.3
extends PanelContainer


const TAG := "SkillsPanel"


@onready var attributes_list: VBoxContainer = $VBox/AttributesSection
@onready var combat_list: VBoxContainer = $VBox/CombatSection
@onready var magic_list: VBoxContainer = $VBox/MagicSection
@onready var trade_list: VBoxContainer = $VBox/TradeSection


func _ready() -> void:
	visible = false
	Log.info(TAG, "SkillsPanel ready")


func _on_visibility_changed() -> void:
	if visible:
		_refresh()


func _refresh() -> void:
	var skill_system: Node = _get_skill_system()
	if skill_system == null:
		return

	# Attributes.
	_clear_children(attributes_list, 1)  # Keep the label.
	for attr_name in skill_system.CORE_ATTRIBUTES:
		var value: int = skill_system.get_attribute(attr_name)
		var label := Label.new()
		label.text = "%s: %d" % [attr_name.capitalize(), value]
		attributes_list.add_child(label)

	# Skill categories.
	_populate_category(combat_list, "combat", skill_system)
	_populate_category(magic_list, "magic", skill_system)
	_populate_category(trade_list, "trade", skill_system)


func _populate_category(container: VBoxContainer, category: String, skill_system: Node) -> void:
	_clear_children(container, 1)  # Keep the category label.
	var skills: Dictionary = skill_system.get_skills_for_category(category)
	for skill_name in skills.keys():
		var value: int = skills[skill_name]
		var buff: int = skill_system.get_skill_buff(skill_name)

		var hbox := HBoxContainer.new()
		var name_label := Label.new()
		name_label.text = skill_name.replace("_", " ").capitalize()
		name_label.custom_minimum_size.x = 120
		hbox.add_child(name_label)

		var bar := ProgressBar.new()
		bar.min_value = 0
		bar.max_value = 100
		bar.value = value
		bar.custom_minimum_size.x = 100
		bar.show_percentage = false
		hbox.add_child(bar)

		var value_label := Label.new()
		var buff_text := ""
		if buff != 0:
			buff_text = " (%+d)" % buff
		value_label.text = "%d%s" % [value, buff_text]
		hbox.add_child(value_label)

		container.add_child(hbox)


func _clear_children(container: Node, keep_count: int = 0) -> void:
	while container.get_child_count() > keep_count:
		var child := container.get_child(container.get_child_count() - 1)
		container.remove_child(child)
		child.queue_free()


func _get_skill_system() -> Node:
	var gameplay := get_tree().current_scene
	if gameplay and gameplay.has_node("SkillSystem"):
		return gameplay.get_node("SkillSystem")
	return null
