extends Node2D

@onready var sprite: Sprite2D = $Sprite

# --- Variables pour l'animation ---
var animation_frame_count: int = 6
var current_frame: int = 0
var animation_timer: float = 0.0
var animation_speed: float = 0.15

# --- Variables pour le combat ---
var monster_target: Node2D = null
var projectile_scene = preload("res://scenes/Projectile.tscn")

# Un tableau pour suivre la progression de chaque sort.
# Il aura la même taille que le tableau `spell_slots`.
var cast_progress: Array = []

func _ready():
	# Initialise le tableau de progression pour qu'il corresponde au nombre d'emplacements
	cast_progress.resize(GameState.spell_slots.size())
	cast_progress.fill(0.0)

func _process(delta: float):
	update_animation(delta)
	update_casting(delta)

func update_animation(delta: float):
	animation_timer += delta
	if animation_timer > animation_speed:
		current_frame = (current_frame + 1) % animation_frame_count
		sprite.frame = current_frame
		animation_timer = 0.0

func update_casting(delta: float):
	if not is_instance_valid(monster_target):
		return

	# On parcourt tous les emplacements de sorts
	for i in range(GameState.spell_slots.size()):
		var spell = GameState.spell_slots[i]
		
		# Si un sort est équipé dans cet emplacement
		if spell != null:
			# On augmente la progression de son incantation
			cast_progress[i] += delta
			
			# On calcule le temps d'incantation (pour l'instant, 1.5s pour tous)
			var celerity_bonus = 1 + (GameState.stats["celerity"] - 1) * 0.05
			var cast_time = 1.5 / celerity_bonus
			
			# Si l'incantation est terminée
			if cast_progress[i] >= cast_time:
				fire_skill(spell)
				# On réinitialise la progression pour cet emplacement
				cast_progress[i] = 0.0

func set_target(target: Node2D):
	monster_target = target
	# On réinitialise la progression de toutes les incantations
	cast_progress.fill(0.0)

func fire_skill(spell_data):
	if not is_instance_valid(monster_target):
		return

	var projectile = projectile_scene.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = self.global_position
	projectile.target = monster_target
	projectile.spell_info = spell_data
