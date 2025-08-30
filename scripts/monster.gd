extends Node2D

# Signal qui sera émis lorsque le monstre est vaincu
signal died

@onready var sprite: Sprite2D = $Sprite
@onready var hp_bar: ProgressBar = $HPBar

# --- Stats du monstre ---
var max_hp: int = 100
var current_hp: int = 100
var essence_reward: int = 10
var is_dead: bool = false

# --- Variables pour l'animation ---
var animation_frame_count: int = 5
var current_frame: int = 0
var animation_timer: float = 0.0
var animation_speed: float = 0.1 # Temps en secondes entre chaque frame (100ms)
var is_animating: bool = false # Pour contrôler si l'animation doit jouer

func _ready():
	# Initialise la barre de vie
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp

# La fonction _process est appelée à chaque image
func _process(delta: float):
	# Si l'animation ne doit pas jouer, on ne fait rien
	if not is_animating:
		return

	animation_timer += delta
	
	if animation_timer > animation_speed:
		current_frame += 1
		
		# Si on a atteint la fin de l'animation
		if current_frame >= animation_frame_count:
			# On arrête l'animation et on revient à la première image
			is_animating = false
			current_frame = 0
		
		sprite.frame = current_frame
		animation_timer = 0.0

# Une fonction pour démarrer l'animation
func play_attack_animation():
	is_animating = true
	current_frame = 0
	animation_timer = 0.0

# Fonction appelée par le projectile lorsqu'il touche le monstre
func take_damage(amount: int):
	# Si le monstre est déjà mort, on ignore les dégâts supplémentaires
	if is_dead:
		return

	current_hp -= amount
	hp_bar.value = current_hp
	print("Monstre touché ! HP restants : ", current_hp)
	
	play_attack_animation()
	
	if current_hp <= 0:
		is_dead = true
		# On émet le signal de mort et on se cache en attendant d'être supprimé/réinitialisé
		emit_signal("died")
		hide() # On cache le monstre
