## Spell Panel — scrollable list of learned spells with icons, mana costs, and cooldown overlays.
##
## Loads spells from StateManager.player_spells on _ready. Connects to
## StateManager.cooldown_started / cooldown_finished for overlay updates.
## Requirements: 11.2, 11.4, 11.6
extends Control


const _TAG := "SpellPanel"


# --- Node references ---
var _spell_list: VBoxContainer
var _spell_rows: Dictionary = {}  # spell_id -> HBoxContainer row node
var _cooldown_overlays: Dictionary = {}  # spell_id -> ColorRect overlay
var _cooldown_timers: Dictionary = {}  # spell_id -> {remaining: float, duration: float}


func _ready() -> void:
	_spell_list = $MarginContainer/VBoxContainer/ScrollContainer/SpellList

	# Connect cooldown signals from StateManager
	StateManager.cooldown_started.connect(_on_cooldown_started)
	StateManager.cooldown_finished.connect(_on_cooldown_finished)

	# Load spells after a frame so StateManager has player data ready.
	call_deferred("_load_spells")

	# Start hidden
	visible = false

	Log.info(_TAG, "SpellPanel initialized")


## Loads spells from StateManager.player_spells and builds the list.
func _load_spells() -> void:
	_clear_spell_list()

	var spells: Array = StateManager.player_spells
	if spells.is_empty():
		Log.debug(_TAG, "No spells to display")
		return

	for spell in spells:
		if spell is Dictionary:
			_add_spell_row(spell)

	Log.info(_TAG, "Loaded %d spells into panel" % spells.size())


## Adds a single spell row to the list.
func _add_spell_row(spell: Dictionary) -> void:
	var spell_id: String = spell.get("id", "")
	if spell_id.is_empty():
		return

	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 40)
	row.name = "Spell_%s" % spell_id

	# Icon placeholder
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(32, 32)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

	# Spell name
	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.text = spell.get("name", "Unknown Spell")
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(name_label)

	# Mana cost
	var mana_label := Label.new()
	mana_label.name = "ManaLabel"
	mana_label.text = "%d MP" % spell.get("mana_cost", 0)
	mana_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	mana_label.custom_minimum_size = Vector2(60, 0)
	mana_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(mana_label)

	# Cooldown overlay — a semi-transparent ColorRect that covers the row
	var overlay := ColorRect.new()
	overlay.name = "CooldownOverlay"
	overlay.color = Color(0.0, 0.0, 0.0, 0.5)
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_child(overlay)

	# Cooldown timer label on top of overlay
	var cd_label := Label.new()
	cd_label.name = "CooldownLabel"
	cd_label.text = ""
	cd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cd_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cd_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cd_label.visible = false
	row.add_child(cd_label)

	# Make the row clickable for casting
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.gui_input.connect(_on_spell_row_input.bind(spell_id))
	row.tooltip_text = _build_tooltip(spell)

	_spell_list.add_child(row)
	_spell_rows[spell_id] = row
	_cooldown_overlays[spell_id] = overlay


## Handles click on a spell row to initiate casting.
func _on_spell_row_input(event: InputEvent, spell_id: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _is_on_cooldown(spell_id):
			Log.debug(_TAG, "Spell '%s' is on cooldown" % spell_id)
			return
		# Cast with empty target — targeting handled elsewhere.
		StateManager.process_spell_cast(spell_id, "")
		Log.debug(_TAG, "Cast spell '%s' from panel" % spell_id)


## Called when a cooldown starts. Maps the category to spell_id if applicable.
func _on_cooldown_started(category: String, duration: float) -> void:
	# The category may be "magic" (global) or a specific spell_id.
	# For global magic cooldown, apply to all spells.
	if category == "magic":
		for spell_id in _cooldown_overlays:
			_start_spell_cooldown(spell_id, duration)
	elif category in _cooldown_overlays:
		_start_spell_cooldown(category, duration)


## Called when a cooldown finishes.
func _on_cooldown_finished(category: String) -> void:
	if category == "magic":
		for spell_id in _cooldown_overlays:
			_end_spell_cooldown(spell_id)
	elif category in _cooldown_overlays:
		_end_spell_cooldown(category)


## Starts the cooldown overlay for a specific spell.
func _start_spell_cooldown(spell_id: String, duration: float) -> void:
	var overlay: ColorRect = _cooldown_overlays.get(spell_id)
	if overlay:
		overlay.visible = true
	_cooldown_timers[spell_id] = {"remaining": duration, "duration": duration}

	# Show cooldown label
	var row: HBoxContainer = _spell_rows.get(spell_id)
	if row:
		var cd_label: Label = row.get_node_or_null("CooldownLabel")
		if cd_label:
			cd_label.visible = true
			cd_label.text = "%.1fs" % duration


## Ends the cooldown overlay for a specific spell.
func _end_spell_cooldown(spell_id: String) -> void:
	var overlay: ColorRect = _cooldown_overlays.get(spell_id)
	if overlay:
		overlay.visible = false
	_cooldown_timers.erase(spell_id)

	var row: HBoxContainer = _spell_rows.get(spell_id)
	if row:
		var cd_label: Label = row.get_node_or_null("CooldownLabel")
		if cd_label:
			cd_label.visible = false
			cd_label.text = ""


## Returns true if the spell is currently on cooldown.
func _is_on_cooldown(spell_id: String) -> bool:
	return spell_id in _cooldown_timers


## Updates cooldown timers and overlay visuals each frame.
func _process(delta: float) -> void:
	var finished: Array = []
	for spell_id in _cooldown_timers:
		var timer: Dictionary = _cooldown_timers[spell_id]
		timer["remaining"] -= delta
		if timer["remaining"] <= 0.0:
			finished.append(spell_id)
		else:
			# Update cooldown label text
			var row: HBoxContainer = _spell_rows.get(spell_id)
			if row:
				var cd_label: Label = row.get_node_or_null("CooldownLabel")
				if cd_label:
					cd_label.text = "%.1fs" % timer["remaining"]

	for spell_id in finished:
		_end_spell_cooldown(spell_id)


## Builds a tooltip string for a spell.
func _build_tooltip(spell: Dictionary) -> String:
	var parts: Array = []
	parts.append(spell.get("name", "Unknown"))
	if spell.has("description"):
		parts.append(spell["description"])
	parts.append("Mana: %d" % spell.get("mana_cost", 0))
	if spell.has("cooldown"):
		parts.append("Cooldown: %.1fs" % spell["cooldown"])
	if spell.has("damage"):
		parts.append("Damage: %d" % spell["damage"])
	if spell.has("element"):
		parts.append("Element: %s" % spell["element"])
	return "\n".join(parts)


## Clears all spell rows from the list.
func _clear_spell_list() -> void:
	for child in _spell_list.get_children():
		child.queue_free()
	_spell_rows.clear()
	_cooldown_overlays.clear()
	_cooldown_timers.clear()
