## HUD — Heads-Up Display showing player vitals, gold, buffs, zone, and coordinates.
##
## Connects to StateManager signals to keep all displays in sync.
## Requirements: 12.5, 12.6, 22.5, 14.6, 26.1, 26.2, 26.3, 26.4
extends Control


const _TAG := "HUD"


# --- Node references (resolved in _ready) ---
var _hp_bar: ProgressBar
var _hp_label: Label
var _mana_bar: ProgressBar
var _mana_label: Label
var _xp_bar: ProgressBar
var _level_label: Label
var _gold_label: Label
var _zone_label: Label
var _coordinate_label: Label
var _buff_bar: HBoxContainer
var _debuff_bar: HBoxContainer
var _target_frame: PanelContainer
var _target_name_label: Label
var _target_hp_bar: ProgressBar
var _feedback_label: Label
var _interaction_prompt: Label


func _ready() -> void:
	_hp_bar = $TopLeft/VitalBars/HPRow/HPBar
	_hp_label = $TopLeft/VitalBars/HPRow/HPLabel
	_mana_bar = $TopLeft/VitalBars/ManaRow/ManaBar
	_mana_label = $TopLeft/VitalBars/ManaRow/ManaLabel
	_xp_bar = $TopLeft/VitalBars/XPRow/XPBar
	_level_label = $TopLeft/VitalBars/XPRow/LevelLabel
	_gold_label = $TopRight/GoldLabel
	_zone_label = $TopRight/ZoneLabel
	_coordinate_label = $TopRight/CoordinateLabel
	_buff_bar = $BottomLeft/BuffBar
	_debuff_bar = $BottomLeft/DebuffBar
	_target_frame = $TargetFrame
	_target_name_label = $TargetFrame/VBox/TargetNameLabel
	_target_hp_bar = $TargetFrame/VBox/TargetHPBar
	_feedback_label = $FeedbackLabel
	_interaction_prompt = $InteractionPrompt

	# Connect to StateManager signals
	StateManager.player_hp_changed.connect(_on_hp_changed)
	StateManager.player_mana_changed.connect(_on_mana_changed)
	StateManager.player_xp_changed.connect(_on_xp_changed)
	StateManager.player_gold_changed.connect(_on_gold_changed)
	StateManager.player_status_effect_changed.connect(_on_status_effects_changed)
	StateManager.zone_changed.connect(_on_zone_changed)
	StateManager.player_position_changed.connect(_on_position_changed)
	StateManager.player_leveled_up.connect(_on_player_leveled_up)

	# Connect target and feedback signals
	StateManager.target_changed.connect(_on_target_changed)
	StateManager.target_cleared.connect(_on_target_cleared)
	StateManager.feedback_message.connect(_on_feedback_message)
	StateManager.interaction_prompt.connect(_on_interaction_prompt)
	StateManager.interaction_prompt_cleared.connect(_on_interaction_prompt_cleared)

	Log.info(_TAG, "HUD initialized")


func _on_hp_changed(current_hp: int, max_hp: int) -> void:
	_hp_bar.max_value = max_hp
	_hp_bar.value = current_hp
	_hp_label.text = "%d / %d" % [current_hp, max_hp]


func _on_mana_changed(current_mana: int, max_mana: int) -> void:
	_mana_bar.max_value = max_mana
	_mana_bar.value = current_mana
	_mana_label.text = "%d / %d" % [current_mana, max_mana]


func _on_xp_changed(current_xp: int, xp_to_next: int, level: int) -> void:
	_xp_bar.max_value = xp_to_next
	_xp_bar.value = current_xp
	_level_label.text = "Lv %d" % level


func _on_gold_changed(gold: int) -> void:
	_gold_label.text = "Gold: %d" % gold


func _on_status_effects_changed(effects: Array) -> void:
	# Clear existing buff/debuff icons
	_clear_container(_buff_bar)
	_clear_container(_debuff_bar)

	for effect in effects:
		var icon := _create_effect_icon(effect)
		var is_debuff: bool = effect.get("is_debuff", false) if effect is Dictionary else false
		if is_debuff:
			_debuff_bar.add_child(icon)
		else:
			_buff_bar.add_child(icon)


func _on_zone_changed(zone_data: Dictionary) -> void:
	var zone_name: String = zone_data.get("name", "Unknown")
	_zone_label.text = zone_name
	Log.debug(_TAG, "Zone changed to: %s" % zone_name)


func _on_position_changed(tile_x: int, tile_y: int) -> void:
	_coordinate_label.text = "(%d, %d)" % [tile_x, tile_y]


## Creates a simple colored panel icon for a status effect.
func _create_effect_icon(effect) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(28, 28)

	var label := Label.new()
	if effect is Dictionary:
		label.text = effect.get("name", "?").substr(0, 2).to_upper()
		label.tooltip_text = effect.get("name", "Unknown Effect")
	else:
		label.text = "?"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)

	return panel


## Shows the target frame with the selected target's name and HP.
func _on_target_changed(target_id: String, target_data: Dictionary) -> void:
	var target_name: String = target_data.get("name", target_id)
	var current_hp: int = target_data.get("hp", 0)
	var max_hp: int = target_data.get("max_hp", current_hp)

	_target_name_label.text = target_name
	_target_hp_bar.max_value = max_hp
	_target_hp_bar.value = current_hp
	_target_frame.visible = true
	Log.debug(_TAG, "Target frame shown: %s (%d/%d HP)" % [target_name, current_hp, max_hp])


## Hides the target frame when the target is cleared.
func _on_target_cleared() -> void:
	_target_frame.visible = false
	Log.debug(_TAG, "Target frame hidden")


## Shows a temporary feedback message that auto-hides after 2 seconds.
func _on_feedback_message(text: String) -> void:
	_feedback_label.text = text
	_feedback_label.visible = true
	Log.debug(_TAG, "Feedback message: %s" % text)

	# Auto-hide after 2 seconds
	get_tree().create_timer(2.0).timeout.connect(func() -> void:
		_feedback_label.visible = false
	)


## Shows the interaction prompt text.
func _on_interaction_prompt(text: String) -> void:
	_interaction_prompt.text = text
	_interaction_prompt.visible = true
	Log.debug(_TAG, "Interaction prompt shown: %s" % text)


## Hides the interaction prompt.
func _on_interaction_prompt_cleared() -> void:
	_interaction_prompt.visible = false
	Log.debug(_TAG, "Interaction prompt hidden")


## Handles player level-up — displays a visual notification with audio.
## Requirements: 22.4, 22.5
func _on_player_leveled_up(new_level: int) -> void:
	Log.info(_TAG, "Level up! Now level %d" % new_level)

	# Update level display.
	_level_label.text = "Lv %d" % new_level

	# Create a centered level-up notification label.
	var notification := Label.new()
	notification.text = "LEVEL UP! You are now level %d!" % new_level
	notification.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notification.add_theme_font_size_override("font_size", 32)
	notification.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	notification.anchors_preset = Control.PRESET_CENTER
	notification.grow_horizontal = Control.GROW_DIRECTION_BOTH
	notification.grow_vertical = Control.GROW_DIRECTION_BOTH
	notification.position = Vector2(get_viewport_rect().size.x / 2 - 200, get_viewport_rect().size.y * 0.3)
	notification.size = Vector2(400, 50)
	add_child(notification)

	# Play level-up SFX.
	AudioManager.play_sfx("res://audio/sfx/level_up.ogg")

	# Animate: scale up, hold, then fade out.
	notification.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(notification, "modulate:a", 1.0, 0.3)
	tween.tween_interval(2.5)
	tween.tween_property(notification, "modulate:a", 0.0, 1.0)
	tween.tween_callback(notification.queue_free)


## Removes all children from a container.
func _clear_container(container: Container) -> void:
	for child in container.get_children():
		child.queue_free()
