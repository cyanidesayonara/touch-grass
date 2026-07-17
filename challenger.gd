extends Node2D

# The combo-challenge giver (Combo Phase B): a show-off kid on a bench who
# dares you into a bounded trick window as you pass. One offer per walk;
# after that they just cheer (or commiserate). Pure flavour + a proximity
# trigger - the challenge logic and reward live in challenge.gd / main.

const NOTICE_R := 240.0

var main: Node2D
var my_dog: Node2D
var trick_target := 5
var window := 12.0
var fired := false
var result := ""  # "", "win", "lose" once resolved
var seed_o := 0.0


func setup(m: Node2D, mine: Node2D, target: int, seconds: float) -> void:
	add_to_group("challengers")
	main = m
	my_dog = mine
	trick_target = target
	window = seconds
	# derived from position, never the global RNG - spawning this must not
	# desync the deterministic autowalk traversal
	seed_o = fmod(absf(position.x) * 0.017, TAU)


func _physics_process(_delta: float) -> void:
	if main.frozen or fired:
		return
	# only offer while walking out - not mid off-leash romp or the way home
	if main.phase != "out":
		return
	if my_dog.global_position.distance_to(global_position) < NOTICE_R:
		fired = true
		main.start_challenge(self, trick_target, window)


func resolve(win: bool) -> void:
	result = "win" if win else "lose"
	queue_redraw()


func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	# a low bench
	draw_rect(Rect2(-22, 6, 44, 8), Color(0.5, 0.37, 0.25))
	draw_rect(Rect2(-20, 14, 5, 10), Color(0.4, 0.29, 0.2))
	draw_rect(Rect2(15, 14, 5, 10), Color(0.4, 0.29, 0.2))
	# the kid, lounging, one arm up
	var bob := sin(t * 3.0 + seed_o) * 1.5
	draw_circle(Vector2(0, -14 + bob), 7.0, Color(0.9, 0.76, 0.62))
	draw_rect(Rect2(-6, -8 + bob, 12, 16), Color(0.85, 0.3, 0.35))
	draw_line(Vector2(5, -6 + bob), Vector2(14, -18 + bob), Color(0.9, 0.76, 0.62), 3.0)
	# a little cap
	draw_arc(Vector2(0, -16 + bob), 7.0, PI, TAU, 8, Color(0.2, 0.35, 0.6), 4.0)
	# speech bubble: the dare, the cheer, or the shrug
	var line := "bet you can't!" if result == "" else ("nice!!" if result == "win" else "heh, next time")
	var col := Color(1, 0.95, 0.75) if result != "win" else Color(0.8, 1.0, 0.8)
	draw_string(ThemeDB.fallback_font, Vector2(14, -26), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, col)
