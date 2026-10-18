extends Node2D

const AFK_SLEEP_TIME: float = 60.0

var speed = 300
var direction = Vector2(1,0)
var screen_size = Vector2()
var window_size = Vector2(200, 200)
var idle_timer = 0.0
var drag_offset = Vector2()
var time_since_last_input = 0.0

var is_idling = false
var is_dragging = false
var is_sleeping = false
var is_spinning = false

@onready var animated_sprite = $AnimatedSprite2D
@onready var area = $Area2D

func _ready():
	screen_size = Vector2(DisplayServer.screen_get_size())
	animated_sprite.play("Walk")
	area.input_event.connect(_on_area_input)
	animated_sprite.animation_finished.connect(_on_animation_finished)
	

func _physics_process(delta: float) -> void:
	
	if is_dragging:
		var mouse_pos = Vector2(DisplayServer.mouse_get_position())
		var new_win_pos = mouse_pos - drag_offset
		DisplayServer.window_set_position(Vector2i(new_win_pos))
		return
		
	if is_spinning:
		return	
			
	if is_idling:
		idle_timer -= delta
		if idle_timer <= 0:
			is_idling = false
			speed = 300
			animated_sprite.play("Walk")
		return
		
	if not is_sleeping and not is_dragging and not is_idling:
		time_since_last_input += delta
		if time_since_last_input >= AFK_SLEEP_TIME:
			start_sleeping()
			
	if is_sleeping:
		return
			
	var window_position = Vector2(DisplayServer.window_get_position())
	window_position += direction * speed * delta
	print(window_position)
	window_position.x = clamp(window_position.x, 0, screen_size.x  - window_size.x)
	window_position.y = clamp(window_position.y, 0, screen_size.y - window_size.y)
	DisplayServer.window_set_position(Vector2i(window_position))
	
	if window_position.x <= 0 or window_position.x >= screen_size.x - window_size.x:
		direction.x *= -1
		animated_sprite.flip_h = !animated_sprite.flip_h
		maybe_idle()
	if window_position.y <= 0 or window_position.y >= screen_size.y - window_size.y:
		direction.y *= -1
		maybe_idle()
		
func _on_area_input(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			time_since_last_input = 0
			if is_sleeping:
				wake_up()
			is_dragging = true
			var mouse_pos = Vector2(DisplayServer.mouse_get_position())
			var win_pos = Vector2(DisplayServer.window_get_position())
			drag_offset = mouse_pos - win_pos
		else:
			is_dragging = false
			if not is_sleeping:
				spin()
		
func maybe_idle():
	if randf() < 0.5:
		is_idling = true
		idle_timer = randf_range(1.0, 3.0)
		speed = 0
		
		var r = randi() % 2
		
		if r == 0:
			animated_sprite.play("Idle")
		elif r == 1:
			animated_sprite.play("Idle_Alt")
			
func start_sleeping() -> void:
	if is_sleeping or is_dragging:
		return
	is_sleeping = true
	is_idling = false
	speed = 0
	animated_sprite.play("Sleep")
	
func wake_up() -> void:
	if not is_sleeping:
		return
	is_sleeping = false
	time_since_last_input = 0.0
	speed = 300
	animated_sprite.play("Walk")
	
func spin():
	is_spinning = true
	is_idling = false
	animated_sprite.play("Spin")
	
func _on_animation_finished():
	if is_spinning:
		is_spinning = false	
		speed = 300
		animated_sprite.play("Walk")
			
			
