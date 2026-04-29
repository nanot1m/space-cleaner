extends Node2D

var dotted_from := Vector2.ZERO
var dotted_to := Vector2.ZERO
var show_dotted := false
var solid_points: Array[Vector2] = []

const PICKUP_WIRE_SEGMENT := 10.0
const PICKUP_WIRE_GAP := 5.0


func _draw() -> void:
	if show_dotted:
		_draw_dotted_wire(dotted_from, dotted_to, Color(0.95, 0.98, 1.0, 1.0))

	if solid_points.size() >= 2:
		for i in range(solid_points.size() - 1):
			draw_line(solid_points[i], solid_points[i + 1], Color(0.82, 0.9, 1.0, 0.95), 2.0)


func _draw_dotted_wire(from: Vector2, to: Vector2, color: Color) -> void:
	var distance := from.distance_to(to)
	if distance <= 0.001:
		return

	var direction := (to - from).normalized()
	var drawn := 0.0
	while drawn < distance:
		var start := from + direction * drawn
		var end := from + direction * minf(drawn + PICKUP_WIRE_SEGMENT, distance)
		draw_line(start, end, color, 2.5)
		drawn += PICKUP_WIRE_SEGMENT + PICKUP_WIRE_GAP
