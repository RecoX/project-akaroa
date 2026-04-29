## Skill_System — loads skill values (0-100) and 5 core attributes from
## MockDataProvider. Supports buff/debuff indicators on skills.
##
## Lives as a child of GameplayScene.
## Requirements: 22.1, 22.3
extends Node


const TAG := "SkillSystem"

## Core attribute names.
const CORE_ATTRIBUTES: Array = ["strength", "dexterity", "intelligence", "constitution", "charisma"]

## Skill categories and their skills.
const SKILL_CATEGORIES: Dictionary = {
	"combat": ["swordsmanship", "archery", "defense", "tactics", "parry"],
	"magic": ["fire_magic", "ice_magic", "healing", "arcane", "enchanting"],
	"trade": ["blacksmithing", "carpentry", "alchemy", "tailoring", "fishing"],
}


# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted when a skill value changes.
signal skill_changed(skill_name: String, new_value: int)

## Emitted when an attribute value changes.
signal attribute_changed(attr_name: String, new_value: int)

## Emitted when a buff/debuff is applied to a skill.
signal skill_buff_changed(skill_name: String, buff_amount: int)


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

## Skill values keyed by skill name (0-100).
var _skills: Dictionary = {}

## Core attribute values keyed by attribute name.
var _attributes: Dictionary = {}

## Active skill buffs/debuffs. Maps skill_name -> buff_amount (can be negative).
var _skill_buffs: Dictionary = {}


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------


func _ready() -> void:
	_load_skills()
	_load_attributes()
	Log.info(TAG, "Skill_System ready — %d skills, %d attributes" % [_skills.size(), _attributes.size()])


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------


## Returns the effective value of a skill (base + buff).
func get_skill_value(skill_name: String) -> int:
	var base: int = _skills.get(skill_name, 0)
	var buff: int = _skill_buffs.get(skill_name, 0)
	return clampi(base + buff, 0, 100)


## Returns the base (unbuffed) value of a skill.
func get_skill_base(skill_name: String) -> int:
	return _skills.get(skill_name, 0)


## Returns all skills as a dictionary.
func get_all_skills() -> Dictionary:
	return _skills


## Returns skills for a given category.
func get_skills_for_category(category: String) -> Dictionary:
	var result: Dictionary = {}
	var skill_names: Array = SKILL_CATEGORIES.get(category, [])
	for skill_name in skill_names:
		result[skill_name] = get_skill_value(skill_name)
	return result


## Returns the value of a core attribute.
func get_attribute(attr_name: String) -> int:
	return _attributes.get(attr_name, 10)


## Returns all core attributes.
func get_all_attributes() -> Dictionary:
	return _attributes


## Applies a buff or debuff to a skill.
func apply_skill_buff(skill_name: String, amount: int) -> void:
	_skill_buffs[skill_name] = _skill_buffs.get(skill_name, 0) + amount
	skill_buff_changed.emit(skill_name, _skill_buffs[skill_name])
	Log.info(TAG, "Skill buff on '%s': %+d (total buff: %d)" % [skill_name, amount, _skill_buffs[skill_name]])


## Removes all buffs/debuffs from a skill.
func clear_skill_buff(skill_name: String) -> void:
	_skill_buffs.erase(skill_name)
	skill_buff_changed.emit(skill_name, 0)


## Returns the buff amount on a skill (0 if none).
func get_skill_buff(skill_name: String) -> int:
	return _skill_buffs.get(skill_name, 0)


## Increases a skill value by [param amount]. Used for skill-ups.
func increase_skill(skill_name: String, amount: int = 1) -> void:
	var current: int = _skills.get(skill_name, 0)
	var new_value: int = clampi(current + amount, 0, 100)
	_skills[skill_name] = new_value
	StateManager.player_skills[skill_name] = new_value
	skill_changed.emit(skill_name, new_value)
	Log.info(TAG, "Skill '%s' increased to %d" % [skill_name, new_value])


# ---------------------------------------------------------------------------
# Data loading
# ---------------------------------------------------------------------------


## Loads skill values from StateManager/MockDataProvider.
func _load_skills() -> void:
	_skills = StateManager.player_skills.duplicate()

	# Ensure all known skills have a value.
	for category in SKILL_CATEGORIES.keys():
		for skill_name in SKILL_CATEGORIES[category]:
			if skill_name not in _skills:
				_skills[skill_name] = randi_range(5, 50)

	# Sync back to StateManager.
	StateManager.player_skills = _skills.duplicate()
	Log.info(TAG, "Loaded %d skills" % _skills.size())


## Loads core attributes from player data.
func _load_attributes() -> void:
	var attrs: Dictionary = StateManager.player_data.get("attributes", {})
	for attr_name in CORE_ATTRIBUTES:
		_attributes[attr_name] = attrs.get(attr_name, 10 + randi_range(0, 5))
	Log.info(TAG, "Loaded %d attributes" % _attributes.size())
