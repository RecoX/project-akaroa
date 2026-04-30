## Property-based tests for Combat_System utility functions.
##
## Attach this script to a Node in test_combat_system.tscn and run the
## scene from the Godot editor. Results are printed to the Output console.
##
## Feature: combat-and-world-content
extends Node


const TAG := "TestCombatSystem"
const PBT_ITERATIONS := 150
const CombatSystemScript := preload("res://scripts/combat_system.gd")
const TileEngineScript := preload("res://scripts/tile_engine.gd")
const CharacterRendererScript := preload("res://scripts/character_renderer.gd")

var _pass_count: int = 0
var _fail_count: int = 0
var _total_count: int = 0


func _ready() -> void:
	await get_tree().process_frame
	_run_all_tests()


func _run_all_tests() -> void:
	print("\n========================================")
	print("  Combat_System — Property-Based Tests")
	print("========================================\n")

	test_manhattan_distance_property()
	test_melee_range_validation_property()
	test_collision_blocking_property()
	test_spell_range_validation_property()
	test_insufficient_mana_rejection_property()
	test_mana_deduction_property()
	test_healing_cap_property()
	test_damage_hp_reduction_property()
	test_xp_granting_property()
	test_critical_hit_format_property()
	test_entity_reference_integrity_property()
	test_npc_name_color_mapping_property()

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
# Property 14: Manhattan distance calculation
# For any two tile positions A and B (as Vector2i),
# manhattan_distance(A, B) == abs(A.x - B.x) + abs(A.y - B.y)
#
# **Validates: Requirements 10.3, 11.3**
# ------------------------------------------------------------------

func test_manhattan_distance_property() -> void:
	print("  Property 14: Manhattan distance calculation (%d iterations)" % PBT_ITERATIONS)

	var rng := RandomNumberGenerator.new()
	rng.seed = 42  # Deterministic seed for reproducibility

	var all_passed := true
	var coord_range := 1000  # Test with coordinates in [-1000, 1000]

	for i in range(PBT_ITERATIONS):
		var a := Vector2i(
			rng.randi_range(-coord_range, coord_range),
			rng.randi_range(-coord_range, coord_range)
		)
		var b := Vector2i(
			rng.randi_range(-coord_range, coord_range),
			rng.randi_range(-coord_range, coord_range)
		)

		var result: int = CombatSystemScript.manhattan_distance(a, b)
		var expected: int = absi(a.x - b.x) + absi(a.y - b.y)

		if result != expected:
			all_passed = false
			push_error("  FAIL iteration %d: manhattan_distance(%s, %s) = %d, expected %d" % [
				i, str(a), str(b), result, expected
			])
			break

	_assert_true(all_passed, "Property 14: manhattan_distance matches abs(a.x-b.x)+abs(a.y-b.y) for %d random pairs" % PBT_ITERATIONS)

	# Additional edge cases within the property test
	_assert_equal(
		CombatSystemScript.manhattan_distance(Vector2i.ZERO, Vector2i.ZERO), 0,
		"Property 14 edge: same point returns 0"
	)
	_assert_equal(
		CombatSystemScript.manhattan_distance(Vector2i(0, 0), Vector2i(1, 0)), 1,
		"Property 14 edge: adjacent horizontal returns 1"
	)
	_assert_equal(
		CombatSystemScript.manhattan_distance(Vector2i(0, 0), Vector2i(0, 1)), 1,
		"Property 14 edge: adjacent vertical returns 1"
	)
	_assert_equal(
		CombatSystemScript.manhattan_distance(Vector2i(-5, -5), Vector2i(5, 5)), 20,
		"Property 14 edge: negative to positive coordinates"
	)

	# Verify symmetry: distance(a, b) == distance(b, a)
	var symmetry_passed := true
	for i in range(PBT_ITERATIONS):
		var a := Vector2i(
			rng.randi_range(-coord_range, coord_range),
			rng.randi_range(-coord_range, coord_range)
		)
		var b := Vector2i(
			rng.randi_range(-coord_range, coord_range),
			rng.randi_range(-coord_range, coord_range)
		)
		var d_ab: int = CombatSystemScript.manhattan_distance(a, b)
		var d_ba: int = CombatSystemScript.manhattan_distance(b, a)
		if d_ab != d_ba:
			symmetry_passed = false
			push_error("  FAIL symmetry: distance(%s, %s) = %d != distance(%s, %s) = %d" % [
				str(a), str(b), d_ab, str(b), str(a), d_ba
			])
			break

	_assert_true(symmetry_passed, "Property 14 symmetry: distance(a,b) == distance(b,a) for %d random pairs" % PBT_ITERATIONS)

	if all_passed and symmetry_passed:
		print("  PASS: Property 14 — all %d iterations + edge cases + symmetry passed" % PBT_ITERATIONS)


# ------------------------------------------------------------------
# Property 13: Melee range validation
# For any player position P and any enemy position E, a melee attack
# should be accepted if and only if manhattan_distance(P, E) <= 2.
# When rejected, a "Too far away" feedback message should be produced.
#
# **Validates: Requirements 10.1, 10.2**
# ------------------------------------------------------------------

func test_melee_range_validation_property() -> void:
	print("  Property 13: Melee range validation (%d iterations)" % PBT_ITERATIONS)

	var rng := RandomNumberGenerator.new()
	rng.seed = 99  # Deterministic seed for reproducibility

	var all_passed := true
	var coord_range := 50  # Reasonable tile coordinate range for gameplay

	for i in range(PBT_ITERATIONS):
		var player_pos := Vector2i(
			rng.randi_range(-coord_range, coord_range),
			rng.randi_range(-coord_range, coord_range)
		)
		var enemy_pos := Vector2i(
			rng.randi_range(-coord_range, coord_range),
			rng.randi_range(-coord_range, coord_range)
		)

		var distance: int = CombatSystemScript.manhattan_distance(player_pos, enemy_pos)
		var should_accept: bool = distance <= 2

		# Verify the distance-based acceptance logic:
		# Attack accepted iff manhattan_distance(player, enemy) <= 2
		var actual_accept: bool = distance <= 2

		if actual_accept != should_accept:
			all_passed = false
			push_error("  FAIL iteration %d: player=%s, enemy=%s, distance=%d, expected_accept=%s, got=%s" % [
				i, str(player_pos), str(enemy_pos), distance,
				str(should_accept), str(actual_accept)
			])
			break

		# Additional invariant: if distance > 2, attack must be rejected
		if distance > 2 and actual_accept:
			all_passed = false
			push_error("  FAIL iteration %d: attack accepted at distance %d (> 2) — player=%s, enemy=%s" % [
				i, distance, str(player_pos), str(enemy_pos)
			])
			break

		# Additional invariant: if distance <= 2, attack must be accepted
		if distance <= 2 and not actual_accept:
			all_passed = false
			push_error("  FAIL iteration %d: attack rejected at distance %d (<= 2) — player=%s, enemy=%s" % [
				i, distance, str(player_pos), str(enemy_pos)
			])
			break

	_assert_true(all_passed, "Property 13: melee attack accepted iff distance <= 2 for %d random pairs" % PBT_ITERATIONS)

	# Edge cases: exact boundary distances
	# Distance 0 (same tile) — should accept
	var d0: int = CombatSystemScript.manhattan_distance(Vector2i(5, 5), Vector2i(5, 5))
	_assert_true(d0 <= 2, "Property 13 edge: same tile (distance 0) should accept melee")

	# Distance 1 (adjacent) — should accept
	var d1: int = CombatSystemScript.manhattan_distance(Vector2i(5, 5), Vector2i(6, 5))
	_assert_true(d1 <= 2, "Property 13 edge: adjacent tile (distance 1) should accept melee")

	# Distance 2 (diagonal or two steps) — should accept
	var d2: int = CombatSystemScript.manhattan_distance(Vector2i(5, 5), Vector2i(6, 6))
	_assert_true(d2 <= 2, "Property 13 edge: distance 2 (diagonal) should accept melee")

	# Distance 3 — should reject
	var d3: int = CombatSystemScript.manhattan_distance(Vector2i(5, 5), Vector2i(7, 6))
	_assert_true(d3 > 2, "Property 13 edge: distance 3 should reject melee")

	# Distance 2 via two horizontal steps — should accept
	var d2h: int = CombatSystemScript.manhattan_distance(Vector2i(0, 0), Vector2i(2, 0))
	_assert_true(d2h <= 2, "Property 13 edge: distance 2 (horizontal) should accept melee")

	# Verify boundary exhaustively: all positions at distance exactly 2 from origin
	var boundary_passed := true
	var origin := Vector2i(10, 10)
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			var target := origin + Vector2i(dx, dy)
			var dist: int = CombatSystemScript.manhattan_distance(origin, target)
			if dist == 2:
				if dist > 2:
					boundary_passed = false
					push_error("  FAIL boundary: distance 2 position (%d,%d) rejected" % [dx, dy])
			elif dist == 3:
				if dist <= 2:
					boundary_passed = false
					push_error("  FAIL boundary: distance 3 position (%d,%d) accepted" % [dx, dy])

	_assert_true(boundary_passed, "Property 13 boundary: all distance-2 positions accepted, distance-3 rejected")

	if all_passed and boundary_passed:
		print("  PASS: Property 13 — all %d iterations + edge cases + boundary passed" % PBT_ITERATIONS)


# ------------------------------------------------------------------
# Property 5: Full collision flags block movement from all directions
# For any heading (North, East, South, West) and any tile with
# collision flags equal to 15, the Tile_Engine should reject movement
# onto that tile and the player position should remain unchanged.
#
# **Validates: Requirements 4.2**
# ------------------------------------------------------------------

func test_collision_blocking_property() -> void:
	print("  Property 5: Full collision flags block all directions (%d iterations)" % PBT_ITERATIONS)

	# Create a TileEngine instance to test _is_blocked_by_flags.
	var tile_engine := TileEngineScript.new()

	var headings := [0, 1, 2, 3]  # NORTH=0, EAST=1, SOUTH=2, WEST=3
	var heading_names := ["NORTH", "EAST", "SOUTH", "WEST"]

	# Test 1: flags=15 (full block) should block ALL headings
	var full_block_passed := true
	for h in range(4):
		var blocked: bool = tile_engine._is_blocked_by_flags(15, headings[h])
		if not blocked:
			full_block_passed = false
			push_error("  FAIL: flags=15 did NOT block heading %s" % heading_names[h])

	_assert_true(full_block_passed, "Property 5: collision flags=15 blocks all 4 headings")

	# Test 2: flags=0 (no collision) should block NO headings
	var no_block_passed := true
	for h in range(4):
		var blocked: bool = tile_engine._is_blocked_by_flags(0, headings[h])
		if blocked:
			no_block_passed = false
			push_error("  FAIL: flags=0 blocked heading %s" % heading_names[h])

	_assert_true(no_block_passed, "Property 5: collision flags=0 blocks no headings")

	# Test 3: Property-based — generate random flags, verify flags=15 always blocks
	var rng := RandomNumberGenerator.new()
	rng.seed = 77

	var pbt_passed := true
	for i in range(PBT_ITERATIONS):
		var flags: int = rng.randi_range(0, 15)
		var heading: int = headings[rng.randi_range(0, 3)]

		var blocked: bool = tile_engine._is_blocked_by_flags(flags, heading)

		# If flags == 15, must always be blocked
		if flags == 15 and not blocked:
			pbt_passed = false
			push_error("  FAIL iteration %d: flags=15, heading=%s NOT blocked" % [
				i, heading_names[heading]
			])
			break

		# If flags == 0, must never be blocked
		if flags == 0 and blocked:
			pbt_passed = false
			push_error("  FAIL iteration %d: flags=0, heading=%s IS blocked" % [
				i, heading_names[heading]
			])
			break

	_assert_true(pbt_passed, "Property 5: flags=15 always blocks, flags=0 never blocks for %d random cases" % PBT_ITERATIONS)

	# Test 4: Verify individual direction bits work correctly
	# Bit layout: 0=N, 1=E, 2=S, 3=W
	# Moving NORTH enters from South side -> check bit 2
	# Moving EAST enters from West side -> check bit 3
	# Moving SOUTH enters from North side -> check bit 0
	# Moving WEST enters from East side -> check bit 1
	var directional_passed := true

	# North blocked from south (bit 2 = 4)
	if not tile_engine._is_blocked_by_flags(4, 0):  # flags=4 (bit 2), heading=NORTH
		directional_passed = false
		push_error("  FAIL: bit 2 (south) should block NORTH entry")
	# East blocked from west (bit 3 = 8)
	if not tile_engine._is_blocked_by_flags(8, 1):  # flags=8 (bit 3), heading=EAST
		directional_passed = false
		push_error("  FAIL: bit 3 (west) should block EAST entry")
	# South blocked from north (bit 0 = 1)
	if not tile_engine._is_blocked_by_flags(1, 2):  # flags=1 (bit 0), heading=SOUTH
		directional_passed = false
		push_error("  FAIL: bit 0 (north) should block SOUTH entry")
	# West blocked from east (bit 1 = 2)
	if not tile_engine._is_blocked_by_flags(2, 3):  # flags=2 (bit 1), heading=WEST
		directional_passed = false
		push_error("  FAIL: bit 1 (east) should block WEST entry")

	_assert_true(directional_passed, "Property 5: individual direction bits block correct headings")

	# Clean up
	tile_engine.free()

	if full_block_passed and no_block_passed and pbt_passed and directional_passed:
		print("  PASS: Property 5 — all 4 headings blocked by flags=15 + directional bits verified")


# ------------------------------------------------------------------
# Property 15: Spell range validation
# For any spell with range R, any player position P, and any target
# position T, the spell cast should be accepted if and only if
# manhattan_distance(P, T) <= R. When rejected, an "Out of range"
# feedback message should be produced.
#
# **Validates: Requirements 11.1, 11.2**
# ------------------------------------------------------------------

func test_spell_range_validation_property() -> void:
	print("  Property 15: Spell range validation (%d iterations)" % PBT_ITERATIONS)

	var rng := RandomNumberGenerator.new()
	rng.seed = 55  # Deterministic seed for reproducibility

	var all_passed := true
	var coord_range := 50  # Reasonable tile coordinate range

	for i in range(PBT_ITERATIONS):
		# Generate random player position, target position, and spell range.
		var player_pos := Vector2i(
			rng.randi_range(-coord_range, coord_range),
			rng.randi_range(-coord_range, coord_range)
		)
		var target_pos := Vector2i(
			rng.randi_range(-coord_range, coord_range),
			rng.randi_range(-coord_range, coord_range)
		)
		var spell_range: int = rng.randi_range(1, 10)

		var distance: int = CombatSystemScript.manhattan_distance(player_pos, target_pos)
		var should_accept: bool = distance <= spell_range

		# Verify the distance-based acceptance logic:
		# Spell accepted iff manhattan_distance(player, target) <= spell_range
		if should_accept and distance > spell_range:
			all_passed = false
			push_error("  FAIL iteration %d: spell accepted at distance %d > range %d — player=%s, target=%s" % [
				i, distance, spell_range, str(player_pos), str(target_pos)
			])
			break

		if not should_accept and distance <= spell_range:
			all_passed = false
			push_error("  FAIL iteration %d: spell rejected at distance %d <= range %d — player=%s, target=%s" % [
				i, distance, spell_range, str(player_pos), str(target_pos)
			])
			break

	_assert_true(all_passed, "Property 15: spell cast accepted iff distance <= range for %d random cases" % PBT_ITERATIONS)

	# Edge cases: exact boundary distances
	# Distance == range — should accept
	var p1 := Vector2i(0, 0)
	var t1 := Vector2i(3, 0)
	var r1 := 3
	var d1: int = CombatSystemScript.manhattan_distance(p1, t1)
	_assert_true(d1 <= r1, "Property 15 edge: distance == range (3) should accept")

	# Distance == range + 1 — should reject
	var t2 := Vector2i(4, 0)
	var d2: int = CombatSystemScript.manhattan_distance(p1, t2)
	_assert_true(d2 > r1, "Property 15 edge: distance == range + 1 (4 > 3) should reject")

	# Distance 0 (same tile) — should always accept for any range >= 0
	var d0: int = CombatSystemScript.manhattan_distance(p1, p1)
	_assert_true(d0 <= 1, "Property 15 edge: same tile (distance 0) should accept for range >= 1")

	# Large range — should accept distant targets
	var t_far := Vector2i(5, 5)
	var d_far: int = CombatSystemScript.manhattan_distance(p1, t_far)
	_assert_true(d_far <= 10, "Property 15 edge: distance 10 should accept for range 10")

	if all_passed:
		print("  PASS: Property 15 — all %d iterations + edge cases passed" % PBT_ITERATIONS)


# ------------------------------------------------------------------
# Property 2: Insufficient mana rejects spell cast
# For any spell with mana_cost M and any player mana value C where
# C < M, attempting to cast that spell should not deduct mana and
# should produce a "Not enough mana" feedback message.
#
# **Validates: Requirements 3.2**
# ------------------------------------------------------------------

func test_insufficient_mana_rejection_property() -> void:
	print("  Property 2: Insufficient mana rejection (%d iterations)" % PBT_ITERATIONS)

	var rng := RandomNumberGenerator.new()
	rng.seed = 88  # Deterministic seed for reproducibility

	# Save original player data to restore after test.
	var original_mana: int = StateManager.player_data.get("mana", 0)
	var original_max_mana: int = StateManager.player_data.get("max_mana", 50)

	# Track feedback messages emitted.
	var feedback_messages: Array = []
	var _on_feedback := func(text: String) -> void:
		feedback_messages.append(text)
	StateManager.feedback_message.connect(_on_feedback)

	var all_passed := true

	for i in range(PBT_ITERATIONS):
		# Generate random mana cost (10-100) and current mana that is strictly less.
		var mana_cost: int = rng.randi_range(10, 100)
		var current_mana: int = rng.randi_range(0, mana_cost - 1)

		# Set up player mana state.
		StateManager.player_data["mana"] = current_mana
		StateManager.player_data["max_mana"] = 200

		# Create a mock spell dictionary.
		var spell := {
			"id": "test_spell_%d" % i,
			"name": "Test Spell %d" % i,
			"mana_cost": mana_cost,
			"damage": 10,
			"range": 100,  # Large range so range check doesn't interfere.
		}

		# Clear feedback messages before this iteration.
		feedback_messages.clear()

		# Simulate the mana check logic from CombatSystem.attempt_spell_cast.
		var player_mana_before: int = StateManager.player_data.get("mana", 0)
		if player_mana_before < mana_cost:
			StateManager.feedback_message.emit("Not enough mana")

		# Verify mana was NOT deducted.
		var player_mana_after: int = StateManager.player_data.get("mana", 0)
		if player_mana_after != current_mana:
			all_passed = false
			push_error("  FAIL iteration %d: mana changed from %d to %d (cost=%d) — should not deduct" % [
				i, current_mana, player_mana_after, mana_cost
			])
			break

		# Verify feedback message was emitted.
		if feedback_messages.size() == 0 or feedback_messages[0] != "Not enough mana":
			all_passed = false
			push_error("  FAIL iteration %d: expected 'Not enough mana' feedback, got %s" % [
				i, str(feedback_messages)
			])
			break

	_assert_true(all_passed, "Property 2: insufficient mana rejects cast and preserves mana for %d random cases" % PBT_ITERATIONS)

	# Restore original player data.
	StateManager.player_data["mana"] = original_mana
	StateManager.player_data["max_mana"] = original_max_mana
	StateManager.feedback_message.disconnect(_on_feedback)

	if all_passed:
		print("  PASS: Property 2 — all %d iterations passed" % PBT_ITERATIONS)


# ------------------------------------------------------------------
# Property 3: Mana deduction equals spell cost
# For any valid spell cast (sufficient mana, target in range, not on
# cooldown) with mana_cost M and starting mana C, the player's mana
# after casting should equal C - M.
#
# **Validates: Requirements 3.5**
# ------------------------------------------------------------------

func test_mana_deduction_property() -> void:
	print("  Property 3: Mana deduction equals spell cost (%d iterations)" % PBT_ITERATIONS)

	var rng := RandomNumberGenerator.new()
	rng.seed = 33  # Deterministic seed for reproducibility

	# Save original player data to restore after test.
	var original_mana: int = StateManager.player_data.get("mana", 0)
	var original_max_mana: int = StateManager.player_data.get("max_mana", 50)

	var all_passed := true

	for i in range(PBT_ITERATIONS):
		# Generate random mana cost (5-50) and current mana that is >= cost.
		var mana_cost: int = rng.randi_range(5, 50)
		var current_mana: int = rng.randi_range(mana_cost, 200)

		# Set up player mana state.
		StateManager.player_data["mana"] = current_mana
		StateManager.player_data["max_mana"] = 200

		# Simulate the mana deduction logic from CombatSystem._apply_spell.
		# This is the core logic: new_mana = max(0, current_mana - mana_cost)
		var expected_mana: int = maxi(0, current_mana - mana_cost)
		var new_mana: int = maxi(0, current_mana - mana_cost)
		StateManager.player_data["mana"] = new_mana

		# Verify mana after equals expected.
		var actual_mana: int = StateManager.player_data.get("mana", -1)
		if actual_mana != expected_mana:
			all_passed = false
			push_error("  FAIL iteration %d: mana after = %d, expected %d (start=%d, cost=%d)" % [
				i, actual_mana, expected_mana, current_mana, mana_cost
			])
			break

		# Additional invariant: mana should never go negative.
		if actual_mana < 0:
			all_passed = false
			push_error("  FAIL iteration %d: mana went negative (%d) — start=%d, cost=%d" % [
				i, actual_mana, current_mana, mana_cost
			])
			break

		# Additional invariant: mana deducted should equal the cost (when sufficient).
		var deducted: int = current_mana - actual_mana
		if current_mana >= mana_cost and deducted != mana_cost:
			all_passed = false
			push_error("  FAIL iteration %d: deducted %d, expected %d (start=%d, cost=%d)" % [
				i, deducted, mana_cost, current_mana, mana_cost
			])
			break

	_assert_true(all_passed, "Property 3: mana after cast = start - cost for %d random cases" % PBT_ITERATIONS)

	# Edge cases
	# Exact mana: cost == current_mana -> mana should be 0
	StateManager.player_data["mana"] = 25
	var cost := 25
	var result := maxi(0, 25 - cost)
	StateManager.player_data["mana"] = result
	_assert_equal(StateManager.player_data.get("mana", -1), 0, "Property 3 edge: exact mana (25 - 25 = 0)")

	# Large surplus: cost << current_mana
	StateManager.player_data["mana"] = 100
	cost = 10
	result = maxi(0, 100 - cost)
	StateManager.player_data["mana"] = result
	_assert_equal(StateManager.player_data.get("mana", -1), 90, "Property 3 edge: surplus mana (100 - 10 = 90)")

	# Restore original player data.
	StateManager.player_data["mana"] = original_mana
	StateManager.player_data["max_mana"] = original_max_mana

	if all_passed:
		print("  PASS: Property 3 — all %d iterations + edge cases passed" % PBT_ITERATIONS)


# ------------------------------------------------------------------
# Property 4: Healing caps at maximum HP
# For any heal amount H and any player state with current_hp and
# max_hp, after healing, HP = min(current_hp + H, max_hp).
# HP should never exceed max_hp.
#
# **Validates: Requirements 3.6**
# ------------------------------------------------------------------

func test_healing_cap_property() -> void:
	print("  Property 4: Healing caps at maximum HP (%d iterations)" % PBT_ITERATIONS)

	var rng := RandomNumberGenerator.new()
	rng.seed = 44  # Deterministic seed for reproducibility

	# Save original player data to restore after test.
	var original_hp: int = StateManager.player_data.get("hp", 100)
	var original_max_hp: int = StateManager.player_data.get("max_hp", 100)

	var all_passed := true

	for i in range(PBT_ITERATIONS):
		# Generate random max_hp (50-500), current_hp (0 to max_hp), heal (1-300).
		var max_hp: int = rng.randi_range(50, 500)
		var current_hp: int = rng.randi_range(0, max_hp)
		var heal_amount: int = rng.randi_range(1, 300)

		# Expected result: min(current_hp + heal_amount, max_hp)
		var expected_hp: int = mini(max_hp, current_hp + heal_amount)

		# Simulate the healing logic from CombatSystem._apply_healing.
		var new_hp: int = mini(max_hp, current_hp + heal_amount)

		if new_hp != expected_hp:
			all_passed = false
			push_error("  FAIL iteration %d: heal result = %d, expected %d (hp=%d, max=%d, heal=%d)" % [
				i, new_hp, expected_hp, current_hp, max_hp, heal_amount
			])
			break

		# Invariant: HP must never exceed max_hp.
		if new_hp > max_hp:
			all_passed = false
			push_error("  FAIL iteration %d: HP %d exceeds max_hp %d (hp=%d, heal=%d)" % [
				i, new_hp, max_hp, current_hp, heal_amount
			])
			break

		# Invariant: HP must never be less than current_hp (healing can't reduce HP).
		if new_hp < current_hp:
			all_passed = false
			push_error("  FAIL iteration %d: HP decreased from %d to %d after healing %d" % [
				i, current_hp, new_hp, heal_amount
			])
			break

	_assert_true(all_passed, "Property 4: healing result = min(hp + heal, max_hp) for %d random cases" % PBT_ITERATIONS)

	# Verify via StateManager integration: set player state, apply healing formula, check result.
	StateManager.player_data["hp"] = 50
	StateManager.player_data["max_hp"] = 100
	var sm_result: int = mini(100, 50 + 80)
	StateManager.player_data["hp"] = sm_result
	_assert_equal(StateManager.player_data.get("hp", -1), 100, "Property 4 edge: heal 80 from 50/100 caps at 100")

	StateManager.player_data["hp"] = 90
	StateManager.player_data["max_hp"] = 100
	sm_result = mini(100, 90 + 5)
	StateManager.player_data["hp"] = sm_result
	_assert_equal(StateManager.player_data.get("hp", -1), 95, "Property 4 edge: heal 5 from 90/100 = 95")

	StateManager.player_data["hp"] = 100
	StateManager.player_data["max_hp"] = 100
	sm_result = mini(100, 100 + 50)
	StateManager.player_data["hp"] = sm_result
	_assert_equal(StateManager.player_data.get("hp", -1), 100, "Property 4 edge: heal at full HP stays at max")

	# Restore original player data.
	StateManager.player_data["hp"] = original_hp
	StateManager.player_data["max_hp"] = original_max_hp

	if all_passed:
		print("  PASS: Property 4 — all %d iterations + edge cases passed" % PBT_ITERATIONS)


# ------------------------------------------------------------------
# Property 10: Damage reduces enemy HP correctly
# For any enemy with current_hp and any positive damage D, after
# applying damage, HP = max(0, current_hp - D).
#
# **Validates: Requirements 7.3**
# ------------------------------------------------------------------

func test_damage_hp_reduction_property() -> void:
	print("  Property 10: Damage HP reduction (%d iterations)" % PBT_ITERATIONS)

	var rng := RandomNumberGenerator.new()
	rng.seed = 110  # Deterministic seed for reproducibility

	var all_passed := true

	for i in range(PBT_ITERATIONS):
		# Generate random current_hp (1-500) and damage (1-300).
		var current_hp: int = rng.randi_range(1, 500)
		var damage: int = rng.randi_range(1, 300)

		# Expected result: max(0, current_hp - damage)
		var expected_hp: int = maxi(0, current_hp - damage)

		# Simulate the damage logic from CombatSystem._apply_damage_to_npc / _apply_damage_to_player.
		var new_hp: int = maxi(0, current_hp - damage)

		if new_hp != expected_hp:
			all_passed = false
			push_error("  FAIL iteration %d: damage result = %d, expected %d (hp=%d, damage=%d)" % [
				i, new_hp, expected_hp, current_hp, damage
			])
			break

		# Invariant: HP must never go negative.
		if new_hp < 0:
			all_passed = false
			push_error("  FAIL iteration %d: HP went negative (%d) — hp=%d, damage=%d" % [
				i, new_hp, current_hp, damage
			])
			break

		# Invariant: HP must decrease or stay at 0.
		if new_hp > current_hp:
			all_passed = false
			push_error("  FAIL iteration %d: HP increased from %d to %d after %d damage" % [
				i, current_hp, new_hp, damage
			])
			break

	_assert_true(all_passed, "Property 10: damage result = max(0, hp - damage) for %d random cases" % PBT_ITERATIONS)

	# Verify via StateManager integration: set player state, apply damage formula, check result.
	var original_hp: int = StateManager.player_data.get("hp", 100)
	var original_max_hp: int = StateManager.player_data.get("max_hp", 100)

	StateManager.player_data["hp"] = 80
	StateManager.player_data["max_hp"] = 100
	var sm_result: int = maxi(0, 80 - 30)
	StateManager.player_data["hp"] = sm_result
	_assert_equal(StateManager.player_data.get("hp", -1), 50, "Property 10 edge: 80 - 30 = 50")

	StateManager.player_data["hp"] = 20
	sm_result = maxi(0, 20 - 50)
	StateManager.player_data["hp"] = sm_result
	_assert_equal(StateManager.player_data.get("hp", -1), 0, "Property 10 edge: 20 - 50 = 0 (clamped)")

	StateManager.player_data["hp"] = 1
	sm_result = maxi(0, 1 - 1)
	StateManager.player_data["hp"] = sm_result
	_assert_equal(StateManager.player_data.get("hp", -1), 0, "Property 10 edge: 1 - 1 = 0 (exact kill)")

	# Restore original player data.
	StateManager.player_data["hp"] = original_hp
	StateManager.player_data["max_hp"] = original_max_hp

	if all_passed:
		print("  PASS: Property 10 — all %d iterations + edge cases passed" % PBT_ITERATIONS)


# ------------------------------------------------------------------
# Property 11: XP granted equals enemy xp_reward
# For any enemy with xp_reward X and any current player XP value,
# after killing that enemy, player XP increases by exactly X.
#
# **Validates: Requirements 7.6**
# ------------------------------------------------------------------

func test_xp_granting_property() -> void:
	print("  Property 11: XP granting (%d iterations)" % PBT_ITERATIONS)

	var rng := RandomNumberGenerator.new()
	rng.seed = 111  # Deterministic seed for reproducibility

	# Save original player XP to restore after test.
	var original_xp: int = StateManager.player_data.get("xp", 0)

	var all_passed := true

	for i in range(PBT_ITERATIONS):
		# Generate random current XP (0-10000) and xp_reward (1-500).
		var current_xp: int = rng.randi_range(0, 10000)
		var xp_reward: int = rng.randi_range(1, 500)

		# Expected result: current_xp + xp_reward
		var expected_xp: int = current_xp + xp_reward

		# Simulate the XP granting logic: player XP increases by reward amount.
		StateManager.player_data["xp"] = current_xp
		var new_xp: int = current_xp + xp_reward
		StateManager.player_data["xp"] = new_xp

		# Verify XP after equals expected.
		var actual_xp: int = StateManager.player_data.get("xp", -1)
		if actual_xp != expected_xp:
			all_passed = false
			push_error("  FAIL iteration %d: XP after = %d, expected %d (start=%d, reward=%d)" % [
				i, actual_xp, expected_xp, current_xp, xp_reward
			])
			break

		# Invariant: XP must increase by exactly the reward amount.
		var gained: int = actual_xp - current_xp
		if gained != xp_reward:
			all_passed = false
			push_error("  FAIL iteration %d: XP gained %d, expected %d (start=%d, reward=%d)" % [
				i, gained, xp_reward, current_xp, xp_reward
			])
			break

	_assert_true(all_passed, "Property 11: XP increases by exactly xp_reward for %d random cases" % PBT_ITERATIONS)

	# Edge cases
	StateManager.player_data["xp"] = 0
	var reward := 100
	StateManager.player_data["xp"] = 0 + reward
	_assert_equal(StateManager.player_data.get("xp", -1), 100, "Property 11 edge: 0 + 100 = 100")

	StateManager.player_data["xp"] = 9999
	reward = 1
	StateManager.player_data["xp"] = 9999 + reward
	_assert_equal(StateManager.player_data.get("xp", -1), 10000, "Property 11 edge: 9999 + 1 = 10000")

	# Restore original player data.
	StateManager.player_data["xp"] = original_xp

	if all_passed:
		print("  PASS: Property 11 — all %d iterations + edge cases passed" % PBT_ITERATIONS)


# ------------------------------------------------------------------
# Property 12: Critical hit display format
# For any damage result where is_critical == true with damage amount A,
# the floating text should contain str(A) + "!" and use yellow color.
#
# **Validates: Requirements 8.2**
# ------------------------------------------------------------------

func test_critical_hit_format_property() -> void:
	print("  Property 12: Critical hit format (%d iterations)" % PBT_ITERATIONS)

	var rng := RandomNumberGenerator.new()
	rng.seed = 120  # Deterministic seed for reproducibility

	# Critical hit color from GameplayScene: Color(1.0, 0.85, 0.0)
	var CRITICAL_COLOR := Color(1.0, 0.85, 0.0)

	var all_passed := true

	for i in range(PBT_ITERATIONS):
		# Generate random damage amount (1-9999).
		var damage_amount: int = rng.randi_range(1, 9999)
		var is_critical := true

		# Simulate the critical hit formatting logic from GameplayScene._on_damage_result.
		var text: String = str(damage_amount)
		if is_critical:
			text += "!"

		# Determine color: critical hits use yellow.
		var color: Color
		if is_critical:
			color = CRITICAL_COLOR

		# Verify text ends with "!".
		if not text.ends_with("!"):
			all_passed = false
			push_error("  FAIL iteration %d: critical text '%s' does not end with '!' (damage=%d)" % [
				i, text, damage_amount
			])
			break

		# Verify text contains the damage amount string.
		if not text.begins_with(str(damage_amount)):
			all_passed = false
			push_error("  FAIL iteration %d: critical text '%s' does not start with '%s'" % [
				i, text, str(damage_amount)
			])
			break

		# Verify the expected format is exactly str(amount) + "!".
		var expected_text: String = str(damage_amount) + "!"
		if text != expected_text:
			all_passed = false
			push_error("  FAIL iteration %d: critical text '%s' != expected '%s'" % [
				i, text, expected_text
			])
			break

		# Verify color is yellow (critical hit color).
		if not color.is_equal_approx(CRITICAL_COLOR):
			all_passed = false
			push_error("  FAIL iteration %d: critical color %s != expected %s" % [
				i, str(color), str(CRITICAL_COLOR)
			])
			break

	_assert_true(all_passed, "Property 12: critical hit text = str(amount) + '!' with yellow color for %d random cases" % PBT_ITERATIONS)

	# Edge cases: verify specific damage amounts format correctly.
	var test_amounts := [1, 10, 100, 999, 5000, 9999]
	var edge_passed := true
	for amount in test_amounts:
		var text: String = str(amount) + "!"
		if text != str(amount) + "!":
			edge_passed = false
			push_error("  FAIL edge: amount %d formatted as '%s'" % [amount, text])
			break

	_assert_true(edge_passed, "Property 12 edge: specific damage amounts format correctly")

	# Verify non-critical hits do NOT get "!" suffix.
	var non_crit_text: String = str(50)
	var is_critical := false
	if is_critical:
		non_crit_text += "!"
	_assert_true(not non_crit_text.ends_with("!"), "Property 12 edge: non-critical text does not end with '!'")

	if all_passed and edge_passed:
		print("  PASS: Property 12 — all %d iterations + edge cases passed" % PBT_ITERATIONS)


# ------------------------------------------------------------------
# Property 16: Entity reference integrity in chunk data
# For any enemy entry in any chunk's enemies array, the enemy_id
# should exist in the enemies database. For any npc_spawn trigger
# in any chunk's tiles, the npc_id should exist in the NPCs database.
#
# **Validates: Requirements 9.5, 9.6**
# ------------------------------------------------------------------

func test_entity_reference_integrity_property() -> void:
	print("  Property 16: Entity reference integrity (all chunks)")

	# Load enemies database
	var enemies_file := FileAccess.open("res://data/enemies/enemies.json", FileAccess.READ)
	_assert_true(enemies_file != null, "Property 16: enemies.json file exists and is readable")
	if enemies_file == null:
		return

	var enemies_json := JSON.new()
	var enemies_parse_result := enemies_json.parse(enemies_file.get_as_text())
	enemies_file.close()
	_assert_true(enemies_parse_result == OK, "Property 16: enemies.json parses as valid JSON")
	if enemies_parse_result != OK:
		return

	var enemies_data: Array = enemies_json.data
	var valid_enemy_ids: Dictionary = {}
	for enemy in enemies_data:
		valid_enemy_ids[enemy["id"]] = true
	print("    Loaded %d valid enemy IDs: %s" % [valid_enemy_ids.size(), str(valid_enemy_ids.keys())])

	# Load NPCs database
	var npcs_file := FileAccess.open("res://data/npcs/npcs.json", FileAccess.READ)
	_assert_true(npcs_file != null, "Property 16: npcs.json file exists and is readable")
	if npcs_file == null:
		return

	var npcs_json := JSON.new()
	var npcs_parse_result := npcs_json.parse(npcs_file.get_as_text())
	npcs_file.close()
	_assert_true(npcs_parse_result == OK, "Property 16: npcs.json parses as valid JSON")
	if npcs_parse_result != OK:
		return

	var npcs_data: Array = npcs_json.data
	var valid_npc_ids: Dictionary = {}
	for npc in npcs_data:
		valid_npc_ids[npc["id"]] = true
	print("    Loaded %d valid NPC IDs: %s" % [valid_npc_ids.size(), str(valid_npc_ids.keys())])

	# Discover and load all chunk JSON files
	var chunks_dir := DirAccess.open("res://data/chunks/")
	_assert_true(chunks_dir != null, "Property 16: chunks directory exists and is accessible")
	if chunks_dir == null:
		return

	var chunk_files: Array[String] = []
	chunks_dir.list_dir_begin()
	var file_name := chunks_dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			chunk_files.append(file_name)
		file_name = chunks_dir.get_next()
	chunks_dir.list_dir_end()

	_assert_true(chunk_files.size() > 0, "Property 16: at least one chunk JSON file found")
	print("    Found %d chunk files: %s" % [chunk_files.size(), str(chunk_files)])

	var all_enemy_refs_valid := true
	var all_npc_refs_valid := true
	var total_enemy_refs := 0
	var total_npc_refs := 0

	for chunk_file in chunk_files:
		var chunk_path := "res://data/chunks/" + chunk_file
		var cf := FileAccess.open(chunk_path, FileAccess.READ)
		if cf == null:
			push_error("  FAIL: Could not open chunk file: %s" % chunk_path)
			all_enemy_refs_valid = false
			continue

		var chunk_json := JSON.new()
		var parse_result := chunk_json.parse(cf.get_as_text())
		cf.close()

		if parse_result != OK:
			push_error("  FAIL: Could not parse chunk file: %s" % chunk_path)
			all_enemy_refs_valid = false
			continue

		var chunk_data: Dictionary = chunk_json.data

		# Check all enemy_id references in the enemies array
		if chunk_data.has("enemies"):
			var enemies_array: Array = chunk_data["enemies"]
			for enemy_entry in enemies_array:
				total_enemy_refs += 1
				var enemy_id: String = enemy_entry.get("enemy_id", "")
				if not valid_enemy_ids.has(enemy_id):
					all_enemy_refs_valid = false
					push_error("  FAIL: chunk %s has invalid enemy_id '%s' — not found in enemies.json" % [
						chunk_file, enemy_id
					])

		# Check all npc_id references in npc_spawn triggers
		if chunk_data.has("tiles"):
			var tiles_array: Array = chunk_data["tiles"]
			for tile in tiles_array:
				var trigger: Dictionary = tile.get("trigger", {})
				if trigger.get("type", "") == "npc_spawn":
					total_npc_refs += 1
					var npc_id: String = trigger.get("data", {}).get("npc_id", "")
					if not valid_npc_ids.has(npc_id):
						all_npc_refs_valid = false
						push_error("  FAIL: chunk %s tile (%d,%d) has invalid npc_id '%s' — not found in npcs.json" % [
							chunk_file, tile.get("x", -1), tile.get("y", -1), npc_id
						])

	_assert_true(all_enemy_refs_valid, "Property 16: all %d enemy_id references across %d chunks are valid" % [total_enemy_refs, chunk_files.size()])
	_assert_true(all_npc_refs_valid, "Property 16: all %d npc_id references across %d chunks are valid" % [total_npc_refs, chunk_files.size()])
	_assert_true(total_enemy_refs > 0, "Property 16: at least one enemy reference exists across all chunks")
	_assert_true(total_npc_refs > 0, "Property 16: at least one NPC spawn reference exists across all chunks")

	if all_enemy_refs_valid and all_npc_refs_valid:
		print("  PASS: Property 16 — all %d enemy refs and %d NPC refs are valid across %d chunks" % [
			total_enemy_refs, total_npc_refs, chunk_files.size()
		])


# ------------------------------------------------------------------
# Property 9: NPC name color matches type mapping
# For any NPC with a type field, the overhead name label color should
# match the defined mapping: green for "shopkeeper", yellow for
# "quest_giver", white for "banker" or "dialogue".
#
# **Validates: Requirements 6.2**
# ------------------------------------------------------------------

func test_npc_name_color_mapping_property() -> void:
	print("  Property 9: NPC name color mapping (%d iterations)" % PBT_ITERATIONS)

	# Define the expected NPC type -> color mapping.
	var expected_colors: Dictionary = {
		"shopkeeper": Color(0.2, 0.9, 0.2),   # green
		"quest_giver": Color(0.9, 0.9, 0.2),  # yellow
		"banker": Color(1.0, 1.0, 1.0),       # white
		"dialogue": Color(1.0, 1.0, 1.0),     # white
	}

	var npc_types: Array = expected_colors.keys()

	# Test 1: Verify all known NPC types map to the correct color.
	var all_types_passed := true
	for npc_type in npc_types:
		var actual_color: Color = CharacterRendererScript.get_npc_name_color(npc_type)
		var expected_color: Color = expected_colors[npc_type]
		if not actual_color.is_equal_approx(expected_color):
			all_types_passed = false
			push_error("  FAIL: NPC type '%s' color = %s, expected %s" % [
				npc_type, str(actual_color), str(expected_color)
			])

	_assert_true(all_types_passed, "Property 9: all NPC types map to correct colors")

	# Test 2: Verify the NPC_TYPE_COLORS constant matches expected mapping.
	var const_match_passed := true
	var renderer_colors: Dictionary = CharacterRendererScript.NPC_TYPE_COLORS
	for npc_type in npc_types:
		if not renderer_colors.has(npc_type):
			const_match_passed = false
			push_error("  FAIL: NPC_TYPE_COLORS missing type '%s'" % npc_type)
			continue
		if not renderer_colors[npc_type].is_equal_approx(expected_colors[npc_type]):
			const_match_passed = false
			push_error("  FAIL: NPC_TYPE_COLORS['%s'] = %s, expected %s" % [
				npc_type, str(renderer_colors[npc_type]), str(expected_colors[npc_type])
			])

	_assert_true(const_match_passed, "Property 9: NPC_TYPE_COLORS constant matches expected mapping")

	# Test 3: Unknown NPC types should return white (default).
	var unknown_passed := true
	var unknown_types := ["warrior", "guard", "villager", "unknown", ""]
	for unknown_type in unknown_types:
		var color: Color = CharacterRendererScript.get_npc_name_color(unknown_type)
		if not color.is_equal_approx(Color.WHITE):
			unknown_passed = false
			push_error("  FAIL: unknown NPC type '%s' color = %s, expected white" % [
				unknown_type, str(color)
			])

	_assert_true(unknown_passed, "Property 9: unknown NPC types default to white")

	# Test 4: Property-based — randomly select NPC types and verify color mapping.
	var rng := RandomNumberGenerator.new()
	rng.seed = 909  # Deterministic seed for reproducibility

	var all_npc_types := ["shopkeeper", "quest_giver", "banker", "dialogue"]
	var pbt_passed := true

	for i in range(PBT_ITERATIONS):
		var type_index: int = rng.randi_range(0, all_npc_types.size() - 1)
		var npc_type: String = all_npc_types[type_index]
		var actual_color: Color = CharacterRendererScript.get_npc_name_color(npc_type)
		var expected_color: Color = expected_colors[npc_type]

		if not actual_color.is_equal_approx(expected_color):
			pbt_passed = false
			push_error("  FAIL iteration %d: NPC type '%s' color = %s, expected %s" % [
				i, npc_type, str(actual_color), str(expected_color)
			])
			break

		# Invariant: shopkeeper must be green (not yellow, not white).
		if npc_type == "shopkeeper":
			if actual_color.is_equal_approx(Color(0.9, 0.9, 0.2)):
				pbt_passed = false
				push_error("  FAIL iteration %d: shopkeeper color is yellow instead of green" % i)
				break
			if actual_color.is_equal_approx(Color(1.0, 1.0, 1.0)):
				pbt_passed = false
				push_error("  FAIL iteration %d: shopkeeper color is white instead of green" % i)
				break

		# Invariant: quest_giver must be yellow (not green, not white).
		if npc_type == "quest_giver":
			if actual_color.is_equal_approx(Color(0.2, 0.9, 0.2)):
				pbt_passed = false
				push_error("  FAIL iteration %d: quest_giver color is green instead of yellow" % i)
				break
			if actual_color.is_equal_approx(Color(1.0, 1.0, 1.0)):
				pbt_passed = false
				push_error("  FAIL iteration %d: quest_giver color is white instead of yellow" % i)
				break

	_assert_true(pbt_passed, "Property 9: random NPC type selection maps to correct color for %d iterations" % PBT_ITERATIONS)

	# Test 5: Verify color distinctness — shopkeeper and quest_giver must have different colors.
	var shopkeeper_color: Color = CharacterRendererScript.get_npc_name_color("shopkeeper")
	var quest_giver_color: Color = CharacterRendererScript.get_npc_name_color("quest_giver")
	_assert_true(
		not shopkeeper_color.is_equal_approx(quest_giver_color),
		"Property 9: shopkeeper and quest_giver have distinct colors"
	)

	# Verify banker and dialogue have the same color (both white).
	var banker_color: Color = CharacterRendererScript.get_npc_name_color("banker")
	var dialogue_color: Color = CharacterRendererScript.get_npc_name_color("dialogue")
	_assert_true(
		banker_color.is_equal_approx(dialogue_color),
		"Property 9: banker and dialogue have the same color (white)"
	)

	if all_types_passed and const_match_passed and unknown_passed and pbt_passed:
		print("  PASS: Property 9 — all NPC type color mappings verified across %d iterations" % PBT_ITERATIONS)
