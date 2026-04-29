## Game camera with fixed orthographic projection and slight downward tilt
## for 2.5D perspective. Smoothly follows the player character and clamps
## at loaded chunk boundaries.
##
## Attach to a Camera3D node in the GameplayScene.
## Requirements: 3.1, 3.2, 3.3, 3.4
extends Camera3D


const TAG := "GameCamera"

## World-space size of one tile (must match World_Manager / Tile_Engine).
const TILE_SIZE: float = 32.0

## Chunk size in tiles (must match World_Manager).
const CHUNK_SIZE: int = 32

## Load radius in chunks (must match World_Manager).
const LOAD_RADIUS: int = 1

## Interpolation speed for smooth camera follow (units per second factor).
@export var follow_speed: float = 8.0

## Fixed height above the ground plane.
@export var camera_height: float = 200.0

## Orthographic projection size (viewport coverage in world units).
@export var ortho_size: float = 512.0

## Downward tilt in degrees for the 2.5D perspective.
@export var tilt_degrees: float = -60.0


func _ready() -> void:
	# Fixed orthographic projection (Req 3.1).
	projection = 1  # PROJECTION_ORTHOGONAL (orthographic)
	size = ortho_size
	rotation_degrees = Vector3(tilt_degrees, 0.0, 0.0)

	# Snap to the player's initial position so there's no lerp-in on spawn.
	var start := _player_world_pos()
	position = Vector3(start.x, camera_height, start.z)

	Log.info(TAG, "Camera ready — ortho size %.0f, tilt %.1f°" % [ortho_size, tilt_degrees])


func _process(delta: float) -> void:
	var target := _player_world_pos()
	target = _clamp_to_loaded_chunks(target)

	# Smooth interpolation toward the target (Req 3.3).
	position = position.lerp(
		Vector3(target.x, camera_height, target.z),
		delta * follow_speed
	)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


## Returns the world-space position derived from the player's tile coordinate.
## Centers on the tile (Req 3.2).
func _player_world_pos() -> Vector3:
	var tile := StateManager.player_position
	return Vector3(
		tile.x * TILE_SIZE + TILE_SIZE * 0.5,
		0.0,
		tile.y * TILE_SIZE + TILE_SIZE * 0.5
	)


## Clamps [param target] so the camera does not scroll beyond the loaded
## chunk boundaries (Req 3.4).
func _clamp_to_loaded_chunks(target: Vector3) -> Vector3:
	var player_chunk := _get_player_chunk()

	# Compute the world-space rectangle covered by loaded chunks.
	var min_cx := player_chunk.x - LOAD_RADIUS
	var min_cy := player_chunk.y - LOAD_RADIUS
	var max_cx := player_chunk.x + LOAD_RADIUS
	var max_cy := player_chunk.y + LOAD_RADIUS

	var world_min_x: float = min_cx * CHUNK_SIZE * TILE_SIZE
	var world_min_z: float = min_cy * CHUNK_SIZE * TILE_SIZE
	var world_max_x: float = (max_cx + 1) * CHUNK_SIZE * TILE_SIZE
	var world_max_z: float = (max_cy + 1) * CHUNK_SIZE * TILE_SIZE

	target.x = clampf(target.x, world_min_x, world_max_x)
	target.z = clampf(target.z, world_min_z, world_max_z)
	return target


## Returns the chunk coordinate the player currently occupies.
func _get_player_chunk() -> Vector2i:
	var pos := StateManager.player_position
	@warning_ignore("integer_division")
	var cx: int = pos.x / CHUNK_SIZE if pos.x >= 0 else (pos.x - CHUNK_SIZE + 1) / CHUNK_SIZE
	@warning_ignore("integer_division")
	var cy: int = pos.y / CHUNK_SIZE if pos.y >= 0 else (pos.y - CHUNK_SIZE + 1) / CHUNK_SIZE
	return Vector2i(cx, cy)
