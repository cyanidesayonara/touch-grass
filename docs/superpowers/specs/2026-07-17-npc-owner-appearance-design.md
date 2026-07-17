# Reusable NPC owner appearances

## Status

This design is approved for the final pre-handover implementation task. It
defines a reusable procedural appearance boundary for generic NPC pair owners.
It does not authorize production code or test changes as part of this design
commit.

## Goal

Add six visibly distinct, neutral NPC owner profiles without changing pair
behavior or the player's owner. Every NPC pair owner continues to be represented
by the existing `npc_owner` node and visibly holds a phone.

The implementation must:

- create a stateless `HumanAppearance` catalog, validator, selector, and
  procedural renderer in `human_appearance.gd`;
- modify only `otherpair.gd` among existing production scripts;
- retain the existing `DogAppearance` integration unchanged;
- preserve the exact global RNG draw count, order, and downstream stream in
  `otherpair.gd::setup`;
- retain one defensive owner profile dictionary for the complete pair
  lifecycle;
- keep owner and dog rendering on the pair parent CanvasItem while `npc_owner`
  and `npc_dog` remain the real gameplay nodes;
- expose a stable profile boundary that a later creator can consume without
  depending on pair behavior or lifecycle code.

This is presentation infrastructure only. Appearance never changes movement,
collision, leash physics, hazards, stats, scoring, behavior, difficulty, or
interaction.

## Architecture

### Appearance module

Create `human_appearance.gd`:

```gdscript
class_name HumanAppearance
extends RefCounted

const MAX_LOCAL_RADIUS := 48.0

static func profile_ids() -> PackedStringArray
static func get_profile(profile_id: String) -> Dictionary
static func profile_id_for_key(key: int) -> String
static func profile_for_key(key: int) -> Dictionary
static func validation_errors(profile: Dictionary) -> PackedStringArray
static func draw_owner(
	canvas: CanvasItem,
	profile: Dictionary,
	origin: Vector2,
	forward: Vector2,
	gait_phase: float,
	gait_amount: float,
	phone_glow: float,
	phone_state: String
) -> void
```

These signatures are the complete public API. Helpers and catalog constants
remain implementation details except for `MAX_LOCAL_RADIUS`.

The module:

- creates no nodes and stores no mutable runtime state;
- does not know about `main.gd`, `human.gd`, pair states, walk phases, AI,
  movement, leashes, tangles, groups, spawning, or cleanup;
- does not call any global RNG function and does not create a
  `RandomNumberGenerator`;
- uses only Godot 4.7 `CanvasItem` procedural primitives;
- issues draw calls only from `draw_owner()`.

Profile listing, lookup, signed-key selection, and validation are pure
headless-safe data operations. Renderer helpers may transform points and issue
draw calls only when reached through `draw_owner()`.

### Pair ownership

`otherpair.gd` preloads `human_appearance.gd` and stores:

```gdscript
var owner_appearance_profile: Dictionary = {}
```

The existing dog field remains:

```gdscript
var appearance_profile: Dictionary = {}
```

The distinct names are required. `owner_appearance_profile` always means the
human owner profile; `appearance_profile` remains the dog profile so the
existing dog tests and callers do not change.

`otherpair.gd` remains the owner of `npc_owner`, `npc_dog`, `leash`, movement,
animation inputs, and lifecycle. It invokes both appearance renderers from its
own `_draw()`. No renderer child is added. `npc_owner` remains the real owner
position and leash endpoint even though the pair parent draws the owner.

`human.gd` is not modified and does not use `HumanAppearance` in this task. Its
existing player-owner preset rendering, states, phone behavior, and gameplay
remain independent.

## Stable profile contract

### IDs and deterministic lookup

`profile_ids()` returns a fresh `PackedStringArray` in this exact order:

1. `compact_short_cap`
2. `tall_long_glasses`
3. `broad_bun_sunglasses`
4. `medium_bald_spot_glasses`
5. `narrow_short_beanie`
6. `rounded_long_cap`

The IDs and order are persistence-facing API. A future creator may store one of
these IDs, so an existing ID must not be renamed, reordered, or repurposed.

`get_profile(profile_id)` returns a deep duplicate of canonical data. Mutating
the returned dictionary must not affect the catalog, later lookups, or another
caller. An unknown ID returns a deep duplicate of `compact_short_cap`.

`profile_id_for_key(key)` uses signed integer arithmetic and positive modulo:

```text
index = ((key % profile_count) + profile_count) % profile_count
```

Positive and negative keys therefore cycle through the exact stable order.
`profile_for_key(key)` is exactly a defensive `get_profile()` of the ID returned
by `profile_id_for_key(key)`.

No selection or lookup function may consume randomness, read a clock, use a
process-specific hash, or depend on scene-tree state.

### Exact schema

Every canonical profile contains exactly these fields and types:

- `id: String`
- `name: String`
- `size_scale: float`
- `body_size: Vector2`, local forward and side half-extents before scale
- `head_radius: float`
- `head_forward_offset: float`
- `foot_radius: float`
- `foot_spread: float`
- `step_distance: float`
- `arm_width: float`
- `skin_color: Color`
- `shirt_color: Color`
- `pants_color: Color`
- `hair_color: Color`
- `hair_style: String`
- `headwear_style: String`
- `headwear_color: Color`
- `eyewear_style: String`
- `eyewear_color: Color`
- `phone_size: Vector2`, local side width and forward length
- `phone_body_color: Color`
- `phone_screen_color: Color`
- `phone_accent_color: Color`
- `phone_treatment: String`

Canonical profiles contain no additional fields. Runtime animation state and
renderer point arrays are not profile data.

Supported enum strings are exact:

- `hair_style`: `short`, `long`, `bun`, `bald_spot`;
- `headwear_style`: `none`, `cap`, `beanie`;
- `eyewear_style`: `none`, `glasses`, `sunglasses`;
- `phone_treatment`: `plain`, `bumper`, `sticker`;
- renderer `phone_state`: `held`, `raised`.

An unsupported profile enum is a validation error. An unsupported
`phone_state` argument is not profile data and deterministically renders as
`held`.

### Exact canonical profiles

The implementation uses these exact values. Names describe visual construction
only and do not imply identity, gender, occupation, nationality, age, or any
real-world demographic category.

```gdscript
const PROFILES := {
	"compact_short_cap": {
		"id": "compact_short_cap",
		"name": "Compact Short-Hair Cap",
		"size_scale": 0.94,
		"body_size": Vector2(13.0, 14.0),
		"head_radius": 8.5,
		"head_forward_offset": 5.0,
		"foot_radius": 4.5,
		"foot_spread": 6.5,
		"step_distance": 5.5,
		"arm_width": 4.5,
		"skin_color": Color(0.78, 0.59, 0.45),
		"shirt_color": Color(0.38, 0.49, 0.66),
		"pants_color": Color(0.22, 0.25, 0.31),
		"hair_color": Color(0.25, 0.18, 0.12),
		"hair_style": "short",
		"headwear_style": "cap",
		"headwear_color": Color(0.72, 0.30, 0.25),
		"eyewear_style": "none",
		"eyewear_color": Color(0.10, 0.10, 0.12),
		"phone_size": Vector2(12.0, 18.0),
		"phone_body_color": Color(0.08, 0.09, 0.12),
		"phone_screen_color": Color(0.63, 0.82, 1.0),
		"phone_accent_color": Color(0.72, 0.30, 0.25),
		"phone_treatment": "plain",
	},
	"tall_long_glasses": {
		"id": "tall_long_glasses",
		"name": "Tall Long-Hair Glasses",
		"size_scale": 1.05,
		"body_size": Vector2(15.0, 13.0),
		"head_radius": 8.0,
		"head_forward_offset": 5.5,
		"foot_radius": 4.2,
		"foot_spread": 7.0,
		"step_distance": 6.0,
		"arm_width": 4.0,
		"skin_color": Color(0.52, 0.34, 0.25),
		"shirt_color": Color(0.24, 0.56, 0.55),
		"pants_color": Color(0.20, 0.24, 0.29),
		"hair_color": Color(0.12, 0.09, 0.08),
		"hair_style": "long",
		"headwear_style": "none",
		"headwear_color": Color(0.24, 0.56, 0.55),
		"eyewear_style": "glasses",
		"eyewear_color": Color(0.12, 0.12, 0.14),
		"phone_size": Vector2(11.0, 18.0),
		"phone_body_color": Color(0.12, 0.13, 0.16),
		"phone_screen_color": Color(0.72, 0.88, 0.96),
		"phone_accent_color": Color(0.90, 0.70, 0.26),
		"phone_treatment": "bumper",
	},
	"broad_bun_sunglasses": {
		"id": "broad_bun_sunglasses",
		"name": "Broad Bun Sunglasses",
		"size_scale": 1.08,
		"body_size": Vector2(13.5, 17.0),
		"head_radius": 9.2,
		"head_forward_offset": 4.8,
		"foot_radius": 4.8,
		"foot_spread": 7.5,
		"step_distance": 5.2,
		"arm_width": 5.0,
		"skin_color": Color(0.88, 0.72, 0.58),
		"shirt_color": Color(0.64, 0.38, 0.55),
		"pants_color": Color(0.29, 0.25, 0.34),
		"hair_color": Color(0.40, 0.25, 0.15),
		"hair_style": "bun",
		"headwear_style": "none",
		"headwear_color": Color(0.64, 0.38, 0.55),
		"eyewear_style": "sunglasses",
		"eyewear_color": Color(0.06, 0.07, 0.09),
		"phone_size": Vector2(13.0, 18.0),
		"phone_body_color": Color(0.15, 0.10, 0.16),
		"phone_screen_color": Color(0.76, 0.82, 1.0),
		"phone_accent_color": Color(0.96, 0.76, 0.30),
		"phone_treatment": "sticker",
	},
	"medium_bald_spot_glasses": {
		"id": "medium_bald_spot_glasses",
		"name": "Medium Bald-Spot Glasses",
		"size_scale": 1.0,
		"body_size": Vector2(14.5, 15.0),
		"head_radius": 9.4,
		"head_forward_offset": 4.5,
		"foot_radius": 4.6,
		"foot_spread": 7.0,
		"step_distance": 5.0,
		"arm_width": 4.8,
		"skin_color": Color(0.68, 0.47, 0.34),
		"shirt_color": Color(0.48, 0.55, 0.34),
		"pants_color": Color(0.28, 0.29, 0.25),
		"hair_color": Color(0.20, 0.15, 0.11),
		"hair_style": "bald_spot",
		"headwear_style": "none",
		"headwear_color": Color(0.48, 0.55, 0.34),
		"eyewear_style": "glasses",
		"eyewear_color": Color(0.18, 0.14, 0.12),
		"phone_size": Vector2(12.0, 17.0),
		"phone_body_color": Color(0.09, 0.11, 0.10),
		"phone_screen_color": Color(0.66, 0.86, 0.78),
		"phone_accent_color": Color(0.48, 0.55, 0.34),
		"phone_treatment": "plain",
	},
	"narrow_short_beanie": {
		"id": "narrow_short_beanie",
		"name": "Narrow Short-Hair Beanie",
		"size_scale": 0.98,
		"body_size": Vector2(15.5, 12.0),
		"head_radius": 8.3,
		"head_forward_offset": 5.5,
		"foot_radius": 4.2,
		"foot_spread": 6.2,
		"step_distance": 6.0,
		"arm_width": 4.0,
		"skin_color": Color(0.39, 0.27, 0.21),
		"shirt_color": Color(0.72, 0.48, 0.24),
		"pants_color": Color(0.18, 0.22, 0.28),
		"hair_color": Color(0.08, 0.07, 0.07),
		"hair_style": "short",
		"headwear_style": "beanie",
		"headwear_color": Color(0.26, 0.38, 0.58),
		"eyewear_style": "sunglasses",
		"eyewear_color": Color(0.05, 0.06, 0.08),
		"phone_size": Vector2(11.0, 18.0),
		"phone_body_color": Color(0.08, 0.09, 0.13),
		"phone_screen_color": Color(0.70, 0.84, 1.0),
		"phone_accent_color": Color(0.26, 0.38, 0.58),
		"phone_treatment": "bumper",
	},
	"rounded_long_cap": {
		"id": "rounded_long_cap",
		"name": "Rounded Long-Hair Cap",
		"size_scale": 1.03,
		"body_size": Vector2(13.0, 16.0),
		"head_radius": 8.8,
		"head_forward_offset": 5.0,
		"foot_radius": 4.7,
		"foot_spread": 7.2,
		"step_distance": 5.4,
		"arm_width": 4.6,
		"skin_color": Color(0.93, 0.79, 0.66),
		"shirt_color": Color(0.38, 0.43, 0.62),
		"pants_color": Color(0.25, 0.23, 0.31),
		"hair_color": Color(0.58, 0.39, 0.20),
		"hair_style": "long",
		"headwear_style": "cap",
		"headwear_color": Color(0.34, 0.62, 0.48),
		"eyewear_style": "none",
		"eyewear_color": Color(0.12, 0.12, 0.14),
		"phone_size": Vector2(12.0, 18.0),
		"phone_body_color": Color(0.13, 0.12, 0.16),
		"phone_screen_color": Color(0.78, 0.88, 1.0),
		"phone_accent_color": Color(0.34, 0.62, 0.48),
		"phone_treatment": "sticker",
	},
}
```

The built-in set visibly exercises all four hair styles, all three headwear
styles, all three eyewear styles, all three phone treatments, at least four
distinct shirt colors, at least four skin colors, and at least three
meaningfully different body aspect/proportion combinations. Every visual schema
field other than identity metadata (`id` and `name`) must affect rendered output
in at least one supported branch; inert decorative appearance data is not
acceptable.

## Renderer contract

### Coordinate system and inputs

`origin` is the owner's center in the supplied caller CanvasItem's coordinates.
Local positive x is `forward`; local positive y is `forward.orthogonal()`.
`draw_owner()` normalizes finite non-zero `forward`. A zero-length or non-finite
`forward` uses `Vector2.UP`, matching the game's north/up default.

`gait_phase` is a caller-owned phase in radians. `gait_amount` is clamped to
inclusive `[0.0, 1.0]` and scales foot stepping and body sway. The renderer
stores no gait state. Foot displacement uses bounded sine motion and cannot
exceed the profile's `step_distance`; sway cannot exceed 1.5 local pixels
before `size_scale`.

`phone_glow` is clamped to inclusive `[0.0, 1.0]` and controls screen alpha.
The phone body remains visible even when glow is zero. `phone_state` affects
only the draw pose:

- `held`: phone center is 24 local pixels forward of `origin`;
- `raised`: phone center is 30 local pixels forward of `origin`.

Both states draw arms reaching toward the phone, a phone body, and a screen.
Every canonical owner therefore visibly holds a phone. An unknown state uses
`held`.

A non-finite `origin`, `gait_phase`, `gait_amount`, or `phone_glow` results in
no draw calls. The renderer never submits non-finite geometry to CanvasItem.

### Draw construction

The renderer draws in this conceptual back-to-front order:

1. feet, offset by `foot_spread`, `foot_radius`, gait phase, and step distance;
2. long-hair rear mass or bun rear circle, when selected;
3. body ellipse using `body_size`, `shirt_color`, bounded sway, and scale;
4. head circle using `head_radius`, `head_forward_offset`, and `skin_color`;
5. the selected hair branch;
6. the selected headwear branch;
7. the selected eyewear branch;
8. arms from body sides toward the phone, using `skin_color` and `arm_width`;
9. phone case, screen, and treatment.

Hair branches are exact:

- `short`: a compact rear-head arc;
- `long`: a rear hair mass extending behind both sides of the head plus a
  hairline arc;
- `bun`: a rear-head arc plus a distinct rear bun circle;
- `bald_spot`: a broader hair arc with a centered skin-colored spot that
  remains visible when no headwear is present.

Headwear branches are exact:

- `none`: no headwear primitive;
- `cap`: a colored crown arc and forward brim;
- `beanie`: a colored rear-head cap with a contrasting lower band derived
  from `hair_color`.

Eyewear branches are exact:

- `none`: no eyewear primitive;
- `glasses`: two outlined lenses joined by a bridge;
- `sunglasses`: two filled dark lenses joined by a bridge.

Phone-treatment branches are exact:

- `plain`: body and inset glowing screen;
- `bumper`: `phone_accent_color` outer case, `phone_body_color` inner body, and
  inset screen;
- `sticker`: body and inset screen plus a visible
  `phone_accent_color` circular mark on the body below the screen.

All rotations and positions derive only from the supplied `origin`, normalized
facing basis, bounded animation inputs, and profile data. Rendering must not
mutate the profile or any caller node.

### Geometry bound

`MAX_LOCAL_RADIUS` is a conservative caller-facing culling bound measured from
`origin` after profile scale and worst-case animation. Validation computes a
conservative radius with these private renderer constants and exact formula:

```text
MAX_SWAY = 1.5
PHONE_RAISED_FORWARD = 30.0
DRAW_MARGIN = 3.0

body_extent =
  body_size.length() + MAX_SWAY
head_extent =
  head_forward_offset + head_radius * 2.35 + DRAW_MARGIN
feet_extent =
  Vector2(
    step_distance + foot_radius,
    foot_spread + foot_radius
  ).length()
phone_extent =
  Vector2(
    PHONE_RAISED_FORWARD + phone_size.y * 0.5,
    phone_size.x * 0.5
  ).length() + DRAW_MARGIN
geometry_radius =
  max(body_extent, head_extent, feet_extent, phone_extent) * size_scale
```

The `2.35` head multiplier bounds long hair, bun, cap, and beanie construction.
`DRAW_MARGIN` bounds phone case, arm and accessory line widths. The phone term
uses the farther `raised` state and `phone_size`'s documented forward/side
component order.

The implementation may overestimate actual geometry but must not
underestimate it. Every canonical profile must validate at or below
`HumanAppearance.MAX_LOCAL_RADIUS == 48.0`. Geometry must not be silently
clipped to pass validation.

## Validation and error handling

`validation_errors(profile)` returns all safely detectable errors in a
`PackedStringArray` and never mutates the supplied dictionary.

Validation enforces:

- every exact schema field is present and no unknown field is present;
- `id` and `name` are non-empty `String` values;
- `size_scale`, `head_radius`, `head_forward_offset`, `foot_radius`,
  `foot_spread`, `step_distance`, and `arm_width` are finite `float` values
  greater than zero;
- both components of `body_size` and `phone_size` are finite and greater than
  zero;
- every color field is a `Color` with finite red, green, blue, and alpha
  channels in inclusive `[0.0, 1.0]`;
- all profile enum values belong to their exact supported sets;
- derived centers, transformed points, arcs, line widths, and rectangles are
  finite and have enough points or positive dimensions for their CanvasItem
  primitives;
- conservative worst-case geometry does not exceed `MAX_LOCAL_RADIUS`.

Catalog-level tests separately enforce that IDs are unique, each dictionary ID
matches its catalog key, and catalog keys follow the stable public order.
Single-profile validation cannot detect a duplicate elsewhere.

`draw_owner()` validates its supplied profile. Invalid profile data falls back
to a fresh defensive copy of `compact_short_cap`; it does not crash, consume
randomness, mutate the input, or attempt malformed geometry.

## Exact pair RNG and data flow

### Setup sequence

`otherpair.gd::setup` keeps its signature and consumes exactly four initial
global random draws in this exact order:

1. `vel = direction * randf_range(58.0, 82.0)`;
2. `seed_o = randf() * 10.0`;
3. `owner_appearance_key = randi()`;
4. `dog_appearance_key = randi()`.

The raw third draw replaces the current three-color owner palette lookup:

```gdscript
var owner_appearance_key := randi()
owner_appearance_profile = HumanAppearanceScript.profile_for_key(owner_appearance_key)
owner_col = owner_appearance_profile["shirt_color"]
```

The raw fourth draw and existing dog integration remain:

```gdscript
var dog_appearance_key := randi()
appearance_profile = DogAppearanceScript.profile_for_key(dog_appearance_key)
dog_col = appearance_profile["base_color"]
```

No random call is inserted, removed, moved, repeated, or hidden inside either
appearance module. The raw third value, not its former `% 3` result, is the
owner profile key. `owner_col` remains available for compatibility and is
derived from the selected profile's `shirt_color` without another draw.

This preserves the velocity draw, animation phase draw, dog-profile key draw,
and the global RNG state seen by every later random consumer. The owner color
is intentionally allowed to differ from the obsolete three-color palette;
stream compatibility, not placeholder color compatibility, is the invariant.

### Lifecycle identity

`owner_appearance_profile` is selected once during setup and is never replaced,
regenerated, or mutated during:

```text
WALKING -> ARRIVING -> PARKED -> RECALLING -> DEPARTING -> WALKING
```

The same dictionary object and profile ID persist through ordinary walking,
arrival, `initialize_parked_departure`, parked waiting, home-phase interruption,
recall, re-leashing, departure, slot release, and resumed walking.

The same pair, `npc_owner`, `npc_dog`, and `leash` node instances also persist.
Appearance code must not create replacement nodes or alter their positions,
instance IDs, parenting, groups, collision, or endpoint roles.

### Parent-Canvas rendering flow

`otherpair.gd::_draw()` delegates the owner placeholder to:

```gdscript
var owner_forward := vel
var owner_gait_amount := (
	0.0
	if pair_state == PairState.PARKED or pair_state == PairState.RECALLING
	else clampf(vel.length() / 82.0, 0.0, 1.0)
)
var owner_phone_glow := 0.55 + 0.2 * sin(t * 7.3 + seed_o)
HumanAppearanceScript.draw_owner(
	self,
	owner_appearance_profile,
	npc_owner.position,
	owner_forward,
	t * 6.0 + seed_o,
	owner_gait_amount,
	owner_phone_glow,
	"held"
)
```

`draw_owner()` performs normalization and the north/up fallback. The caller
passes `"held"` in every lifecycle state, so all NPC pair owners retain a
visible phone without adding a lifecycle-dependent phone behavior.

The existing time value and `seed_o` are reused. Drawing consumes no random
values. The dog-facing calculation, dog bob, dog wag, and
`DogAppearanceScript.draw_dog(...)` call remain byte-for-byte unchanged except
for any mechanical movement needed to share the existing `t` local.

Complete data flow:

```text
otherpair.setup
  -> velocity randf_range
  -> seed_o randf
  -> raw owner randi
  -> HumanAppearance.profile_for_key returns defensive profile
  -> owner_col derives from profile shirt_color
  -> raw dog randi
  -> existing DogAppearance.profile_for_key flow
  -> profile dictionaries persist on the pair
  -> otherpair._draw computes owner animation inputs
  -> HumanAppearance.draw_owner draws at npc_owner.position on pair parent
  -> existing DogAppearance.draw_dog draws at npc_dog.position on pair parent
```

## Preserved integration contracts

The implementation does not alter:

- `otherpair.gd::setup` parameters or caller sites;
- `PairState` values or
  `WALKING -> ARRIVING -> PARKED -> RECALLING -> DEPARTING -> WALKING`;
- walking, route detours, blocked behavior, arrival, parked wandering, recall,
  departure, speed, acceleration, timers, probabilities, bounds, or leash cap;
- `npc_owner`, `npc_dog`, pair, and leash identity or parenting;
- real leash setup, ticking, detachment, visibility, resnap, sampled points,
  dynamic obstacles, or endpoint nodes;
- tangle detection, latching, messages, rewards, or rearm timing;
- `pairs` group membership, greeting identity, park-slot ownership/release,
  despawn, or cleanup;
- main's spawn policy, pair cap, phase orchestration, routing, or reservations;
- DogAppearance profile selection, field names, rendering, tests, or behavior;
- player-owner code or rendering in `human.gd`.

The selected owner profile is data only. It cannot influence any branch outside
the parent draw path.

## TDD and testing

Tests load the real `human_appearance.gd` and `otherpair.gd`. They do not copy
production selection formulas into a fake implementation and do not use
source-text inspection as their primary assertion.

### Catalog and renderer test

Create `tests/test_human_appearance.gd` as a `SceneTree` test. It prints
`FAIL:` for assertion failures, exits `1` if any fail, and prints
`test_human_appearance: OK` before exiting `0` on success.

It covers:

1. `MAX_LOCAL_RADIUS == 48.0` and the exact public method signatures;
2. the exact six IDs and order, with no duplicate IDs or catalog keys;
3. expected positive and negative key selection, including profile-count
   cycling and `-1` selecting `rounded_long_cap`;
4. defensive `profile_ids()`, known-profile, unknown-profile, and
   `profile_for_key()` results;
5. the exact schema and types with no missing or extra fields;
6. every canonical key matching its profile ID and every canonical profile
   producing zero validation errors;
7. malformed and oversized synthetic profiles returning errors without input
   mutation or crashes;
8. non-empty strings, finite positive dimensions, finite bounded colors, enum
   rejection, derived primitive safety, and radius enforcement;
9. all hair, headwear, eyewear, and phone-treatment branches plus required
   color and proportion variety;
10. selection, lookup, validation, and rendering preserving global RNG through
    seed/expected/reseed/call/actual comparisons;
11. headless `draw_owner()` smoke for every profile using `held` and `raised`
    phone states;
12. a zero `forward` and non-finite `forward` exercising `Vector2.UP` fallback
    without draw errors;
13. malformed profile fallback drawing without mutation;
14. non-finite origin and animation inputs returning without invalid draw
    calls;
15. all six canonical profiles unconditionally drawing a phone body and screen:
    render one owner at a time into a transparent offscreen `SubViewport`, read
    its texture image after a frame with `phone_glow = 1.0`, and assert that the
    expected phone rectangle contains at least one opaque body pixel and one
    opaque screen pixel whose red, green, blue, and alpha channels each differ
    from the corresponding profile color by no more than `0.08`.

The phone assertion must test rendered primitives or a renderer-visible
invariant, not merely the presence of phone fields in the schema.

### Real pair integration test

Create `tests/test_pair_owner_appearance.gd` as a separate `SceneTree` test
using real `otherpair.gd`, `human_appearance.gd`, `dog_appearance.gd`, and
`leash.gd` with minimal fake main/player fixtures. It follows the existing
`tests/test_pair_dog_appearance.gd` lifecycle fixture pattern.

It covers:

1. exact setup RNG by seeding, recording expected `randf_range`, `randf`, raw
   owner `randi`, raw dog `randi`, and the following random value, then
   reseeding and running real pair setup;
2. `vel` matching the first draw and supplied direction;
3. `seed_o` matching the second draw;
4. `owner_appearance_profile` matching
   `HumanAppearance.profile_for_key()` of the raw third draw;
5. `appearance_profile` still matching `DogAppearance.profile_for_key()` of
   the raw fourth draw;
6. `owner_col == owner_appearance_profile["shirt_color"]` and existing
   `dog_col == appearance_profile["base_color"]`;
7. the following global RNG value matching exactly, proving no setup draw was
   added, removed, reordered, or repeated;
8. equal seeds selecting equal owner and dog profiles and equal animation
   phases, while representative seeds select more than one owner profile;
9. the same owner profile dictionary object and ID persisting through
   `WALKING`, `ARRIVING`, `PARKED`, `RECALLING`, `DEPARTING`, and resumed
   `WALKING`;
10. persistence through `initialize_parked_departure` and home-phase
    interruption;
11. unchanged pair, owner, dog, and leash instance IDs and endpoint references
    through the same transitions;
12. parent-Canvas headless redraw for every owner profile while the existing
    dog renderer executes in the same frame;
13. zero owner velocity exercising the north/up fallback;
14. every real pair owner profile visibly retaining a phone;
15. pair drawing preserving the global RNG stream.

Existing `tests/test_pair_dog_appearance.gd` remains unchanged and continues to
guard the dog integration. Existing lifecycle, leash, tangle, route, group,
cleanup, and traffic tests remain authoritative for their current contracts.

### TDD order

The isolated implementation follows this order:

1. add the catalog/renderer test and confirm it fails because
   `human_appearance.gd` does not exist;
2. implement catalog IDs, schema, defensive lookup, signed-key selection, and
   validation; run the focused test;
3. implement bounded procedural rendering and all phone branches; run the
   focused test;
4. add the real pair integration test and confirm it fails because
   `otherpair.gd` does not yet expose the owner profile;
5. integrate selection, compatibility color, profile persistence, and
   parent-Canvas drawing in `otherpair.gd`;
6. run both focused tests and the unchanged pair-dog appearance test;
7. inspect only the isolated implementation diff and perform an implementation
   review before any integration-document change.

## Review and integration boundary

The initial implementation/review boundary is exactly:

- create `human_appearance.gd`;
- modify `otherpair.gd`;
- create `tests/test_human_appearance.gd`;
- create `tests/test_pair_owner_appearance.gd`.

During that isolated implementation:

- do not modify `human.gd`, `dog_appearance.gd`, `main.gd`, `leash.gd`,
  `bypasser_route.gd`, or any other production script;
- do not modify existing tests;
- do not modify `.github/workflows/ci.yml`, `CHANGELOG.md`, `HANDOVER.md`,
  `PROJECT.md`, plans, or specifications;
- preserve unrelated working-tree changes and do not stage or reformat files
  outside the four-file boundary;
- review the isolated diff before committing or integrating it.

After isolated implementation review, a separate integration step:

1. adds the two focused tests to `.github/workflows/ci.yml`;
2. runs both focused tests, the complete current focused regression suite, all
   four level smoke tests, and fixed-60-FPS autowalk through
   `AUTOWALK FINISHED`;
3. updates `CHANGELOG.md`;
4. updates `HANDOVER.md` with the completed architecture, exact test evidence,
   remaining risks, and next work.

The final `HANDOVER.md` must be sufficient for the user to switch to another
model with no conversation context. If a human has not launched the game and
visually inspected all profiles and lifecycle poses, it must explicitly state
that manual visual acceptance remains outstanding. Headless draw smoke is not
evidence of readability, phone legibility, accessory layering, silhouette
quality, or animation feel.

## Scope exclusions

- No changes to the player's owner in `human.gd`.
- No owner behavior, AI, events, telegraphs, hazards, collision, stats,
  difficulty, scoring, quests, dialogue, names, or interactions.
- No creator UI, playable-owner selector, save data, migration, unlock,
  progression, shop, or persistence implementation.
- No changes to NPC dog profiles, DogAppearance, the player dog, free dogs,
  dog behavior, or dog rendering.
- No movement, route, leash, tangle, park-lifecycle, spawn, group, greeting,
  slot, cleanup, or population changes.
- No external assets, scenes, resources, textures, SVGs, fonts, plugins,
  dependencies, or production-art replacement.
- No named real people, gender labels, emoji, or claims about real-world
  demographic groups.
- No profile field may become a gameplay input.

Future creator reuse is limited to the stable IDs, defensive profile API, exact
schema, validation, and renderer. Designing or implementing that creator is a
separate task.

## Acceptance criteria

The owner appearance task is accepted only when:

- `HumanAppearance` exposes the exact approved API and
  `MAX_LOCAL_RADIUS == 48.0`;
- six profiles use the exact stable IDs, order, schema, values, and enum
  strings;
- lookup and signed-key selection are deterministic, defensive, and use
  positive modulo;
- validation is non-mutating and rejects schema, type, finite-value, enum,
  primitive-safety, and radius violations;
- every canonical profile validates and remains inside the conservative local
  radius;
- all required hair, headwear, eyewear, phone, color, and proportion variety is
  visibly exercised;
- every owner visibly holds a procedurally drawn phone in every pair lifecycle
  state;
- invalid profiles fall back defensively and zero/non-finite forward falls back
  to north/up without randomness or invalid geometry;
- non-finite origin or animation scalars produce no draw calls;
- pair setup retains exactly velocity `randf_range`, `seed_o` `randf`, owner
  appearance `randi`, and dog appearance `randi` in that order;
- the raw third and fourth draws select owner and dog profiles respectively,
  and every downstream random consumer observes the unchanged stream;
- `owner_col` remains compatible by deriving from the owner profile's
  `shirt_color`;
- one owner profile dictionary object persists through every lifecycle state,
  initialization path, interruption, and resumed walking;
- pair, owner, dog, and leash node identities and endpoint references remain
  unchanged;
- the pair parent remains the CanvasItem for both renderers and `npc_owner`
  remains the real owner node;
- existing DogAppearance integration is unchanged;
- player `human.gd` is unchanged;
- real-script focused tests cover the exact catalog, validation, RNG, profile
  identity, node identity, zero-forward rendering, phones, and compatibility
  fields;
- the isolated implementation changes only its four approved files and passes
  review before CI or documentation integration;
- the final integration runs the complete regression, smoke, and autowalk
  evidence, then updates CI, `CHANGELOG.md`, and `HANDOVER.md`;
- final handover records manual visual acceptance as outstanding unless it was
  actually performed;
- no excluded asset, dependency, demographic claim, creator, save, gameplay,
  behavior, or interaction work is introduced.
