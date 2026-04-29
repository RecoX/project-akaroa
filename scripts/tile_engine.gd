## Tile_Engine — handles player movement input, cooldown enforcement,
## collision checking, smooth tile-to-tile scrolling, and coordinate
## conversion between tile-space and world-space.
##
## Lives as a child of GameplayScene alongside World_Manager.
## Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6
extends Node


const TAG := "TileEngine"

## World-space size of one tile.
const TILE_SIZE: float = 32.0

## Minimum interval (seconds) between consecutive move requests (Req 7.2).
const MOVE_INTERVAL: float = 0.15

## Duration (seconds) for the visual scroll between tiles (Req 7.3).
const SCROLL_DURATION: float = 0.12


# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted when a movement request is accepted.
signal movement_requested(heading: int)

## Emitted when the visual scroll to the destination tile finishes.
signal movement_completed(tile_pos: Vector2i)


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

## Remaining cooldown before the next move is allowed.
var _move_cooldown_timer: float = 0.0

## Whether the player visual is currently scrolling between tiles.
var _is_moving: bool = false

## Queued heading from held keys so direction changes are seamless (Req 7.5).
var _queued_heading: int = -1

## When true, all movement input is ignored (Req 7.6).
var _player_immobilized: bool = false

## Progress [0..1] of the current visual scroll.
var _move_progress: float = 0.0

## World-space origin of the current scroll.
var _scroll_from: Vector3 = Vector3.ZERO

## World-space destination of the current scroll.
var _scroll_to: Vector3 = Vector3.ZERO

## Reference to the World_Manager sibling node (resolved once on _ready).
var _world_manager: Node = null


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------


func _ready() -> void:
	# Resolve World_Manager from the parent GameplayScene.
	_world_manager = get_parent().get_node_or_null("WorldManager")
	if _world_manager == null:
		Log.warning(TAG, "World_Manager sibling not found — collision checks disabled")

	# Listen for immobilization changes from StateManager.
	StateManager.player_status_effect_changed.connect(_on_status_effects_changed)

	Log.info(TAG, "Tile_Engine ready")


func _process(delta: float) -> void:
	_update_move_cooldown(delta)
	_process_input()
	_update_scroll(delta)


# ---------------------------------------------------------------------------
# Input processing  (Req 7.1, 7.5)
# ---------------------------------------------------------------------------


## Reads directional keys (arrows + WASD), queues the heading, and attempts
## a move when the cooldown has expired.
func _process_input() -> void:
	if _player_immobilized:
		return

	var heading: int = _read_heading_from_keys()
	if heading >= 0:
		_queued_heading = heading

	# Attempt to consume the queued heading.
	if _queued_heading >= 0 and _move_cooldown_timer <= 0.0 and not _is_moving:
		var h: int = _queued_heading
		_queued_heading = -1
		try_move(h)


## Maps currently-held directional keys to a Heading value.
## Returns -1 when no directional key is pressed.
func _read_heading_from_keys() -> int:
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		return StateManager.Heading.NORTH
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		return StateManager.Heading.SOUTH
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		return StateManager.Heading.WEST
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		return StateManager.Heading.EAST
	return -1


# ---------------------------------------------------------------------------
# Movement logic  (Req 7.2, 7.3, 7.4)
# ---------------------------------------------------------------------------


## Attempts to move the player one tile in [param heading].
## Returns true if the move was accepted.
func try_move(heading: int) -> bool:
	# Cooldown guard (Req 7.2).
	if _move_cooldown_timer > 0.0:
		return false

	if _is_moving:
		return false

	var direction: Vector2i = _heading_to_offset(heading)
	var dest: Vector2i = StateManager.player_position + direction

	# --- Collision check (Req 7.4) ---
	if _world_manager != null:
		var flags: int = _world_manager.get_collision_flags(dest.x, dest.y)
		if _is_blocked_by_flags(flags, heading):
			Log.debug(TAG, "Tile (%d, %d) blocked by collision flags" % [dest.x, dest.y])
			return false

	# --- Occupancy check: non-dead, non-invisible characters (Req 7.4) ---
	# TODO: Query Character_Renderer for occupancy when implemented.

	# Accept the move — update state through StateManager.
	StateManager.move_player(heading as StateManager.Heading)

	# Start visual scroll (Req 7.3).
	_begin_scroll(StateManager.player_position - direction, StateManager.player_position)

	# Reset cooldown (Req 7.2).
	_move_cooldown_timer = MOVE_INTERVAL

	movement_requested.emit(heading)
	Log.debug(TAG, "Move accepted — heading %s to (%d, %d)" % [
		StateManager.Heading.keys()[heading], dest.x, dest.y
	])
	return true


## Returns true if the collision [param flags] bitmask blocks entry from
## [param heading].  Bit layout: 0=N, 1=E, 2=S, 3=W.
## We check the *opposite* direction — e.g. moving North means we enter from
## the South side, so we check bit 2 (South).
func _is_blocked_by_flags(flags: int, heading: int) -> bool:
	if flags == 0:
		return false
	# Full block — all bits set.
	if flags == 0xF:
		return true
	match heading:
		StateManager.Heading.NORTH:
			return (flags & (1 << 2)) != 0  # blocked from south
		StateManager.Heading.EAST:
			return (flags & (1 << 3)) != 0  # blocked from west
		StateManager.Heading.SOUTH:
			return (flags & (1 << 0)) != 0  # blocked from north
		StateManager.Heading.WEST:
			return (flags & (1 << 1)) != 0  # blocked from east
	return false


# ---------------------------------------------------------------------------
# Smooth scrolling  (Req 7.3)
# ---------------------------------------------------------------------------


## Kicks off the visual interpolation from [param from_tile] to [param to_tile].
func _begin_scroll(from_tile: Vector2i, to_tile: Vector2i) -> void:
	_scroll_from = tile_to_world(from_tile)
	_scroll_to = tile_to_world(to_tile)
	_move_progress = 0.0
	_is_moving = true


## Advances the scroll interpolation each frame.
func _update_scroll(delta: float) -> void:
	if not _is_moving:
		return

	_move_progress += delta / SCROLL_DURATION
	if _move_progress >= 1.0:
		_move_progress = 1.0
		_is_moving = false
		movement_completed.emit(StateManager.player_position)

	# The actual visual position is consumed by the camera / character renderer
	# via get_visual_position().


## Returns the interpolated world-space position of the player during a scroll.
## Other systems (camera, character renderer) should use this for smooth visuals.
func get_visual_position() -> Vector3:
	if _is_moving:
		return _scroll_from.lerp(_scroll_to, _move_progress)
	return tile_to_world(StateManager.player_position)


# ---------------------------------------------------------------------------
# Cooldown
# ---------------------------------------------------------------------------


## Ticks down the movement cooldown timer.
func _update_move_cooldown(delta: float) -> void:
	if _move_cooldown_timer > 0.0:
		_move_cooldown_timer -= delta
		if _move_cooldown_timer < 0.0:
			_move_cooldown_timer = 0.0


# ---------------------------------------------------------------------------
# Coordinate conversion
# ---------------------------------------------------------------------------


## Converts a tile coordinate to a world-space position (center of tile).
func tile_to_world(tile_pos: Vector2i) -> Vector3:
	return Vector3(
		tile_pos.x * TILE_SIZE + TILE_SIZE * 0.5,
		0.0,
		tile_pos.y * TILE_SIZE + TILE_SIZE * 0.5
	)


## Converts a world-space position to the nearest tile coordinate.
func world_to_tile(world_pos: Vector3) -> Vector2i:
	return Vector2i(
		int(floor(world_pos.x / TILE_SIZE)),
		int(floor(world_pos.z / TILE_SIZE))
	)


# ---------------------------------------------------------------------------
# Immobilization  (Req 7.6)
# ---------------------------------------------------------------------------


## Called when the player's status effects change. Sets the immobilization
## flag if any effect has type "paralyze" or "immobilize".
func _on_status_effects_changed(effects: Array) -> void:
	_player_immobilized = false
	for effect in effects:
		if effect is Dictionary:
			var etype: String = effect.get("type", "")
			if etype == "paralyze" or etype == "immobilize":
				_player_immobilized = true
				Log.info(TAG, "Player immobilized by '%s'" % etype)
				return
	if not _player_immobilized:
		Log.debug(TAG, "Player movement restored")


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


## Converts a Heading enum value to a Vector2i tile offset.
func _heading_to_offset(heading: int) -> Vector2i:
	match heading:
		StateManager.Heading.NORTH:
			return Vector2i(0, -1)
		StateManager.Heading.EAST:
			return Vector2i(1, 0)
		StateManager.Heading.SOUTH:
			return Vector2i(0, 1)
		StateManager.Heading.WEST:
			return Vector2i(-1, 0)
	return Vector2i.ZERO
