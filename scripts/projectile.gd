extends Node2D

var speed: float = 300.0 # Vitesse en pixels par seconde
var target: Node2D = null
var base_damage: int = 5

func _process(delta: float):
	# Si la cible n'existe plus (ex: monstre mort), on s'auto-détruit
	if not is_instance_valid(target):
		queue_free()
		return

	# On calcule la direction vers la cible
	var direction = (target.global_position - global_position).normalized()
	# On se déplace dans cette direction
	global_position += direction * speed * delta
	
	# On vérifie si on est assez proche de la cible pour la considérer "touchée"
	if global_position.distance_to(target.global_position) < 10:
		# On calcule les dégâts réels en incluant le bonus de puissance
		var power_bonus = 1 + (GameState.stats["power"] - 1) * 0.1
		var actual_damage = round(base_damage * power_bonus)
		
		# On appelle la fonction 'take_damage' de la cible
		if target.has_method("take_damage"):
			target.take_damage(actual_damage)
		
		# On s'auto-détruit
		queue_free()
