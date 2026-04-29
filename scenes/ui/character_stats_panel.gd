## Character Stats Panel — shows faction info, PvP statistics, and reputation.
##
## Starts hidden. Toggle via UI_Manager.
## Requirements: 19.4, 19.5
extends PanelContainer


const TAG := "CharStatsPanel"


@onready var name_label: Label = $VBox/NameLabel
@onready var faction_label: Label = $VBox/FactionLabel
@onready var reputation_label: Label = $VBox/ReputationLabel
@onready var alignment_label: Label = $VBox/AlignmentLabel
@onready var kills_label: Label = $VBox/PvPSection/KillsLabel
@onready var deaths_label: Label = $VBox/PvPSection/DeathsLabel
@onready var streak_label: Label = $VBox/PvPSection/StreakLabel


func _ready() -> void:
	visible = false
	Log.info(TAG, "CharacterStatsPanel ready")


func _on_visibility_changed() -> void:
	if visible:
		_refresh()


func _refresh() -> void:
	# Player info.
	name_label.text = StateManager.player_data.get("name", "Unknown")

	# Faction info.
	var rep_data: Dictionary = StateManager.player_reputation
	var faction_name: String = rep_data.get("faction", "None")
	faction_label.text = "Faction: %s" % (faction_name if faction_name != "" else "None")

	# Reputation.
	var rep_system: Node = _get_reputation_system()
	if rep_system:
		alignment_label.text = "Alignment: %s" % rep_system.get_alignment().capitalize()
		reputation_label.text = "Reputation: %d" % rep_system.get_reputation_value()
		var color: Color = rep_system.get_name_color()
		alignment_label.add_theme_color_override("font_color", color)

		# PvP stats.
		var pvp: Dictionary = rep_system.get_pvp_stats()
		kills_label.text = "Kills: %d" % pvp.get("kills", 0)
		deaths_label.text = "Deaths: %d" % pvp.get("deaths", 0)
		streak_label.text = "Best Streak: %d" % pvp.get("best_streak", 0)
	else:
		alignment_label.text = "Alignment: %s" % rep_data.get("alignment", "citizen").capitalize()
		reputation_label.text = "Reputation: N/A"
		kills_label.text = "Kills: 0"
		deaths_label.text = "Deaths: 0"
		streak_label.text = "Best Streak: 0"


func _get_reputation_system() -> Node:
	var gameplay := get_tree().current_scene
	if gameplay and gameplay.has_node("ReputationSystem"):
		return gameplay.get_node("ReputationSystem")
	return null
