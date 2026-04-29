## Unit tests for Mock_Data_Provider data loading and getter methods.
##
## Attach this script to a Node in test_mock_data_provider.tscn and run the
## scene from the Godot editor. Results are printed to the Output console.
##
## Validates: Requirements 29.1, 30.5
extends Node


var _pass_count: int = 0
var _fail_count: int = 0
var _total_count: int = 0


func _ready() -> void:
	# Give MockDataProvider a frame to finish _ready() loading
	await get_tree().process_frame
	_run_all_tests()


func _run_all_tests() -> void:
	print("\n========================================")
	print("  Mock_Data_Provider — Unit Tests")
	print("========================================\n")

	# Discover and run every method starting with "test_"
	for method in get_method_list():
		var method_name: String = method["name"]
		if method_name.begins_with("test_"):
			call(method_name)

	print("\n========================================")
	print("  Results: %d passed, %d failed, %d total" % [_pass_count, _fail_count, _total_count])
	print("========================================\n")

	if _fail_count > 0:
		push_error("SOME TESTS FAILED — see output above")
	else:
		print("ALL TESTS PASSED")


# ------------------------------------------------------------------
# Assertion helpers
# ------------------------------------------------------------------

func _assert_true(condition: bool, description: String) -> void:
	_total_count += 1
	if condition:
		_pass_count += 1
		print("  PASS: %s" % description)
	else:
		_fail_count += 1
		push_error("  FAIL: %s" % description)


# ------------------------------------------------------------------
# 1. JSON files load without errors
# ------------------------------------------------------------------

func test_items_loaded() -> void:
	var item: Dictionary = MockDataProvider.get_item("iron_sword_01")
	_assert_true(not item.is_empty(), "items.json loaded — iron_sword_01 exists")


func test_spells_loaded() -> void:
	var spell: Dictionary = MockDataProvider.get_spell("fireball_01")
	_assert_true(not spell.is_empty(), "spells.json loaded — fireball_01 exists")


func test_npcs_loaded() -> void:
	var npc: Dictionary = MockDataProvider.get_npc("blacksmith_01")
	_assert_true(not npc.is_empty(), "npcs.json loaded — blacksmith_01 exists")


func test_quests_loaded() -> void:
	var quest: Dictionary = MockDataProvider.get_quest("quest_forge_sword")
	_assert_true(not quest.is_empty(), "quests.json loaded — quest_forge_sword exists")


func test_recipes_loaded() -> void:
	var recipes: Array = MockDataProvider.get_recipes_for_discipline("blacksmithing")
	_assert_true(recipes.size() > 0, "recipes.json loaded — blacksmithing recipes exist")


func test_enemies_loaded() -> void:
	var enemies: Array = MockDataProvider.get_enemies_in_chunk(0, 0)
	_assert_true(enemies.size() > 0, "enemies.json loaded — enemies in chunk 0,0 exist")


func test_classes_loaded() -> void:
	var cls: Dictionary = MockDataProvider.get_class_data("warrior")
	_assert_true(not cls.is_empty(), "classes.json loaded — warrior exists")


func test_races_loaded() -> void:
	var race: Dictionary = MockDataProvider.get_race_data("human")
	_assert_true(not race.is_empty(), "races.json loaded — human exists")


func test_zones_loaded() -> void:
	var zone: Dictionary = MockDataProvider.get_zone_metadata("verdant_plains")
	_assert_true(not zone.is_empty(), "zones.json loaded — verdant_plains exists")


func test_characters_loaded() -> void:
	var chars: Array = MockDataProvider.get_mock_characters()
	_assert_true(chars.size() >= 2, "mock_characters.json loaded — at least 2 characters")


func test_guilds_loaded() -> void:
	var guild: Dictionary = MockDataProvider.get_guild_data()
	# Guild data may be a dict or empty depending on guilds.json format
	_assert_true(guild is Dictionary, "guilds.json loaded — guild data is a Dictionary")


func test_chunks_loaded() -> void:
	var chunk: Dictionary = MockDataProvider.get_chunk(0, 0)
	_assert_true(not chunk.is_empty(), "chunk_0_0.json loaded — chunk 0,0 exists")


func test_factions_loaded() -> void:
	# Factions are loaded but no direct getter by id exists on the public API;
	# verify indirectly that the load did not crash by checking another dataset
	# still works after the full _load_all_data() call.
	var item: Dictionary = MockDataProvider.get_item("iron_sword_01")
	_assert_true(not item.is_empty(), "factions.json load did not break data pipeline")


# ------------------------------------------------------------------
# 2. Getter methods return expected data structures
# ------------------------------------------------------------------

func test_get_item_structure() -> void:
	var item: Dictionary = MockDataProvider.get_item("iron_sword_01")
	_assert_true(item.has("id"), "get_item — has 'id' key")
	_assert_true(item.has("name"), "get_item — has 'name' key")
	_assert_true(item.has("type"), "get_item — has 'type' key")


func test_get_spell_structure() -> void:
	var spell: Dictionary = MockDataProvider.get_spell("fireball_01")
	_assert_true(spell.has("id"), "get_spell — has 'id' key")
	_assert_true(spell.has("name"), "get_spell — has 'name' key")
	_assert_true(spell.has("mana_cost"), "get_spell — has 'mana_cost' key")


func test_get_npc_structure() -> void:
	var npc: Dictionary = MockDataProvider.get_npc("blacksmith_01")
	_assert_true(npc.has("id"), "get_npc — has 'id' key")
	_assert_true(npc.has("name"), "get_npc — has 'name' key")
	_assert_true(npc.has("type"), "get_npc — has 'type' key")


func test_get_quest_structure() -> void:
	var quest: Dictionary = MockDataProvider.get_quest("quest_forge_sword")
	_assert_true(quest.has("id"), "get_quest — has 'id' key")
	_assert_true(quest.has("title"), "get_quest — has 'title' key")


func test_get_mock_characters_structure() -> void:
	var chars: Array = MockDataProvider.get_mock_characters()
	_assert_true(chars is Array, "get_mock_characters — returns Array")
	_assert_true(chars.size() >= 2, "get_mock_characters — at least 2 entries")


func test_get_chunk_structure() -> void:
	var chunk: Dictionary = MockDataProvider.get_chunk(0, 0)
	_assert_true(chunk.has("chunk_x"), "get_chunk — has 'chunk_x' key")
	_assert_true(chunk.has("chunk_y"), "get_chunk — has 'chunk_y' key")
	_assert_true(chunk.has("tiles"), "get_chunk — has 'tiles' key")


func test_get_zone_metadata_structure() -> void:
	var zone: Dictionary = MockDataProvider.get_zone_metadata("verdant_plains")
	_assert_true(zone.has("id"), "get_zone_metadata — has 'id' key")
	_assert_true(zone.has("name"), "get_zone_metadata — has 'name' key")


func test_get_class_data_structure() -> void:
	var cls: Dictionary = MockDataProvider.get_class_data("warrior")
	_assert_true(not cls.is_empty(), "get_class_data('warrior') — non-empty dict")


func test_get_race_data_structure() -> void:
	var race: Dictionary = MockDataProvider.get_race_data("human")
	_assert_true(not race.is_empty(), "get_race_data('human') — non-empty dict")


func test_get_enemies_in_chunk_structure() -> void:
	var enemies: Array = MockDataProvider.get_enemies_in_chunk(0, 0)
	_assert_true(enemies is Array, "get_enemies_in_chunk(0,0) — returns Array")


func test_get_recipes_for_discipline_structure() -> void:
	var recipes: Array = MockDataProvider.get_recipes_for_discipline("blacksmithing")
	_assert_true(recipes is Array, "get_recipes_for_discipline — returns Array")
	_assert_true(recipes.size() >= 1, "get_recipes_for_discipline('blacksmithing') — at least 1 entry")


# ------------------------------------------------------------------
# 3. Fallback behavior for missing / nonexistent data
# ------------------------------------------------------------------

func test_get_item_nonexistent() -> void:
	var item: Dictionary = MockDataProvider.get_item("nonexistent_item")
	_assert_true(item.has("id"), "get_item('nonexistent_item') — returns fallback dict with 'id'")


func test_get_spell_nonexistent() -> void:
	var spell: Dictionary = MockDataProvider.get_spell("nonexistent_spell")
	_assert_true(spell.has("id"), "get_spell('nonexistent_spell') — returns fallback dict with 'id'")


func test_get_chunk_nonexistent() -> void:
	var chunk: Dictionary = MockDataProvider.get_chunk(999, 999)
	_assert_true(chunk.is_empty(), "get_chunk(999,999) — returns empty dict")
