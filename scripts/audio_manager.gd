## Audio manager autoload singleton.
##
## Handles music playback with crossfade, SFX pooling, ambient positional audio,
## and per-category volume control.
##
## Usage:
##   AudioManager.play_music("res://audio/music/track.ogg")
##   AudioManager.play_sfx("res://audio/sfx/hit.ogg")
##   AudioManager.play_footstep("grass")
##   AudioManager.play_ambient("campfire_01", "res://audio/ambient/fire.ogg", Vector3(10, 0, 5))
##   AudioManager.stop_ambient("campfire_01")
##   AudioManager.set_volume("music", 0.8)
extends Node

const TAG := "AudioManager"
const SFX_POOL_SIZE := 8

## Crossfade duration default in seconds.
const DEFAULT_CROSSFADE := 2.0

## Minimum dB value treated as silence.
const SILENCE_DB := -80.0

## Footstep sound path mapping by terrain type.
const FOOTSTEP_PATHS: Dictionary = {
	"grass": "res://audio/sfx/footstep_grass.ogg",
	"stone": "res://audio/sfx/footstep_stone.ogg",
	"sand": "res://audio/sfx/footstep_sand.ogg",
	"snow": "res://audio/sfx/footstep_snow.ogg",
	"wood": "res://audio/sfx/footstep_wood.ogg",
	"water": "res://audio/sfx/footstep_water.ogg",
	"dungeon": "res://audio/sfx/footstep_dungeon.ogg",
}

## Default footstep path when terrain type is unknown.
const FOOTSTEP_DEFAULT := "res://audio/sfx/footstep_stone.ogg"

## Volume levels per category (0.0 to 1.0).
var music_volume: float = 1.0
var sfx_volume: float = 1.0
var footstep_volume: float = 1.0
var ambient_volume: float = 1.0

## Music crossfade players.
var _music_player_a: AudioStreamPlayer
var _music_player_b: AudioStreamPlayer
var _active_music_player: AudioStreamPlayer

## Currently playing music track path.
var _current_music_path: String = ""

## Pool of AudioStreamPlayer nodes for concurrent SFX playback.
var _sfx_pool: Array[AudioStreamPlayer] = []

## Active ambient sound sources. Maps source_id -> AudioStreamPlayer3D.
var _ambient_players: Dictionary = {}

## Reference to the active crossfade tween (so we can kill it on rapid changes).
var _crossfade_tween: Tween = null


func _ready() -> void:
	_music_player_a = AudioStreamPlayer.new()
	_music_player_a.name = "MusicPlayerA"
	_music_player_a.bus = "Master"
	add_child(_music_player_a)

	_music_player_b = AudioStreamPlayer.new()
	_music_player_b.name = "MusicPlayerB"
	_music_player_b.bus = "Master"
	add_child(_music_player_b)

	_active_music_player = _music_player_a

	for i in range(SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "SFXPlayer_%d" % i
		player.bus = "Master"
		add_child(player)
		_sfx_pool.append(player)

	# Connect to StateManager signals for automatic audio responses.
	if StateManager:
		StateManager.zone_changed.connect(_on_zone_changed)
		StateManager.player_position_changed.connect(_on_player_position_changed)

	Log.info(TAG, "Audio_Manager ready — %d SFX pool players created" % SFX_POOL_SIZE)


# ---------------------------------------------------------------------------
# Music
# ---------------------------------------------------------------------------


## Plays a music track with crossfade from the current track.
## [param track_path] Resource path to the audio stream.
## [param crossfade_duration] Duration in seconds for the crossfade transition.
func play_music(track_path: String, crossfade_duration: float = DEFAULT_CROSSFADE) -> void:
	if track_path == _current_music_path and _active_music_player.playing:
		Log.debug(TAG, "Music track already playing: %s" % track_path)
		return

	if track_path.is_empty():
		Log.warning(TAG, "play_music called with empty track path")
		return

	# Determine which player is the new one (swap A/B).
	var old_player := _active_music_player
	var new_player := _music_player_b if _active_music_player == _music_player_a else _music_player_a

	# Load the stream — use a placeholder if the file doesn't exist.
	var stream: AudioStream = _load_audio_stream(track_path)
	if stream == null:
		Log.warning(TAG, "Could not load music track: %s — playing silence" % track_path)
		_current_music_path = track_path
		return

	new_player.stream = stream
	new_player.volume_db = SILENCE_DB
	new_player.play()

	# Kill any existing crossfade tween.
	if _crossfade_tween and _crossfade_tween.is_valid():
		_crossfade_tween.kill()

	# Create crossfade tween.
	var target_db := _volume_to_db(music_volume)
	_crossfade_tween = create_tween()
	_crossfade_tween.set_parallel(true)
	_crossfade_tween.tween_property(new_player, "volume_db", target_db, crossfade_duration)
	_crossfade_tween.tween_property(old_player, "volume_db", SILENCE_DB, crossfade_duration)
	_crossfade_tween.set_parallel(false)
	_crossfade_tween.tween_callback(old_player.stop)

	_active_music_player = new_player
	_current_music_path = track_path
	Log.info(TAG, "Crossfading to music: %s (%.1fs)" % [track_path, crossfade_duration])


# ---------------------------------------------------------------------------
# SFX
# ---------------------------------------------------------------------------


## Plays a sound effect. Optionally positional in 3D space.
## [param sfx_path] Resource path to the sound effect.
## [param position] World position for positional audio (ignored when [param positional] is false).
## [param positional] If true, pans/attenuates based on distance from listener.
func play_sfx(sfx_path: String, position: Vector3 = Vector3.ZERO, positional: bool = false) -> void:
	if sfx_path.is_empty():
		return

	var stream: AudioStream = _load_audio_stream(sfx_path)
	if stream == null:
		Log.debug(TAG, "SFX not found: %s — skipping" % sfx_path)
		return

	if positional:
		# Create a temporary AudioStreamPlayer3D for positional playback.
		var player_3d := AudioStreamPlayer3D.new()
		player_3d.stream = stream
		player_3d.volume_db = _volume_to_db(sfx_volume)
		player_3d.max_distance = 50.0
		player_3d.bus = "Master"
		add_child(player_3d)
		player_3d.global_position = position
		player_3d.play()
		# Auto-remove when finished.
		player_3d.finished.connect(player_3d.queue_free)
		Log.debug(TAG, "Playing positional SFX: %s at %s" % [sfx_path, str(position)])
	else:
		# Use the SFX pool for non-positional playback.
		var player := _get_available_sfx_player()
		if player == null:
			Log.debug(TAG, "SFX pool exhausted — skipping: %s" % sfx_path)
			return
		player.stream = stream
		player.volume_db = _volume_to_db(sfx_volume)
		player.play()
		Log.debug(TAG, "Playing SFX: %s" % sfx_path)


# ---------------------------------------------------------------------------
# Footsteps
# ---------------------------------------------------------------------------


## Plays a footstep sound matching the given terrain type.
## [param terrain_type] One of: grass, stone, sand, snow, wood, water, dungeon.
func play_footstep(terrain_type: String) -> void:
	var path: String = FOOTSTEP_PATHS.get(terrain_type, FOOTSTEP_DEFAULT)
	var stream: AudioStream = _load_audio_stream(path)
	if stream == null:
		Log.debug(TAG, "Footstep audio not found for terrain '%s' — skipping" % terrain_type)
		return

	var player := _get_available_sfx_player()
	if player == null:
		return
	player.stream = stream
	player.volume_db = _volume_to_db(footstep_volume)
	# Add slight pitch variation for natural feel.
	player.pitch_scale = randf_range(0.9, 1.1)
	player.play()
	Log.debug(TAG, "Footstep: terrain=%s" % terrain_type)


# ---------------------------------------------------------------------------
# Ambient
# ---------------------------------------------------------------------------


## Starts a looping ambient sound at a world position.
## [param source_id] Unique identifier for this ambient source.
## [param sound_path] Resource path to the ambient audio stream.
## [param world_position] 3D position in the world for positional falloff.
func play_ambient(source_id: String, sound_path: String, world_position: Vector3) -> void:
	# If this source is already playing, just update its position.
	if source_id in _ambient_players:
		var existing: AudioStreamPlayer3D = _ambient_players[source_id]
		existing.global_position = world_position
		Log.debug(TAG, "Updated ambient position: %s -> %s" % [source_id, str(world_position)])
		return

	var stream: AudioStream = _load_audio_stream(sound_path)
	if stream == null:
		Log.warning(TAG, "Ambient audio not found: %s — skipping" % sound_path)
		return

	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.volume_db = _volume_to_db(ambient_volume)
	player.max_distance = 40.0
	player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	player.bus = "Master"
	player.autoplay = false
	add_child(player)
	player.global_position = world_position

	# Loop: Godot 4 loops via the stream resource, but for safety reconnect on finish.
	player.finished.connect(_on_ambient_finished.bind(source_id))
	player.play()

	_ambient_players[source_id] = player
	Log.info(TAG, "Started ambient: %s at %s" % [source_id, str(world_position)])


## Stops and removes an ambient sound source.
## [param source_id] The identifier used when the ambient source was started.
func stop_ambient(source_id: String) -> void:
	if source_id not in _ambient_players:
		Log.debug(TAG, "stop_ambient: source '%s' not active" % source_id)
		return

	var player: AudioStreamPlayer3D = _ambient_players[source_id]
	player.stop()
	player.queue_free()
	_ambient_players.erase(source_id)
	Log.info(TAG, "Stopped ambient: %s" % source_id)


# ---------------------------------------------------------------------------
# Volume
# ---------------------------------------------------------------------------


## Sets the volume for a given audio category.
## [param category] One of: "music", "sfx", "footstep", "ambient".
## [param value] Volume level from 0.0 (silent) to 1.0 (full).
func set_volume(category: String, value: float) -> void:
	var clamped := clampf(value, 0.0, 1.0)
	match category:
		"music":
			music_volume = clamped
			# Apply immediately to the active music player.
			if _active_music_player and _active_music_player.playing:
				_active_music_player.volume_db = _volume_to_db(clamped)
		"sfx":
			sfx_volume = clamped
		"footstep":
			footstep_volume = clamped
		"ambient":
			ambient_volume = clamped
			# Apply to all active ambient players.
			for player in _ambient_players.values():
				if player is AudioStreamPlayer3D:
					player.volume_db = _volume_to_db(clamped)
		_:
			Log.warning(TAG, "Unknown volume category: %s" % category)
			return
	Log.info(TAG, "Volume '%s' set to %.2f" % [category, clamped])


# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------


## Called when the player enters a new zone — crossfade to zone music.
func _on_zone_changed(zone_data: Dictionary) -> void:
	var music_track: String = zone_data.get("music_track", "")
	if music_track.is_empty():
		Log.debug(TAG, "Zone has no music track defined")
		return
	play_music(music_track)

	# Handle zone ambient sound.
	var ambient_sound: String = zone_data.get("ambient_sound", "")
	var zone_id: String = zone_data.get("zone_id", zone_data.get("id", "zone"))
	var ambient_key := "zone_%s" % zone_id

	# Stop previous zone ambient.
	for key in _ambient_players.keys():
		if key.begins_with("zone_"):
			stop_ambient(key)

	if not ambient_sound.is_empty():
		# Place zone ambient at the player's approximate position.
		var px: int = StateManager.player_position.x
		var py: int = StateManager.player_position.y
		play_ambient(ambient_key, ambient_sound, Vector3(px * 32.0, 0.0, py * 32.0))


## Called when the player moves — play footstep sounds.
func _on_player_position_changed(tile_x: int, tile_y: int) -> void:
	# Determine terrain type from the world manager if available.
	var terrain_type := "stone"  # default
	var world_manager: Node = _get_world_manager()
	if world_manager and world_manager.has_method("get_tile_data"):
		var tile_data: Dictionary = world_manager.get_tile_data(tile_x, tile_y)
		if not tile_data.is_empty():
			# Try to infer terrain from ground graphic id.
			var ground_layer: Dictionary = tile_data.get("layers", {}).get("ground", {})
			var graphic_id: String = ground_layer.get("graphic_id", "")
			terrain_type = _graphic_to_terrain(graphic_id)
	play_footstep(terrain_type)


## Re-loops ambient sounds when they finish (for non-looping streams).
func _on_ambient_finished(source_id: String) -> void:
	if source_id in _ambient_players:
		var player: AudioStreamPlayer3D = _ambient_players[source_id]
		if is_instance_valid(player):
			player.play()


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


## Converts a linear volume (0.0–1.0) to decibels.
func _volume_to_db(linear: float) -> float:
	if linear <= 0.0:
		return SILENCE_DB
	return linear_to_db(linear)


## Returns the first non-playing SFX pool player, or null if all are busy.
func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_pool:
		if not player.playing:
			player.pitch_scale = 1.0  # reset pitch
			return player
	return null


## Attempts to load an audio stream from the given path.
## Returns null if the file doesn't exist (graceful fallback).
func _load_audio_stream(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		return null
	var resource: Resource = load(path)
	if resource is AudioStream:
		return resource
	return null


## Tries to find the World_Manager node in the scene tree.
func _get_world_manager() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	var root := tree.current_scene
	if root == null:
		return null
	if root.has_node("World_Manager"):
		return root.get_node("World_Manager")
	# Try gameplay scene path.
	var gameplay := root.get_node_or_null("GameplayScene")
	if gameplay and gameplay.has_node("World_Manager"):
		return gameplay.get_node("World_Manager")
	return null


## Maps a ground graphic ID to a terrain type string.
func _graphic_to_terrain(graphic_id: String) -> String:
	if graphic_id.is_empty():
		return "stone"
	if "grass" in graphic_id:
		return "grass"
	if "sand" in graphic_id or "desert" in graphic_id:
		return "sand"
	if "snow" in graphic_id or "ice" in graphic_id:
		return "snow"
	if "wood" in graphic_id or "plank" in graphic_id:
		return "wood"
	if "water" in graphic_id or "river" in graphic_id:
		return "water"
	if "dungeon" in graphic_id or "cave" in graphic_id:
		return "dungeon"
	if "stone" in graphic_id or "cobble" in graphic_id or "brick" in graphic_id:
		return "stone"
	return "stone"
