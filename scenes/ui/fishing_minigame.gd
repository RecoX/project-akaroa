## Fishing Minigame — simple timing bar where the player clicks when the
## indicator is in the target zone.
##
## The indicator oscillates back and forth across a bar. The player must
## click/press when the indicator overlaps the green target zone to catch
## a fish. Results are processed locally through the Crafting_System.
##
## Requirements: 16.5
extends Control


const TAG := "FishingMinigame"

## Bar dimensions (logical units).
const BAR_WIDTH: float = 300.0
const BAR_HEIGHT: float = 30.0

## Target zone width as a fraction of the bar (0.0–1.0).
const TARGET_ZONE_RATIO: float = 0.2

## Indicator movement speed (pixels per second).
const INDICATOR_SPEED: float = 250.0

## Maximum attempts before auto-fail.
const MAX_ATTEMPTS: int = 3

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var bar_container: Control = $MarginContainer/VBoxContainer/BarArea/BarContainer
@onready var indicator: ColorRect = $MarginContainer/VBoxContainer/BarArea/BarContainer/Indicator
@onready var target_zone: ColorRect = $MarginContainer/VBoxContainer/BarArea/BarContainer/TargetZone
@onready var bar_bg: ColorRect = $MarginContainer/VBoxContainer/BarArea/BarContainer/BarBG
@onready var catch_button: Button = $MarginContainer/VBoxContainer/ButtonBar/CatchButton
@onready var cancel_button: Button = $MarginContainer/VBoxContainer/ButtonBar/CancelButton
@onready var status_label: Label = $MarginContainer/VBoxContainer/StatusLabel

## Current indicator position (0.0 to BAR_WIDTH).
var _indicator_pos: float = 0.0

## Direction of indicator movement (1 = right, -1 = left).
var _direction: float = 1.0

## Target zone start position.
var _target_start: float = 0.0

## Target zone end position.
var _target_end: float = 0.0

## Whether the minigame is actively running.
var _active: bool = false

## Number of attempts made.
var _attempts: int = 0


func _ready() -> void:
	visible = false

	if catch_button:
		catch_button.pressed.connect(_on_catch_pressed)
	if cancel_button:
		cancel_button.pressed.connect(_on_cancel_pressed)

	Log.info(TAG, "FishingMinigame ready")


func _process(delta: float) -> void:
	if not _active or not visible:
		return

	# Move indicator back and forth.
	_indicator_pos += INDICATOR_SPEED * _direction * delta

	if _indicator_pos >= BAR_WIDTH:
		_indicator_pos = BAR_WIDTH
		_direction = -1.0
	elif _indicator_pos <= 0.0:
		_indicator_pos = 0.0
		_direction = 1.0

	# Update indicator visual position.
	if indicator:
		indicator.position.x = _indicator_pos - 3.0  # center the 6px wide indicator


## Starts the fishing minigame.
func start_minigame() -> void:
	_active = true
	_attempts = 0
	_indicator_pos = 0.0
	_direction = 1.0

	# Randomize target zone position.
	var zone_width: float = BAR_WIDTH * TARGET_ZONE_RATIO
	_target_start = randf_range(zone_width, BAR_WIDTH - zone_width)
	_target_end = _target_start + zone_width

	# Position the target zone visual.
	if target_zone:
		target_zone.position.x = _target_start
		target_zone.size.x = zone_width

	if status_label:
		status_label.text = "Click 'Catch!' when the marker is in the green zone!"

	visible = true
	Log.info(TAG, "Fishing minigame started — target zone: %.0f to %.0f" % [
		_target_start, _target_end])


## Handles the catch button press.
func _on_catch_pressed() -> void:
	if not _active:
		return

	_attempts += 1

	# Check if indicator is within the target zone.
	if _indicator_pos >= _target_start and _indicator_pos <= _target_end:
		_finish(true)
	elif _attempts >= MAX_ATTEMPTS:
		_finish(false)
	else:
		if status_label:
			status_label.text = "Missed! %d attempt(s) remaining." % (MAX_ATTEMPTS - _attempts)
		Log.info(TAG, "Fishing attempt %d missed (pos: %.0f, target: %.0f-%.0f)" % [
			_attempts, _indicator_pos, _target_start, _target_end])


## Handles the cancel button press.
func _on_cancel_pressed() -> void:
	_active = false
	visible = false
	var crafting_system: Node = _get_crafting_system()
	if crafting_system and crafting_system.has_method("cancel_gathering"):
		crafting_system.cancel_gathering()
	Log.info(TAG, "Fishing cancelled")


## Finishes the minigame with a result.
func _finish(success: bool) -> void:
	_active = false

	if success:
		if status_label:
			status_label.text = "You caught a fish!"
		Log.info(TAG, "Fishing success!")
	else:
		if status_label:
			status_label.text = "The fish got away..."
		Log.info(TAG, "Fishing failed after %d attempts" % _attempts)

	# Notify the crafting system.
	var crafting_system: Node = _get_crafting_system()
	if crafting_system and crafting_system.has_method("complete_fishing"):
		crafting_system.complete_fishing(success)

	# Hide after a short delay.
	await get_tree().create_timer(1.5).timeout
	visible = false


## Handles keyboard input for the catch action.
func _input(event: InputEvent) -> void:
	if not _active or not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_on_catch_pressed()
			get_viewport().set_input_as_handled()


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
