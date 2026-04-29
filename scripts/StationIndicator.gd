extends Control

var arrow_angle := 0.0


func _draw() -> void:
	var arrow_color := Color(0.95, 0.98, 1.0, 0.95)
	var outline_color := Color(0.15, 0.22, 0.35, 0.95)
	var points := PackedVector2Array([
		Vector2(14, 0),
		Vector2(-10, -8),
		Vector2(-4, 0),
		Vector2(-10, 8),
	])

	for i in range(points.size()):
		points[i] = points[i].rotated(arrow_angle)

	draw_colored_polygon(points, arrow_color)
	draw_polyline(points + PackedVector2Array([points[0]]), outline_color, 2.0)
	draw_circle(Vector2.ZERO, 3.0, outline_color)
