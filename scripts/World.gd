extends Node

const WORLD_WRAP_SIZE := Vector2(19840.0, 19840.0)
const EARTH_GRAVITY_MU := 3300000.0
const MOON_GRAVITY_MU := 330000.0
const MIN_GRAVITY_DISTANCE_SQ := 14400.0
const EARTH_RADIUS := 150.0
const ORBIT_RADIUS := 240.0

var moon_position := Vector2.ZERO


func wrap_position(position: Vector2) -> Vector2:
	position.x = wrapf(position.x + WORLD_WRAP_SIZE.x * 0.5, 0.0, WORLD_WRAP_SIZE.x) - WORLD_WRAP_SIZE.x * 0.5
	position.y = wrapf(position.y + WORLD_WRAP_SIZE.y * 0.5, 0.0, WORLD_WRAP_SIZE.y) - WORLD_WRAP_SIZE.y * 0.5
	return position


func wrapped_delta(from: Vector2, to: Vector2) -> Vector2:
	var delta := to - from
	if delta.x > WORLD_WRAP_SIZE.x * 0.5:
		delta.x -= WORLD_WRAP_SIZE.x
	elif delta.x < -WORLD_WRAP_SIZE.x * 0.5:
		delta.x += WORLD_WRAP_SIZE.x
	if delta.y > WORLD_WRAP_SIZE.y * 0.5:
		delta.y -= WORLD_WRAP_SIZE.y
	elif delta.y < -WORLD_WRAP_SIZE.y * 0.5:
		delta.y += WORLD_WRAP_SIZE.y
	return delta


func wrapped_distance(from: Vector2, to: Vector2) -> float:
	return wrapped_delta(from, to).length()


func wrapped_target_position(from: Vector2, to: Vector2) -> Vector2:
	return from + wrapped_delta(from, to)


func calculate_gravity(position: Vector2) -> Vector2:
	var earth_offset := wrapped_delta(position, Vector2.ZERO)
	var earth_dist_sq := maxf(earth_offset.length_squared(), MIN_GRAVITY_DISTANCE_SQ)
	var earth_accel := earth_offset.normalized() * (EARTH_GRAVITY_MU / earth_dist_sq)

	var moon_offset := wrapped_delta(position, moon_position)
	var moon_dist_sq := maxf(moon_offset.length_squared(), MIN_GRAVITY_DISTANCE_SQ)
	var moon_accel := moon_offset.normalized() * (MOON_GRAVITY_MU / moon_dist_sq)

	return earth_accel + moon_accel
