## World_Manager — manages chunk streaming, zone transitions, weather, and
## per-tile lighting for the continuous tile-based world.
##
## Lives as a child of GameplayScene. Loads chunk data from Mock_Data_Provider,
## builds Node3D meshes per chunk, and reacts to player movement for zone
## detection, weather changes, and roof transparency.
extends Node3D


const TAG := "WorldManager"
const CHUNK_SIZE: int = 32          ## Tiles per chunk side.
const LOAD_RADIUS: int = 1          ## Chunks around player (3×3 grid).
const PRELOAD_DISTANCE: int = 2     ## Chunks ahead in movement direction.
const TILE_SIZE: float = 32.0       ## World-space size of one tile.


# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted when a chunk finishes loading into the scene tree.
signal chunk_loaded(chunk_x: int, chunk_y: int)

## Emitted when a chunk is unloaded from the scene tree.
signal chunk_unloaded(chunk_x: int, chunk_y: int)

## Emitted when the player crosses into a different zone.
signal zone_transition(old_zone: Dictionary, new_zone: Dictionary)


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

## Loaded chunk nodes keyed by "x_y".
var _loaded_chunks: Dictionary = {}

## Current zone id the player is in.
var _current_zone_id: String = ""

## Day/night cycle speed multiplier (real-time → game-time).
var _day_night_speed: float = 1.0


# ---------------------------------------------------------------------------
# Node references
# ---------------------------------------------------------------------------

@onready var chunk_container: Node3D = $ChunkContainer
@onready var weather_particles: GPUParticles3D = $WeatherParticles
@onready var environment_node: WorldEnvironment = $EnvironmentNode


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------


func _ready() -> void:
	# Connect to player position changes so we can check zone transitions.
	StateManager.player_position_changed.connect(_on_player_position_changed)
	Log.info(TAG, "World_Manager ready")


func _process(delta: float) -> void:
	_update_chunk_loading()


# ---------------------------------------------------------------------------
# Chunk streaming
# ---------------------------------------------------------------------------


## Determines which chunks should be loaded/unloaded based on the player's
## current chunk coordinate.
func _update_chunk_loading() -> void:
	var player_chunk := _get_player_chunk()
	_load_chunks_around(player_chunk)
	_unload_distant_chunks(player_chunk)


## Returns the chunk coordinate the player currently occupies.
func _get_player_chunk() -> Vector2i:
	var pos := StateManager.player_position
	@warning_ignore("integer_division")
	var cx: int = pos.x / CHUNK_SIZE if pos.x >= 0 else (pos.x - CHUNK_SIZE + 1) / CHUNK_SIZE
	@warning_ignore("integer_division")
	var cy: int = pos.y / CHUNK_SIZE if pos.y >= 0 else (pos.y - CHUNK_SIZE + 1) / CHUNK_SIZE
	return Vector2i(cx, cy)


## Loads all chunks within LOAD_RADIUS of [param center] that are not yet loaded.
func _load_chunks_around(center: Vector2i) -> void:
	for dx in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
		for dy in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
			var cx := center.x + dx
			var cy := center.y + dy
			var key := "%d_%d" % [cx, cy]
			if key not in _loaded_chunks:
				_load_chunk_async(cx, cy)


## Unloads chunks that are farther than LOAD_RADIUS from [param center].
func _unload_distant_chunks(center: Vector2i) -> void:
	var keys_to_remove: Array[String] = []
	for key in _loaded_chunks.keys():
		var parts := (key as String).split("_")
		if parts.size() != 2:
			continue
		var cx := int(parts[0])
		var cy := int(parts[1])
		if absi(cx - center.x) > LOAD_RADIUS or absi(cy - center.y) > LOAD_RADIUS:
			keys_to_remove.append(key)
	for key in keys_to_remove:
		var node: Node = _loaded_chunks[key]
		if node and is_instance_valid(node):
			node.queue_free()
		_loaded_chunks.erase(key)
		var parts := key.split("_")
		chunk_unloaded.emit(int(parts[0]), int(parts[1]))
		Log.debug(TAG, "Unloaded chunk %s" % key)


## Requests chunk data from Mock_Data_Provider and defers instantiation.
func _load_chunk_async(chunk_x: int, chunk_y: int) -> void:
	var key := "%d_%d" % [chunk_x, chunk_y]
	# Mark as loading to prevent duplicate requests.
	_loaded_chunks[key] = null
	var chunk_data: Dictionary = MockDataProvider.get_chunk(chunk_x, chunk_y)
	if chunk_data.is_empty():
		_create_placeholder_chunk(chunk_x, chunk_y)
		return
	call_deferred("_instantiate_chunk", chunk_x, chunk_y, chunk_data)


## Builds a Node3D for the chunk with 4 MeshInstance3D children (ground,
## detail, object, roof) from tile data.
func _instantiate_chunk(chunk_x: int, chunk_y: int, data: Dictionary) -> void:
	var key := "%d_%d" % [chunk_x, chunk_y]
	var chunk_node := Node3D.new()
	chunk_node.name = "Chunk_%s" % key

	# World-space origin for this chunk.
	chunk_node.position = Vector3(
		chunk_x * CHUNK_SIZE * TILE_SIZE,
		0.0,
		chunk_y * CHUNK_SIZE * TILE_SIZE
	)

	# Create layer meshes.
	var ground_mesh := MeshInstance3D.new()
	ground_mesh.name = "GroundMesh"
	chunk_node.add_child(ground_mesh)

	var detail_mesh := MeshInstance3D.new()
	detail_mesh.name = "DetailMesh"
	chunk_node.add_child(detail_mesh)

	var object_mesh := MeshInstance3D.new()
	object_mesh.name = "ObjectMesh"
	chunk_node.add_child(object_mesh)

	var roof_mesh := MeshInstance3D.new()
	roof_mesh.name = "RoofMesh"
	chunk_node.add_child(roof_mesh)

	# Build quad geometry from tile data.
	var tiles: Array = data.get("tiles", [])
	for tile in tiles:
		var tx: int = tile.get("x", 0)
		var ty: int = tile.get("y", 0)
		var layers: Dictionary = tile.get("layers", {})
		var local_pos := Vector3(tx * TILE_SIZE, 0.0, ty * TILE_SIZE)

		# Ground layer quad.
		var ground_gfx: String = layers.get("ground", {}).get("graphic_id", "")
		if ground_gfx != "":
			var quad := _create_tile_quad(local_pos, Color(0.3, 0.6, 0.2))  # placeholder green
			ground_mesh.add_child(quad)

		# Detail layer quad (slightly above ground).
		var detail_gfx: String = layers.get("detail", {}).get("graphic_id", "")
		if detail_gfx != "":
			var quad := _create_tile_quad(local_pos + Vector3(0, 0.01, 0), Color(0.5, 0.7, 0.3))
			detail_mesh.add_child(quad)

		# Object layer quad — color and height vary by graphic_id prefix.
		var object_gfx: String = layers.get("object", {}).get("graphic_id", "")
		if object_gfx != "":
			var obj_color := _get_object_color(object_gfx)
			var obj_y := _get_object_elevation(object_gfx)
			var quad := _create_tile_quad(local_pos + Vector3(0, obj_y, 0), obj_color)
			object_mesh.add_child(quad)

		# Roof layer quad (above objects).
		var roof_gfx: String = layers.get("roof", {}).get("graphic_id", "")
		if roof_gfx != "":
			var quad := _create_tile_quad(local_pos + Vector3(0, 2.0, 0), Color(0.5, 0.3, 0.2))
			roof_mesh.add_child(quad)

	chunk_container.add_child(chunk_node)
	_loaded_chunks[key] = chunk_node
	chunk_loaded.emit(chunk_x, chunk_y)
	Log.debug(TAG, "Instantiated chunk %s (%d tiles)" % [key, tiles.size()])


## Creates a small flat quad MeshInstance3D at [param pos] with the given color.
func _create_tile_quad(pos: Vector3, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var quad := PlaneMesh.new()
	quad.size = Vector2(TILE_SIZE, TILE_SIZE)
	mesh_instance.mesh = quad
	mesh_instance.position = pos + Vector3(TILE_SIZE * 0.5, 0.0, TILE_SIZE * 0.5)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = mat
	return mesh_instance


## Returns a placeholder color for an object layer tile based on its graphic_id prefix.
func _get_object_color(graphic_id: String) -> Color:
	if graphic_id.begins_with("wall_"):
		return Color(0.5, 0.5, 0.5)
	if graphic_id.begins_with("tree_"):
		return Color(0.1, 0.4, 0.1)
	if graphic_id.begins_with("rock_"):
		return Color(0.4, 0.3, 0.2)
	if graphic_id.begins_with("bush_"):
		return Color(0.2, 0.6, 0.2)
	if graphic_id.begins_with("crate_") or graphic_id.begins_with("barrel_"):
		return Color(0.6, 0.5, 0.3)
	if graphic_id.begins_with("torch_"):
		return Color(0.9, 0.5, 0.1)
	if graphic_id.begins_with("campfire_"):
		return Color(0.8, 0.3, 0.1)
	if graphic_id.begins_with("signpost_"):
		return Color(0.5, 0.35, 0.2)
	if graphic_id.begins_with("fence_"):
		return Color(0.55, 0.4, 0.25)
	# Default fallback for unrecognized prefixes.
	return Color(0.6, 0.4, 0.2)


## Returns the Y elevation for an object layer tile based on its graphic_id prefix.
## Walls are tallest (1.0), fences slightly lower (0.75), other objects at half-height (0.5).
func _get_object_elevation(graphic_id: String) -> float:
	if graphic_id.begins_with("wall_"):
		return 1.0
	if graphic_id.begins_with("fence_"):
		return 0.75
	return 0.5


## Creates a placeholder chunk node when chunk data fails to load.
func _create_placeholder_chunk(chunk_x: int, chunk_y: int) -> void:
	var key := "%d_%d" % [chunk_x, chunk_y]
	var chunk_node := Node3D.new()
	chunk_node.name = "Chunk_%s_placeholder" % key
	chunk_node.position = Vector3(
		chunk_x * CHUNK_SIZE * TILE_SIZE,
		0.0,
		chunk_y * CHUNK_SIZE * TILE_SIZE
	)
	# Single red quad to indicate error.
	var quad := _create_tile_quad(Vector3.ZERO, Color(0.8, 0.1, 0.1, 0.5))
	chunk_node.add_child(quad)
	chunk_container.add_child(chunk_node)
	_loaded_chunks[key] = chunk_node
	Log.debug(TAG, "Created placeholder for missing chunk %s" % key)


# ---------------------------------------------------------------------------
# Tile queries
# ---------------------------------------------------------------------------


## Returns the directional collision bitmask for the tile at world coordinates.
## 0 = no collision. Bit 0 = North, Bit 1 = East, Bit 2 = South, Bit 3 = West.
func get_collision_flags(tile_x: int, tile_y: int) -> int:
	var tile := get_tile_data(tile_x, tile_y)
	return tile.get("collision", 0)


## Returns the full tile data dictionary for the tile at world coordinates,
## or an empty dictionary if the tile is not loaded.
func get_tile_data(tile_x: int, tile_y: int) -> Dictionary:
	@warning_ignore("integer_division")
	var cx: int = tile_x / CHUNK_SIZE if tile_x >= 0 else (tile_x - CHUNK_SIZE + 1) / CHUNK_SIZE
	@warning_ignore("integer_division")
	var cy: int = tile_y / CHUNK_SIZE if tile_y >= 0 else (tile_y - CHUNK_SIZE + 1) / CHUNK_SIZE
	var key := "%d_%d" % [cx, cy]
	var chunk_data: Dictionary = MockDataProvider.get_chunk(cx, cy)
	if chunk_data.is_empty():
		return {}
	var local_x: int = tile_x - cx * CHUNK_SIZE
	var local_y: int = tile_y - cy * CHUNK_SIZE
	for tile in chunk_data.get("tiles", []):
		if tile.get("x", -1) == local_x and tile.get("y", -1) == local_y:
			return tile
	return {}


## Returns zone metadata for the tile at world coordinates by looking up the
## chunk's zone_id in Mock_Data_Provider.
func get_zone_for_tile(tile_x: int, tile_y: int) -> Dictionary:
	@warning_ignore("integer_division")
	var cx: int = tile_x / CHUNK_SIZE if tile_x >= 0 else (tile_x - CHUNK_SIZE + 1) / CHUNK_SIZE
	@warning_ignore("integer_division")
	var cy: int = tile_y / CHUNK_SIZE if tile_y >= 0 else (tile_y - CHUNK_SIZE + 1) / CHUNK_SIZE
	var chunk_data: Dictionary = MockDataProvider.get_chunk(cx, cy)
	if chunk_data.is_empty():
		return {}
	var zone_id: String = chunk_data.get("zone_id", "")
	if zone_id == "":
		return {}
	return MockDataProvider.get_zone_metadata(zone_id)


# ---------------------------------------------------------------------------
# Zone transition detection  (Task 4.2)
# ---------------------------------------------------------------------------


## Called when the player moves to a new tile. Checks whether the zone has
## changed and, if so, emits [signal zone_transition], updates StateManager,
## and triggers audio transitions.
func _on_player_position_changed(tile_x: int, tile_y: int) -> void:
	_check_zone_transition(tile_x, tile_y)


## Compares the zone at the player's current tile with [member _current_zone_id].
## On change: emits signal, updates StateManager, triggers music crossfade and
## ambient sound swap.
func _check_zone_transition(tile_x: int, tile_y: int) -> void:
	var zone_data := get_zone_for_tile(tile_x, tile_y)
	if zone_data.is_empty():
		return

	var new_zone_id: String = zone_data.get("zone_id", zone_data.get("id", ""))
	if new_zone_id == "" or new_zone_id == _current_zone_id:
		return

	var old_zone := StateManager.current_zone
	_current_zone_id = new_zone_id

	# Update central state.
	StateManager.current_zone = zone_data
	StateManager.zone_changed.emit(zone_data)

	# Emit our own signal for any direct listeners.
	zone_transition.emit(old_zone, zone_data)

	# Trigger music crossfade.
	var music_track: String = zone_data.get("music_track", "")
	if music_track != "":
		AudioManager.play_music(music_track)

	# Swap ambient sound.
	var ambient_sound: String = zone_data.get("ambient_sound", "")
	if ambient_sound != "":
		AudioManager.stop_ambient("zone_ambient")
		AudioManager.play_ambient("zone_ambient", ambient_sound, Vector3.ZERO)

	# Apply zone default weather.
	var weather_default: String = zone_data.get("weather_default", "clear")
	set_weather(weather_default)

	Log.info(TAG, "Zone transition: '%s' -> '%s'" % [
		old_zone.get("name", "none"), zone_data.get("name", new_zone_id)
	])


# ---------------------------------------------------------------------------
# Weather control  (Task 4.2)
# ---------------------------------------------------------------------------


## Toggles weather particle effects based on [param weather_type].
## Supported types: "clear", "rain", "snow", "fog".
## Updates StateManager.current_weather and emits weather_changed.
func set_weather(weather_type: String) -> void:
	match weather_type:
		"clear":
			weather_particles.emitting = false
		"rain":
			weather_particles.emitting = true
			_configure_rain_particles()
		"snow":
			weather_particles.emitting = true
			_configure_snow_particles()
		"fog":
			# Fog is handled via environment, not particles.
			weather_particles.emitting = false
			_configure_fog_environment(true)
		_:
			Log.warning(TAG, "Unknown weather type: %s" % weather_type)
			weather_particles.emitting = false

	# Disable fog when switching away from it.
	if weather_type != "fog":
		_configure_fog_environment(false)

	StateManager.current_weather = weather_type
	StateManager.weather_changed.emit(weather_type)
	Log.info(TAG, "Weather set to '%s'" % weather_type)


## Configures WeatherParticles for a rain-like effect: fast downward blue-ish
## streaks.
func _configure_rain_particles() -> void:
	if weather_particles == null:
		return
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0.0, -1.0, 0.0)
	mat.spread = 5.0
	mat.initial_velocity_min = 20.0
	mat.initial_velocity_max = 30.0
	mat.gravity = Vector3(0.0, -9.8, 0.0)
	mat.color = Color(0.6, 0.7, 1.0, 0.6)
	mat.scale_min = 0.05
	mat.scale_max = 0.1
	weather_particles.process_material = mat
	weather_particles.amount = 300
	weather_particles.lifetime = 1.5


## Configures WeatherParticles for a snow effect: slow drifting white flakes.
func _configure_snow_particles() -> void:
	if weather_particles == null:
		return
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0.0, -1.0, 0.2)
	mat.spread = 15.0
	mat.initial_velocity_min = 2.0
	mat.initial_velocity_max = 5.0
	mat.gravity = Vector3(0.0, -2.0, 0.0)
	mat.color = Color(1.0, 1.0, 1.0, 0.8)
	mat.scale_min = 0.08
	mat.scale_max = 0.15
	weather_particles.process_material = mat
	weather_particles.amount = 200
	weather_particles.lifetime = 4.0


## Enables or disables volumetric fog on the WorldEnvironment.
func _configure_fog_environment(enabled: bool) -> void:
	if environment_node == null:
		return
	var env: Environment = environment_node.environment
	if env == null:
		env = Environment.new()
		environment_node.environment = env
	env.fog_enabled = enabled
	if enabled:
		env.fog_light_color = Color(0.7, 0.7, 0.75)
		env.fog_density = 0.03
	Log.debug(TAG, "Fog environment %s" % ("enabled" if enabled else "disabled"))


# ---------------------------------------------------------------------------
# Roof transparency  (Task 4.2)
# ---------------------------------------------------------------------------


## Fades the RoofMesh in the chunk identified by [param chunk_key] to the
## given [param alpha] (0.0 = fully transparent, 1.0 = fully opaque).
## Called when the player enters or exits a building.
func set_roof_transparency(chunk_key: String, alpha: float) -> void:
	if chunk_key not in _loaded_chunks:
		Log.warning(TAG, "Cannot set roof transparency — chunk '%s' not loaded" % chunk_key)
		return
	var chunk_node: Node = _loaded_chunks[chunk_key]
	if chunk_node == null or not is_instance_valid(chunk_node):
		return
	var roof_mesh: Node = chunk_node.get_node_or_null("RoofMesh")
	if roof_mesh == null:
		return
	var clamped_alpha := clampf(alpha, 0.0, 1.0)
	# Iterate over all child quads of the RoofMesh and set their material alpha.
	for child in roof_mesh.get_children():
		if child is MeshInstance3D:
			var mat: StandardMaterial3D = child.material_override as StandardMaterial3D
			if mat:
				mat.albedo_color.a = clamped_alpha
	Log.debug(TAG, "Roof transparency for chunk '%s' set to %.2f" % [chunk_key, clamped_alpha])


# ---------------------------------------------------------------------------
# Ground effects  (Task 22.2)
# ---------------------------------------------------------------------------


## Spawns a particle effect at the given tile position. The effect scene is
## instantiated, positioned at the tile center, started, and auto-freed after
## its lifetime expires.
## [param tile_pos] Tile coordinates (x, y).
## [param effect_scene] A PackedScene containing a GPUParticles3D root node.
func spawn_ground_effect(tile_pos: Vector2i, effect_scene: PackedScene) -> void:
	if effect_scene == null:
		Log.warning(TAG, "spawn_ground_effect called with null scene")
		return

	var instance: Node = effect_scene.instantiate()
	if instance == null:
		Log.error(TAG, "Failed to instantiate ground effect scene")
		return

	var world_pos := Vector3(
		tile_pos.x * TILE_SIZE + TILE_SIZE * 0.5,
		0.5,
		tile_pos.y * TILE_SIZE + TILE_SIZE * 0.5
	)

	if instance is GPUParticles3D:
		instance.position = world_pos
		instance.emitting = true
		chunk_container.add_child(instance)

		# Auto-free after lifetime + a small buffer.
		var lifetime: float = instance.lifetime + 0.5
		var timer := get_tree().create_timer(lifetime)
		timer.timeout.connect(func():
			if is_instance_valid(instance):
				instance.queue_free()
		)
		Log.debug(TAG, "Ground effect spawned at tile (%d, %d)" % [tile_pos.x, tile_pos.y])
	else:
		# Non-particle effect — just place and auto-free after 3 seconds.
		instance.position = world_pos if instance is Node3D else Vector3.ZERO
		chunk_container.add_child(instance)
		var timer := get_tree().create_timer(3.0)
		timer.timeout.connect(func():
			if is_instance_valid(instance):
				instance.queue_free()
		)
		Log.debug(TAG, "Non-particle ground effect spawned at tile (%d, %d)" % [tile_pos.x, tile_pos.y])
