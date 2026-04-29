## Per-instance script attached to each character scene root (CharacterBody3D).
##
## Holds character-specific data (char_id, display name, reputation, etc.)
## and provides helpers for the Character_Renderer to manipulate this instance.
## Requirements: 5.1, 5.2, 5.4, 6.6
extends CharacterBody3D


const TAG := "Character"

## Unique identifier for this character instance.
var char_id: String = ""

## Display name shown in the overhead label.
var display_name: String = ""

## Guild tag shown after the name (e.g. "<TAG>").
var guild_tag: String = ""

## Reputation alignment — drives name color (citizen, criminal, new, gm).
var reputation: String = "citizen"

## Current / max HP for the overhead bar.
var current_hp: int = 100
var max_hp: int = 100

## Shield points for the overhead shield bar segment.
var shield_points: int = 0
var max_shield: int = 0

## Whether this character is currently visible.
var is_visible_character: bool = true

## Whether this character is a ghost (dead).
var is_ghost: bool = false

## Whether this character is mounted.
var is_mounted: bool = false

## Current mount type if mounted.
var mount_type: String = ""

## Whether this character is in a boat.
var is_in_boat: bool = false

## Active aura effects keyed by slot name.
var aura_effects: Dictionary = {}

## Stored original material for model swaps.
var _original_material: Material = null


func _ready() -> void:
	# Store the original material from CharacterModel for later restoration.
	var model := get_node_or_null("CharacterModel")
	if model and model is MeshInstance3D:
		_original_material = model.material_override
