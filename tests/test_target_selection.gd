## Property-based tests for target selection via StateManager.
##
## Attach this script to a Node in test_target_selection.tscn and run the
## scene from the Godot editor. Results are printed to the Output console.
##
## Feature: combat-and-world-content
extends Node


const TAG := "TestTargetSelection"
const PBT_ITERATIONS := 150


var _pass_count: int = 0
var _fail_count: int = 0
var _total_count: int = 0


func _ready() -> void:
	await get_tree().process_frame
	_run_all_tests()


func _run_all_tests() -> void:
	print("\n========================================")
	print("  Target Selection — Property-Based Tests")
	print("========================================\n")

	test_target_selection_property()

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
	else:
		_fail_count += 1
		push_error("  FAIL: %s" % description)


func _assert_equal(actual, expected, description: String) -> void:
	_total_count += 1
	if actual == expected:
		_pass_count += 1
	else:
		_fail_count += 1
		push_error("  FAIL: %s — expected %s, got %s" % [description, str(expected), str(actual)])


# ------------------------------------------------------------------
# Property 1: Target selection sets current target
# For any character data (enemy or NPC) with a valid id field,
# calling set_target with that character's data should result in
# StateManager.current_target_id being equal to that character's id,
# and StateManager.current_target_data containing the character's data.
#
# **Validates: Requirements 2.1, 2.2**
# ------------------------------------------------------------------

func test_target_selection_property() -> void:
	print("  Property 1: Target selection sets current target (%d iterations)" % PBT_ITERATIONS)

	var rng := RandomNumberGenerator.new()
	rng.seed = 42  # Deterministic seed for reproducibility

	var all_passed := true
	var reputations := ["citizen", "criminal", "new", "gm"]
	var npc_types := ["shopkeeper", "quest_giver", "banker", "dialogue"]

	for i in range(PBT_ITERATIONS):
		# Generate random character data.
		var is_enemy: bool = rng.randi_range(0, 1) == 0
		var char_id: String
		if is_enemy:
			char_id = "enemy_%d_%d" % [rng.randi_range(0, 999), rng.randi_range(0, 999)]
		else:
			char_id = "npc_%d" % rng.randi_range(0, 999)

		var max_hp: int = rng.randi_range(10, 500)
		var current_hp: int = rng.randi_range(1, max_hp)
		var reputation: String = reputations[rng.randi_range(0, reputations.size() - 1)]

		var char_data: Dictionary = {
			"id": char_id,
			"name": "TestChar_%d" % i,
			"hp": current_hp,
			"max_hp": max_hp,
			"reputation": reputation,
			"position_x": rng.randi_range(-100, 100),
			"position_y": rng.randi_range(-100, 100),
		}

		if not is_enemy:
			char_data["type"] = npc_types[rng.randi_range(0, npc_types.size() - 1)]

		# Call set_target.
		StateManager.set_target(char_id, char_data)

		# Verify current_target_id matches.
		if StateManager.current_target_id != char_id:
			all_passed = false
			push_error("  FAIL iteration %d: current_target_id = '%s', expected '%s'" % [
				i, StateManager.current_target_id, char_id
			])
			break

		# Verify current_target_data contains the character's data.
		if StateManager.current_target_data.get("id", "") != char_id:
			all_passed = false
			push_error("  FAIL iteration %d: current_target_data.id = '%s', expected '%s'" % [
				i, StateManager.current_target_data.get("id", ""), char_id
			])
			break

		if StateManager.current_target_data.get("hp", -1) != current_hp:
			all_passed = false
			push_error("  FAIL iteration %d: current_target_data.hp = %d, expected %d" % [
				i, StateManager.current_target_data.get("hp", -1), current_hp
			])
			break

		if StateManager.current_target_data.get("max_hp", -1) != max_hp:
			all_passed = false
			push_error("  FAIL iteration %d: current_target_data.max_hp = %d, expected %d" % [
				i, StateManager.current_target_data.get("max_hp", -1), max_hp
			])
			break

	_assert_true(all_passed, "Property 1: set_target sets current_target_id and current_target_data for %d random characters" % PBT_ITERATIONS)

	# Verify clear_target resets state.
	StateManager.set_target("test_clear", {"id": "test_clear", "name": "ClearTest"})
	StateManager.clear_target()
	_assert_equal(StateManager.current_target_id, "", "Property 1 edge: clear_target resets current_target_id to empty")
	_assert_equal(StateManager.current_target_data.size(), 0, "Property 1 edge: clear_target resets current_target_data to empty dict")

	# Verify overwriting target works.
	StateManager.set_target("first_target", {"id": "first_target", "name": "First"})
	StateManager.set_target("second_target", {"id": "second_target", "name": "Second"})
	_assert_equal(StateManager.current_target_id, "second_target", "Property 1 edge: setting new target overwrites previous")
	_assert_equal(StateManager.current_target_data.get("name", ""), "Second", "Property 1 edge: new target data overwrites previous data")

	# Clean up.
	StateManager.clear_target()

	if all_passed:
		print("  PASS: Property 1 — all %d iterations + edge cases passed" % PBT_ITERATIONS)
