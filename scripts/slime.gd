extends "res://scripts/monster.gd"

# Cette fonction est appelée quand le Slime est créé.
# Elle nous permet de changer les stats de base définies dans monster.gd.
func _ready():
	# On définit l'ID unique pour le Slime
	monster_id = "slime"
	
	# Statistiques de base spécifiques au Slime
	base_hp = 80
	base_essence_reward = 15
	
	# On appelle la fonction _ready() du script parent (monster.gd)
	# pour qu'elle initialise tout avec nos nouvelles valeurs.
	super._ready()
