# Shared NPC dog appearance foundation

## Status and relationship to the earlier handoff

This design is approved for a shared NPC-dog appearance foundation. It retains
the exact profile catalog, public API, schema, validation, deterministic
free-dog selection, procedural rendering, and gameplay-preservation
requirements from `docs/PARALLEL_TASK_FREE_DOG_VARIETY.md`.

It supersedes only that handoff's earlier ownership and scope statements that
restricted the renderer to `freedog.gd` and excluded `otherpair.gd`. The shared
implementation now includes both free dogs and NPC dog-walker pair dogs. The
handoff itself remains unchanged as historical context.

The existing untracked implementation-plan draft predates this expanded
boundary. It is not authoritative and must be revised separately after this
specification is reviewed.

## Goal

Create one reusable, deterministic, procedural appearance system for every
generic NPC dog currently drawn by `freedog.gd` and `otherpair.gd`.

The result must:

- make off-leash and corridor dog populations visibly varied;
- keep one neutral six-profile vocabulary across both callers;
- preserve free-dog movement, greeting, grouping, and cleanup;
- preserve NPC pair movement, lifecycle, leash, tangles, greeting identity,
  grouping, and cleanup;
- preserve the exact global RNG call count and order in `otherpair.gd::setup`;
- consume no RNG in the appearance module or free-dog appearance setup;
- remain reusable by a later playable-dog selector without depending on
  either NPC script.

This is appearance infrastructure only. Profiles do not change speed,
strength, collision, leash length, scoring, behavior, or difficulty.

## Architecture

### Shared appearance module

Create `dog_appearance.gd` as a stateless profile catalog, validator,
deterministic selector, and procedural vector renderer:

```gdscript
class_name DogAppearance
extends RefCounted

const MAX_LOCAL_RADIUS := 40.0

static func profile_ids() -> PackedStringArray
static func get_profile(profile_id: String) -> Dictionary
static func profile_id_for_key(key: int) -> String
static func profile_for_key(key: int) -> Dictionary
static func validation_errors(profile: Dictionary) -> PackedStringArray
static func draw_dog(
	canvas: CanvasItem,
	profile: Dictionary,
	origin: Vector2,
	forward: Vector2,
	bob: float,
	wag_phase: float
) -> void
```

The module has no reference to `main.gd`, walk phases, movement, greetings,
leashes, tangles, pair states, owners, spawning, or cleanup. It stores no
mutable runtime state and creates no nodes. It uses no global or local random
number generator.

`draw_dog()` is the module's only function allowed to issue CanvasItem draw
calls. Geometry helpers may calculate points, but profile listing, selection,
lookup, and validation remain pure data operations that can run headlessly
without a CanvasItem.

### Caller responsibilities

`freedog.gd` and `otherpair.gd` each preload the shared module, own one
`appearance_profile: Dictionary`, calculate caller-specific animation inputs,
and invoke `DogAppearance.draw_dog()` from their existing drawing path.

Neither caller passes behavior or lifecycle state into the appearance module.
Neither caller creates a separate visual child. The existing nodes, positions,
groups, instance IDs, leash endpoints, and cleanup ownership remain the source
of gameplay identity.

This design deliberately keeps pair rendering on the parent `otherpair.gd`
CanvasItem. `npc_dog` remains a positional/leash endpoint node, not a new
renderer.

## Public profile contract

### Stable IDs and lookup

`profile_ids()` returns a new `PackedStringArray` in this exact stable order:

1. `compact_point_ear`
2. `long_low_drop_ear`
3. `tall_narrow_rose_ear`
4. `stocky_fold_ear`
5. `fluffy_curl_tail`
6. `shaggy_drop_ear`

The order is a persistence-facing contract because integer keys map into it.
Existing IDs must not be renamed, reordered, or repurposed.

`get_profile(profile_id)` returns a deep duplicate of canonical profile data.
A caller may mutate its returned dictionary without changing later lookups or
another caller's profile. An unknown ID deterministically returns a deep
duplicate of `compact_point_ear`.

`profile_id_for_key(key)` uses integer arithmetic and positive modulo:

```text
index = ((key % profile_count) + profile_count) % profile_count
```

The same positive or negative key always resolves to the same ID.
`profile_for_key(key)` is exactly a defensive `get_profile()` of that ID.

### Exact schema

Every canonical profile contains exactly these fields and types:

- `id: String`
- `name: String`
- `size_scale: float`
- `body_size: Vector2`, local half-extents before `size_scale`
- `head_radius: float`
- `muzzle_size: Vector2`, length and half-width
- `ear_style: String`
- `ear_size: Vector2`
- `ear_offset: Vector2`
- `tail_style: String`
- `tail_length: float`
- `tail_thickness: float`
- `tail_carriage: float`
- `base_color: Color`
- `secondary_color: Color`
- `marking_color: Color`
- `marking_style: String`
- `marking_offset: Vector2`
- `marking_scale: Vector2`

Canonical profiles contain no extra renderer-only fields. Renderer point
arrays are calculated from this schema rather than stored as mutable profile
data.

Supported style values are exact:

- ears: `point`, `drop`, `rose`, `fold`;
- tails: `straight`, `whip`, `curl`, `plume`;
- markings: `solid`, `patch`, `blaze_points`, `brindle`.

Profile names remain neutral visual descriptions. Code, comments, tests, and
UI must not claim that a profile represents a real breed.

## Procedural profile vocabulary

The six profiles are generic top-down silhouettes:

- `compact_point_ear`: short compact body, point ears, short carried tail,
  simple solid treatment;
- `long_low_drop_ear`: long low body, drop ears, elongated muzzle, patch
  treatment;
- `tall_narrow_rose_ear`: narrow silhouette, rose ears, fine tail,
  blaze-and-points treatment;
- `stocky_fold_ear`: broad stocky body, fold ears, heavier muzzle, brindle
  treatment;
- `fluffy_curl_tail`: fuller silhouette, visibly curled tail, contrasting
  patch treatment;
- `shaggy_drop_ear`: medium-long shaggy silhouette, drop ears, plume tail,
  striped or brindled treatment.

Across the canonical set, the actual data and renderer must exercise all four
ear styles, all four tail styles, all four marking styles, at least four
distinct base-coat colors, and at least three meaningfully different
body-size/aspect combinations. This stronger all-branch requirement ensures
the real built-in set covers every supported procedural branch.

The renderer must visibly use every schema dimension: overall scale, body
half-extents/aspect, head radius, muzzle dimensions, ear style/size/offset,
tail style/length/thickness/carriage, all three colors, and marking
style/offset/scale. A field that never changes generated drawing does not
satisfy the schema.

All shapes remain legible at the current small top-down scale. The renderer
preserves happy bob-and-wag intent without adding animation state. `bob` is
clamped to the renderer's documented maximum displacement of 1.5 local
pixels; `wag_phase` is converted through bounded trigonometric motion. The
worst-case bob, wag, line thickness, offsets, and style geometry are included
when enforcing `MAX_LOCAL_RADIUS`.

No resource files, scenes, textures, SVGs, plugins, dependencies, or external
assets are added. Rendering uses CanvasItem primitives from the callers'
existing `_draw()` paths and remains compatible with Godot 4.7 GL
Compatibility/web export.

## Validation and error handling

`validation_errors(profile)` returns every safely detectable error in a
`PackedStringArray` and never mutates the supplied dictionary.

Validation enforces:

- all exact schema fields are present and no unknown fields are present;
- `id` and `name` are non-empty strings;
- `size_scale`, body/muzzle/ear dimensions, `head_radius`, `tail_length`,
  `tail_thickness`, and marking scale are finite and greater than zero;
- `tail_carriage` is finite;
- ear and marking offsets are finite vectors;
- ear, tail, and marking styles belong to their exact supported sets;
- color values are `Color` instances whose red, green, blue, and alpha
  channels are finite and inside inclusive `[0.0, 1.0]`;
- any generated point collection contains enough finite points for its draw
  primitive;
- conservative worst-case generated geometry remains within
  `DogAppearance.MAX_LOCAL_RADIUS` of `origin`.

Catalog construction and tests separately enforce that built-in IDs are
unique, match their catalog keys, and follow the stable order. A
single-profile validation call cannot detect a duplicate elsewhere.

`draw_dog()` validates its input. If the supplied dictionary is malformed, it
uses a defensive copy of the first canonical profile rather than crashing,
drawing invalid geometry, consuming randomness, or mutating the input. A
zero-length or non-finite `forward` uses `Vector2.RIGHT` as the stable fallback.
Non-finite `origin`, `bob`, or `wag_phase` results in no draw calls; the
renderer must not submit non-finite geometry to CanvasItem.

These rules make malformed future selector input deterministic while keeping
normal built-in rendering simple and headless-testable.

## Free-dog integration

`freedog.gd` keeps its current four-argument entry point:

```gdscript
setup(main, player_dog, freedom_y_lo, freedom_y_hi)
```

No appearance argument is added. The script stores:

```gdscript
var appearance_profile: Dictionary = {}
```

During setup, it derives one signed integer appearance key from:

- `roundi(position.x)`;
- `roundi(position.y)`;
- `roundi(y_lo)`;
- `roundi(y_hi)`;
- fixed integer multipliers and integer combination only.

The key calculation has no process-specific hash, floating random source, or
clock input. The same assigned position and bounds produce the same key,
profile, and animation phase across fresh instances and runs. Representative
valid spawn positions must resolve to more than one profile.

`DogAppearance.profile_for_key(appearance_key)` supplies the profile. The
existing `seed_o` animation offset becomes a bounded deterministic value
derived from the same key with positive integer modulo. The old random color
selection is removed; any retained compatibility color field takes
`appearance_profile.base_color`.

Free-dog setup consumes no global RNG. Its existing random calls when a wander
decision becomes due retain their exact order and cadence:

1. `randf_range(0.5, 1.5)` for the next timer;
2. `randf()` for approach versus milling;
3. only on milling, x then y `randf_range(-1, 1)`.

The existing `_physics_process` location, frozen/phase early return, movement
speeds, probabilities, damping, x/y bounds, group name, greeting exposure,
spawn count, z-order, and cleanup ownership do not change.

In `_draw()`, free dogs preserve their current animation intent:

- `origin` is `Vector2.ZERO`;
- `forward` is the normalized direction from the free dog to the player dog;
- `bob` remains the existing bow-based sine at maximum 1.5 pixels;
- `wag_phase` retains the current time-based fast wag plus deterministic
  `seed_o`.

Coincident dog positions produce a zero vector and therefore exercise the
module's stable `Vector2.RIGHT` fallback.

## NPC pair integration and exact RNG contract

### Setup sequence

`otherpair.gd::setup` retains its signature and its first four random draws in
this exact order:

1. `vel = direction * randf_range(58.0, 82.0)`;
2. `seed_o = randf() * 10.0`;
3. one `randi()` selects `owner_col` through the existing three-color owner
   palette and existing modulo behavior;
4. one `randi()` is captured as the dog appearance key.

The fourth draw is the same draw currently used by
`dog_col = palette[randi() % 3]`. The implementation changes only how that
already-consumed raw integer is interpreted:

```text
dog_appearance_key = randi()
appearance_profile = DogAppearance.profile_for_key(dog_appearance_key)
```

No random call is inserted, removed, moved, repeated, or hidden inside
`DogAppearance`. The fourth raw value, not its old `% 3` result, is passed to
`profile_for_key`, which applies the catalog's positive modulo.

This preserves:

- the exact global RNG call count;
- the exact global RNG call order;
- the existing velocity value;
- the existing `seed_o` value;
- the existing owner-color result;
- the global RNG state observed by every later system in seeded and unseeded
  runs.

The visual dog profile is intentionally allowed to differ from the former
three-color placeholder result. "Seeded-run behavior" here means identical
random stream position and identical non-dog random outcomes, not preservation
of the obsolete dog-color palette.

If `dog_col` remains for compatibility with existing tests or callers, it is
assigned from `appearance_profile.base_color` without another random draw.

### Identity and lifecycle

`otherpair.gd` stores one defensive `appearance_profile` during setup. It is
never reselected, regenerated, or mutated during:

```text
WALKING -> ARRIVING -> PARKED -> RECALLING -> DEPARTING -> WALKING
```

The same pair node, owner node, dog node, leash node, instance IDs, profile
dictionary, and profile ID persist through the lifecycle. Arrival,
`initialize_parked_departure`, parking, recall, re-leashing, departure, route
resumption, and home-phase interruption must not consume appearance RNG or
change the profile.

The appearance work does not alter:

- walking, detour, blocked-route, arrival, park wander, recall, departure, or
  leash-cap movement;
- velocity, timers, bounds, probabilities, damping, or movement constants;
- real leash ticking, detachment, resnap, sampled points, dynamic obstacles,
  or tangle latching/rewards;
- `pairs` membership, greeting identity, park-slot ownership/release, despawn,
  or cleanup;
- main's pair creation, spawn policy, population cap, phase orchestration, or
  reservation logic.

### Parent-Canvas rendering

`otherpair.gd` continues drawing both owner and dog from its own CanvasItem.
The owner drawing statements remain unchanged. Only the current dog placeholder
draw statements are replaced by:

```gdscript
DogAppearance.draw_dog(
	self,
	appearance_profile,
	npc_dog.position,
	facing,
	bob,
	wag
)
```

The pair supplies:

- `origin = npc_dog.position`, retaining the child node as the leash and
  movement endpoint;
- `facing = (my_dog.global_position - npc_dog.position).normalized()`,
  preserving the current parent-Canvas calculation and intent that the NPC dog
  looks toward the player dog;
- `bob = sin(t * 6.0 + seed_o) * 1.5`, a bounded happy visual offset derived
  from the existing time and setup phase;
- `wag = t * 8.0 + seed_o`, retaining the current pair tail-wag frequency and
  phase source.

These values consume no randomness. A coincident player/NPC dog position
passes a zero `facing`, which the shared renderer handles deterministically.
Drawing never changes `npc_dog.position`, collision, route formation offsets,
or leash endpoints.

## Data flow

### Free dog

```text
main assigns spawn position
  -> freedog.setup(main, player_dog, y_lo, y_hi)
  -> rounded position and bounds form integer key
  -> DogAppearance.profile_for_key(key) returns defensive profile
  -> same key forms deterministic seed_o
  -> freedog._draw computes origin/facing/bob/wag
  -> DogAppearance.draw_dog draws on freedog CanvasItem
```

There is no RNG edge in this flow.

### NPC pair dog

```text
otherpair.setup
  -> existing velocity randf_range
  -> existing seed_o randf
  -> existing owner-color randi
  -> existing dog-color randi captured as raw appearance key
  -> DogAppearance.profile_for_key(key) returns defensive profile
  -> profile remains attached to the same pair through every PairState
  -> otherpair._draw computes origin/facing/bob/wag
  -> DogAppearance.draw_dog draws on otherpair CanvasItem
```

All later random consumers observe the same global RNG state as before this
feature.

## Testing strategy

Tests use the real `dog_appearance.gd`, `freedog.gd`, and `otherpair.gd`
scripts. They do not copy production selection formulas into fake
implementations and do not use source-text inspection as their primary
assertion.

### Free-dog and catalog regression

Create `tests/test_free_dog_variety.gd` as a `SceneTree` test. It prints
`FAIL:` for each assertion failure, exits `1` when any assertion fails, and
prints `test_free_dog_variety: OK` before exiting `0` on success.

It covers:

1. the exact six supported public methods and `MAX_LOCAL_RADIUS`;
2. the exact six stable IDs and order, with no duplicates;
3. expected positive and negative key selection and profile-count cycling;
4. defensive `profile_ids`, known-profile, and unknown-profile results;
5. the exact required schema with no missing or extra fields;
6. zero validation errors for every built-in profile;
7. invalid synthetic profiles reporting errors without mutation or crashes;
8. duplicate built-in ID/catalog-key detection;
9. all four ear, tail, and marking branches, at least four coats, and at
   least three silhouettes;
10. a deliberately oversized profile failing `MAX_LOCAL_RADIUS` validation;
11. appearance list/selection/lookup/validation preserving global RNG through
    a seed/expected/reseed/call/actual comparison;
12. real free-dog setup preserving global RNG through the same comparison;
13. identical real free-dog setup inputs yielding equal profiles and animation
    offsets across fresh instances;
14. representative different positions selecting more than one profile;
15. real free dogs retaining setup references, bounds, `freedogs` membership,
    frozen and non-freedom stationary behavior, active fixed-velocity movement,
    damping, and existing x/y clamps;
16. assigning every profile to a real free dog, requesting redraw, and
    advancing a frame without draw errors;
17. a coincident player/free-dog position exercising the zero-forward
    fallback.

Lifecycle movement assertions set `wander_t` above zero and fixed velocity so
they do not trigger the intentionally preserved random wander branch.

### Shared pair appearance regression

Create a separate `tests/test_pair_dog_appearance.gd` `SceneTree` test. The
pair-specific RNG and lifecycle contract is substantial enough to keep
separate from the catalog/free-dog test. It uses a real `otherpair.gd`, real
`leash.gd`, and minimal fake main/player nodes following current lifecycle
test patterns.

It prints `FAIL:` on assertion failure, exits `1` on failure, and prints
`test_pair_dog_appearance: OK` before exiting `0` on success.

It covers:

1. the exact setup RNG sequence by seeding, independently recording the
   expected `randf_range`, `randf`, owner `randi`, dog `randi`, and following
   random value, reseeding, running real pair setup, and comparing:
   - `vel` to the first draw and supplied direction;
   - `seed_o` to the second draw;
   - `owner_col` to the third draw and existing owner palette;
   - `appearance_profile` to `DogAppearance.profile_for_key` of the fourth raw
     draw;
   - the next global random value to the recorded following value;
2. no extra RNG from assigning `dog_col` or rendering;
3. two equal seeds producing the same pair profile and animation phase;
4. selected seeds covering more than one profile without changing draw count;
5. one profile dictionary and profile ID persisting through `WALKING`,
   `ARRIVING`, `PARKED`, `RECALLING`, `DEPARTING`, and resumed `WALKING`;
6. existing owner, dog, leash, and pair instance identities persisting through
   the same transitions;
7. profile persistence through `initialize_parked_departure` and home-phase
   interruption;
8. parent-Canvas render smoke for every profile by assigning the profile,
   requesting a redraw on the real pair, and advancing one frame;
9. coincident `my_dog` and `npc_dog` positions exercising zero-forward
   fallback without draw errors;
10. unchanged owner rendering path remaining callable in the same frame;
11. draw smoke preserving the global RNG state.

The existing `tests/test_pair_park_lifecycle.gd` remains unchanged during the
isolated implementation and continues to prove movement, leash, identity,
tangle, route-resume, and cleanup contracts. Its existing color-persistence
assertion may continue through a compatibility `dog_col`; the new focused test
is authoritative for profile persistence.

### Existing regression and smoke coverage

After the focused tests pass, run at least:

- `tests/test_pair_park_lifecycle.gd`;
- `tests/test_pair_park_traffic.gd`;
- `tests/test_freedom_traffic.gd`;
- `tests/test_pair_direction.gd`;
- `tests/test_bypasser_route.gd`;
- `tests/test_pair_pond_avoidance.gd`;
- `tests/test_tangle_latch.gd`;
- `tests/test_wrap.gd`;
- park headless smoke;
- fixed-60-FPS park autowalk through `AUTOWALK FINISHED`.

The final implementation plan must enumerate the complete current regression
suite and exact commands.

Manual park acceptance confirms that free dogs and pair dogs visibly share the
same vocabulary, remain readable at gameplay scale, preserve owner drawing,
keep pair leashes attached to the positional dog node, and do not visually
change identity during park lifecycle transitions.

## Implementation and integration boundary

The initial implementation/review boundary is exactly:

- create `dog_appearance.gd`;
- modify `freedog.gd`;
- modify `otherpair.gd`;
- create `tests/test_free_dog_variety.gd`;
- create `tests/test_pair_dog_appearance.gd`.

The separate pair test is required because it isolates the exact RNG cadence
and five-state profile-persistence contract from free-dog/catalog assertions.

During this initial boundary:

- do not modify `main.gd`, `leash.gd`, `bypasser_route.gd`, `bike.gd`, or
  existing tests;
- do not modify `.github/workflows/ci.yml`, `CHANGELOG.md`, `HANDOVER.md`,
  `PROJECT.md`, the earlier handoff, this spec, or the stale plan draft;
- inspect the working tree before editing and preserve unrelated work;
- do not stage, revert, overwrite, or format files outside the five-file
  boundary;
- if `freedog.gd` or `otherpair.gd` has changed since planning, stop and
  coordinate;
- do not commit or push until the implementation boundary is reviewed and the
  parent explicitly authorizes integration.

After review, a separate integration task adds both focused tests to CI and
updates `CHANGELOG.md` and `HANDOVER.md`. Those integration edits receive their
own diff review and commit checkpoint.

## Explicit non-goals

- No owner visual changes.
- No owner appearance catalog, renderer, random selection, or profile state.
- No hats, glasses, bald spots, long hair, or other owner accessories.
- No playable dog selector, character-creator UI, saves, progression, shop,
  unlock, or persistence work.
- No named real breeds or claims that procedural shapes depict real breeds.
- No changes to Millie in `dog.gd`.
- No collars, harnesses, bandanas, sounds, names, interactions, behaviors, or
  stats for NPC dogs.
- No changes to spawn orchestration, population count/balance, pair cap,
  greeting scoring, quests, or cleanup.
- No movement, collision, route, leash, tangle, lifecycle, or difficulty
  changes.
- No external assets, production-art replacement, new scenes, resources,
  textures, SVGs, plugins, or dependencies.

## Next separate task: owner appearance profiles

Reusable owner appearance profiles are the next independent design task after
shared NPC dog appearances are accepted.

That future task will define neutral owner profile data and procedural
rendering that can support hats, glasses, bald spots, and long hair, with a
boundary suitable for a later character creator. It must separately decide
its schema, selection/RNG compatibility, renderer ownership, profile identity,
tests, and relationship to the existing HIM/HER player-owner presets.

No owner API or visual behavior is preselected here. Keeping it separate
prevents dog-profile implementation from silently changing owner RNG,
silhouette, identity, or future save-format decisions.

## Acceptance criteria

The shared NPC dog appearance foundation is accepted only when:

- one stateless `DogAppearance` module serves both `freedog.gd` and
  `otherpair.gd`;
- the module exposes the exact approved API and `MAX_LOCAL_RADIUS`;
- all six stable neutral profiles use the exact schema and defensive copies;
- positive and negative integer keys select deterministically by positive
  modulo;
- built-in and synthetic validation covers schema, finite dimensions,
  placement, styles, colors, point safety, uniqueness, and radius bounds;
- the six profiles visibly exercise every supported ear, tail, and marking
  branch and all required coat/silhouette variety;
- only `draw_dog()` issues appearance-module CanvasItem draw calls;
- invalid renderer input and zero-forward input are handled deterministically
  without invalid geometry or RNG;
- free-dog profile and animation selection are deterministic from rounded
  spawn position/bounds and consume no RNG;
- free-dog gameplay, random wander cadence, groups, greetings, spawn count,
  z-order, bounds, and cleanup are unchanged;
- pair setup retains exactly `randf_range`, `randf`, owner `randi`, dog
  appearance `randi` in that order, with no added or removed random draw;
- the raw fourth pair setup draw is the appearance key and all later random
  consumers retain their prior seeded stream position;
- each pair's profile persists with the same nodes through all five lifecycle
  states and resumed walking;
- pair owner drawing remains on the parent unchanged and pair dog drawing is
  delegated from the parent with the approved origin/facing/bob/wag data;
- pair movement, leash, tangle, greeting, group, slot, route, lifecycle, and
  cleanup contracts are unchanged;
- real-script focused tests cover the catalog, both callers, RNG contracts,
  lifecycle persistence, every profile, zero-forward fallback, and headless
  rendering;
- existing pair, traffic, route, tangle, rope, park smoke, and park autowalk
  regressions pass;
- the initial reviewed diff contains only the five implementation/test files;
- CI and documentation changes occur only in the reviewed final integration
  task;
- owner appearance work remains a separate follow-up with no owner visual
  change in this feature;
- no external asset, breed claim, gameplay/stat change, or playable selector
  is introduced.
