## Quest Log Panel — shows active quests with objectives, progress bars,
## and reward information.
##
## Requirements: 21.3, 21.5
extends Control


const TAG := "QuestLog"

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var quest_list: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/QuestList
@onready var close_button: Button = $MarginContainer/VBoxContainer/BottomBar/CloseButton


func _ready() -> void:
	visible = false

	if close_button:
		close_button.pressed.connect(_on_close_pressed)

	# Connect to quest signals for live updates.
	StateManager.quest_accepted.connect(_on_quest_changed)
	StateManager.quest_objective_updated.connect(_on_objective_updated)
	StateManager.quest_completed.connect(_on_quest_changed)

	Log.info(TAG, "QuestLog ready")


## Refreshes the entire quest list display.
func refresh() -> void:
	# Clear existing entries.
	for child in quest_list.get_children():
		child.queue_free()

	var quests: Array = StateManager.player_quests
	if quests.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No active quests."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.modulate = Color(0.6, 0.6, 0.6)
		quest_list.add_child(empty_label)
		return

	for quest in quests:
		_create_quest_entry(quest)


## Creates a visual entry for a single quest.
func _create_quest_entry(quest: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)

	# Quest title.
	var title := Label.new()
	var quest_title: String = quest.get("title", "Unknown Quest")
	var is_complete := _is_quest_complete(quest)
	if is_complete:
		title.text = "✓ %s" % quest_title
		title.modulate = Color(0.5, 1.0, 0.5)
	else:
		title.text = quest_title
	title.add_theme_font_size_override("font_size", 16)
	container.add_child(title)

	# Quest description.
	var desc := Label.new()
	desc.text = quest.get("description", "")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.modulate = Color(0.8, 0.8, 0.8)
	container.add_child(desc)

	# Objectives with progress bars.
	var objectives: Array = quest.get("objectives", [])
	for obj in objectives:
		var obj_container := HBoxContainer.new()
		obj_container.custom_minimum_size = Vector2(0, 24)

		# Objective description.
		var obj_label := Label.new()
		var obj_type: String = obj.get("type", "")
		var current: int = obj.get("current", 0)
		var quantity: int = obj.get("quantity", 1)

		match obj_type:
			"kill":
				obj_label.text = "  Kill %s: %d/%d" % [
					obj.get("enemy_id", "?"), current, quantity]
			"collect":
				obj_label.text = "  Collect %s: %d/%d" % [
					obj.get("item_id", "?"), current, quantity]
			_:
				obj_label.text = "  %s: %d/%d" % [obj_type, current, quantity]

		if current >= quantity:
			obj_label.modulate = Color(0.5, 1.0, 0.5)
		obj_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		obj_container.add_child(obj_label)

		# Progress bar.
		var progress := ProgressBar.new()
		progress.custom_minimum_size = Vector2(80, 16)
		progress.max_value = quantity
		progress.value = current
		progress.show_percentage = false
		obj_container.add_child(progress)

		container.add_child(obj_container)

	# Rewards section.
	var rewards: Dictionary = quest.get("rewards", {})
	if not rewards.is_empty():
		var reward_label := Label.new()
		var reward_parts: Array = []
		if rewards.get("xp", 0) > 0:
			reward_parts.append("%d XP" % rewards["xp"])
		if rewards.get("gold", 0) > 0:
			reward_parts.append("%d Gold" % rewards["gold"])
		var reward_items: Array = rewards.get("items", [])
		if not reward_items.is_empty():
			reward_parts.append("%d item(s)" % reward_items.size())
		reward_label.text = "  Rewards: %s" % ", ".join(reward_parts)
		reward_label.modulate = Color(1.0, 0.85, 0.4)
		container.add_child(reward_label)

	# Separator.
	var sep := HSeparator.new()
	container.add_child(sep)

	quest_list.add_child(container)


func _is_quest_complete(quest: Dictionary) -> bool:
	var objectives: Array = quest.get("objectives", [])
	for obj in objectives:
		if obj.get("current", 0) < obj.get("quantity", 1):
			return false
	return true


func _on_quest_changed(_quest_id: String) -> void:
	if visible:
		refresh()


func _on_objective_updated(_quest_id: String, _obj_index: int, _progress: int) -> void:
	if visible:
		refresh()


func _on_close_pressed() -> void:
	visible = false


## Override visibility to refresh when shown.
func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible:
		refresh()
