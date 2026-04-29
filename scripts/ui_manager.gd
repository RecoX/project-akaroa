## UI Manager — manages panel registration, toggling, and hotkey bindings.
##
## Attached to the UILayer CanvasLayer in the GameplayScene. All UI panels
## register themselves here and can be toggled via hotkeys or API calls.
## Requirements: 1.5
extends CanvasLayer


const _TAG := "UIManager"


## Registered panels keyed by name (e.g. "inventory", "spells").
var _panels: Dictionary = {}  # panel_name -> Control node


# --- Hotkey mapping: Godot keycode -> panel name ---
var _hotkey_map: Dictionary = {
	KEY_I: "inventory",
	KEY_K: "spells",
	KEY_J: "skills",
	KEY_L: "quest_log",
	KEY_M: "minimap",
	KEY_G: "guild",
	KEY_C: "crafting",
}


func _ready() -> void:
	Log.info(_TAG, "UIManager initializing...")
	# Panels are registered by child scenes calling register_panel() in their
	# own _ready(), or we can discover them here after the tree is built.
	# We use call_deferred so child nodes have time to initialize first.
	call_deferred("_discover_panels")


## Discovers and registers child Control nodes that follow the naming convention.
func _discover_panels() -> void:
	for child in get_children():
		if child is Control and child.name.ends_with("Panel"):
			var panel_name: String = _node_name_to_key(child.name)
			register_panel(panel_name, child)
	Log.info(_TAG, "Panel discovery complete — %d panels registered" % _panels.size())


## Registers a panel with the given name. Panels start hidden by default.
func register_panel(panel_name: String, panel: Control) -> void:
	_panels[panel_name] = panel
	Log.debug(_TAG, "Registered panel: %s" % panel_name)


## Toggles the visibility of the named panel.
func toggle_panel(panel_name: String) -> void:
	var panel: Control = _panels.get(panel_name)
	if panel:
		panel.visible = !panel.visible
		Log.debug(_TAG, "Toggled panel '%s' -> %s" % [panel_name, str(panel.visible)])
	else:
		Log.warning(_TAG, "toggle_panel: unknown panel '%s'" % panel_name)


## Opens (shows) the named panel.
func open_panel(panel_name: String) -> void:
	var panel: Control = _panels.get(panel_name)
	if panel:
		panel.visible = true
		Log.debug(_TAG, "Opened panel '%s'" % panel_name)
	else:
		Log.warning(_TAG, "open_panel: unknown panel '%s'" % panel_name)


## Closes (hides) the named panel.
func close_panel(panel_name: String) -> void:
	var panel: Control = _panels.get(panel_name)
	if panel:
		panel.visible = false
		Log.debug(_TAG, "Closed panel '%s'" % panel_name)
	else:
		Log.warning(_TAG, "close_panel: unknown panel '%s'" % panel_name)


## Closes all registered panels.
func close_all_panels() -> void:
	for panel_name in _panels:
		var panel: Control = _panels[panel_name]
		panel.visible = false
	Log.debug(_TAG, "All panels closed")


## Processes hotkey input for panel toggling.
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# Don't process hotkeys when a text input has focus.
		var focused := get_viewport().gui_get_focus_owner()
		if focused is LineEdit or focused is TextEdit:
			return

		var keycode: int = event.keycode
		if keycode in _hotkey_map:
			var panel_name: String = _hotkey_map[keycode]
			toggle_panel(panel_name)
			get_viewport().set_input_as_handled()


## Converts a PascalCase node name like "InventoryPanel" to a snake_case key
## like "inventory". Strips the trailing "Panel" suffix.
func _node_name_to_key(node_name: String) -> String:
	var key := node_name
	if key.ends_with("Panel"):
		key = key.substr(0, key.length() - 5)  # strip "Panel"
	# Convert PascalCase to snake_case
	var result := ""
	for i in range(key.length()):
		var ch: String = key[i]
		if ch == ch.to_upper() and i > 0:
			result += "_"
		result += ch.to_lower()
	return result
