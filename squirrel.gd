extends Node2D

# A squirrel: the temptation that tugs at the DOG (main.gd applies the
# pull). Never catchable - the last-second escape is a law of nature -
# but the chase pays bones. Barking scares them off.

var main: Node2D
var dog: Node2D
var state := 0  # 0 idle, 1 alert, 2 flee
var flee_dir := Vector2.UP
var hop_t := 0.0
var seed_o := 0.0
var chased := false


func setup(m: Node2D, d: Node2D) -> void:
	add_to_group("squirrels")
	main = m
	dog = d
	seed_o = randf() * 10.0


func _physics_process(delta: float) -> void:
	if main.frozen:
		return
	var dd: float = global_position.distance_to(dog.global_position)
	match state:
		0:
			hop_t -= delta
			if hop_t <= 0.0:
				hop_t = randf_range(0.8, 2.2)
				position += Vector2(randf_range(-14.0, 14.0), randf_range(-14.0, 14.0))
			if dd < 150.0:
				state = 1
		1:
			if dd < 95.0:
				scare()
			elif dd > 190.0:
				state = 0
		2:
			# zigzag escape, faster than any dog in a straight line
			var t := Time.get_ticks_msec() / 1000.0
			position += flee_dir.rotated(sin(t * 9.0 + seed_o) * 0.5) * 400.0 * delta
			if absf(global_position.y - float(main.cam.position.y)) > 800.0:
				queue_free()
	if not chased and state != 2 and dd < 26.0:
		chased = true
		main.on_squirrel_chase(global_position)
		scare()
	queue_redraw()


func scare() -> void:
	if state == 2:
		return
	state = 2
	flee_dir = (global_position - dog.global_position).normalized()
	# prefer escaping along the walk axis rather than into walls
	flee_dir = (flee_dir + Vector2(0, -1.2 if flee_dir.y < 0.0 else 1.2)).normalized()


func _draw() -> void:
	var body := Color(0.5, 0.33, 0.2)
	var t := Time.get_ticks_msec() / 1000.0
	var up := state == 1
	# the tail is the whole silhouette
	draw_arc(Vector2(-7, 2), 6.0, PI * 0.2 + sin(t * 6.0 + seed_o) * 0.3, PI * 1.4, 10, body.lightened(0.15), 4.0)
	draw_circle(Vector2.ZERO, 5.5, body)
	draw_circle(Vector2(2, -6) if up else Vector2(4, -3), 3.5, body)
	draw_circle(Vector2(3, -8) if up else Vector2(5, -5), 1.2, Color(0.1, 0.08, 0.06))
