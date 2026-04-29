class_name TrashLayer
extends Node2D


const TRASH_SCENE := preload("res://scenes/Trash.tscn")
const INITIAL_COUNT := 18
const RESPAWN_DELAY := 4.0
const COLLISION_RADIUS := 9.0

var _respawn_timer := 0.0
var _spawn_counter := 0


func spawn_initial() -> void:
	for i in range(INITIAL_COUNT):
		_spawn()


func _process(delta: float) -> void:
	_update_physics(delta)
	_respawn_if_needed(delta)


func _update_physics(delta: float) -> void:
	for child in get_children():
		var trash := child as OrbitTrash
		if trash.is_cargo:
			continue
		trash.velocity += World.calculate_gravity(trash.position) * delta
		trash.position = World.wrap_position(trash.position + trash.velocity * delta)
		trash.rotation += delta * 0.7
		if World.wrapped_distance(trash.position, Vector2.ZERO) < World.EARTH_RADIUS + 12.0:
			trash.queue_free()
			_spawn()
	_resolve_collisions()


func _respawn_if_needed(delta: float) -> void:
	if get_child_count() >= INITIAL_COUNT:
		_respawn_timer = 0.0
		return
	_respawn_timer += delta
	if _respawn_timer < RESPAWN_DELAY:
		return
	_respawn_timer = 0.0
	_spawn()


func _spawn() -> void:
	var trash := TRASH_SCENE.instantiate() as OrbitTrash
	var angle := randf_range(0.0, TAU)
	var radius := World.ORBIT_RADIUS + randf_range(-38.0, 58.0)
	var pos := Vector2.RIGHT.rotated(angle) * radius
	var tangent := pos.orthogonal().normalized()
	var circular_speed := sqrt(World.EARTH_GRAVITY_MU / radius)
	trash.position = pos
	trash.velocity = tangent * circular_speed * randf_range(0.94, 1.06)
	trash.name = "Trash%d" % _spawn_counter
	_spawn_counter += 1
	add_child(trash)


func _resolve_collisions() -> void:
	var scraps := get_children()
	for i in range(scraps.size()):
		var first := scraps[i] as OrbitTrash
		if not is_instance_valid(first):
			continue
		for j in range(i + 1, scraps.size()):
			var second := scraps[j] as OrbitTrash
			if not is_instance_valid(second):
				continue
			_separate_pair(first, second)


func _separate_pair(first: OrbitTrash, second: OrbitTrash) -> void:
	var delta: Vector2 = World.wrapped_delta(first.position, second.position)
	var distance: float = delta.length()
	var min_distance: float = COLLISION_RADIUS * 2.0
	if distance >= min_distance:
		return
	var direction: Vector2 = Vector2.RIGHT if distance <= 0.001 else delta / distance
	var overlap: float = min_distance - distance
	if first.is_cargo and second.is_cargo:
		first.position = World.wrap_position(first.position - direction * (overlap * 0.5))
		second.position = World.wrap_position(second.position + direction * (overlap * 0.5))
	elif first.is_cargo:
		second.position = World.wrap_position(second.position + direction * overlap)
		second.velocity += direction * 10.0
	elif second.is_cargo:
		first.position = World.wrap_position(first.position - direction * overlap)
		first.velocity -= direction * 10.0
	else:
		first.position = World.wrap_position(first.position - direction * (overlap * 0.5))
		second.position = World.wrap_position(second.position + direction * (overlap * 0.5))
		first.velocity -= direction * 8.0
		second.velocity += direction * 8.0
