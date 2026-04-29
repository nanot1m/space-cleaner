extends Control

var world_wrap_size := Vector2(4480.0, 4480.0)
var earth_center := Vector2.ZERO
var earth_radius := 150.0
var moon_position := Vector2.ZERO
var moon_radius := 32.0
var station_position := Vector2.ZERO
var moon_station_position := Vector2.ZERO
var ship_position := Vector2.ZERO
var astronaut_position := Vector2.ZERO
var is_piloting_ship := false


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color(0.04, 0.08, 0.14, 0.92), true)
	draw_rect(rect, Color(0.55, 0.72, 0.9, 0.9), false, 2.0)

	var center := size * 0.5
	var scale_factor := minf(size.x / world_wrap_size.x, size.y / world_wrap_size.y)
	var earth_map_radius := earth_radius * scale_factor
	var moon_map_radius := moon_radius * scale_factor

	draw_circle(center, earth_map_radius, Color(0.15, 0.45, 0.72, 0.95))
	draw_arc(center, earth_map_radius + 1.0, 0.0, TAU, 64, Color(0.5, 0.84, 1.0, 0.45), 1.0)

	draw_circle(_to_minimap_point(moon_position, scale_factor), moon_map_radius, Color(0.78, 0.8, 0.84, 0.95))
	draw_circle(_to_minimap_point(station_position, scale_factor), 3.0, Color(0.58, 0.88, 1.0, 1.0))
	draw_circle(_to_minimap_point(moon_station_position, scale_factor), 2.7, Color(1.0, 0.84, 0.58, 1.0))
	draw_circle(_to_minimap_point(astronaut_position, scale_factor), 2.3, Color(0.95, 0.95, 1.0, 0.95))
	draw_circle(_to_minimap_point(ship_position, scale_factor), 2.6, Color(1.0, 0.76, 0.42, 1.0))

	if is_piloting_ship:
		draw_circle(_to_minimap_point(ship_position, scale_factor), 5.0, Color(1.0, 1.0, 1.0, 0.18))
	else:
		draw_circle(_to_minimap_point(astronaut_position, scale_factor), 4.6, Color(1.0, 1.0, 1.0, 0.16))


func _to_minimap_point(world_position: Vector2, scale_factor: float) -> Vector2:
	var relative := world_position - earth_center
	return size * 0.5 + relative * scale_factor
