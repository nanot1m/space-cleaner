@tool
class_name PlayerShip
extends Node2D


const MAX_CARGO := 5
const MAX_SPEED := 360.0
const MIN_SPEED := 105.0
const DRAG_PER_SCRAP := 24.0
const THRUST := 260.0
const BRAKE := 140.0
const ROTATION_SPEED := 2.8
const PICKUP_DISTANCE := 52.0

var velocity := Vector2.ZERO
var is_piloting := false
var cargo_scrap: Array[Node2D] = []

var throttle_amount := 0.0:
	set(value):
		throttle_amount = value
		_update_engine_fire()

var cargo_count := 0:
	set(value):
		cargo_count = value
		queue_redraw()

@onready var engine_fire: GPUParticles2D = $EngineFire


func _ready() -> void:
	_update_engine_fire()


func _draw() -> void:
	var hull := Color("f6b35c")
	var cockpit := Color("20324d")
	var wing := Color("88d0ff")
	draw_rect(Rect2(Vector2(8, -2), Vector2(4, 4)), hull)
	draw_rect(Rect2(Vector2(4, -4), Vector2(4, 8)), hull)
	draw_rect(Rect2(Vector2(0, -5), Vector2(4, 10)), hull)
	draw_rect(Rect2(Vector2(-4, -3), Vector2(4, 6)), hull)
	draw_rect(Rect2(Vector2(-8, -6), Vector2(4, 3)), wing)
	draw_rect(Rect2(Vector2(-8, 3), Vector2(4, 3)), wing)
	draw_rect(Rect2(Vector2(2, -2), Vector2(3, 4)), cockpit)
	draw_rect(Rect2(Vector2(-11, -2), Vector2(3, 4)), Color("ff8d5c"))
	for i in range(cargo_count):
		draw_rect(Rect2(Vector2(-12 - float(i) * 5.0, 11), Vector2(3, 3)), Color("d6dce3"))


func pilot_update(delta: float) -> void:
	if not is_piloting:
		velocity = Vector2.ZERO
		throttle_amount = 0.0
		_update_cargo_chain(delta)
		return

	var turn_input := Input.get_axis("ui_left", "ui_right")
	var throttle_input := Input.get_action_strength("ui_up")
	var brake_input := Input.get_action_strength("ui_down")
	var forward := Vector2.RIGHT.rotated(rotation)

	throttle_amount = throttle_input
	rotation += turn_input * ROTATION_SPEED * delta
	velocity += World.calculate_gravity(position) * delta

	if throttle_input > 0.0:
		velocity += forward * THRUST * throttle_input * delta

	if brake_input > 0.0 and velocity.length() > 0.0:
		velocity = velocity.move_toward(Vector2.ZERO, BRAKE * brake_input * delta)

	var move_speed := current_move_speed()
	if velocity.length() > move_speed:
		velocity = velocity.normalized() * move_speed

	position = World.wrap_position(position + velocity * delta)
	_update_cargo_chain(delta)


func collect_nearby(trash_layer: Node2D) -> void:
	if not is_piloting or cargo_scrap.size() >= MAX_CARGO:
		return
	for child in trash_layer.get_children():
		var trash := child as OrbitTrash
		if trash.is_cargo:
			continue
		if World.wrapped_distance(position, trash.position) <= PICKUP_DISTANCE:
			trash.is_cargo = true
			trash.velocity = Vector2.ZERO
			cargo_scrap.append(trash)
			cargo_count = cargo_scrap.size()
			if cargo_scrap.size() >= MAX_CARGO:
				return


func release_one() -> void:
	if cargo_scrap.is_empty():
		return
	var trash := cargo_scrap.pop_back() as OrbitTrash
	if not is_instance_valid(trash):
		cargo_count = cargo_scrap.size()
		return
	var release_dir := Vector2.LEFT.rotated(rotation)
	trash.is_cargo = false
	trash.position = World.wrap_position(position + release_dir * 20.0)
	trash.velocity = velocity + release_dir * 40.0
	cargo_count = cargo_scrap.size()


func deliver_all() -> int:
	var count := 0
	for trash in cargo_scrap:
		if is_instance_valid(trash):
			trash.queue_free()
			count += 1
	cargo_scrap.clear()
	cargo_count = 0
	return count


func start_docking(landing_station: Node2D, dock_offset: Vector2, on_complete: Callable) -> void:
	is_piloting = false
	velocity = Vector2.ZERO
	throttle_amount = 0.0

	var departing := cargo_scrap.duplicate()
	cargo_scrap.clear()
	cargo_count = 0

	var delivered := 0
	for t in departing:
		if is_instance_valid(t):
			delivered += 1

	var ship_start := position
	var dock_rot := landing_station.rotation

	var tween := create_tween().set_parallel(true)
	tween.tween_method(func(t: float) -> void:
		var live_dock := World.wrapped_target_position(ship_start, landing_station.position + dock_offset)
		position = ship_start.lerp(live_dock, t),
		0.0, 1.0, 0.6).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "rotation",
		rotation + angle_difference(rotation, dock_rot), 0.6) \
		.set_ease(Tween.EASE_IN_OUT)

	for i in range(departing.size()):
		var trash := departing[i] as OrbitTrash
		if not is_instance_valid(trash):
			continue
		var trash_start := trash.position
		tween.tween_method(func(t: float) -> void:
			var live_target := World.wrapped_target_position(trash_start, landing_station.position)
			trash.position = trash_start.lerp(live_target, t),
			0.0, 1.0, 0.35).set_delay(float(i) * 0.06) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)

	tween.chain().tween_callback(func() -> void:
		for trash in departing:
			if is_instance_valid(trash):
				trash.queue_free()
		on_complete.call(delivered)
	)


func get_tether_points() -> Array[Vector2]:
	var points: Array[Vector2] = [position]
	for trash in cargo_scrap:
		if not is_instance_valid(trash):
			continue
		points.append(points[-1] + World.wrapped_delta(points[-1], trash.position))
	return points


func get_collectible_target(trash_layer: Node2D) -> Node2D:
	if not is_piloting or cargo_scrap.size() >= MAX_CARGO:
		return null
	var best_target: Node2D = null
	var best_distance := PICKUP_DISTANCE
	for child in trash_layer.get_children():
		var trash := child as OrbitTrash
		if trash.is_cargo:
			continue
		var distance := World.wrapped_distance(position, trash.position)
		if distance <= best_distance:
			best_distance = distance
			best_target = trash
	return best_target


func current_move_speed() -> float:
	return maxf(MIN_SPEED, MAX_SPEED - float(cargo_scrap.size()) * DRAG_PER_SCRAP)


func _update_cargo_chain(delta: float) -> void:
	for i in range(cargo_scrap.size()):
		var trash := cargo_scrap[i]
		if not is_instance_valid(trash):
			continue
		var follow_offset := Vector2(-24.0 - float(i) * 14.0, 0).rotated(rotation)
		var desired: Vector2 = position + follow_offset
		var wrapped_desired := World.wrapped_target_position(trash.position, desired)
		trash.position = World.wrap_position(trash.position.move_toward(wrapped_desired, (170.0 - float(i) * 18.0) * delta))
		trash.rotation = rotation


func _update_engine_fire() -> void:
	if not is_node_ready():
		return
	engine_fire.emitting = throttle_amount > 0.02
