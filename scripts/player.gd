extends Node2D

@onready var sprite: Sprite2D = $Sprite

var animation_frame_count: int = 6
var current_frame: int = 0
var animation_timer: float = 0.0
var animation_speed: float = 0.15

var monster_target: Node2D = null
var projectile_scene = preload("res://scenes/Projectile.tscn")

var cast_progress: Array = []
var cast_bars: Dictionary = {}
var cast_bar_stylebox = StyleBoxFlat.new()

var direction: String = "right"

func _ready():
	cast_progress.resize(GameState.spell_slots.size())
	cast_progress.fill(0.0)
	cast_bar_stylebox.bg_color = Color.PURPLE

func _process(delta: float):
	update_animation(delta)
	update_casting(delta)
	update_cast_bar_positions()

func update_animation(delta: float):
	animation_timer += delta
	if animation_timer > animation_speed:
		current_frame = (current_frame + 1) % animation_frame_count
		sprite.frame = current_frame
		animation_timer = 0.0

func update_casting(delta: float):
	if not is_instance_valid(monster_target):
		if not cast_bars.is_empty():
			clear_all_cast_bars()
		return

	for i in range(GameState.spell_slots.size()):
		var spell = GameState.spell_slots[i]
		
		if spell != null:
			cast_progress[i] += delta
			var celerity_bonus = 1 + (GameState.stats["celerity"] - 1) * 0.05
			var cast_time = 1.5 / celerity_bonus
			
			if not cast_bars.has(i):
				var new_bar = ProgressBar.new()
				new_bar.custom_minimum_size = Vector2(50, 8)
				new_bar.add_theme_stylebox_override("fill", cast_bar_stylebox)
				new_bar.max_value = cast_time
				new_bar.show_percentage = false
				add_child(new_bar)
				cast_bars[i] = new_bar
			
			cast_bars[i].value = cast_progress[i]
			
			if cast_progress[i] >= cast_time:
				fire_skill(spell)
				cast_progress[i] = 0.0
		else:
			if cast_bars.has(i):
				cast_bars[i].queue_free()
				cast_bars.erase(i)

func update_cast_bar_positions():
	var y_offset = 40.0
	var visible_bars = cast_bars.values()
	for i in range(visible_bars.size()):
		var bar = visible_bars[i]
		bar.position = Vector2(-bar.size.x / 2, -y_offset - (i * (bar.size.y + 2)))

func set_direction(new_direction: String):
	if direction != new_direction:
		direction = new_direction
		sprite.flip_h = (direction == "left")

func move_to(target_position: Vector2, duration: float):
	var tween = create_tween()
	tween.tween_property(self, "position", target_position, duration).set_trans(Tween.TRANS_SINE)

func set_target(target: Node2D):
	monster_target = target
	cast_progress.fill(0.0)
	clear_all_cast_bars()

func clear_all_cast_bars():
	for bar in cast_bars.values():
		bar.queue_free()
	cast_bars.clear()

func resize_cast_progress():
	cast_progress.resize(GameState.spell_slots.size())
	for i in range(cast_progress.size()):
		if cast_progress[i] == null:
			cast_progress[i] = 0.0

func fire_skill(spell_data):
	if not is_instance_valid(monster_target):
		return

	var projectile = projectile_scene.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = self.global_position
	projectile.target = monster_target
	projectile.spell_info = spell_data
