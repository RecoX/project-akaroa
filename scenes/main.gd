## Main scene script — orchestrates application states by swapping child scenes
## based on StateManager.app_state_changed signals.
##
## On _ready, loads the LoginScreen as the initial scene.
## Requirements: 1.4
extends Node


const TAG := "Main"

## Scene paths for each application state.
const SCENE_PATHS: Dictionary = {
	StateManager.AppState.LOGIN: "res://scenes/ui/login_screen.tscn",
	StateManager.AppState.CHARACTER_SELECT: "res://scenes/ui/char_select_screen.tscn",
	StateManager.AppState.GAMEPLAY: "res://scenes/world/gameplay_scene.tscn",
}

## The currently loaded child scene instance.
var _current_scene: Node = null


func _ready() -> void:
	StateManager.app_state_changed.connect(_on_app_state_changed)
	# Load the initial login screen.
	_switch_scene(StateManager.AppState.LOGIN)
	Log.info(TAG, "Main scene ready — starting at LOGIN state")


## Called when StateManager transitions to a new application state.
func _on_app_state_changed(new_state: StateManager.AppState) -> void:
	Log.info(TAG, "App state changed to: %s" % StateManager.AppState.keys()[new_state])
	_switch_scene(new_state)


## Removes the current child scene and loads the scene for [param state].
func _switch_scene(state: StateManager.AppState) -> void:
	# Free the current scene if one exists.
	if _current_scene != null:
		_current_scene.queue_free()
		_current_scene = null

	if state == StateManager.AppState.DISCONNECTED:
		Log.info(TAG, "Disconnected state — returning to LOGIN")
		_switch_scene(StateManager.AppState.LOGIN)
		return

	var scene_path: String = SCENE_PATHS.get(state, "")
	if scene_path == "":
		Log.error(TAG, "No scene path for state: %s" % StateManager.AppState.keys()[state])
		return

	var scene_resource := load(scene_path)
	if scene_resource == null:
		Log.error(TAG, "Failed to load scene: %s" % scene_path)
		return

	_current_scene = scene_resource.instantiate()
	add_child(_current_scene)
	Log.info(TAG, "Loaded scene for state: %s" % StateManager.AppState.keys()[state])
