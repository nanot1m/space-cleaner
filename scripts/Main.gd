extends Node2D

const MOON_ORBIT_RADIUS := 9048.0
const MOON_RADIUS := 40.9
const MOON_ANGULAR_SPEED := 0.02
const MOON_STATION_ORBIT_RADIUS := 92.0
const STATION_DOCK_OFFSET := Vector2(32, 0)
const STATION_ASTRONAUT_OFFSET := Vector2(-18, -12)
const DOCK_DISTANCE := 36.0
const CAMERA_ZOOM_STEP := 0.12
const CAMERA_MIN_ZOOM := 0.45
const CAMERA_MAX_ZOOM := 2.4

var moon_angle := 1.2
var stored_scrap := 0
var is_piloting_ship := false
var is_docking := false
var is_undocking := false
var _camera_target_is_ship := false
var current_station: Node2D
var is_panning := false
var station_velocity := Vector2.ZERO
var moon_station_velocity := Vector2.ZERO

@onready var camera: Camera2D = $Camera2D
@onready var earth = $Earth
@onready var station = $Station
@onready var moon = $Moon
@onready var moon_station = $MoonStation
@onready var astronaut = $Astronaut
@onready var ship: PlayerShip = $Ship
@onready var trash_layer: Node2D = $Trash
@onready var tether_overlay: Node2D = $TetherOverlay
@onready var status_label: Label = $UI/Margin/Panel/VBox/Status
@onready var station_indicator: Control = $UI/StationIndicator
@onready var minimap: Control = $UI/Minimap
@onready var music: AudioStreamPlayer = $Music


func _ready() -> void:
	music.finished.connect(music.play)
	seed(1337)
	earth.orbit_radius = World.ORBIT_RADIUS
	earth.earth_radius = World.EARTH_RADIUS
	earth.wrap_size = World.WORLD_WRAP_SIZE
	earth.view_center = camera.position
	current_station = station

	var station_angle := -0.3
	station.position = Vector2.RIGHT.rotated(station_angle) * World.ORBIT_RADIUS
	station_velocity = Vector2.RIGHT.rotated(station_angle - PI * 0.5) * sqrt(World.EARTH_GRAVITY_MU / World.ORBIT_RADIUS)

	moon.position = Vector2.RIGHT.rotated(moon_angle) * MOON_ORBIT_RADIUS
	moon.rotation = moon_angle * 0.35
	World.moon_position = moon.position
	var moon_station_angle := -0.6
	moon_station.position = moon.position + Vector2.RIGHT.rotated(moon_station_angle) * MOON_STATION_ORBIT_RADIUS
	var moon_vel := Vector2.RIGHT.rotated(moon_angle + PI * 0.5) * MOON_ORBIT_RADIUS * MOON_ANGULAR_SPEED
	moon_station_velocity = moon_vel + Vector2.RIGHT.rotated(moon_station_angle - PI * 0.5) * sqrt(World.MOON_GRAVITY_MU / MOON_STATION_ORBIT_RADIUS)

	_reset_docked_ship()
	trash_layer.spawn_initial()
	camera.position = astronaut.position
	camera.make_current()
	_update_actor_visibility()
	_update_camera_target()
	_update_ui()


func _process(delta: float) -> void:
	_update_station(delta)
	_update_moon_system(delta)
	ship.pilot_update(delta)
	_update_camera_target()
	earth.view_center = camera.position
	_update_station_indicator()
	_update_tether_overlay()
	_update_minimap()
	_update_ui()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_E: _toggle_ship_interaction()
			KEY_SPACE: ship.collect_nearby(trash_layer)
			KEY_Q: ship.release_one()


func _update_station(delta: float) -> void:
	station_velocity += World.calculate_gravity(station.position) * delta
	station.position = World.wrap_position(station.position + station_velocity * delta)

	if not is_piloting_ship and not is_docking and current_station != null:
		ship.position = _dock_anchor(current_station)
		ship.rotation = current_station.rotation
		if not is_undocking:
			astronaut.position = current_station.position + STATION_ASTRONAUT_OFFSET.rotated(current_station.rotation)
			astronaut.rotation = current_station.rotation


func _update_moon_system(delta: float) -> void:
	moon_angle = wrapf(moon_angle + MOON_ANGULAR_SPEED * delta, 0.0, TAU)
	moon.position = Vector2.RIGHT.rotated(moon_angle) * MOON_ORBIT_RADIUS
	moon.rotation = moon_angle * 0.35
	World.moon_position = moon.position

	moon_station_velocity += World.calculate_gravity(moon_station.position) * delta
	moon_station.position = World.wrap_position(moon_station.position + moon_station_velocity * delta)


func _toggle_ship_interaction() -> void:
	if is_docking or is_undocking:
		return
	if not is_piloting_ship and current_station != null \
			and World.wrapped_distance(ship.position, current_station.position) <= DOCK_DISTANCE:
		is_undocking = true
		astronaut.set_anim_row(1)
		var arc_from: Vector2 = astronaut.position
		var arc_to: Vector2 = ship.position
		var arc_out: Vector2 = ((arc_from + arc_to) * 0.5).normalized()
		var tween := create_tween()
		tween.tween_method(func(t: float) -> void:
			astronaut.position = arc_from.lerp(arc_to, t) + arc_out * 28.0 * sin(t * PI),
			0.0, 1.0, 0.45).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		tween.chain().tween_callback(func() -> void:
			is_undocking = false
			is_piloting_ship = true
			_camera_target_is_ship = true
			ship.is_piloting = true
			ship.velocity = _station_velocity(current_station)
			astronaut.set_anim_row(0)
			_update_actor_visibility()
		)
		return

	var landing := _nearest_station()
	if is_piloting_ship and landing != null:
		is_piloting_ship = false
		is_docking = true
		_update_actor_visibility()
		ship.start_docking(
			_dock_anchor(landing),
			landing.rotation,
			landing.position,
			func(delivered: int) -> void:
				stored_scrap += delivered
				current_station = landing
				_reset_docked_ship()
				_camera_target_is_ship = false
				astronaut.position = _dock_anchor(landing)
				astronaut.rotation = landing.rotation
				astronaut.visible = true
				astronaut.set_anim_row(1)
				var arc_from2: Vector2 = astronaut.position
				var arc_to2: Vector2 = landing.position + STATION_ASTRONAUT_OFFSET.rotated(landing.rotation)
				var arc_out2: Vector2 = ((arc_from2 + arc_to2) * 0.5).normalized()
				var tween := create_tween()
				tween.tween_method(func(t: float) -> void:
					astronaut.position = arc_from2.lerp(arc_to2, t) + arc_out2 * 28.0 * sin(t * PI),
					0.0, 1.0, 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
				tween.chain().tween_callback(func() -> void:
					is_docking = false
					astronaut.set_anim_row(0)
					_update_actor_visibility()
				)
		)


func _reset_docked_ship() -> void:
	ship.velocity = Vector2.ZERO
	ship.position = _dock_anchor(current_station)
	ship.rotation = current_station.rotation


func _update_actor_visibility() -> void:
	astronaut.visible = not is_piloting_ship and not is_docking


func _update_camera_target() -> void:
	if is_panning:
		return
	camera.position = ship.position if _camera_target_is_ship else astronaut.position


func _dock_anchor(station_node: Node2D) -> Vector2:
	return station_node.position + STATION_DOCK_OFFSET.rotated(station_node.rotation)


func _station_velocity(station_node: Node2D) -> Vector2:
	return moon_station_velocity if station_node == moon_station else station_velocity


func _nearest_station() -> Node2D:
	var stations: Array[Node2D] = [station, moon_station]
	var closest: Node2D = null
	var closest_dist := DOCK_DISTANCE
	for s in stations:
		var d := World.wrapped_distance(ship.position, s.position)
		if d <= closest_dist:
			closest_dist = d
			closest = s
	return closest


func _update_station_indicator() -> void:
	var viewport_rect := get_viewport_rect()
	var screen_center := viewport_rect.size * 0.5
	var focus: Vector2 = ship.position if is_piloting_ship else astronaut.position
	var station_world := focus + World.wrapped_delta(focus, station.global_position)
	var station_screen := screen_center + (station_world - camera.position) / camera.zoom
	var screen_margin := 48.0
	var inner_rect := Rect2(Vector2.ONE * screen_margin, viewport_rect.size - Vector2.ONE * screen_margin * 2.0)

	if inner_rect.has_point(station_screen):
		station_indicator.visible = false
		return

	var direction := station_screen - screen_center
	if direction.length_squared() <= 0.001:
		station_indicator.visible = false
		return

	var scale_x := INF if absf(direction.x) <= 0.001 else (inner_rect.size.x * 0.5) / absf(direction.x)
	var scale_y := INF if absf(direction.y) <= 0.001 else (inner_rect.size.y * 0.5) / absf(direction.y)
	var indicator_center := screen_center + direction * minf(scale_x, scale_y)

	station_indicator.visible = true
	station_indicator.position = indicator_center - station_indicator.size * 0.5
	station_indicator.set("arrow_angle", direction.angle())
	station_indicator.queue_redraw()


func _update_tether_overlay() -> void:
	var points := ship.get_tether_points()
	tether_overlay.set("solid_points", points)

	var target := ship.get_collectible_target(trash_layer)
	if target == null:
		tether_overlay.set("show_dotted", false)
	else:
		tether_overlay.set("show_dotted", true)
		tether_overlay.set("dotted_from", ship.position)
		tether_overlay.set("dotted_to", ship.position + World.wrapped_delta(ship.position, target.position))
	tether_overlay.queue_redraw()


func _update_minimap() -> void:
	minimap.set("world_wrap_size", World.WORLD_WRAP_SIZE)
	minimap.set("earth_center", Vector2.ZERO)
	minimap.set("earth_radius", World.EARTH_RADIUS)
	minimap.set("moon_position", moon.position)
	minimap.set("moon_radius", MOON_RADIUS)
	minimap.set("station_position", station.position)
	minimap.set("moon_station_position", moon_station.position)
	minimap.set("ship_position", ship.position)
	minimap.set("astronaut_position", astronaut.position)
	minimap.set("is_piloting_ship", is_piloting_ship)
	minimap.queue_redraw()


func _update_ui() -> void:
	status_label.text = "Stored Scrap: %d | Cargo: %d/%d | Max Speed: %d | %s | Ship Pos: (%.1f, %.1f) | Space: collect | Q: drop" % [
		stored_scrap,
		ship.cargo_scrap.size(),
		PlayerShip.MAX_CARGO,
		int(ship.current_move_speed()),
		"Piloting ship" if is_piloting_ship else "On station",
		ship.position.x,
		ship.position.y,
	]


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT:
			is_panning = event.pressed
			return
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_camera(1.0 - CAMERA_ZOOM_STEP)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_camera(1.0 + CAMERA_ZOOM_STEP)
	elif event is InputEventMouseMotion and is_panning:
		camera.position -= event.relative * camera.zoom


func _zoom_camera(factor: float) -> void:
	var before_zoom_mouse := get_global_mouse_position()
	camera.zoom = Vector2.ONE * clampf(camera.zoom.x * factor, CAMERA_MIN_ZOOM, CAMERA_MAX_ZOOM)
	camera.position += before_zoom_mouse - get_global_mouse_position()
