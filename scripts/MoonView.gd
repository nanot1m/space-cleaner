@tool
class_name MoonView
extends Node2D

const PLANET_VIEWPORT_SIZE := 100.0

@export var moon_radius := 40.9:
	set(value):
		moon_radius = value
		_apply_moon_scale()

var _time := 700.0

@onready var viewport: SubViewport = $PlanetViewport
@onready var planet_sprite: Sprite2D = $PlanetSprite
@onready var under_rect: ColorRect = $PlanetViewport/PlanetRoot/Under
@onready var land_rect: ColorRect = $PlanetViewport/PlanetRoot/Land
@onready var cloud_rect: ColorRect = $PlanetViewport/PlanetRoot/Cloud


func _ready() -> void:
	planet_sprite.visible = false
	_randomize_moon()
	_apply_moon_scale()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	_set_shader_time(under_rect, _time * _get_multiplier(under_rect.material) * 0.012)
	_set_shader_time(land_rect, _time * _get_multiplier(land_rect.material) * 0.012)
	_set_shader_time(cloud_rect, _time * _get_multiplier(cloud_rect.material) * 0.006)
	queue_redraw()


func _draw() -> void:
	var scale_factor := (moon_radius * 2.0) / PLANET_VIEWPORT_SIZE
	var moon_size := Vector2.ONE * PLANET_VIEWPORT_SIZE * scale_factor
	var texture := viewport.get_texture()
	if texture != null:
		draw_texture_rect(
			texture,
			Rect2(-moon_size * 0.5, moon_size),
			false,
			Color.WHITE
		)


func _randomize_moon() -> void:
	_set_shader_seed(under_rect, 3.2)
	_set_shader_seed(land_rect, 4.7)
	_set_shader_seed(cloud_rect, 6.4)

	under_rect.material.set_shader_parameter("colors", PackedColorArray([
		Color("d8dde2"),
		Color("9ca6b0"),
		Color("5f6871"),
	]))
	land_rect.material.set_shader_parameter("colors", PackedColorArray([
		Color("eef1f4"),
		Color("bcc4cb"),
		Color("8d96a0"),
		Color("545d67"),
	]))
	cloud_rect.material.set_shader_parameter("colors", PackedColorArray([
		Color(1, 1, 1, 0.10),
		Color(0.88, 0.9, 0.93, 0.08),
		Color(0.72, 0.75, 0.8, 0.05),
		Color(0.52, 0.56, 0.62, 0.03),
	]))
	cloud_rect.material.set_shader_parameter("cloud_cover", 0.82)


func _apply_moon_scale() -> void:
	if not is_node_ready():
		return
	planet_sprite.scale = Vector2.ONE * ((moon_radius * 2.0) / PLANET_VIEWPORT_SIZE)


func _get_multiplier(mat: Material) -> float:
	return (round(mat.get_shader_parameter("size")) * 2.0) / mat.get_shader_parameter("time_speed")


func _set_shader_time(rect: ColorRect, value: float) -> void:
	rect.material.set_shader_parameter("time", value)


func _set_shader_seed(rect: ColorRect, value: float) -> void:
	rect.material.set_shader_parameter("seed", value)
