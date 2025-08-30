extends Node2D

signal died
signal hit_by_spell(spell_info)

@onready var sprite: Sprite2D = $Sprite
@onready var hp_bar: ProgressBar = $HPBar
@onready var xp_bar: ProgressBar = $XPBar

var monster_id: String = "training_dummy"
var base_hp: int = 100
var base_essence_reward: int = 10
var level: int = 1
var xp: int = 0
var xp_to_next_level: int = 100
var max_hp: int = 100
var current_hp: int = 100
var essence_reward: int = 10
var is_dead: bool = false

var animation_frame_count: int = 5
var current_frame: int = 0
var animation_timer: float = 0.0
var animation_speed: float = 0.1
var is_animating: bool = false

func _ready():
	var monster_data = GameState.get_monster_data(monster_id)
	level = monster_data.level
	xp = monster_data.xp
	update_stats_to_level()
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	xp_bar.max_value = xp_to_next_level
	xp_bar.value = xp

func update_stats_to_level():
	max_hp = floor(base_hp * pow(1.2, level - 1))
	essence_reward = floor(base_essence_reward * pow(1.1, level - 1))
	xp_to_next_level = floor(100 * pow(1.5, level - 1))
	current_hp = max_hp

func gain_xp():
	xp += floor(xp_to_next_level / 10.0)
	xp_bar.value = xp
	if xp >= xp_to_next_level:
		level += 1
		xp = 0
		update_stats_to_level() # Met à jour les barres après la montée de niveau
	GameState.update_monster_data(monster_id, {"level": level, "xp": xp})

func _process(delta: float):
	if not is_animating:
		return
		
	animation_timer += delta
	if animation_timer > animation_speed:
		animation_timer = 0.0
		current_frame += 1
		
		# Si on a joué toutes les images
		if current_frame >= animation_frame_count:
			# On arrête l'animation et on revient à l'image de repos (la première)
			current_frame = 0
			is_animating = false
		
		sprite.frame = current_frame

func play_attack_animation():
	# Si l'animation est déjà en train de se jouer, on ne la relance pas
	if is_animating:
		return
	is_animating = true
	current_frame = 0
	animation_timer = 0.0

func take_damage(amount: int, spell_info: Dictionary):
	if is_dead:
		return
	current_hp -= amount
	hp_bar.value = current_hp
	emit_signal("hit_by_spell", spell_info)
	play_attack_animation()
	if current_hp <= 0:
		is_dead = true
		gain_xp()
		emit_signal("died")
		hide()
