@tool
class_name EarthView
extends Node2D

const BACKGROUND_HALF_SIZE := 2200.0
const PLANET_VIEWPORT_SIZE := 100.0

const STARFIELD_BASE := preload("res://assets/backgrounds/pixelart_starfield.png")
const STARFIELD_CORONA := preload("res://assets/backgrounds/pixelart_starfield_corona.png")
const STARFIELD_SPIKES := preload("res://assets/backgrounds/pixelart_starfield_diagonal_diffraction_spikes.png")

@export var earth_radius := 150.0:
	set(value):
		earth_radius = value
		_apply_planet_scale()

@export var orbit_radius := 240.0
@export var wrap_size := Vector2(19840.0, 19840.0)
@export var view_center := Vector2.ZERO

var _time := 1000.0

@onready var viewport: SubViewport = $PlanetViewport
@onready var planet_sprite: Sprite2D = $PlanetSprite
@onready var water_rect: ColorRect = $PlanetViewport/PlanetRoot/Water
@onready var land_rect: ColorRect = $PlanetViewport/PlanetRoot/Land
@onready var cloud_rect: ColorRect = $PlanetViewport/PlanetRoot/Cloud


func _ready() -> void:
	planet_sprite.visible = false
	_randomize_planet()
	_apply_planet_scale()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	_set_shader_time(water_rect, _time * _get_multiplier(water_rect.material) * 0.02)
	_set_shader_time(land_rect, _time * _get_multiplier(land_rect.material) * 0.02)
	_set_shader_time(cloud_rect, _time * _get_multiplier(cloud_rect.material) * 0.01)
	queue_redraw()


func _draw() -> void:
	draw_rect(
		Rect2(
			view_center - Vector2.ONE * BACKGROUND_HALF_SIZE,
			Vector2.ONE * BACKGROUND_HALF_SIZE * 2.0
		),
		Color("07111f")
	)

	_draw_tiled_starfield(STARFIELD_BASE, Vector2(_time * -1.5, _time * -0.2), Color(1, 1, 1, 0.72))
	_draw_tiled_starfield(STARFIELD_CORONA, Vector2(_time * 0.5, _time * -0.35), Color(0.52, 0.78, 1.0, 0.35))
	_draw_tiled_starfield(STARFIELD_SPIKES, Vector2(_time * -0.25, _time * 0.4), Color(1, 1, 1, 0.32))

	var nearest_origin := _get_nearest_wrap_origin(view_center)
	for y in range(-1, 2):
		for x in range(-1, 2):
			var offset := nearest_origin + Vector2(float(x) * wrap_size.x, float(y) * wrap_size.y)
			_draw_planet_tile(offset)


func _randomize_planet() -> void:
	_set_shader_seed(water_rect, 10.0)
	_set_shader_seed(land_rect, 7.947)
	_set_shader_seed(cloud_rect, 5.939)

	water_rect.material.set_shader_parameter(
		"colors",
		PackedColorArray([
			Color("92e8c0"),
			Color("4fa4b8"),
			Color("25344d"),
		])
	)
	land_rect.material.set_shader_parameter(
		"colors",
		PackedColorArray([
			Color("c8d45d"),
			Color("62ab3f"),
			Color("2f574f"),
			Color("283540"),
		])
	)
	cloud_rect.material.set_shader_parameter(
		"colors",
		PackedColorArray([
			Color("e5ecf3"),
			Color("b5bed3"),
			Color("7683a9"),
			Color("435179"),
		])
	)
	cloud_rect.material.set_shader_parameter("cloud_cover", 0.44)


func _apply_planet_scale() -> void:
	if not is_node_ready():
		return
	var scale_factor := (earth_radius * 2.0) / PLANET_VIEWPORT_SIZE
	planet_sprite.scale = Vector2.ONE * scale_factor


func _get_multiplier(mat: Material) -> float:
	return (round(mat.get_shader_parameter("size")) * 2.0) / mat.get_shader_parameter("time_speed")


func _set_shader_time(rect: ColorRect, value: float) -> void:
	rect.material.set_shader_parameter("time", value)


func _set_shader_seed(rect: ColorRect, value: float) -> void:
	rect.material.set_shader_parameter("seed", value)


func _draw_tiled_starfield(texture: Texture2D, scroll: Vector2, tint: Color) -> void:
	var texture_size := texture.get_size()
	var start_x := view_center.x - BACKGROUND_HALF_SIZE - texture_size.x
	var end_x := view_center.x + BACKGROUND_HALF_SIZE + texture_size.x
	var start_y := view_center.y - BACKGROUND_HALF_SIZE - texture_size.y
	var end_y := view_center.y + BACKGROUND_HALF_SIZE + texture_size.y
	var offset := Vector2(
		wrapf(scroll.x, 0.0, texture_size.x),
		wrapf(scroll.y, 0.0, texture_size.y)
	)

	var y := start_y
	while y <= end_y:
		var x := start_x
		while x <= end_x:
			draw_texture(texture, Vector2(x, y) - offset, tint)
			x += texture_size.x
		y += texture_size.y


func _draw_planet_tile(offset: Vector2) -> void:
	draw_arc(offset, orbit_radius, 0.0, TAU, 120, Color(1, 1, 1, 0.18), 2.0)

	var scale_factor := (earth_radius * 2.0) / PLANET_VIEWPORT_SIZE
	var planet_size := Vector2.ONE * PLANET_VIEWPORT_SIZE * scale_factor
	var texture := viewport.get_texture()
	if texture != null:
		draw_texture_rect(
			texture,
			Rect2(offset - planet_size * 0.5, planet_size),
			false,
			Color.WHITE
		)


func _get_nearest_wrap_origin(pos: Vector2) -> Vector2:
	return Vector2(
		round(pos.x / wrap_size.x) * wrap_size.x,
		round(pos.y / wrap_size.y) * wrap_size.y
	)
