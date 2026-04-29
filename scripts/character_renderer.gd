## Character_Renderer — manages 3D character models, skeletal animation,
## equipment overlays, overhead UI, and visual state swaps (ghost, mount, boat).
##
## Lives as a child of GameplayScene. Instantiates character scenes, positions
## them on the tile grid, and provides methods for all visual updates.
## Requirements: 5.1–5.7, 6.1–6.6, 24.1, 24.2, 24.4, 25.1, 25.4
extends Node


const TAG := "CharRenderer"

## Preloaded character scene template.
const CHARACTER_SCENE := preload("res://scenes/characters/character.tscn")

## World-space size of one tile (must match Tile_Engine / World_Manager).
const TILE_SIZE: float = 32.0

## Name color mapping by reputation alignment.
const NAME_COLORS: Dictionary = {
	"citizen": Color(0.2, 0.9, 0.2),    # green
	"criminal": Color(0.9, 0.2, 0.2),   # red
	"new": Color(0.9, 0.9, 0.2),        # yellow
	"gm": Color(0.2, 0.9, 0.9),         # cyan
}

## Default chat bubble display duration per character of message text.
const BUBBLE_SECONDS_PER_CHAR: float = 0.06
## Minimum chat bubble duration.
const BUBBLE_MIN_DURATION: float = 2.0

## Floating text rise speed (world units per second).
const FLOAT_TEXT_SPEED: float = 8.0


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

## Active character instances keyed by char_id.
var _characters: Dictionary = {}


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------


func _ready() -> void:
	# Connect to StateManager signals for character events.
	StateManager.character_spawned.connect(_on_character_spawned)
	StateManager.character_despawned.connect(_on_character_despawned)
	StateManager.character_moved.connect(_on_character_moved)
	StateManager.character_attacked.connect(_on_character_attacked)
	StateManager.character_died.connect(_on_character_died)
	StateManager.chat_bubble.connect(_on_chat_bubble)
	Log.info(TAG, "Character_Renderer ready")


# ---------------------------------------------------------------------------
# Spawn / Despawn  (Task 7.2)
# ---------------------------------------------------------------------------


## Instantiates a character scene, configures it from [param data], positions
## it at [param tile_pos], and adds it to the CharacterContainer.
func spawn_character(char_id: String, data: Dictionary, tile_pos: Vector2i) -> void:
	if char_id in _characters:
		Log.warning(TAG, "Character '%s' already spawned — skipping" % char_id)
		return

	var instance: CharacterBody3D = null
	if CHARACTER_SCENE != null:
		instance = CHARACTER_SCENE.instantiate()
	else:
		Log.error(TAG, "Character scene not loaded — creating placeholder for '%s'" % char_id)
		instance = _create_placeholder_character(char_id)

	instance.char_id = char_id
	_configure_character(instance, data)
	instance.position = _tile_to_world(tile_pos)

	var container := get_parent().get_node_or_null("CharacterContainer")
	if container:
		container.add_child(instance)
	else:
		Log.warning(TAG, "CharacterContainer not found — adding to parent")
		get_parent().add_child(instance)

	_characters[char_id] = instance

	# Wire the OverheadSprite to the SubViewport texture so the billboard
	# displays the overhead UI.
	_bind_overhead_sprite(instance)

	Log.info(TAG, "Spawned character '%s' at tile (%d, %d)" % [char_id, tile_pos.x, tile_pos.y])


## Removes and frees the character instance for [param char_id].
func despawn_character(char_id: String) -> void:
	if char_id not in _characters:
		Log.warning(TAG, "Cannot despawn unknown character '%s'" % char_id)
		return
	var instance: Node = _characters[char_id]
	if is_instance_valid(instance):
		instance.queue_free()
	_characters.erase(char_id)
	Log.info(TAG, "Despawned character '%s'" % char_id)


## Configures a freshly instantiated character from a data dictionary.
## Expected keys: name, guild_tag, reputation, hp, max_hp, shield, max_shield,
## equipment, heading.
func _configure_character(instance: CharacterBody3D, data: Dictionary) -> void:
	instance.display_name = data.get("name", "Unknown")
	instance.guild_tag = data.get("guild_tag", "")
	instance.reputation = data.get("reputation", "citizen")
	instance.current_hp = data.get("hp", 100)
	instance.max_hp = data.get("max_hp", 100)
	instance.shield_points = data.get("shield", 0)
	instance.max_shield = data.get("max_shield", 0)

	# Apply initial overhead UI.
	_apply_overhead_ui(instance)

	# Apply initial equipment if provided.
	var equipment: Dictionary = data.get("equipment", {})
	for slot_name in equipment.keys():
		var equip_value = equipment[slot_name]
		var equip_data: Dictionary = {}
		if equip_value is String and equip_value != "":
			equip_data = MockDataProvider.get_item(equip_value)
		elif equip_value is Dictionary:
			equip_data = equip_value
		_apply_equipment_to_slot(instance, slot_name, equip_data)

	# Set initial heading.
	var heading: int = data.get("heading", StateManager.Heading.SOUTH)
	_apply_heading(instance, heading)

	Log.debug(TAG, "Configured character '%s'" % instance.display_name)


# ---------------------------------------------------------------------------
# Equipment  (Task 7.2)
# ---------------------------------------------------------------------------


## Updates the equipment mesh on the specified bone attachment slot.
## [param slot] is one of "weapon", "shield", "helmet".
## [param item_data] should contain at least "id"; empty dict hides the slot.
func update_equipment(char_id: String, slot: String, item_data: Dictionary) -> void:
	var instance := _get_character(char_id)
	if instance == null:
		return
	_apply_equipment_to_slot(instance, slot, item_data)


## Internal: shows or hides a mesh on the named BoneAttachment3D slot.
func _apply_equipment_to_slot(instance: CharacterBody3D, slot: String, item_data: Dictionary) -> void:
	var slot_name := slot + "_slot"
	var skeleton: Skeleton3D = instance.get_node_or_null("CharacterModel/Skeleton3D")
	if skeleton == null:
		return
	var attachment: BoneAttachment3D = skeleton.get_node_or_null(slot_name)
	if attachment == null:
		Log.warning(TAG, "Bone attachment '%s' not found" % slot_name)
		return

	# Clear existing children.
	for child in attachment.get_children():
		child.queue_free()

	# If item_data is empty or has no id, leave the slot empty (unequipped).
	if item_data.is_empty() or item_data.get("id", "") == "":
		return

	# Create a placeholder mesh to represent the equipped item.
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "EquipMesh_%s" % slot

	match slot:
		"weapon":
			var box := BoxMesh.new()
			box.size = Vector3(1.0, 6.0, 1.0)
			mesh_instance.mesh = box
		"shield":
			var box := BoxMesh.new()
			box.size = Vector3(3.0, 4.0, 0.5)
			mesh_instance.mesh = box
		"helmet":
			var sphere := SphereMesh.new()
			sphere.radius = 2.5
			sphere.height = 3.0
			mesh_instance.mesh = sphere
		_:
			var box := BoxMesh.new()
			box.size = Vector3(2.0, 2.0, 2.0)
			mesh_instance.mesh = box

	# Tint based on item rarity or type if available.
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _get_equipment_color(item_data)
	mesh_instance.material_override = mat

	attachment.add_child(mesh_instance)
	Log.debug(TAG, "Equipped '%s' in slot '%s'" % [item_data.get("id", "?"), slot])


## Returns a color tint for equipment based on item data.
func _get_equipment_color(item_data: Dictionary) -> Color:
	var rarity: String = item_data.get("rarity", "common")
	match rarity:
		"common":
			return Color(0.7, 0.7, 0.7)
		"uncommon":
			return Color(0.3, 0.8, 0.3)
		"rare":
			return Color(0.3, 0.3, 0.9)
		"epic":
			return Color(0.6, 0.2, 0.8)
		"legendary":
			return Color(0.9, 0.6, 0.1)
	return Color(0.7, 0.7, 0.7)


# ---------------------------------------------------------------------------
# Animation  (Task 7.2)
# ---------------------------------------------------------------------------


## Travels the AnimationTree state machine to [param anim_name].
## Common names: idle_south, walk_north, attack_melee, cast_spell, hit, death.
func play_animation(char_id: String, anim_name: String) -> void:
	var instance := _get_character(char_id)
	if instance == null:
		return

	var anim_tree: AnimationTree = instance.get_node_or_null("AnimationTree")
	if anim_tree == null:
		Log.warning(TAG, "AnimationTree not found on '%s'" % char_id)
		return

	# Ensure the tree is active.
	if not anim_tree.active:
		anim_tree.active = true

	var playback = anim_tree.get("parameters/playback")
	if playback == null:
		Log.warning(TAG, "No playback parameter on AnimationTree for '%s'" % char_id)
		return

	playback.travel(anim_name)
	Log.debug(TAG, "Playing animation '%s' on '%s'" % [anim_name, char_id])


# ---------------------------------------------------------------------------
# Heading  (Task 7.2)
# ---------------------------------------------------------------------------


## Updates the facing direction of the character by rotating the model.
func set_heading(char_id: String, heading: int) -> void:
	var instance := _get_character(char_id)
	if instance == null:
		return
	_apply_heading(instance, heading)


## Internal: rotates the CharacterModel to face the given heading.
func _apply_heading(instance: CharacterBody3D, heading: int) -> void:
	var model: Node3D = instance.get_node_or_null("CharacterModel")
	if model == null:
		return

	var angle: float = 0.0
	match heading:
		StateManager.Heading.NORTH:
			angle = 0.0
		StateManager.Heading.EAST:
			angle = -PI / 2.0
		StateManager.Heading.SOUTH:
			angle = PI
		StateManager.Heading.WEST:
			angle = PI / 2.0

	model.rotation.y = angle


# ---------------------------------------------------------------------------
# Overhead UI  (Task 7.3)
# ---------------------------------------------------------------------------


## Updates the overhead UI elements (name label, HP bar, shield bar, name color)
## for the character identified by [param char_id].
## [param data] may contain: name, guild_tag, reputation, hp, max_hp, shield,
## max_shield.
func update_overhead_ui(char_id: String, data: Dictionary) -> void:
	var instance := _get_character(char_id)
	if instance == null:
		return

	# Merge incoming data into instance state.
	if data.has("name"):
		instance.display_name = data["name"]
	if data.has("guild_tag"):
		instance.guild_tag = data["guild_tag"]
	if data.has("reputation"):
		instance.reputation = data["reputation"]
	if data.has("hp"):
		instance.current_hp = data["hp"]
	if data.has("max_hp"):
		instance.max_hp = data["max_hp"]
	if data.has("shield"):
		instance.shield_points = data["shield"]
	if data.has("max_shield"):
		instance.max_shield = data["max_shield"]

	_apply_overhead_ui(instance)


## Internal: applies the current instance state to the overhead UI nodes.
func _apply_overhead_ui(instance: CharacterBody3D) -> void:
	var overhead_control: Control = instance.get_node_or_null("OverheadUI/OverheadControl")
	if overhead_control == null:
		return

	# --- Name label with guild tag ---
	var name_label: Label = overhead_control.get_node_or_null("NameLabel")
	if name_label:
		var label_text: String = instance.display_name
		if instance.guild_tag != "":
			label_text += " <%s>" % instance.guild_tag
		name_label.text = label_text

		# Name color based on reputation.
		var name_color: Color = NAME_COLORS.get(instance.reputation, Color.WHITE)
		name_label.add_theme_color_override("font_color", name_color)

	# --- HP bar ---
	var hp_bar: ProgressBar = overhead_control.get_node_or_null("HPBar")
	if hp_bar:
		hp_bar.max_value = instance.max_hp
		hp_bar.value = instance.current_hp

	# --- Shield bar ---
	var shield_bar: ProgressBar = overhead_control.get_node_or_null("ShieldBar")
	if shield_bar:
		if instance.max_shield > 0:
			shield_bar.visible = true
			shield_bar.max_value = instance.max_shield
			shield_bar.value = instance.shield_points
		else:
			shield_bar.visible = false


## Displays a chat bubble above the character that auto-hides after [param duration].
## If [param duration] <= 0, duration is calculated from message length.
func show_chat_bubble(char_id: String, message: String, duration: float = 0.0) -> void:
	var instance := _get_character(char_id)
	if instance == null:
		return

	var bubble: RichTextLabel = instance.get_node_or_null("OverheadUI/OverheadControl/ChatBubble")
	if bubble == null:
		return

	bubble.text = message
	bubble.visible = true

	# Calculate duration from message length if not specified.
	var actual_duration := duration
	if actual_duration <= 0.0:
		actual_duration = maxf(BUBBLE_MIN_DURATION, message.length() * BUBBLE_SECONDS_PER_CHAR)

	# Create a timer to auto-hide the bubble.
	var timer := get_tree().create_timer(actual_duration)
	timer.timeout.connect(func():
		if is_instance_valid(bubble):
			bubble.visible = false
			bubble.text = ""
	)

	Log.debug(TAG, "Chat bubble on '%s': '%s' (%.1fs)" % [char_id, message.left(30), actual_duration])


## Creates a temporary floating Label3D above the character that rises and fades.
## Used for damage numbers, healing, XP gains, etc.
func show_floating_text(char_id: String, text: String, color: Color = Color.WHITE, duration: float = 1.5) -> void:
	var instance := _get_character(char_id)
	if instance == null:
		return

	var label := Label3D.new()
	label.text = text
	label.modulate = color
	label.font_size = 48
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.pixel_size = 0.05

	# Position above the character's EffectAttachPoint.
	var attach_point: Node3D = instance.get_node_or_null("EffectAttachPoint")
	if attach_point:
		label.position = attach_point.global_position + Vector3(0, 2, 0)
	else:
		label.position = instance.global_position + Vector3(0, 20, 0)

	# Add to the scene tree (not as child of character so it doesn't move with it).
	var container := get_parent().get_node_or_null("CharacterContainer")
	if container:
		container.add_child(label)
	else:
		get_parent().add_child(label)

	# Animate: float upward and fade out.
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y + FLOAT_TEXT_SPEED * duration, duration)
	tween.tween_property(label, "modulate:a", 0.0, duration).set_delay(duration * 0.3)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)


## Binds the OverheadSprite (Sprite3D billboard) to the SubViewport texture
## so the overhead UI renders in 3D space facing the camera.
func _bind_overhead_sprite(instance: CharacterBody3D) -> void:
	var viewport: SubViewport = instance.get_node_or_null("OverheadUI")
	var sprite: Sprite3D = instance.get_node_or_null("OverheadSprite")
	if viewport and sprite:
		# The SubViewport texture becomes available after the first frame.
		# Use call_deferred to ensure it's ready.
		(func():
			sprite.texture = viewport.get_texture()
		).call_deferred()


# ---------------------------------------------------------------------------
# Special model swaps  (Task 7.4)
# ---------------------------------------------------------------------------


## Swaps the character's material to a translucent blue/white ghost appearance.
## Used when a character dies. (Req 5.6)
func swap_to_ghost_model(char_id: String) -> void:
	var instance := _get_character(char_id)
	if instance == null:
		return

	var model: MeshInstance3D = instance.get_node_or_null("CharacterModel")
	if model == null:
		return

	# Store original material if not already stored.
	if instance._original_material == null:
		instance._original_material = model.material_override

	var ghost_mat := StandardMaterial3D.new()
	ghost_mat.albedo_color = Color(0.7, 0.8, 1.0, 0.4)
	ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ghost_mat.emission_enabled = true
	ghost_mat.emission = Color(0.5, 0.6, 1.0)
	ghost_mat.emission_energy_multiplier = 0.5
	model.material_override = ghost_mat

	instance.is_ghost = true
	Log.info(TAG, "Character '%s' swapped to ghost model" % char_id)


## Toggles the visibility of the character. (Req 5.7)
func set_character_visible(char_id: String, visible: bool) -> void:
	var instance := _get_character(char_id)
	if instance == null:
		return

	instance.visible = visible
	instance.is_visible_character = visible
	Log.debug(TAG, "Character '%s' visibility set to %s" % [char_id, str(visible)])


## Swaps the character to a mounted appearance — scales up the model and
## applies a tint based on [param mount_type]. (Req 24.1, 24.2)
func swap_to_mounted_model(char_id: String, mount_type: String = "horse") -> void:
	var instance := _get_character(char_id)
	if instance == null:
		return

	var model: MeshInstance3D = instance.get_node_or_null("CharacterModel")
	if model == null:
		return

	# Store original material if not already stored.
	if instance._original_material == null:
		instance._original_material = model.material_override

	# Scale up to indicate mounted state.
	model.scale = Vector3(1.3, 1.3, 1.3)

	# Apply mount-type tint.
	var mount_mat := StandardMaterial3D.new()
	match mount_type:
		"horse":
			mount_mat.albedo_color = Color(0.55, 0.35, 0.2)
		"war_horse":
			mount_mat.albedo_color = Color(0.3, 0.3, 0.35)
		_:
			mount_mat.albedo_color = Color(0.5, 0.4, 0.3)
	model.material_override = mount_mat

	instance.is_mounted = true
	instance.mount_type = mount_type
	Log.info(TAG, "Character '%s' mounted on '%s'" % [char_id, mount_type])


## Swaps the character to a boat appearance for water navigation. (Req 24.4)
func swap_to_boat_model(char_id: String) -> void:
	var instance := _get_character(char_id)
	if instance == null:
		return

	var model: MeshInstance3D = instance.get_node_or_null("CharacterModel")
	if model == null:
		return

	# Store original material if not already stored.
	if instance._original_material == null:
		instance._original_material = model.material_override

	# Replace mesh with a flat boat-like shape.
	var boat_mesh := BoxMesh.new()
	boat_mesh.size = Vector3(10.0, 3.0, 16.0)
	model.mesh = boat_mesh
	model.scale = Vector3.ONE
	model.transform.origin = Vector3(0, 2, 0)

	var boat_mat := StandardMaterial3D.new()
	boat_mat.albedo_color = Color(0.45, 0.3, 0.15)
	model.material_override = boat_mat

	instance.is_in_boat = true
	Log.info(TAG, "Character '%s' swapped to boat model" % char_id)


## Restores the character to its normal model (undoes ghost, mount, or boat).
func _restore_normal_model(char_id: String) -> void:
	var instance := _get_character(char_id)
	if instance == null:
		return

	var model: MeshInstance3D = instance.get_node_or_null("CharacterModel")
	if model == null:
		return

	# Restore original mesh (capsule).
	var capsule := CapsuleMesh.new()
	capsule.radius = 4.0
	capsule.height = 14.0
	model.mesh = capsule
	model.scale = Vector3.ONE
	model.transform.origin = Vector3(0, 7, 0)

	# Restore original material.
	if instance._original_material:
		model.material_override = instance._original_material
	else:
		var default_mat := StandardMaterial3D.new()
		default_mat.albedo_color = Color(0.6, 0.5, 0.4)
		model.material_override = default_mat

	instance.is_ghost = false
	instance.is_mounted = false
	instance.mount_type = ""
	instance.is_in_boat = false
	Log.debug(TAG, "Character '%s' restored to normal model" % char_id)


## Adds or removes a persistent aura particle effect on the character's
## EffectAttachPoint. (Req 25.1, 25.4)
## [param aura_slot] is one of: "head", "body", "weapon", "shield".
## [param effect_id] is the effect identifier; empty string removes the aura.
func set_aura(char_id: String, aura_slot: String, effect_id: String) -> void:
	var instance := _get_character(char_id)
	if instance == null:
		return

	var attach_point: Node3D = instance.get_node_or_null("EffectAttachPoint")
	if attach_point == null:
		Log.warning(TAG, "EffectAttachPoint not found on '%s'" % char_id)
		return

	var aura_node_name := "Aura_%s" % aura_slot

	# Remove existing aura in this slot.
	var existing: Node = attach_point.get_node_or_null(aura_node_name)
	if existing:
		existing.queue_free()
		instance.aura_effects.erase(aura_slot)

	# If effect_id is empty, we just wanted to remove.
	if effect_id == "":
		Log.debug(TAG, "Removed aura '%s' from '%s'" % [aura_slot, char_id])
		return

	# Create a simple particle effect as placeholder aura.
	var particles := GPUParticles3D.new()
	particles.name = aura_node_name
	particles.emitting = true
	particles.amount = 20
	particles.lifetime = 1.5

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 45.0
	mat.initial_velocity_min = 1.0
	mat.initial_velocity_max = 3.0
	mat.gravity = Vector3(0, 0.5, 0)
	mat.scale_min = 0.1
	mat.scale_max = 0.3

	# Color based on aura slot for visual distinction.
	match aura_slot:
		"head":
			mat.color = Color(1.0, 1.0, 0.3, 0.7)
			particles.transform.origin = Vector3(0, 2, 0)
		"body":
			mat.color = Color(0.3, 0.5, 1.0, 0.6)
		"weapon":
			mat.color = Color(1.0, 0.3, 0.1, 0.7)
			particles.transform.origin = Vector3(2, 0, 0)
		"shield":
			mat.color = Color(0.2, 0.8, 0.9, 0.6)
			particles.transform.origin = Vector3(-2, 0, 0)
		_:
			mat.color = Color(0.8, 0.8, 0.8, 0.5)

	particles.process_material = mat
	attach_point.add_child(particles)
	instance.aura_effects[aura_slot] = effect_id

	Log.debug(TAG, "Set aura '%s' (effect '%s') on '%s'" % [aura_slot, effect_id, char_id])


# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------


## Handles StateManager.character_spawned — auto-spawns the character.
func _on_character_spawned(char_id: String, char_data: Dictionary) -> void:
	var pos := Vector2i(char_data.get("position_x", 0), char_data.get("position_y", 0))
	spawn_character(char_id, char_data, pos)


## Handles StateManager.character_despawned — auto-despawns the character.
func _on_character_despawned(char_id: String) -> void:
	despawn_character(char_id)


## Handles StateManager.character_moved — updates position smoothly.
func _on_character_moved(char_id: String, _from_tile: Vector2i, to_tile: Vector2i) -> void:
	var instance := _get_character(char_id)
	if instance == null:
		return
	# Snap to destination tile (smooth interpolation can be added later).
	instance.position = _tile_to_world(to_tile)


## Handles StateManager.character_attacked — plays attack animation.
func _on_character_attacked(attacker_id: String, _target_id: String, _damage: int, _is_critical: bool) -> void:
	play_animation(attacker_id, "attack_melee")


## Handles StateManager.character_died — swaps to ghost model.
func _on_character_died(char_id: String) -> void:
	play_animation(char_id, "death")
	swap_to_ghost_model(char_id)


## Handles StateManager.chat_bubble — shows a chat bubble.
func _on_chat_bubble(char_id: String, message: String, duration: float) -> void:
	show_chat_bubble(char_id, message, duration)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


## Returns the character instance for [param char_id], or null with a warning.
func _get_character(char_id: String) -> CharacterBody3D:
	if char_id not in _characters:
		Log.warning(TAG, "Character '%s' not found" % char_id)
		return null
	var instance: CharacterBody3D = _characters[char_id]
	if not is_instance_valid(instance):
		_characters.erase(char_id)
		Log.warning(TAG, "Character '%s' instance invalid — removed" % char_id)
		return null
	return instance


## Converts a tile coordinate to a world-space position (center of tile).
func _tile_to_world(tile_pos: Vector2i) -> Vector3:
	return Vector3(
		tile_pos.x * TILE_SIZE + TILE_SIZE * 0.5,
		0.0,
		tile_pos.y * TILE_SIZE + TILE_SIZE * 0.5
	)


## Creates a minimal placeholder CharacterBody3D when the character scene
## fails to load. Used as a fallback for error handling (Task 24.1).
func _create_placeholder_character(char_id: String) -> CharacterBody3D:
	var body := CharacterBody3D.new()
	body.name = "Placeholder_%s" % char_id

	# Add required properties that the rest of the code expects.
	body.set_meta("char_id", char_id)

	# Create a simple capsule mesh as placeholder.
	var model := MeshInstance3D.new()
	model.name = "CharacterModel"
	var capsule := CapsuleMesh.new()
	capsule.radius = 4.0
	capsule.height = 14.0
	model.mesh = capsule
	model.position = Vector3(0, 7, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.2, 0.8)  # Magenta = placeholder
	model.material_override = mat
	body.add_child(model)

	Log.warning(TAG, "Created placeholder character for '%s'" % char_id)
	return body
