## Reputation_System — tracks citizen/criminal alignment, computes name colors,
## tracks PvP statistics, and responds to reputation change events.
##
## Lives as a child of GameplayScene.
## Requirements: 19.1, 19.2, 19.3, 19.5
extends Node


const TAG := "ReputationSystem"

## Alignment thresholds. Reputation is an integer from -1000 to 1000.
const CRIMINAL_THRESHOLD: int = -100
const CITIZEN_THRESHOLD: int = 0

## Name color mapping by alignment.
const ALIGNMENT_COLORS: Dictionary = {
	"citizen": Color(0.2, 0.9, 0.2),
	"criminal": Color(0.9, 0.2, 0.2),
	"new": Color(0.9, 0.9, 0.2),
	"gm": Color(0.2, 0.9, 0.9),
}


# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted when the player's alignment changes.
signal alignment_changed(new_alignment: String)

## Emitted when PvP stats are updated.
signal pvp_stats_updated(stats: Dictionary)

## Emitted when reputation value changes.
signal reputation_changed(new_value: int)


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

## Current reputation value (-1000 to 1000).
var _reputation_value: int = 0

## Current alignment string.
var _alignment: String = "citizen"

## PvP statistics.
var _pvp_stats: Dictionary = {
	"kills": 0,
	"deaths": 0,
	"assists": 0,
	"kill_streak": 0,
	"best_streak": 0,
}


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------


func _ready() -> void:
	_load_from_state()
	# Connect to combat events for PvP tracking.
	StateManager.character_died.connect(_on_character_died)
	StateManager.player_died.connect(_on_player_died)
	Log.info(TAG, "Reputation_System ready — alignment: %s, rep: %d" % [_alignment, _reputation_value])


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------


## Returns the current alignment string ("citizen", "criminal", "new").
func get_alignment() -> String:
	return _alignment


## Returns the current reputation value.
func get_reputation_value() -> int:
	return _reputation_value


## Returns the name color for the current alignment.
func get_name_color() -> Color:
	return ALIGNMENT_COLORS.get(_alignment, Color.WHITE)


## Returns the name color for a given alignment string.
func get_color_for_alignment(alignment: String) -> Color:
	return ALIGNMENT_COLORS.get(alignment, Color.WHITE)


## Returns the PvP statistics dictionary.
func get_pvp_stats() -> Dictionary:
	return _pvp_stats


## Modifies the reputation value by [param delta] and recalculates alignment.
func change_reputation(delta: int) -> void:
	var old_alignment := _alignment
	_reputation_value = clampi(_reputation_value + delta, -1000, 1000)
	_alignment = _compute_alignment(_reputation_value)

	StateManager.player_reputation["alignment"] = _alignment
	StateManager.player_reputation["value"] = _reputation_value
	reputation_changed.emit(_reputation_value)

	if _alignment != old_alignment:
		alignment_changed.emit(_alignment)
		Log.info(TAG, "Alignment changed: %s -> %s (rep: %d)" % [old_alignment, _alignment, _reputation_value])


## Records a PvP kill.
func record_kill() -> void:
	_pvp_stats["kills"] += 1
	_pvp_stats["kill_streak"] += 1
	if _pvp_stats["kill_streak"] > _pvp_stats["best_streak"]:
		_pvp_stats["best_streak"] = _pvp_stats["kill_streak"]
	StateManager.player_reputation["pvp_stats"] = _pvp_stats
	pvp_stats_updated.emit(_pvp_stats)


## Records a PvP death.
func record_death() -> void:
	_pvp_stats["deaths"] += 1
	_pvp_stats["kill_streak"] = 0
	StateManager.player_reputation["pvp_stats"] = _pvp_stats
	pvp_stats_updated.emit(_pvp_stats)


# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------


func _on_character_died(char_id: String) -> void:
	var player_id: String = StateManager.player_data.get("id", "player")
	if char_id != player_id:
		# Player killed something — could be PvP.
		record_kill()
		# Criminal reputation penalty for killing citizens (mock).
		change_reputation(-10)


func _on_player_died() -> void:
	record_death()


# ---------------------------------------------------------------------------
# Internal
# ---------------------------------------------------------------------------


## Loads reputation data from StateManager.
func _load_from_state() -> void:
	var rep_data: Dictionary = StateManager.player_reputation
	_alignment = rep_data.get("alignment", "citizen")
	_reputation_value = rep_data.get("value", 0)
	_pvp_stats = rep_data.get("pvp_stats", _pvp_stats)


## Computes alignment string from a reputation value.
func _compute_alignment(value: int) -> String:
	if value < CRIMINAL_THRESHOLD:
		return "criminal"
	elif value >= CITIZEN_THRESHOLD:
		return "citizen"
	else:
		return "new"
