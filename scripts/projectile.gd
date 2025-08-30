extends Node2D

@onready var visual_label: Label = $Visual

var speed: float = 300.0
var target: Node2D = null
var actual_damage: int = 0

# On utilise un "setter" pour la variable spell_info.
# Cette fonction sera appelée AUTOMATIQUEMENT quand quelqu'un écrira dans "spell_info".
# C'est le bon endroit pour configurer le projectile.
var spell_info: Dictionary = {}:
	set(value):
		spell_info = value
		# On vérifie que le projectile est prêt et que les données ne sont pas vides
		if is_node_ready() and not spell_info.is_empty():
			_configure_projectile()

func _ready():
	# On appelle la configuration ici aussi, au cas où les données
	# auraient été assignées avant que le nœud soit prêt.
	_configure_projectile()

func _configure_projectile():
	# Si les données sont vides, on ne fait rien
	if spell_info.is_empty():
		return
		
	# On récupère les données statiques du sort
	var spell_static_data = GameState.SPELL_DATA[spell_info.id]
	
	# 1. On met à jour l'apparence
	visual_label.text = spell_static_data.symbol
	
	# 2. On calcule les dégâts
	var power_bonus = 1 + (GameState.stats["power"] - 1) * 0.1
	actual_damage = round(spell_static_data.base_damage * power_bonus)

func _process(delta: float):
	if not is_instance_valid(target):
		queue_free()
		return

	var direction = (target.global_position - global_position).normalized()
	global_position += direction * speed * delta
	
	if global_position.distance_to(target.global_position) < 10:
		if target.has_method("take_damage"):
			# On passe les dégâts ET les infos du sort
			target.take_damage(actual_damage, spell_info)
		queue_free()
