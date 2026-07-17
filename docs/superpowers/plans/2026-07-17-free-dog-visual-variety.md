# Shared NPC Dog Appearance Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add six reusable procedural appearances shared by free dogs and NPC pair dogs while preserving free-dog determinism, the exact NPC-pair RNG stream, and every gameplay, leash, lifecycle, greeting, and cleanup contract.

**Architecture:** Introduce `dog_appearance.gd` as a stateless `RefCounted` profile catalog, validator, deterministic selector, and CanvasItem renderer used by both NPC scripts. `freedog.gd` derives profile and animation state from rounded spawn inputs without RNG; `otherpair.gd` reuses its existing fourth setup draw as the profile key and keeps drawing owner and dog from the parent CanvasItem. Split catalog/free-dog and pair RNG/lifecycle coverage into two focused real-script `SceneTree` regressions.

**Tech Stack:** Godot 4.7, GDScript, procedural CanvasItem drawing, SceneTree headless regression tests, PowerShell, Git, GitHub Actions.

## Global Constraints

- During isolated implementation, create `dog_appearance.gd`, modify `freedog.gd` and `otherpair.gd`, and create `tests/test_free_dog_variety.gd` and `tests/test_pair_dog_appearance.gd`.
- Do not edit `main.gd`, `leash.gd`, `bypasser_route.gd`, `bike.gd`, any existing test, `.github/workflows/ci.yml`, `CHANGELOG.md`, `HANDOVER.md`, `PROJECT.md`, the approved spec, the earlier handoff, or this plan during the isolated five-file implementation.
- Inspect `git status --short` and the current `freedog.gd` and `otherpair.gd` diffs before editing. Preserve unrelated work. If either production caller changed after this plan was approved, stop and coordinate instead of merging the overlap silently.
- Do not stage, revert, overwrite, or format files outside the active task's file list.
- Do not commit or push the isolated implementation until its five-file diff has passed both review stages and the parent agent explicitly authorizes a checkpoint.
- Keep `setup(m: Node2D, mine: Node2D, y_lo: float, y_hi: float) -> void` unchanged and compatible with `main.gd`.
- Preserve the `freedogs` group, stored setup references and bounds, `_physics_process` callback, frozen/non-`freedom` early return, movement speeds, wander probabilities and timers, random wander call order/cadence, x/y clamps, spawn count, z-order, greeting semantics, and cleanup ownership.
- `dog_appearance.gd` and free-dog appearance setup must not call `seed`, `randf`, `randf_range`, `randi`, `randi_range`, `randomize`, or `RandomNumberGenerator`.
- Preserve `otherpair.gd::setup` random calls exactly as velocity `randf_range(58.0, 82.0)`, `seed_o` `randf()`, owner-color `randi()`, and dog-appearance `randi()` in that order. The raw fourth draw is the profile key; no call is inserted, removed, or moved.
- Use rounded integer spawn coordinates and bounds plus fixed integer arithmetic for the appearance key. Use positive modulo for profile selection, including negative keys.
- `dog_appearance.gd` must know nothing about main, phases, greetings, movement, leashes, tangles, pair states, spawning, or ownership.
- Keep one defensive pair profile dictionary and profile ID unchanged through `WALKING`, `ARRIVING`, `PARKED`, `RECALLING`, `DEPARTING`, and resumed `WALKING`.
- Keep pair owner drawing unchanged on the parent CanvasItem. Delegate only dog drawing with `DogAppearance.draw_dog(self, appearance_profile, npc_dog.position, facing, bob, wag)`.
- Use no external assets, resource files, scenes, textures, SVGs, plugins, dependencies, or real-breed labels. All art remains procedural vector drawing.
- Use Godot 4.7 GDScript only and retain GL Compatibility/web compatibility.
- Use no emoji.
- Do not add owner profiles, hats, glasses, bald spots, long hair, owner visual changes, playable selectors, saves, progression, or gameplay/stat differences.
- The final integration task may update CI, `CHANGELOG.md`, and `HANDOVER.md` only after the isolated five-file implementation has passed two-stage review.

## File Map

- Create `dog_appearance.gd`: canonical six-profile table, exact reusable public API, defensive lookup, positive-modulo selection, validation, finite geometry bound, and all procedural drawing branches.
- Modify `freedog.gd`: preload the appearance module, derive deterministic setup state, preserve gameplay logic byte-for-byte where possible, and delegate `_draw()`.
- Modify `otherpair.gd`: preserve the exact four-draw setup sequence, store a persistent defensive profile, retain parent owner drawing, and delegate only pair-dog drawing.
- Create `tests/test_free_dog_variety.gd`: real-script `SceneTree` regression for API/schema, selection, defensive copies, validation, variety, RNG isolation, deterministic setup, lifecycle, clamps, and render smoke.
- Create `tests/test_pair_dog_appearance.gd`: real-script pair regression for exact setup RNG cadence, profile persistence through every pair state, caller draw smoke, zero-forward fallback, and identity/leash compatibility.
- Modify `.github/workflows/ci.yml` only in final integration: run both focused regressions on Linux CI.
- Modify `CHANGELOG.md` only in final integration: record the shared NPC-dog foundation and its regression coverage.
- Modify `HANDOVER.md` only in final integration: add both focused tests to CI documentation, record evidence, and identify reusable owner profiles as the next separate appearance task.

---

### Task 1: Establish the Real-Script Regression

**Files:**
- Create: `tests/test_free_dog_variety.gd`
- Inspect only: `freedog.gd`
- Inspect only: `main.gd:2047-2074,2098-2110`

**Interfaces:**
- Consumes: the approved `DogAppearance` static API and existing `freedog.gd` four-argument `setup`.
- Produces: a `SceneTree` test that exits `1` with `FAIL:` assertions and exits `0` only after printing `test_free_dog_variety: OK`.
- Produces: exact behavioral requirements for Tasks 2-4; it loads production scripts through `load()` and never copies production formulas.

- [ ] **Step 1: Confirm the ownership baseline**

Run from the repository root:

```powershell
git status --short
git log -3 --oneline --decorate
git diff -- freedog.gd
git diff -- otherpair.gd
```

Expected after this plan is committed: no output from `git status --short`, `git diff -- freedog.gd`, or `git diff -- otherpair.gd`; `HEAD` includes `Plan shared NPC dog appearances` above `57443a9 Design shared NPC dog appearances`. If the tree is not clean, preserve all unrelated changes. If either caller has a diff, stop and coordinate.

- [ ] **Step 2: Write the complete failing real-script test**

Create `tests/test_free_dog_variety.gd` with exactly:

```gdscript
extends SceneTree

const EXPECTED_IDS := PackedStringArray([
	"compact_point_ear",
	"long_low_drop_ear",
	"tall_narrow_rose_ear",
	"stocky_fold_ear",
	"fluffy_curl_tail",
	"shaggy_drop_ear",
])
const REQUIRED_FIELDS := PackedStringArray([
	"id",
	"name",
	"size_scale",
	"body_size",
	"head_radius",
	"muzzle_size",
	"ear_style",
	"ear_size",
	"ear_offset",
	"tail_style",
	"tail_length",
	"tail_thickness",
	"tail_carriage",
	"base_color",
	"secondary_color",
	"marking_color",
	"marking_style",
	"marking_offset",
	"marking_scale",
])
const REPRESENTATIVE_POSITIONS := [
	Vector2(200.0, -160.0),
	Vector2(640.0, -220.0),
	Vector2(1080.0, -80.0),
]
const Y_LO := -300.0
const Y_HI := -30.0

var failures := 0
var fixtures: Array[Node] = []
var appearance_script: GDScript
var free_dog_script: GDScript


class FakeMain:
	extends Node2D

	var phase := "freedom"
	var frozen := false


func _check(condition: bool, message: String) -> void:
	if not condition:
		print("FAIL: " + message)
		failures += 1


func _script_has_method(script: GDScript, method_name: String) -> bool:
	for method: Dictionary in script.get_script_method_list():
		if String(method.get("name", "")) == method_name:
			return true
	return false


func _has_property(object: Object, property_name: String) -> bool:
	for property: Dictionary in object.get_property_list():
		if String(property.get("name", "")) == property_name:
			return true
	return false


func _contains_fragment(messages: PackedStringArray, fragment: String) -> bool:
	for message: String in messages:
		if message.contains(fragment):
			return true
	return false


func _make_free_dog(
	main: FakeMain,
	player_dog: Node2D,
	spawn_position: Vector2,
	run_setup := true
) -> Node2D:
	var free_dog := Node2D.new()
	free_dog.set_script(free_dog_script)
	free_dog.position = spawn_position
	root.add_child(free_dog)
	free_dog.set_physics_process(false)
	fixtures.append(free_dog)
	if run_setup:
		free_dog.setup(main, player_dog, Y_LO, Y_HI)
	return free_dog


func _test_public_api_and_selection() -> bool:
	var required_methods := [
		"profile_ids",
		"get_profile",
		"profile_id_for_key",
		"profile_for_key",
		"validation_errors",
	]
	var complete := true
	for method_name: String in required_methods:
		var present := _script_has_method(appearance_script, method_name)
		_check(present, "DogAppearance exposes " + method_name)
		complete = complete and present
	if not complete:
		return false
	var constants := appearance_script.get_script_constant_map()
	_check(
		is_equal_approx(float(constants.get("MAX_LOCAL_RADIUS", 0.0)), 40.0),
		"DogAppearance exposes MAX_LOCAL_RADIUS = 40.0"
	)

	var ids: PackedStringArray = appearance_script.call("profile_ids")
	_check(ids == EXPECTED_IDS, "profile IDs retain the exact stable order")
	var unique := {}
	for profile_id: String in ids:
		unique[profile_id] = true
	_check(ids.size() >= 6, "profile list contains at least six IDs")
	_check(unique.size() == ids.size(), "profile IDs are unique")

	var mutated_ids := ids
	mutated_ids[0] = "mutated"
	_check(
		appearance_script.call("profile_ids") == EXPECTED_IDS,
		"profile ID lookup returns an independent array"
	)

	var expected_by_key := {
		0: EXPECTED_IDS[0],
		1: EXPECTED_IDS[1],
		5: EXPECTED_IDS[5],
		6: EXPECTED_IDS[0],
		7: EXPECTED_IDS[1],
		-1: EXPECTED_IDS[5],
		-6: EXPECTED_IDS[0],
		-7: EXPECTED_IDS[5],
	}
	for key: int in expected_by_key:
		var first: String = appearance_script.call("profile_id_for_key", key)
		var second: String = appearance_script.call("profile_id_for_key", key)
		_check(first == String(expected_by_key[key]), "key %d selects the expected ID" % key)
		_check(second == first, "key %d selection is repeatable" % key)

	var count := EXPECTED_IDS.size()
	for key in range(-18, 19):
		_check(
			appearance_script.call("profile_id_for_key", key)
				== appearance_script.call("profile_id_for_key", key + count),
			"selection cycles by profile count for key %d" % key
		)
	return true


func _test_profiles_validation_and_variety() -> void:
	var ear_styles := {}
	var tail_styles := {}
	var marking_styles := {}
	var coat_colors := {}
	var silhouettes := {}
	for profile_id: String in EXPECTED_IDS:
		var profile: Dictionary = appearance_script.call("get_profile", profile_id)
		_check(profile.keys().size() == REQUIRED_FIELDS.size(), profile_id + " uses only the exact schema")
		for field: String in REQUIRED_FIELDS:
			_check(profile.has(field), profile_id + " has field " + field)
		_check(String(profile.get("id", "")) == profile_id, profile_id + " matches its catalog key")
		var errors: PackedStringArray = appearance_script.call("validation_errors", profile)
		_check(errors.is_empty(), profile_id + " validates: " + ", ".join(errors))
		ear_styles[String(profile.get("ear_style", ""))] = true
		tail_styles[String(profile.get("tail_style", ""))] = true
		marking_styles[String(profile.get("marking_style", ""))] = true
		coat_colors[profile.get("base_color")] = true
		var body_size: Vector2 = profile.get("body_size", Vector2.ZERO)
		var size_scale: float = profile.get("size_scale", 0.0)
		silhouettes["%.2f:%.2f:%.2f" % [body_size.x, body_size.y, size_scale]] = true

		var first: Dictionary = appearance_script.call("get_profile", profile_id)
		var second: Dictionary = appearance_script.call("get_profile", profile_id)
		_check(first == second, profile_id + " repeated lookups are value-equal")
		first["name"] = "mutated"
		first["body_size"] = Vector2(999.0, 999.0)
		_check(first != second, profile_id + " lookups are independently mutable")
		_check(
			appearance_script.call("get_profile", profile_id) == second,
			profile_id + " canonical data is protected from caller mutation"
		)

	_check(ear_styles.size() >= 3, "profiles exercise at least three ear styles")
	_check(tail_styles.size() >= 3, "profiles exercise at least three tail styles")
	_check(marking_styles.size() >= 4, "profiles exercise all four marking styles")
	_check(coat_colors.size() >= 4, "profiles use at least four base-coat colors")
	_check(silhouettes.size() >= 3, "profiles use at least three silhouettes")
	_check(ear_styles.has("point"), "point ears are represented")
	_check(ear_styles.has("drop"), "drop ears are represented")
	_check(ear_styles.has("rose"), "rose ears are represented")
	_check(ear_styles.has("fold"), "fold ears are represented")
	_check(tail_styles.has("straight"), "straight tails are represented")
	_check(tail_styles.has("whip"), "whip tails are represented")
	_check(tail_styles.has("curl"), "curl tails are represented")
	_check(tail_styles.has("plume"), "plume tails are represented")
	_check(marking_styles.has("solid"), "solid coats are represented")
	_check(marking_styles.has("patch"), "patched coats are represented")
	_check(marking_styles.has("blaze_points"), "blazed/pointed coats are represented")
	_check(marking_styles.has("brindle"), "brindled coats are represented")

	var fallback: Dictionary = appearance_script.call("get_profile", "not_a_profile")
	_check(fallback["id"] == EXPECTED_IDS[0], "unknown IDs fall back to the first profile")
	var fallback_again: Dictionary = appearance_script.call("get_profile", "not_a_profile")
	fallback["name"] = "mutated"
	_check(fallback_again["name"] != "mutated", "fallback profiles are defensive copies")

	var invalid: Dictionary = appearance_script.call("get_profile", EXPECTED_IDS[0])
	invalid["id"] = ""
	invalid["size_scale"] = 0.0
	invalid["body_size"] = Vector2(INF, -1.0)
	invalid["ear_style"] = "bat"
	invalid["tail_style"] = "stub"
	invalid["marking_style"] = "spots"
	invalid["base_color"] = Color(2.0, -1.0, NAN, 1.0)
	invalid["unexpected"] = true
	var invalid_snapshot := invalid.duplicate(true)
	var invalid_errors: PackedStringArray = appearance_script.call("validation_errors", invalid)
	_check(invalid_errors.size() >= 8, "malformed profiles return multiple validation errors")
	_check(invalid == invalid_snapshot, "validation does not mutate malformed input")

	var missing_errors: PackedStringArray = appearance_script.call("validation_errors", {})
	_check(missing_errors.size() == REQUIRED_FIELDS.size(), "missing schema fields are all reported")

	var oversized: Dictionary = appearance_script.call("get_profile", EXPECTED_IDS[0])
	oversized["body_size"] = Vector2(100.0, 100.0)
	var oversized_errors: PackedStringArray = appearance_script.call("validation_errors", oversized)
	_check(
		_contains_fragment(oversized_errors, "MAX_LOCAL_RADIUS"),
		"validation rejects geometry outside MAX_LOCAL_RADIUS"
	)


func _test_appearance_rng_isolation() -> void:
	seed(170717)
	var expected_next := randf()
	seed(170717)
	var ids: PackedStringArray = appearance_script.call("profile_ids")
	var selected_id: String = appearance_script.call("profile_id_for_key", -17)
	var selected: Dictionary = appearance_script.call("profile_for_key", 31)
	var looked_up: Dictionary = appearance_script.call("get_profile", selected_id)
	var errors: PackedStringArray = appearance_script.call("validation_errors", looked_up)
	var actual_next := randf()
	_check(not ids.is_empty() and not selected.is_empty(), "RNG fixture exercises selection and lookup")
	_check(errors.is_empty(), "RNG fixture exercises validation")
	_check(
		is_equal_approx(actual_next, expected_next),
		"selection, lookup, and validation preserve global RNG state"
	)


func _test_free_dog_setup_and_lifecycle(main: FakeMain, player_dog: Node2D) -> bool:
	var probe := _make_free_dog(main, player_dog, REPRESENTATIVE_POSITIONS[0], false)
	var has_profile := _has_property(probe, "appearance_profile")
	_check(has_profile, "freedog stores appearance_profile")
	if not has_profile:
		return false

	seed(271828)
	var expected_next := randf()
	seed(271828)
	probe.setup(main, player_dog, Y_LO, Y_HI)
	var actual_next := randf()
	_check(
		is_equal_approx(actual_next, expected_next),
		"freedog setup preserves global RNG state"
	)
	_check(probe.is_in_group("freedogs"), "setup joins freedogs")
	_check(probe.main == main, "setup retains the main reference")
	_check(probe.my_dog == player_dog, "setup retains the player-dog reference")
	_check(is_equal_approx(probe.lo, Y_LO), "setup retains the lower bound")
	_check(is_equal_approx(probe.hi, Y_HI), "setup retains the upper bound")

	var duplicate := _make_free_dog(main, player_dog, REPRESENTATIVE_POSITIONS[0])
	_check(
		probe.appearance_profile == duplicate.appearance_profile,
		"identical setup inputs produce equal profiles"
	)
	_check(
		is_equal_approx(probe.seed_o, duplicate.seed_o),
		"identical setup inputs produce equal animation offsets"
	)

	var selected_ids := {}
	for spawn_position: Vector2 in REPRESENTATIVE_POSITIONS:
		var first := _make_free_dog(main, player_dog, spawn_position)
		var second := _make_free_dog(main, player_dog, spawn_position)
		_check(
			first.appearance_profile == second.appearance_profile,
			"position %s produces a repeatable profile" % spawn_position
		)
		_check(
			is_equal_approx(first.seed_o, second.seed_o),
			"position %s produces a repeatable animation offset" % spawn_position
		)
		selected_ids[String(first.appearance_profile.get("id", ""))] = true
	_check(selected_ids.size() > 1, "representative spawn inputs select more than one profile")

	probe.position = Vector2(500.0, 0.0)
	probe.vel = Vector2(120.0, 0.0)
	probe.wander_t = 1.0
	main.frozen = true
	var before := probe.position
	probe._physics_process(0.1)
	_check(probe.position.is_equal_approx(before), "frozen free dogs remain stationary")

	main.frozen = false
	main.phase = "home"
	probe._physics_process(0.1)
	_check(probe.position.is_equal_approx(before), "free dogs remain stationary outside freedom")

	main.phase = "freedom"
	probe._physics_process(0.1)
	_check(
		probe.position.is_equal_approx(before + Vector2(12.0, 0.0)),
		"active free dogs retain fixed-velocity movement"
	)

	probe.position = Vector2(1188.0, 99.0)
	probe.vel = Vector2(100.0, 100.0)
	probe.wander_t = 1.0
	probe._physics_process(0.1)
	_check(is_equal_approx(probe.position.x, 1190.0), "active movement keeps the x clamp")
	_check(is_equal_approx(probe.position.y, Y_HI), "active movement keeps the y clamp")
	return true


func _test_render_smoke(main: FakeMain, player_dog: Node2D) -> void:
	var free_dog := _make_free_dog(main, player_dog, Vector2(400.0, -120.0))
	player_dog.position = free_dog.position
	for profile_id: String in EXPECTED_IDS:
		free_dog.appearance_profile = appearance_script.call("get_profile", profile_id)
		free_dog.queue_redraw()
		await process_frame
	var invalid: Dictionary = appearance_script.call("get_profile", EXPECTED_IDS[0])
	invalid["tail_style"] = "invalid"
	free_dog.appearance_profile = invalid
	free_dog.queue_redraw()
	await process_frame
	_check(true, "all profiles draw with coincident player position")


func _cleanup() -> void:
	for index in range(fixtures.size() - 1, -1, -1):
		var fixture := fixtures[index]
		if is_instance_valid(fixture):
			fixture.free()
	fixtures.clear()


func _finish() -> void:
	_cleanup()
	if failures > 0:
		print("test_free_dog_variety: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_free_dog_variety: OK")
		quit(0)


func _run() -> void:
	appearance_script = load("res://dog_appearance.gd") as GDScript
	if appearance_script == null:
		_check(false, "dog_appearance.gd loads")
		_finish()
		return
	free_dog_script = load("res://freedog.gd") as GDScript
	if free_dog_script == null:
		_check(false, "freedog.gd loads")
		_finish()
		return
	if not _test_public_api_and_selection():
		_finish()
		return

	_test_profiles_validation_and_variety()
	_test_appearance_rng_isolation()
	var has_renderer := _script_has_method(appearance_script, "draw_dog")
	_check(has_renderer, "DogAppearance exposes draw_dog")
	if not has_renderer:
		_finish()
		return

	var main := FakeMain.new()
	main.visible = false
	root.add_child(main)
	fixtures.append(main)
	var player_dog := Node2D.new()
	player_dog.visible = false
	root.add_child(player_dog)
	fixtures.append(player_dog)
	if _test_free_dog_setup_and_lifecycle(main, player_dog):
		await _test_render_smoke(main, player_dog)
	_finish()


func _initialize() -> void:
	call_deferred("_run")
```

- [ ] **Step 3: Run the focused test and verify the intended red state**

Run:

```powershell
.\godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_free_dog_variety.gd
```

Expected: exit code `1`, a resource-load diagnostic for missing `res://dog_appearance.gd`, and:

```text
FAIL: dog_appearance.gd loads
test_free_dog_variety: 1 FAILURES
```

The test file itself must parse. Do not create a stub module to make this step green.

- [ ] **Step 4: Confirm only the test was added**

Run:

```powershell
git status --short
git diff --check -- tests/test_free_dog_variety.gd
git diff -- tests/test_free_dog_variety.gd
```

Expected: only `?? tests/test_free_dog_variety.gd`; `git diff --check` exits `0`. Do not stage or commit.

---

### Task 2: Add Profiles, Selection, and Validation

**Files:**
- Create: `dog_appearance.gd`
- Test: `tests/test_free_dog_variety.gd`

**Interfaces:**
- Consumes: exact IDs, schema, styles, and validation assertions from Task 1.
- Produces: `class_name DogAppearance extends RefCounted`.
- Produces: `const MAX_LOCAL_RADIUS := 40.0`.
- Produces: `static func profile_ids() -> PackedStringArray`.
- Produces: `static func get_profile(profile_id: String) -> Dictionary`.
- Produces: `static func profile_id_for_key(key: int) -> String`.
- Produces: `static func profile_for_key(key: int) -> Dictionary`.
- Produces: `static func validation_errors(profile: Dictionary) -> PackedStringArray`.
- Does not yet produce `draw_dog`; the focused test remains red until Task 3.

- [ ] **Step 1: Create the exact canonical data and pure API**

Create `dog_appearance.gd` with:

```gdscript
class_name DogAppearance
extends RefCounted

const MAX_LOCAL_RADIUS := 40.0
const MAX_BOB := 1.5
const PROFILE_IDS := [
	"compact_point_ear",
	"long_low_drop_ear",
	"tall_narrow_rose_ear",
	"stocky_fold_ear",
	"fluffy_curl_tail",
	"shaggy_drop_ear",
]
const REQUIRED_FIELDS := [
	"id",
	"name",
	"size_scale",
	"body_size",
	"head_radius",
	"muzzle_size",
	"ear_style",
	"ear_size",
	"ear_offset",
	"tail_style",
	"tail_length",
	"tail_thickness",
	"tail_carriage",
	"base_color",
	"secondary_color",
	"marking_color",
	"marking_style",
	"marking_offset",
	"marking_scale",
]
const POSITIVE_FLOAT_FIELDS := [
	"size_scale",
	"head_radius",
	"tail_length",
	"tail_thickness",
]
const POSITIVE_VECTOR_FIELDS := [
	"body_size",
	"muzzle_size",
	"ear_size",
	"marking_scale",
]
const PLACEMENT_VECTOR_FIELDS := [
	"ear_offset",
	"marking_offset",
]
const COLOR_FIELDS := [
	"base_color",
	"secondary_color",
	"marking_color",
]
const EAR_STYLES := ["point", "drop", "rose", "fold"]
const TAIL_STYLES := ["straight", "whip", "curl", "plume"]
const MARKING_STYLES := ["solid", "patch", "blaze_points", "brindle"]

const PROFILES := {
	"compact_point_ear": {
		"id": "compact_point_ear",
		"name": "Compact Point-Ear",
		"size_scale": 0.92,
		"body_size": Vector2(8.5, 6.5),
		"head_radius": 5.4,
		"muzzle_size": Vector2(3.8, 1.8),
		"ear_style": "point",
		"ear_size": Vector2(3.0, 5.0),
		"ear_offset": Vector2(-1.0, 3.6),
		"tail_style": "straight",
		"tail_length": 9.0,
		"tail_thickness": 2.2,
		"tail_carriage": 0.35,
		"base_color": Color(0.63, 0.43, 0.25),
		"secondary_color": Color(0.78, 0.62, 0.40),
		"marking_color": Color(0.94, 0.86, 0.68),
		"marking_style": "solid",
		"marking_offset": Vector2(-1.0, 0.0),
		"marking_scale": Vector2(2.0, 1.5),
	},
	"long_low_drop_ear": {
		"id": "long_low_drop_ear",
		"name": "Long Low Drop-Ear",
		"size_scale": 0.88,
		"body_size": Vector2(14.0, 5.0),
		"head_radius": 5.0,
		"muzzle_size": Vector2(5.0, 2.0),
		"ear_style": "drop",
		"ear_size": Vector2(3.0, 6.0),
		"ear_offset": Vector2(-2.0, 3.8),
		"tail_style": "whip",
		"tail_length": 12.0,
		"tail_thickness": 1.4,
		"tail_carriage": -0.15,
		"base_color": Color(0.74, 0.57, 0.34),
		"secondary_color": Color(0.52, 0.35, 0.20),
		"marking_color": Color(0.91, 0.80, 0.60),
		"marking_style": "patch",
		"marking_offset": Vector2(-2.5, 1.0),
		"marking_scale": Vector2(5.0, 2.8),
	},
	"tall_narrow_rose_ear": {
		"id": "tall_narrow_rose_ear",
		"name": "Tall Narrow Rose-Ear",
		"size_scale": 1.08,
		"body_size": Vector2(9.0, 4.2),
		"head_radius": 4.6,
		"muzzle_size": Vector2(4.2, 1.6),
		"ear_style": "rose",
		"ear_size": Vector2(3.5, 3.0),
		"ear_offset": Vector2(-1.2, 3.0),
		"tail_style": "straight",
		"tail_length": 12.5,
		"tail_thickness": 1.2,
		"tail_carriage": 0.05,
		"base_color": Color(0.42, 0.43, 0.46),
		"secondary_color": Color(0.61, 0.61, 0.63),
		"marking_color": Color(0.92, 0.91, 0.86),
		"marking_style": "blaze_points",
		"marking_offset": Vector2(1.5, 0.0),
		"marking_scale": Vector2(4.2, 1.1),
	},
	"stocky_fold_ear": {
		"id": "stocky_fold_ear",
		"name": "Stocky Fold-Ear",
		"size_scale": 1.12,
		"body_size": Vector2(10.0, 7.2),
		"head_radius": 6.2,
		"muzzle_size": Vector2(3.8, 2.6),
		"ear_style": "fold",
		"ear_size": Vector2(4.2, 4.0),
		"ear_offset": Vector2(-1.8, 4.0),
		"tail_style": "whip",
		"tail_length": 8.0,
		"tail_thickness": 2.0,
		"tail_carriage": 0.55,
		"base_color": Color(0.24, 0.22, 0.21),
		"secondary_color": Color(0.39, 0.32, 0.27),
		"marking_color": Color(0.62, 0.48, 0.34),
		"marking_style": "brindle",
		"marking_offset": Vector2(-1.0, 0.0),
		"marking_scale": Vector2(6.0, 5.0),
	},
	"fluffy_curl_tail": {
		"id": "fluffy_curl_tail",
		"name": "Fluffy Curl-Tail",
		"size_scale": 1.02,
		"body_size": Vector2(11.0, 7.6),
		"head_radius": 6.0,
		"muzzle_size": Vector2(4.0, 2.3),
		"ear_style": "point",
		"ear_size": Vector2(4.0, 5.5),
		"ear_offset": Vector2(-1.5, 4.2),
		"tail_style": "curl",
		"tail_length": 10.0,
		"tail_thickness": 3.0,
		"tail_carriage": 0.9,
		"base_color": Color(0.87, 0.78, 0.58),
		"secondary_color": Color(0.96, 0.90, 0.73),
		"marking_color": Color(0.58, 0.43, 0.27),
		"marking_style": "patch",
		"marking_offset": Vector2(0.5, -2.0),
		"marking_scale": Vector2(4.0, 2.8),
	},
	"shaggy_drop_ear": {
		"id": "shaggy_drop_ear",
		"name": "Shaggy Drop-Ear",
		"size_scale": 0.98,
		"body_size": Vector2(12.0, 6.2),
		"head_radius": 5.8,
		"muzzle_size": Vector2(5.2, 2.4),
		"ear_style": "drop",
		"ear_size": Vector2(3.8, 6.2),
		"ear_offset": Vector2(-1.8, 4.0),
		"tail_style": "plume",
		"tail_length": 13.0,
		"tail_thickness": 2.8,
		"tail_carriage": 0.45,
		"base_color": Color(0.36, 0.30, 0.24),
		"secondary_color": Color(0.60, 0.53, 0.42),
		"marking_color": Color(0.78, 0.72, 0.62),
		"marking_style": "brindle",
		"marking_offset": Vector2(-1.0, 0.0),
		"marking_scale": Vector2(7.0, 4.5),
	},
}


static func profile_ids() -> PackedStringArray:
	return PackedStringArray(PROFILE_IDS)


static func get_profile(profile_id: String) -> Dictionary:
	var resolved_id := profile_id if PROFILES.has(profile_id) else String(PROFILE_IDS[0])
	var canonical: Dictionary = PROFILES[resolved_id]
	return canonical.duplicate(true)


static func profile_id_for_key(key: int) -> String:
	var count := PROFILE_IDS.size()
	var index := ((key % count) + count) % count
	return String(PROFILE_IDS[index])


static func profile_for_key(key: int) -> Dictionary:
	return get_profile(profile_id_for_key(key))
```

- [ ] **Step 2: Add complete non-mutating validation**

Append to `dog_appearance.gd`:

```gdscript
static func _is_finite_vector(value: Vector2) -> bool:
	return is_finite(value.x) and is_finite(value.y)


static func _is_valid_color(value: Variant) -> bool:
	if typeof(value) != TYPE_COLOR:
		return false
	var color: Color = value
	return (
		is_finite(color.r)
		and is_finite(color.g)
		and is_finite(color.b)
		and is_finite(color.a)
		and color.r >= 0.0
		and color.r <= 1.0
		and color.g >= 0.0
		and color.g <= 1.0
		and color.b >= 0.0
		and color.b <= 1.0
		and color.a >= 0.0
		and color.a <= 1.0
	)


static func _geometry_radius(profile: Dictionary) -> float:
	var scale: float = profile["size_scale"]
	var body_size: Vector2 = profile["body_size"]
	var head_radius: float = profile["head_radius"]
	var muzzle_size: Vector2 = profile["muzzle_size"]
	var ear_size: Vector2 = profile["ear_size"]
	var ear_offset: Vector2 = profile["ear_offset"]
	var tail_length: float = profile["tail_length"]
	var tail_thickness: float = profile["tail_thickness"]
	var marking_offset: Vector2 = profile["marking_offset"]
	var marking_scale: Vector2 = profile["marking_scale"]
	var head_center_x := body_size.x * 0.65 + head_radius * 0.35
	var body_radius := body_size.length()
	var head_extent := head_center_x + head_radius
	var muzzle_extent := head_center_x + head_radius + muzzle_size.x + muzzle_size.y
	var ear_extent := head_center_x + ear_offset.length() + ear_size.length()
	var tail_extent := body_size.x * 0.8 + tail_length * 1.25 + tail_thickness * 1.65
	var marking_extent := head_center_x + marking_offset.length() + marking_scale.length()
	return (
		maxf(
			body_radius,
			maxf(
				head_extent,
				maxf(muzzle_extent, maxf(ear_extent, maxf(tail_extent, marking_extent)))
			)
		) * scale
		+ MAX_BOB
	)


static func validation_errors(profile: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	var has_missing_field := false
	for field: String in REQUIRED_FIELDS:
		if not profile.has(field):
			errors.append("missing field: " + field)
			has_missing_field = true
	for field: Variant in profile.keys():
		if not REQUIRED_FIELDS.has(String(field)):
			errors.append("unexpected field: " + String(field))
	if has_missing_field:
		return errors

	for field: String in ["id", "name"]:
		var value: Variant = profile[field]
		if typeof(value) != TYPE_STRING or String(value).strip_edges().is_empty():
			errors.append(field + " must be a non-empty String")

	for field: String in POSITIVE_FLOAT_FIELDS:
		var value: Variant = profile[field]
		if typeof(value) != TYPE_FLOAT or not is_finite(float(value)) or float(value) <= 0.0:
			errors.append(field + " must be a finite float greater than zero")

	var carriage: Variant = profile["tail_carriage"]
	if typeof(carriage) != TYPE_FLOAT or not is_finite(float(carriage)):
		errors.append("tail_carriage must be a finite float")

	for field: String in POSITIVE_VECTOR_FIELDS:
		var value: Variant = profile[field]
		if (
			typeof(value) != TYPE_VECTOR2
			or not _is_finite_vector(value)
			or (value as Vector2).x <= 0.0
			or (value as Vector2).y <= 0.0
		):
			errors.append(field + " must have finite positive components")

	for field: String in PLACEMENT_VECTOR_FIELDS:
		var value: Variant = profile[field]
		if typeof(value) != TYPE_VECTOR2 or not _is_finite_vector(value):
			errors.append(field + " must be a finite Vector2")

	for field: String in COLOR_FIELDS:
		if not _is_valid_color(profile[field]):
			errors.append(field + " must be a finite Color in [0.0, 1.0]")

	if typeof(profile["ear_style"]) != TYPE_STRING or not EAR_STYLES.has(profile["ear_style"]):
		errors.append("ear_style must be one of: point, drop, rose, fold")
	if typeof(profile["tail_style"]) != TYPE_STRING or not TAIL_STYLES.has(profile["tail_style"]):
		errors.append("tail_style must be one of: straight, whip, curl, plume")
	if (
		typeof(profile["marking_style"]) != TYPE_STRING
		or not MARKING_STYLES.has(profile["marking_style"])
	):
		errors.append("marking_style must be one of: solid, patch, blaze_points, brindle")

	if errors.is_empty() and _geometry_radius(profile) > MAX_LOCAL_RADIUS:
		errors.append("generated geometry exceeds MAX_LOCAL_RADIUS")
	return errors
```

- [ ] **Step 3: Run the focused test and verify the next intended red state**

Run:

```powershell
.\godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_free_dog_variety.gd
```

Expected: exit code `1` with:

```text
FAIL: DogAppearance exposes draw_dog
```

There must be no parse error, no validation failure for a built-in profile, and no RNG-isolation failure. This red state proves the data layer is usable while the renderer is still absent.

- [ ] **Step 4: Inspect the profile/data diff**

Run:

```powershell
git diff --check -- dog_appearance.gd tests/test_free_dog_variety.gd
git status --short
```

Expected: only the two new untracked files are reported; `freedog.gd` remains untouched; `git diff --check` exits `0`. Do not stage or commit.

---

### Task 3: Add Every Procedural Renderer Branch

**Files:**
- Modify: `dog_appearance.gd`
- Test: `tests/test_free_dog_variety.gd`

**Interfaces:**
- Consumes: validated schema and canonical profiles from Task 2.
- Produces: `static func draw_dog(canvas: CanvasItem, profile: Dictionary, origin: Vector2, forward: Vector2, bob: float, wag_phase: float) -> void`.
- Produces: pure point-conversion helpers; only `draw_dog()` issues CanvasItem draw calls.
- Guarantees: zero-length `forward` uses `Vector2.RIGHT`; `bob` is clamped to `MAX_BOB`; all generated profile geometry remains inside `MAX_LOCAL_RADIUS`.

- [ ] **Step 1: Add pure geometry helpers**

Append to `dog_appearance.gd` before `draw_dog()`:

```gdscript
static func _to_canvas(
	local_point: Vector2,
	origin: Vector2,
	forward: Vector2,
	side: Vector2
) -> Vector2:
	return origin + forward * local_point.x + side * local_point.y


static func _ellipse_points(
	center: Vector2,
	half_extents: Vector2,
	origin: Vector2,
	forward: Vector2,
	side: Vector2
) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(16):
		var angle := TAU * float(index) / 16.0
		var local_point := center + Vector2(cos(angle) * half_extents.x, sin(angle) * half_extents.y)
		points.append(_to_canvas(local_point, origin, forward, side))
	return points


static func _polygon_points(
	local_points: PackedVector2Array,
	origin: Vector2,
	forward: Vector2,
	side: Vector2
) -> PackedVector2Array:
	var points := PackedVector2Array()
	for local_point: Vector2 in local_points:
		points.append(_to_canvas(local_point, origin, forward, side))
	return points
```

- [ ] **Step 2: Add the complete renderer**

Append:

```gdscript
static func draw_dog(
	canvas: CanvasItem,
	profile: Dictionary,
	origin: Vector2,
	forward: Vector2,
	bob: float,
	wag_phase: float
) -> void:
	if (
		not _is_finite_vector(origin)
		or not is_finite(bob)
		or not is_finite(wag_phase)
	):
		return
	var active_profile := profile
	if not validation_errors(active_profile).is_empty():
		active_profile = get_profile(String(PROFILE_IDS[0]))

	var facing := forward
	if not _is_finite_vector(facing) or facing.is_zero_approx():
		facing = Vector2.RIGHT
	else:
		facing = facing.normalized()
	var side := facing.orthogonal()
	var draw_origin := origin + Vector2(0.0, clampf(bob, -MAX_BOB, MAX_BOB))
	var scale: float = active_profile["size_scale"]
	var body_size: Vector2 = active_profile["body_size"] * scale
	var head_radius: float = active_profile["head_radius"] * scale
	var muzzle_size: Vector2 = active_profile["muzzle_size"] * scale
	var ear_size: Vector2 = active_profile["ear_size"] * scale
	var ear_offset: Vector2 = active_profile["ear_offset"] * scale
	var tail_length: float = active_profile["tail_length"] * scale
	var tail_thickness: float = active_profile["tail_thickness"] * scale
	var tail_carriage: float = active_profile["tail_carriage"]
	var marking_offset: Vector2 = active_profile["marking_offset"] * scale
	var marking_scale: Vector2 = active_profile["marking_scale"] * scale
	var base_color: Color = active_profile["base_color"]
	var secondary_color: Color = active_profile["secondary_color"]
	var marking_color: Color = active_profile["marking_color"]
	var head_center := Vector2(body_size.x * 0.65 + head_radius * 0.35, 0.0)
	var tail_base := Vector2(-body_size.x * 0.8, 0.0)
	var wag := sin(wag_phase) * 0.35
	var tail_angle := tail_carriage + wag
	var tail_direction := Vector2(-cos(tail_angle), sin(tail_angle))

	match String(active_profile["tail_style"]):
		"straight":
			canvas.draw_line(
				_to_canvas(tail_base, draw_origin, facing, side),
				_to_canvas(tail_base + tail_direction * tail_length, draw_origin, facing, side),
				secondary_color,
				tail_thickness,
				true
			)
		"whip":
			var whip := PackedVector2Array([
				_to_canvas(tail_base, draw_origin, facing, side),
				_to_canvas(
					tail_base + tail_direction * tail_length * 0.55 + Vector2(0.0, wag * 3.0),
					draw_origin,
					facing,
					side
				),
				_to_canvas(
					tail_base + tail_direction * tail_length + Vector2(0.0, wag * 5.0),
					draw_origin,
					facing,
					side
				),
			])
			canvas.draw_polyline(whip, secondary_color, tail_thickness, true)
		"curl":
			var curl_radius := tail_length * 0.42
			var curl_center_local := (
				tail_base
				+ tail_direction * (tail_length - curl_radius)
				+ Vector2(0.0, wag * 2.0)
			)
			var curl_center := _to_canvas(curl_center_local, draw_origin, facing, side)
			var curl_start := facing.angle() + tail_angle + PI * 0.25
			canvas.draw_arc(
				curl_center,
				curl_radius,
				curl_start,
				curl_start + PI * 1.65,
				14,
				secondary_color,
				tail_thickness,
				true
			)
		"plume":
			var plume := PackedVector2Array([
				_to_canvas(tail_base, draw_origin, facing, side),
				_to_canvas(
					tail_base + tail_direction * tail_length * 0.5 + Vector2(0.0, -tail_length * 0.2),
					draw_origin,
					facing,
					side
				),
				_to_canvas(
					tail_base + tail_direction * tail_length + Vector2(0.0, wag * 4.0),
					draw_origin,
					facing,
					side
				),
			])
			canvas.draw_polyline(plume, secondary_color, tail_thickness * 1.65, true)
			canvas.draw_polyline(plume, base_color, tail_thickness * 0.7, true)

	canvas.draw_colored_polygon(
		_ellipse_points(Vector2.ZERO, body_size, draw_origin, facing, side),
		base_color
	)

	match String(active_profile["marking_style"]):
		"solid":
			pass
		"patch":
			canvas.draw_colored_polygon(
				_ellipse_points(marking_offset, marking_scale, draw_origin, facing, side),
				marking_color
			)
		"blaze_points":
			var blaze_center := head_center + marking_offset
			canvas.draw_line(
				_to_canvas(
					blaze_center - Vector2(marking_scale.x * 0.5, 0.0),
					draw_origin,
					facing,
					side
				),
				_to_canvas(
					blaze_center + Vector2(marking_scale.x * 0.5, 0.0),
					draw_origin,
					facing,
					side
				),
				marking_color,
				maxf(1.0, marking_scale.y),
				true
			)
			canvas.draw_circle(
				_to_canvas(
					head_center + Vector2(0.0, head_radius * 0.55),
					draw_origin,
					facing,
					side
				),
				maxf(0.8, marking_scale.y * 0.65),
				marking_color
			)
			canvas.draw_circle(
				_to_canvas(
					head_center + Vector2(0.0, -head_radius * 0.55),
					draw_origin,
					facing,
					side
				),
				maxf(0.8, marking_scale.y * 0.65),
				marking_color
			)
		"brindle":
			for stripe_index in range(-2, 3):
				var stripe_x := marking_offset.x + float(stripe_index) * marking_scale.x * 0.22
				var stripe_half_y := marking_scale.y * (0.45 + 0.08 * absf(float(stripe_index)))
				canvas.draw_line(
					_to_canvas(
						Vector2(stripe_x - marking_scale.x * 0.08, marking_offset.y - stripe_half_y),
						draw_origin,
						facing,
						side
					),
					_to_canvas(
						Vector2(stripe_x + marking_scale.x * 0.08, marking_offset.y + stripe_half_y),
						draw_origin,
						facing,
						side
					),
					marking_color,
					maxf(0.8, scale),
					true
				)

	canvas.draw_colored_polygon(
		_ellipse_points(head_center, Vector2(head_radius, head_radius), draw_origin, facing, side),
		base_color
	)

	for ear_side in [-1.0, 1.0]:
		var ear_base := head_center + Vector2(ear_offset.x, ear_offset.y * ear_side)
		match String(active_profile["ear_style"]):
			"point":
				var point_ear := PackedVector2Array([
					ear_base + Vector2(ear_size.x * 0.45, -ear_size.x * 0.45 * ear_side),
					ear_base + Vector2(-ear_size.y, 0.0),
					ear_base + Vector2(ear_size.x * 0.45, ear_size.x * 0.45 * ear_side),
				])
				canvas.draw_colored_polygon(
					_polygon_points(point_ear, draw_origin, facing, side),
					secondary_color
				)
			"drop":
				var drop_ear := PackedVector2Array([
					ear_base + Vector2(ear_size.x * 0.35, -ear_size.x * 0.45 * ear_side),
					ear_base + Vector2(-ear_size.x * 0.3, ear_size.y * ear_side),
					ear_base + Vector2(-ear_size.x, ear_size.y * 0.65 * ear_side),
					ear_base + Vector2(-ear_size.x * 0.4, ear_size.x * 0.45 * ear_side),
				])
				canvas.draw_colored_polygon(
					_polygon_points(drop_ear, draw_origin, facing, side),
					secondary_color
				)
			"rose":
				var rose_ear := PackedVector2Array([
					ear_base + Vector2(ear_size.x * 0.45, -ear_size.y * 0.5 * ear_side),
					ear_base + Vector2(-ear_size.x, 0.0),
					ear_base + Vector2(ear_size.x * 0.25, ear_size.y * 0.5 * ear_side),
				])
				canvas.draw_colored_polygon(
					_polygon_points(rose_ear, draw_origin, facing, side),
					secondary_color
				)
			"fold":
				var fold_ear := PackedVector2Array([
					ear_base + Vector2(ear_size.x * 0.5, -ear_size.y * 0.4 * ear_side),
					ear_base + Vector2(-ear_size.x, -ear_size.y * 0.2 * ear_side),
					ear_base + Vector2(-ear_size.x * 0.2, ear_size.y * ear_side),
					ear_base + Vector2(ear_size.x * 0.45, ear_size.y * 0.35 * ear_side),
				])
				canvas.draw_colored_polygon(
					_polygon_points(fold_ear, draw_origin, facing, side),
					secondary_color
				)
				canvas.draw_line(
					_to_canvas(ear_base, draw_origin, facing, side),
					_to_canvas(
						ear_base + Vector2(-ear_size.x * 0.35, ear_size.y * 0.35 * ear_side),
						draw_origin,
						facing,
						side
					),
					base_color,
					maxf(0.8, scale),
					true
				)

	var muzzle_center := head_center + Vector2(head_radius + muzzle_size.x * 0.45, 0.0)
	canvas.draw_colored_polygon(
		_ellipse_points(
			muzzle_center,
			Vector2(muzzle_size.x * 0.55, muzzle_size.y),
			draw_origin,
			facing,
			side
		),
		secondary_color
	)
	for eye_side in [-1.0, 1.0]:
		canvas.draw_circle(
			_to_canvas(
				head_center + Vector2(head_radius * 0.3, head_radius * 0.42 * eye_side),
				draw_origin,
				facing,
				side
			),
			maxf(0.7, scale),
			Color(0.08, 0.07, 0.06)
		)
	canvas.draw_circle(
		_to_canvas(
			muzzle_center + Vector2(muzzle_size.x * 0.52, 0.0),
			draw_origin,
			facing,
			side
		),
		maxf(1.0, muzzle_size.y * 0.45),
		Color(0.08, 0.07, 0.06)
	)
```

- [ ] **Step 3: Run the focused test and verify renderer coverage is green but integration remains red**

Run:

```powershell
.\godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_free_dog_variety.gd
```

Expected: exit code `1` with:

```text
FAIL: freedog stores appearance_profile
```

There must be no profile validation error and no renderer parse error. The test cannot yet enter its per-profile free-dog render smoke because Task 4 has not added `appearance_profile`.

- [ ] **Step 4: Verify the appearance module contains no RNG or lifecycle dependency**

Run:

```powershell
rg -n "seed|randf|randi|randomize|RandomNumberGenerator|main|freedom|greet|leash|owner" dog_appearance.gd
rg -n "draw_(line|circle|arc|polyline|colored_polygon)" dog_appearance.gd
```

Expected: the first command has no matches. The second command reports draw calls only inside `draw_dog`; no helper or profile/validation function issues a CanvasItem draw call.

---

### Task 4: Integrate Deterministic Appearance Without Gameplay Changes

**Files:**
- Modify: `freedog.gd:1-57`
- Test: `tests/test_free_dog_variety.gd`

**Interfaces:**
- Consumes: `DogAppearanceScript.profile_for_key(key: int) -> Dictionary` and `DogAppearanceScript.draw_dog(...)`.
- Produces: `var appearance_profile: Dictionary = {}` for focused tests and future explicit profile reuse.
- Produces: `_appearance_key(y_lo: float, y_hi: float) -> int`, based only on rounded position and bounds.
- Preserves: `setup(main, player_dog, freedom_y_lo, freedom_y_hi)`, `freedogs` membership, lifecycle fields, and the existing `_physics_process` body.

- [ ] **Step 1: Preload the appearance module and add profile state**

At the top of `freedog.gd`, change:

```gdscript
extends Node2D
```

to:

```gdscript
extends Node2D

const DogAppearanceScript := preload("res://dog_appearance.gd")
```

Add the profile beside the existing visual state:

```gdscript
var seed_o := 0.0
var col := Color(0.6, 0.5, 0.4)
var appearance_profile: Dictionary = {}
var lo := 0.0
```

- [ ] **Step 2: Replace only setup-time appearance randomness**

Insert this helper immediately before `setup`:

```gdscript
func _appearance_key(y_lo: float, y_hi: float) -> int:
	return (
		roundi(position.x) * 73856093
		+ roundi(position.y) * 19349663
		+ roundi(y_lo) * 83492791
		+ roundi(y_hi) * 2654435761
	)
```

Replace the existing `setup` with:

```gdscript
func setup(m: Node2D, mine: Node2D, y_lo: float, y_hi: float) -> void:
	add_to_group("freedogs")
	main = m
	my_dog = mine
	lo = y_lo
	hi = y_hi
	var appearance_key := _appearance_key(y_lo, y_hi)
	appearance_profile = DogAppearanceScript.profile_for_key(appearance_key)
	var phase_bucket := ((appearance_key % 10000) + 10000) % 10000
	seed_o = float(phase_bucket) / 1000.0
	col = appearance_profile["base_color"]
```

This intentionally removes the two setup-time appearance RNG calls. Do not alter, move, or add any random call in `_physics_process`.

- [ ] **Step 3: Preserve the gameplay callback exactly**

Leave this function unchanged:

```gdscript
func _physics_process(delta: float) -> void:
	if main.frozen or main.phase != "freedom":
		return
	wander_t -= delta
	if wander_t <= 0.0:
		wander_t = randf_range(0.5, 1.5)
		# mostly mill about; sometimes bolt after your dog to play
		if randf() < 0.4 and my_dog.global_position.distance_to(global_position) < 300.0:
			vel = (my_dog.global_position - global_position).normalized() * 150.0
		else:
			vel = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 110.0
	bow += delta
	position += vel * delta
	vel = vel.move_toward(Vector2.ZERO, 120.0 * delta)
	position.x = clampf(position.x, 90.0, 1190.0)
	position.y = clampf(position.y, lo, hi)
	queue_redraw()
```

- [ ] **Step 4: Delegate drawing while preserving bob and wag timing**

Replace `_draw()` with:

```gdscript
func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var b := sin(bow * 6.0 + seed_o) * 1.5
	var face := (my_dog.global_position - global_position).normalized()
	DogAppearanceScript.draw_dog(
		self,
		appearance_profile,
		Vector2.ZERO,
		face,
		b,
		t * 12.0 + seed_o
	)
```

- [ ] **Step 5: Run the focused test to green**

Run:

```powershell
.\godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_free_dog_variety.gd
```

Expected: exit code `0` and:

```text
test_free_dog_variety: OK
```

The per-profile redraw loop must advance one frame for all six profiles with the player dog coincident with the free dog, exercising the stable zero-forward fallback without draw errors.

- [ ] **Step 6: Re-run to prove fresh-process determinism**

Run:

```powershell
1..3 | ForEach-Object {
  .\godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_free_dog_variety.gd
  if ($LASTEXITCODE -ne 0) { throw "focused run $_ failed" }
}
```

Expected: three `test_free_dog_variety: OK` markers and no parse, runtime, or draw errors.

---

### Task 5: Establish the Pair RNG and Lifecycle Regression

**Files:**
- Create: `tests/test_pair_dog_appearance.gd`
- Inspect only: `otherpair.gd`
- Test: `tests/test_pair_park_lifecycle.gd`

**Interfaces:**
- Consumes: the complete `DogAppearance` API from Tasks 2-3 and real `otherpair.gd`/`leash.gd`.
- Produces: a separate `SceneTree` regression with `test_pair_dog_appearance: OK`, keeping pair RNG and lifecycle fixtures out of the catalog/free-dog test.
- Specifies: `otherpair.gd` must expose `appearance_profile: Dictionary` and keep the same dictionary through every `PairState`.

- [ ] **Step 1: Write the failing real-pair regression**

Create `tests/test_pair_dog_appearance.gd`:

```gdscript
extends SceneTree

const DogAppearanceScript := preload("res://dog_appearance.gd")
const PairScript := preload("res://otherpair.gd")
const DT := 1.0 / 60.0
const PARK_BOUNDS := Rect2(20.0, -260.0, 360.0, 230.0)
const PARK_SPOT := Vector2(300.0, -90.0)
const WALKING := 0
const ARRIVING := 1
const PARKED := 2
const RECALLING := 3
const DEPARTING := 4
const OWNER_COLORS := [
	Color(0.5, 0.45, 0.55),
	Color(0.45, 0.5, 0.42),
	Color(0.55, 0.48, 0.4),
]

var failures := 0
var fixtures: Array[Node] = []


class FakeMain:
	extends Node2D

	var phase := "freedom"
	var frozen := false
	var cam := Camera2D.new()
	var released_pair_ids: Array[int] = []

	func _init() -> void:
		add_child(cam)

	func release_pair_park_spot(pair_instance_id: int) -> void:
		released_pair_ids.append(pair_instance_id)

	func float_text(_position: Vector2, _text: String, _color: Color) -> void:
		pass


func _check(condition: bool, message: String) -> void:
	if not condition:
		print("FAIL: " + message)
		failures += 1


func _has_property(object: Object, property_name: String) -> bool:
	for property: Dictionary in object.get_property_list():
		if String(property.get("name", "")) == property_name:
			return true
	return false


func _make_main() -> FakeMain:
	var main := FakeMain.new()
	main.visible = false
	root.add_child(main)
	fixtures.append(main)
	return main


func _make_player() -> Node2D:
	var player := Node2D.new()
	player.visible = false
	player.position = Vector2(1000.0, 1000.0)
	root.add_child(player)
	fixtures.append(player)
	return player


func _make_pair(
	main: FakeMain,
	player: Node2D,
	seed_value: int,
	start := Vector2(200.0, 120.0),
	direction := Vector2.UP
) -> Node2D:
	seed(seed_value)
	var pair := Node2D.new()
	pair.set_script(PairScript)
	var poles: Array[Vector2] = []
	pair.setup(main, player, poles, start, direction)
	var blockers: Array[Dictionary] = []
	_check(
		bool(pair.configure_route(start.x, 20.0, 380.0, blockers)),
		"real pair route configures"
	)
	root.add_child(pair)
	pair.set_physics_process(false)
	fixtures.append(pair)
	main.cam.position = pair.npc_owner.position
	return pair


func _state(pair: Node2D) -> int:
	return int(pair.get_pair_state())


func _check_profile_identity(
	pair: Node2D,
	original_profile: Dictionary,
	original_id: String,
	label: String
) -> void:
	_check(
		is_same(pair.appearance_profile, original_profile),
		label + " keeps the same profile dictionary"
	)
	_check(
		String(pair.appearance_profile.get("id", "")) == original_id,
		label + " keeps the same profile ID"
	)


func _test_exact_setup_rng(main: FakeMain, player: Node2D) -> void:
	const RNG_SEED := 424242
	var direction := Vector2.UP
	seed(RNG_SEED)
	var expected_speed := randf_range(58.0, 82.0)
	var expected_seed_o := randf() * 10.0
	var owner_key := randi()
	var dog_key := randi()
	var expected_next := randf()

	seed(RNG_SEED)
	var pair := Node2D.new()
	pair.set_script(PairScript)
	var poles: Array[Vector2] = []
	pair.setup(main, player, poles, Vector2(200.0, 120.0), direction)
	var actual_next := randf()
	root.add_child(pair)
	pair.set_physics_process(false)
	fixtures.append(pair)

	_check(pair.vel.is_equal_approx(direction * expected_speed), "velocity uses the first randf_range")
	_check(is_equal_approx(pair.seed_o, expected_seed_o), "seed_o uses the second randf")
	_check(pair.owner_col == OWNER_COLORS[owner_key % OWNER_COLORS.size()], "owner color uses the third randi")
	var expected_profile: Dictionary = DogAppearanceScript.profile_for_key(dog_key)
	_check(pair.appearance_profile == expected_profile, "raw fourth randi selects the dog profile")
	_check(pair.dog_col == expected_profile["base_color"], "compatibility dog_col follows the profile")
	_check(is_equal_approx(actual_next, expected_next), "pair setup preserves the following RNG value")

	var repeated := _make_pair(main, player, RNG_SEED)
	_check(repeated.appearance_profile == pair.appearance_profile, "equal seeds select equal pair profiles")
	_check(is_equal_approx(repeated.seed_o, pair.seed_o), "equal seeds select equal pair phases")

	var selected_ids := {}
	for seed_value in [11, 29, 47, 83, 131, 197]:
		var candidate := _make_pair(main, player, seed_value)
		selected_ids[String(candidate.appearance_profile["id"])] = true
	_check(selected_ids.size() > 1, "representative seeds select multiple profiles")


func _test_lifecycle_profile_persistence(main: FakeMain, player: Node2D) -> Node2D:
	var pair := _make_pair(main, player, 1707)
	pair.configure_park_area(0.0, PARK_BOUNDS)
	var profile: Dictionary = pair.appearance_profile
	var profile_id := String(profile["id"])
	var pair_id := pair.get_instance_id()
	var owner_id := pair.npc_owner.get_instance_id()
	var dog_id := pair.npc_dog.get_instance_id()
	var leash_id := pair.leash.get_instance_id()

	_check(_state(pair) == WALKING, "pair starts WALKING")
	_check_profile_identity(pair, profile, profile_id, "WALKING")
	_check(bool(pair.begin_park_arrival(7, PARK_SPOT)), "pair starts arrival")
	_check(_state(pair) == ARRIVING, "pair enters ARRIVING")
	_check_profile_identity(pair, profile, profile_id, "ARRIVING")

	pair._enter_parked(100.0)
	_check(_state(pair) == PARKED, "pair enters PARKED")
	_check_profile_identity(pair, profile, profile_id, "PARKED")
	_check(pair.leash.detached and not pair.leash.visible, "PARKED keeps the leash suspended")

	pair.begin_park_recall()
	_check(_state(pair) == RECALLING, "pair enters RECALLING")
	_check_profile_identity(pair, profile, profile_id, "RECALLING")
	pair.npc_dog.position = pair.npc_owner.position
	pair._physics_process(0.0)
	_check(_state(pair) == DEPARTING, "close recall enters DEPARTING")
	_check_profile_identity(pair, profile, profile_id, "DEPARTING")
	_check(not pair.leash.detached and pair.leash.visible, "DEPARTING restores the real leash")

	pair.npc_owner.position = Vector2(pair.walking_lane_x, 80.0)
	pair._physics_process(0.0)
	_check(_state(pair) == WALKING, "gate clearance resumes WALKING")
	_check_profile_identity(pair, profile, profile_id, "resumed WALKING")
	_check(pair.get_instance_id() == pair_id, "pair identity persists")
	_check(pair.npc_owner.get_instance_id() == owner_id, "owner identity persists")
	_check(pair.npc_dog.get_instance_id() == dog_id, "dog identity persists")
	_check(pair.leash.get_instance_id() == leash_id, "leash identity persists")
	return pair


func _test_parked_departure_and_home_interrupt(main: FakeMain, player: Node2D) -> void:
	var departure := _make_pair(main, player, 2718)
	departure.configure_park_area(0.0, PARK_BOUNDS)
	var departure_profile: Dictionary = departure.appearance_profile
	var departure_id := String(departure_profile["id"])
	_check(
		bool(departure.initialize_parked_departure(
			9,
			PARK_SPOT,
			Vector2(80.0, -220.0),
			100.0
		)),
		"parked departure initializes"
	)
	_check_profile_identity(departure, departure_profile, departure_id, "initialized PARKED")

	var interrupted := _make_pair(main, player, 3141)
	interrupted.configure_park_area(0.0, PARK_BOUNDS)
	var interrupted_profile: Dictionary = interrupted.appearance_profile
	var interrupted_id := String(interrupted_profile["id"])
	_check(bool(interrupted.begin_park_arrival(10, PARK_SPOT)), "interrupt fixture enters ARRIVING")
	main.phase = "home"
	interrupted._physics_process(0.0)
	_check(_state(interrupted) == RECALLING, "home interrupts arrival into RECALLING")
	_check_profile_identity(interrupted, interrupted_profile, interrupted_id, "home-interrupted RECALLING")
	main.phase = "freedom"


func _test_render_smoke(pair: Node2D, player: Node2D) -> void:
	player.position = pair.npc_dog.position
	seed(98765)
	var expected_next := randf()
	seed(98765)
	for profile_id: String in DogAppearanceScript.profile_ids():
		pair.appearance_profile = DogAppearanceScript.get_profile(profile_id)
		pair.queue_redraw()
		await process_frame
	var actual_next := randf()
	_check(is_equal_approx(actual_next, expected_next), "pair drawing preserves global RNG")
	_check(true, "parent CanvasItem draws owner and every dog profile at zero forward")


func _cleanup() -> void:
	for index in range(fixtures.size() - 1, -1, -1):
		var fixture := fixtures[index]
		if is_instance_valid(fixture):
			fixture.free()
	fixtures.clear()


func _finish() -> void:
	_cleanup()
	if failures > 0:
		print("test_pair_dog_appearance: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_pair_dog_appearance: OK")
		quit(0)


func _run() -> void:
	var probe := Node2D.new()
	probe.set_script(PairScript)
	var has_profile := _has_property(probe, "appearance_profile")
	_check(has_profile, "otherpair stores appearance_profile")
	probe.free()
	if not has_profile:
		_finish()
		return

	var main := _make_main()
	var player := _make_player()
	_test_exact_setup_rng(main, player)
	var lifecycle_pair := _test_lifecycle_profile_persistence(main, player)
	_test_parked_departure_and_home_interrupt(main, player)
	await _test_render_smoke(lifecycle_pair, player)
	_finish()


func _initialize() -> void:
	call_deferred("_run")
```

- [ ] **Step 2: Run the pair test and verify the intended failure**

Run:

```powershell
.\godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_pair_dog_appearance.gd
```

Expected: exit code `1` with:

```text
FAIL: otherpair stores appearance_profile
test_pair_dog_appearance: 1 FAILURES
```

There must be no parse error and no copied fake pair implementation.

---

### Task 6: Integrate Shared Appearance Into Real NPC Pairs

**Files:**
- Modify: `otherpair.gd:1-79,460-474`
- Test: `tests/test_pair_dog_appearance.gd`
- Regression: `tests/test_pair_park_lifecycle.gd`

**Interfaces:**
- Consumes: `DogAppearanceScript.profile_for_key(key: int) -> Dictionary` and `draw_dog(...)`.
- Produces: `var appearance_profile: Dictionary = {}` owned by one persistent pair.
- Preserves: `setup(m: Node2D, mine: Node2D, poles: Array[Vector2], start: Vector2, direction: Vector2) -> void` and every existing pair state/movement/leash method.

- [ ] **Step 1: Preload the module and add persistent profile state**

Add beside the existing route preload:

```gdscript
const BypasserRouteScript := preload("res://bypasser_route.gd")
const DogAppearanceScript := preload("res://dog_appearance.gd")
```

Add beside `dog_col`:

```gdscript
var owner_col := Color(0.5, 0.45, 0.55)
var dog_col := Color(0.6, 0.5, 0.4)
var appearance_profile: Dictionary = {}
var wander_t := 0.0
```

- [ ] **Step 2: Reuse exactly the existing fourth random draw**

Replace only the four appearance/setup lines with:

```gdscript
	vel = direction * randf_range(58.0, 82.0)
	seed_o = randf() * 10.0
	owner_col = [Color(0.5, 0.45, 0.55), Color(0.45, 0.5, 0.42), Color(0.55, 0.48, 0.4)][randi() % 3]
	var dog_appearance_key := randi()
	appearance_profile = DogAppearanceScript.profile_for_key(dog_appearance_key)
	dog_col = appearance_profile["base_color"]
```

The order is velocity `randf_range`, phase `randf`, owner `randi`, dog appearance `randi`. Do not call RNG before, between, or after these lines for appearance.

- [ ] **Step 3: Keep owner drawing and delegate only dog drawing**

Replace `_draw()` with:

```gdscript
func _draw() -> void:
	# NPC owner (no glowing phone - they are present, unlike yours)
	var op: Vector2 = npc_owner.position
	draw_circle(op + Vector2(0, 14), 5.0, Color(0.25, 0.25, 0.3))
	draw_circle(op, 13.0, owner_col)
	draw_circle(op + Vector2(0, -12), 7.0, Color(0.85, 0.72, 0.58))
	draw_arc(op + Vector2(0, -12), 7.0, PI, TAU, 10, Color(0.3, 0.24, 0.16), 4.0)
	# NPC dog remains drawn by the pair parent; npc_dog stays the real endpoint.
	var dp: Vector2 = npc_dog.position
	var t := Time.get_ticks_msec() / 1000.0
	var facing := (my_dog.global_position - dp).normalized()
	var bob := sin(t * 6.0 + seed_o) * 1.5
	var wag := t * 8.0 + seed_o
	DogAppearanceScript.draw_dog(
		self,
		appearance_profile,
		dp,
		facing,
		bob,
		wag
	)
```

Do not alter any pair state transition, movement, route, leash, tangle, greeting, group, slot, or cleanup code.

- [ ] **Step 4: Run the pair test to green**

Run:

```powershell
.\godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_pair_dog_appearance.gd
```

Expected:

```text
test_pair_dog_appearance: OK
```

- [ ] **Step 5: Run focused lifecycle and free-dog tests**

Run:

```powershell
foreach ($test in @(
  "test_free_dog_variety.gd",
  "test_pair_dog_appearance.gd",
  "test_pair_park_lifecycle.gd",
  "test_pair_park_traffic.gd"
)) {
  .\godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script "res://tests/$test"
  if ($LASTEXITCODE -ne 0) { throw "$test failed" }
}
```

Expected: all four commands exit `0` and print their `: OK` markers.

---

### Task 7: Verify and Review the Isolated Five-File Boundary

**Files:**
- Review: `freedog.gd`
- Review: `otherpair.gd`
- Review: `dog_appearance.gd`
- Review: `tests/test_free_dog_variety.gd`
- Review: `tests/test_pair_dog_appearance.gd`
- Do not modify any other file.

**Interfaces:**
- Consumes: complete isolated implementation from Tasks 1-6.
- Produces: review evidence that the exact API, all visual branches, real lifecycle contracts, regressions, park smoke, and full traversal pass.
- Produces: the approval gate required before any CI/docs edit, commit, or push.

- [ ] **Step 1: Run every current SceneTree regression**

Run:

```powershell
$tests = @(
  "test_free_dog_variety.gd",
  "test_pair_dog_appearance.gd",
  "test_wrap.gd",
  "test_critter_chase.gd",
  "test_tangle_latch.gd",
  "test_freedom_traffic.gd",
  "test_pair_direction.gd",
  "test_bandana_preview.gd",
  "test_owner_label.gd",
  "test_bypasser_route.gd",
  "test_rider_avoidance.gd",
  "test_pair_pond_avoidance.gd",
  "test_pair_park_lifecycle.gd",
  "test_pair_park_slots.gd",
  "test_pair_park_traffic.gd"
)
foreach ($test in $tests) {
  .\godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script "res://tests/$test"
  if ($LASTEXITCODE -ne 0) { throw "$test failed" }
}
```

Expected: every command exits `0` and prints its own `: OK` marker. `test_wrap.gd` may also print rope metrics.

- [ ] **Step 2: Run all four CI level smokes**

Run:

```powershell
foreach ($level in @("street", "park", "beach", "market")) {
  $smoke = & .\godot\Godot_v4.7-stable_win64_console.exe --headless --path . --quit-after 1800 -- "--level=$level" 2>&1
  $exitCode = $LASTEXITCODE
  $smoke | Set-Content "build\shared-dog-smoke-$level.log"
  $smoke
  if ($exitCode -ne 0) { throw "$level smoke failed" }
  if ($smoke -match "SCRIPT ERROR|Parse Error|Failed to load script") {
    throw "$level smoke logged a script failure"
  }
}
```

Expected: all four commands exit `0`; no log contains `SCRIPT ERROR`, `Parse Error`, or `Failed to load script`. `build/` is gitignored.

- [ ] **Step 3: Run deterministic street and park autowalk**

Run:

```powershell
foreach ($level in @("street", "park")) {
  $autowalk = & .\godot\Godot_v4.7-stable_win64_console.exe --headless --fixed-fps 60 --path . --quit-after 12000 -- "--level=$level" --autowalk 2>&1
  $exitCode = $LASTEXITCODE
  $autowalk | Set-Content "build\shared-dog-autowalk-$level.log"
  $autowalk
  if ($exitCode -ne 0) { throw "$level autowalk failed" }
  if ($autowalk -match "SCRIPT ERROR|Parse Error|Failed to load script") {
    throw "$level autowalk logged a script failure"
  }
  if ($autowalk -notmatch "AUTOWALK FINISHED") {
    throw "$level autowalk did not finish"
  }
}
```

Expected: both commands exit `0`, log no script/load error, and include `AUTOWALK FINISHED`. Street mirrors CI; park exercises shared pair/free-dog freedom rendering.

- [ ] **Step 4: Perform the visual park review**

Run:

```powershell
.\godot\Godot_v4.7-stable_win64.exe --path . -- --level=park
```

During corridor walking and the freedom phase, verify all of the following before approval:

1. free dogs and pair dogs share visibly distinguishable generic silhouettes/coats at gameplay scale;
2. point, drop, rose, and fold ear treatments remain legible;
3. straight, whip, curl, and plume tails animate without detaching;
4. solid, patch, blaze/points, and brindle treatments are visible;
5. bob and wag remain happy and stable;
6. no shape extends implausibly beyond the 40-pixel local envelope;
7. free dogs still wander, approach, decelerate, greet once, remain bounded, and disappear on the home transition;
8. pair dogs keep the same appearance through arrival, parking, recall, re-leashing, departure, and resumed walking;
9. pair owner art is unchanged and pair leashes remain attached to the real `npc_dog` endpoint;
10. free-dog spawn count/z-order and pair movement, tangles, slots, and cleanup remain unchanged.

Record any visual tuning defect as a profile/renderer-only correction. Do not alter gameplay to fix appearance.

- [ ] **Step 5: Review forbidden calls, names, and exact API**

Run:

```powershell
rg -n "seed|randf|randi|randomize|RandomNumberGenerator" dog_appearance.gd
rg -n "hat|glasses|bald|long hair|character.creator|gameplay.stat|playable.selector" dog_appearance.gd freedog.gd otherpair.gd tests/test_free_dog_variety.gd tests/test_pair_dog_appearance.gd
rg -n "static func (profile_ids|get_profile|profile_id_for_key|profile_for_key|validation_errors|draw_dog)" dog_appearance.gd
rg -n "func setup\(m: Node2D, mine: Node2D, y_lo: float, y_hi: float\) -> void" freedog.gd
rg -n "func setup\(m: Node2D, mine: Node2D, poles: Array\[Vector2\], start: Vector2, direction: Vector2\) -> void" otherpair.gd
```

Expected: the first two commands have no matches. The API command reports the six supported static functions, and both caller commands report unchanged setup signatures.

- [ ] **Step 6: Inspect the exact isolated diff and status**

Run:

```powershell
git diff --check
git diff -- dog_appearance.gd freedog.gd otherpair.gd tests/test_free_dog_variety.gd tests/test_pair_dog_appearance.gd
git status --short
```

Expected: `git diff --check` exits `0`; all production/test changes are limited to:

```text
 M freedog.gd
 M otherpair.gd
?? dog_appearance.gd
?? tests/test_free_dog_variety.gd
?? tests/test_pair_dog_appearance.gd
```

There must be no change to `main.gd`, `leash.gd`, existing tests, CI, changelog, handover, roadmap/spec files, or owner visuals.

- [ ] **Step 7: Run stage-one spec-compliance review**

Provide the reviewer:

```text
Review only dog_appearance.gd, freedog.gd, otherpair.gd,
tests/test_free_dog_variety.gd, and tests/test_pair_dog_appearance.gd.
Check exact DogAppearance API/schema, defensive copies, positive modulo,
validation and MAX_LOCAL_RADIUS, RNG isolation, all ear/tail/marking renderer
branches, deterministic freedog setup, unchanged wander RNG order/cadence,
exact pair randf_range/randf/owner-randi/dog-randi cadence, persistent pair
profile through every PairState, unchanged caller setup signatures, parent
owner drawing, group/greeting/leash/tangle/slot/cleanup contracts, and both
real-script tests. CI/docs are deferred until this five-file boundary passes
both review stages.
```

Expected: every approved spec requirement maps to code and a test. Resolve all findings inside the five-file boundary and rerun Steps 1-6.

- [ ] **Step 8: Run stage-two code-quality review**

Provide the second reviewer:

```text
Review the accepted five-file implementation for GDScript correctness,
headless safety, finite geometry, renderer-only draw calls, avoidable
duplication, hidden RNG consumption, dictionary aliasing, lifecycle mutation,
and accidental gameplay or owner-visual changes. Treat the stage-one
spec-compliance result as fixed scope; report only concrete correctness,
maintainability, or regression risks.
```

Expected: no unresolved correctness or maintainability finding. Resolve findings, rerun Steps 1-6, and repeat both review stages. No commit, push, CI edit, or docs edit occurs until both reviews pass and the parent explicitly authorizes integration.

---

### Task 8: Create the Authorized Implementation Checkpoint

**Files:**
- Stage only: `freedog.gd`
- Stage only: `otherpair.gd`
- Stage only: `dog_appearance.gd`
- Stage only: `tests/test_free_dog_variety.gd`
- Stage only: `tests/test_pair_dog_appearance.gd`

**Interfaces:**
- Consumes: both approved Task 7 five-file reviews.
- Produces: one isolated implementation commit only if the parent agent explicitly supersedes the original no-commit instruction.
- Does not push; final push remains gated after Task 9.

- [ ] **Step 1: Confirm explicit authorization**

Do not infer approval from passing tests. Obtain an explicit instruction equivalent to:

```text
The five-file shared NPC dog appearance implementation passed both reviews.
You may commit it and
continue with CI/docs integration.
```

If authorization is absent, stop here with the working tree uncommitted.

- [ ] **Step 2: Re-run the focused test immediately before staging**

Run:

```powershell
.\godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_free_dog_variety.gd
.\godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_pair_dog_appearance.gd
```

Expected: both focused tests print `: OK`.

- [ ] **Step 3: Stage only the implementation boundary and inspect it**

Run:

```powershell
git add -- dog_appearance.gd freedog.gd otherpair.gd tests/test_free_dog_variety.gd tests/test_pair_dog_appearance.gd
git diff --cached --check
git diff --cached --name-only
```

Expected staged names, exactly:

```text
dog_appearance.gd
freedog.gd
otherpair.gd
tests/test_free_dog_variety.gd
tests/test_pair_dog_appearance.gd
```

- [ ] **Step 4: Commit the reviewed implementation**

Run only with Step 1 authorization:

```powershell
git commit -m "Add shared NPC dog appearances"
```

Expected: one commit containing exactly the five reviewed files. Do not push yet.

---

### Task 9: Finalize CI and Documentation After Review

**Files:**
- Modify: `.github/workflows/ci.yml:59-62`
- Modify: `CHANGELOG.md:5`
- Modify: `HANDOVER.md:71-76,153-166,197-209`

**Interfaces:**
- Consumes: both reviewed focused tests and the authorized implementation commit from Task 8.
- Produces: Linux CI execution of both focused tests and accurate append-only project documentation.
- Produces: final regression/smoke/diff evidence and a separately reviewable integration commit.

- [ ] **Step 1: Add both focused tests to CI**

Immediately before `Headless smoke tests (all levels)` in `.github/workflows/ci.yml`, add:

```yaml
      - name: Free-dog visual variety regression test
        run: ./Godot_v4.7-stable_linux.x86_64 --headless --path . --script res://tests/test_free_dog_variety.gd

      - name: NPC pair dog appearance regression test
        run: ./Godot_v4.7-stable_linux.x86_64 --headless --path . --script res://tests/test_pair_dog_appearance.gd

```

- [ ] **Step 2: Add the append-only changelog entry**

Immediately after the changelog preamble and before the current newest entry, insert:

```markdown
## 2026-07-17 — shared NPC dog visual variety

- Added six neutral procedural dog profiles with distinct silhouettes, ears,
  muzzles, tails, coats, and markings shared by free dogs and NPC pair dogs.
- Free-dog profile and animation selection now derive deterministically from
  spawn inputs without consuming global RNG or changing wander behavior.
- Pair dogs reuse their existing dog-color random draw as the profile key,
  preserving setup RNG cadence and appearance through the full park lifecycle.
- Added real-script coverage for profile validation, both caller renderers,
  RNG contracts, lifecycle persistence, bounds, and every profile.

```

- [ ] **Step 3: Update the handover CI source-of-truth paragraph**

Replace the existing CI summary at `HANDOVER.md:71-76` with:

```markdown
- **CI source of truth:** `.github/workflows/ci.yml`. It runs focused rope,
  critter, tangle, freedom-traffic, pair-direction, bandana, owner-label,
  bypasser-route, rider-avoidance, pair-obstacle, pair-park-lifecycle,
  park-slot, pair-park-traffic, free-dog visual-variety, and pair-dog
  appearance regressions,
  followed by all four smoke tests and deterministic autowalk. The suite runs
  on every push to `main` and every pull request targeting `main`.
```

- [ ] **Step 4: Add implementation evidence and advance recommended work**

Under `HANDOVER.md` section `### Evidence in the repository`, add:

```markdown
- `test_free_dog_variety.gd` loads the real appearance and free-dog scripts
  and covers stable profile selection, defensive data, validation, RNG
  isolation, deterministic setup, preserved lifecycle movement/bounds, and a
  headless redraw of all six profiles including the zero-forward case.
- `test_pair_dog_appearance.gd` loads the real pair, leash, and appearance
  scripts and covers exact setup RNG cadence, stable profile identity through
  every park lifecycle state, preserved node/leash identity, and parent-Canvas
  redraw of all six profiles including the zero-forward case.
```

Replace the numbered list under `## 7. Recommended next work` with:

```markdown
1. **Manual NPC lifecycle acceptance first.** Record observed failures before
   tuning timing, movement, or presentation.
2. **Then reusable owner appearance profiles.** Design neutral procedural
   owner profiles for hats, glasses, bald spots, and long hair behind a
   character-creator-ready boundary without changing owner gameplay.
3. **Then roadmap content:** richer NPC-owner props/conversation, a real
   owner-throw/return fetch loop, more off-leash dog interactions, the
   bring-Tofu-home quest, Rainy Day level, and a shareable daily results card.
   The reusable dog appearance profiles are now available to a future
   playable-dog selector without depending on either NPC caller.
```

- [ ] **Step 5: Run every focused regression after CI/docs integration**

Run the exact suite from Task 7 Step 1 again.

Expected: all fifteen tests exit `0` with their `: OK` markers.

- [ ] **Step 6: Re-run all smokes and deterministic autowalks**

Run the exact commands from Task 7 Steps 2 and 3 again.

Expected: all four smokes and both autowalks exit `0` without script/load errors; both autowalk logs include `AUTOWALK FINISHED`.

- [ ] **Step 7: Inspect final integration diff and repository status**

Run:

```powershell
git diff --check
git diff -- .github/workflows/ci.yml CHANGELOG.md HANDOVER.md
git status --short
```

Expected before the integration commit: only these files are newly modified after the implementation checkpoint:

```text
 M .github/workflows/ci.yml
 M CHANGELOG.md
 M HANDOVER.md
```

The CI diff adds exactly two focused steps; documentation accurately describes accepted behavior and does not claim visual acceptance that was not performed.

- [ ] **Step 8: Commit the final integration checkpoint**

Run only under the same explicit commit authorization:

```powershell
git add -- .github/workflows/ci.yml CHANGELOG.md HANDOVER.md
git diff --cached --check
git diff --cached --name-only
git commit -m "Integrate shared dog appearance regressions"
```

Expected: a second commit containing exactly CI and documentation changes.

- [ ] **Step 9: Push only with explicit push authorization**

First inspect:

```powershell
git status --short
git log -2 --oneline --decorate
```

Expected: clean working tree and two reviewable commits. Push only if the parent agent explicitly authorizes the target branch:

```powershell
git push -u origin HEAD
```

Expected: both commits reach the authorized remote branch. Never push directly merely because tests pass, and never expose the secret itch.io URL.

---

## Requirement-to-Task Trace

- Exact six-ID public API and stable order: Tasks 1-2.
- Defensive profile and ID copies plus unknown-ID fallback: Tasks 1-2.
- Positive modulo for positive/negative keys: Tasks 1-2.
- Exact profile schema, neutral labels, supported styles, and six archetypes: Tasks 1-2.
- Finite positive dimensions, finite placement, style/color validation, non-mutation, and radius enforcement: Tasks 1-2.
- No RNG in appearance selection, lookup, validation, rendering, or free-dog setup: Tasks 1-7.
- Every ear, tail, marking, silhouette, muzzle, size, and color renderer branch: Tasks 2-3.
- Zero/non-finite forward fallback, malformed-profile fallback, finite-input guard, and draw smoke: Tasks 1, 3-6.
- Deterministic setup from position/bounds and stable animation phase: Tasks 1 and 4.
- Free-dog setup signature, group, references, bounds, phase gates, movement, clamps, greeting exposure, and cleanup: Tasks 1, 4, and 7.
- Free-dog wander RNG order/cadence and gameplay constants unchanged: Tasks 4 and 7.
- Exact pair `randf_range`, `randf`, owner `randi`, dog `randi` cadence and downstream stream: Tasks 5-7.
- Pair profile/dictionary and node/leash identity through all lifecycle states: Tasks 5-7.
- Parent-Canvas pair renderer with unchanged owner art and approved origin/facing/bob/wag: Tasks 5-7.
- Pair movement, route, leash, tangle, greeting, group, slot, and cleanup contracts unchanged: Tasks 5-7.
- Separate real-script focused regressions with exit `1`/`FAIL:` and success markers: Tasks 1 and 5.
- All current CI regressions, four level smokes, street/park autowalk, and diff/status checks: Task 7.
- Two-stage implementation review and five-file isolation boundary: Tasks 7-8.
- No owner visual/profile changes, external assets, gameplay stats, or selector: Global Constraints and Task 7.
- Both focused CI steps, changelog/handover, owner-profile follow-up, commit, and push checkpoints: Tasks 8-9.
