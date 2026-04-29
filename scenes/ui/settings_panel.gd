## Settings Panel — audio volume sliders, graphics quality, resolution,
## fullscreen toggle, and keybinding configuration.
##
## Starts hidden. Accessible from login screen and in-game menu.
## Requirements: 28.1, 28.2, 28.4
extends PanelContainer


const TAG := "SettingsPanel"

## Default keybindings.
const DEFAULT_KEYBINDS: Dictionary = {
	"move_up": "W",
	"move_down": "S",
	"move_left": "A",
	"move_right": "D",
	"attack": "Space",
	"cast_spell": "Q",
	"interact": "E",
	"inventory": "I",
	"spell_book": "P",
	"quest_log": "J",
	"guild": "G",
	"skills": "K",
	"settings": "Escape",
}


# ---------------------------------------------------------------------------
# Node references
# ---------------------------------------------------------------------------

@onready var music_slider: HSlider = $VBox/AudioSection/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $VBox/AudioSection/SFXRow/SFXSlider
@onready var footstep_slider: HSlider = $VBox/AudioSection/FootstepRow/FootstepSlider
@onready var ambient_slider: HSlider = $VBox/AudioSection/AmbientRow/AmbientSlider
@onready var fullscreen_check: CheckButton = $VBox/GraphicsSection/FullscreenCheck
@onready var resolution_option: OptionButton = $VBox/GraphicsSection/ResolutionOption
@onready var quality_option: OptionButton = $VBox/GraphicsSection/QualityOption
@onready var keybind_list: VBoxContainer = $VBox/KeybindSection/KeybindList
@onready var close_button: Button = $VBox/CloseButton

## Current keybindings.
var _keybinds: Dictionary = {}

## Whether we are currently rebinding a key.
var _rebinding_action: String = ""
var _rebinding_button: Button = null


func _ready() -> void:
	visible = false
	_keybinds = DEFAULT_KEYBINDS.duplicate()

	# Setup sliders.
	_setup_slider(music_slider, AudioManager.music_volume)
	_setup_slider(sfx_slider, AudioManager.sfx_volume)
	_setup_slider(footstep_slider, AudioManager.footstep_volume)
	_setup_slider(ambient_slider, AudioManager.ambient_volume)

	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	footstep_slider.value_changed.connect(_on_footstep_volume_changed)
	ambient_slider.value_changed.connect(_on_ambient_volume_changed)

	# Setup resolution options.
	resolution_option.add_item("1280x720")
	resolution_option.add_item("1600x900")
	resolution_option.add_item("1920x1080")
	resolution_option.add_item("2560x1440")
	resolution_option.item_selected.connect(_on_resolution_changed)

	# Setup quality options.
	quality_option.add_item("Low")
	quality_option.add_item("Medium")
	quality_option.add_item("High")
	quality_option.select(2)
	quality_option.item_selected.connect(_on_quality_changed)

	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	close_button.pressed.connect(func(): visible = false)

	_populate_keybind_list()

	# Restore saved settings on startup.
	call_deferred("load_settings")
	Log.info(TAG, "SettingsPanel ready")


func _setup_slider(slider: HSlider, initial_value: float) -> void:
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = initial_value


func _input(event: InputEvent) -> void:
	if _rebinding_action == "" or _rebinding_button == null:
		return
	if event is InputEventKey and event.pressed:
		var key_name: String = OS.get_keycode_string(event.keycode)
		_keybinds[_rebinding_action] = key_name
		_rebinding_button.text = key_name
		_rebinding_action = ""
		_rebinding_button = null
		_save_settings()
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------------------
# Volume callbacks
# ---------------------------------------------------------------------------


func _on_music_volume_changed(value: float) -> void:
	AudioManager.set_volume("music", value)
	_save_settings()


func _on_sfx_volume_changed(value: float) -> void:
	AudioManager.set_volume("sfx", value)
	_save_settings()


func _on_footstep_volume_changed(value: float) -> void:
	AudioManager.set_volume("footstep", value)
	_save_settings()


func _on_ambient_volume_changed(value: float) -> void:
	AudioManager.set_volume("ambient", value)
	_save_settings()


# ---------------------------------------------------------------------------
# Graphics callbacks
# ---------------------------------------------------------------------------


func _on_fullscreen_toggled(enabled: bool) -> void:
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	_save_settings()


func _on_resolution_changed(index: int) -> void:
	var resolutions: Array = [
		Vector2i(1280, 720),
		Vector2i(1600, 900),
		Vector2i(1920, 1080),
		Vector2i(2560, 1440),
	]
	if index >= 0 and index < resolutions.size():
		var res: Vector2i = resolutions[index]
		DisplayServer.window_set_size(res)
		Log.info(TAG, "Resolution set to %dx%d" % [res.x, res.y])
	_save_settings()


func _on_quality_changed(_index: int) -> void:
	# Quality settings are cosmetic in this demo.
	_save_settings()


# ---------------------------------------------------------------------------
# Keybinding
# ---------------------------------------------------------------------------


func _populate_keybind_list() -> void:
	# Clear existing entries.
	for child in keybind_list.get_children():
		child.queue_free()

	for action in _keybinds.keys():
		var hbox := HBoxContainer.new()
		var label := Label.new()
		label.text = action.replace("_", " ").capitalize()
		label.custom_minimum_size.x = 140
		hbox.add_child(label)

		var button := Button.new()
		button.text = _keybinds[action]
		button.custom_minimum_size.x = 80
		button.pressed.connect(_on_keybind_button_pressed.bind(action, button))
		hbox.add_child(button)

		keybind_list.add_child(hbox)


func _on_keybind_button_pressed(action: String, button: Button) -> void:
	_rebinding_action = action
	_rebinding_button = button
	button.text = "Press key..."


# ---------------------------------------------------------------------------
# Settings persistence (delegates to SettingsManager logic)
# ---------------------------------------------------------------------------


func _save_settings() -> void:
	var settings := {
		"audio": {
			"music": music_slider.value,
			"sfx": sfx_slider.value,
			"footstep": footstep_slider.value,
			"ambient": ambient_slider.value,
		},
		"graphics": {
			"fullscreen": fullscreen_check.button_pressed,
			"resolution": resolution_option.selected,
			"quality": quality_option.selected,
		},
		"keybinds": _keybinds,
	}

	var file := FileAccess.open("user://settings.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(settings, "\t"))
		file.close()
		Log.debug(TAG, "Settings saved")
	else:
		Log.error(TAG, "Failed to save settings")


## Loads settings from disk and applies them.
func load_settings() -> void:
	if not FileAccess.file_exists("user://settings.json"):
		Log.info(TAG, "No settings file found — using defaults")
		return

	var file := FileAccess.open("user://settings.json", FileAccess.READ)
	if file == null:
		Log.error(TAG, "Failed to open settings file")
		return

	var content := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(content) != OK:
		Log.error(TAG, "Failed to parse settings JSON")
		return

	var settings: Dictionary = json.data if json.data is Dictionary else {}

	# Apply audio settings.
	var audio: Dictionary = settings.get("audio", {})
	if audio.has("music"):
		music_slider.value = audio["music"]
		AudioManager.set_volume("music", audio["music"])
	if audio.has("sfx"):
		sfx_slider.value = audio["sfx"]
		AudioManager.set_volume("sfx", audio["sfx"])
	if audio.has("footstep"):
		footstep_slider.value = audio["footstep"]
		AudioManager.set_volume("footstep", audio["footstep"])
	if audio.has("ambient"):
		ambient_slider.value = audio["ambient"]
		AudioManager.set_volume("ambient", audio["ambient"])

	# Apply graphics settings.
	var graphics: Dictionary = settings.get("graphics", {})
	if graphics.has("fullscreen"):
		fullscreen_check.button_pressed = graphics["fullscreen"]
		_on_fullscreen_toggled(graphics["fullscreen"])
	if graphics.has("resolution"):
		resolution_option.select(graphics["resolution"])
	if graphics.has("quality"):
		quality_option.select(graphics["quality"])

	# Apply keybindings.
	var keybinds: Dictionary = settings.get("keybinds", {})
	if not keybinds.is_empty():
		_keybinds = keybinds
		_populate_keybind_list()

	Log.info(TAG, "Settings loaded from disk")
