extends Node2D

# Référence au nœud Sprite2D pour pouvoir le manipuler
@onready var sprite: Sprite2D = $Sprite

# --- Variables pour l'animation ---
var animation_frame_count: int = 6  # Nombre d'images dans la spritesheet
var current_frame: int = 0
var animation_timer: float = 0.0
var animation_speed: float = 0.15  # Temps en secondes entre chaque frame (150ms)

# --- Variables pour le combat ---
var cast_timer: float = 0.0
var cast_interval: float = 1.5 # Temps en secondes entre chaque sort (1500ms)
var monster_target: Node2D = null

# On pré-charge la scène du projectile pour pouvoir la créer rapidement
var projectile_scene = preload("res://scenes/Projectile.tscn")

# La fonction _process est appelée à chaque image par Godot
func _process(delta: float):
	# Met à jour le timer d'animation
	animation_timer += delta
	
	# Si le temps écoulé est supérieur à notre vitesse d'animation
	if animation_timer > animation_speed:
		# On passe à l'image suivante
		current_frame = (current_frame + 1) % animation_frame_count
		
		# On met à jour le sprite pour afficher la nouvelle image
		sprite.frame = current_frame
		
		# On réinitialise le timer
		animation_timer = 0.0
	
	# --- Logique de combat ---
	# S'il y a une cible valide (un monstre)
	if is_instance_valid(monster_target):
		cast_timer += delta
		# Si le temps d'incantation est écoulé
		if cast_timer >= cast_interval:
			fire_skill()
			# On réinitialise le timer
			cast_timer = 0.0

# Permet au script Game.gd de dire au joueur qui est sa cible
func set_target(target: Node2D):
	monster_target = target
	cast_timer = 0.0 # On réinitialise le timer à chaque changement de cible

# Fonction pour créer et lancer un projectile
func fire_skill():
	# Sécurité : on vérifie que la cible existe toujours
	if not is_instance_valid(monster_target):
		return

	var projectile = projectile_scene.instantiate()
	
	# On ajoute le projectile à la scène principale (pas au joueur)
	# pour qu'il ne bouge pas avec le joueur
	get_parent().add_child(projectile)
	
	# On le positionne sur le joueur
	projectile.global_position = self.global_position
	
	# On lui donne sa cible
	projectile.target = monster_target
