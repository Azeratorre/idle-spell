extends Node2D

# Références aux nœuds de l'interface utilisateur pour un accès facile
@onready var player_name_label = $UI/MarginContainer/VBoxContainer/TopBar/PlayerStats/PlayerNameLabel
@onready var zone_name_label = $UI/MarginContainer/VBoxContainer/TopBar/PlayerStats/ZoneNameLabel
@onready var essence_label = $UI/MarginContainer/VBoxContainer/TopBar/PlayerStats/EssenceLabel
@onready var upgrade_power_button = $UI/MarginContainer/VBoxContainer/TopBar/PlayerStats/UpgradePowerButton
@onready var monster_stats_label = $UI/MarginContainer/VBoxContainer/TopBar/MonsterStats
@onready var fast_travel_bar = $UI/MarginContainer/VBoxContainer/FastTravelBar
@onready var player = $Player
@onready var pause_menu = $UI/PauseMenu

# Le monde du jeu, avec les informations sur les monstres
var world = [
	{"name": "Village", "monster": null},
	{"name": "École de Magie", "monster": null},
	{"name": "Zone d'entraînement", "monster": "res://scenes/Monster.tscn"},
	{"name": "Forêt", "monster": null} # On ajoutera le Slime plus tard
]

# Variable pour garder une référence au monstre actuel
var current_monster = null

# S'exécute lorsque la scène et tous ses nœuds sont prêts
func _ready():
	# Met à jour l'interface avec les données initiales de GameState
	update_ui()
	
	# Positionne le joueur
	var screen_size = get_viewport_rect().size
	player.position = Vector2(screen_size.x / 2, screen_size.y - 100)
	
	# Connecte le signal 'essence_updated' de GameState à une fonction locale
	# pour mettre à jour l'UI automatiquement quand l'essence change.
	GameState.essence_updated.connect(on_essence_updated)
	
	# Connecte le clic du bouton d'amélioration
	upgrade_power_button.pressed.connect(_on_upgrade_power_pressed)
	
	# Connecte le bouton "Reprendre" du menu pause
	pause_menu.get_node("MenuButtons/ResumeButton").pressed.connect(toggle_pause)


# Gère les entrées clavier non gérées par l'UI
func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"): # ui_cancel est la touche Echap par défaut
		toggle_pause()

func toggle_pause():
	# On inverse l'état de la pause de l'arbre de scènes
	get_tree().paused = not get_tree().paused
	# On affiche/cache le menu
	pause_menu.visible = get_tree().paused


# Met à jour toutes les informations de l'interface
func update_ui():
	# Affiche le nom du joueur
	player_name_label.text = "Mage: " + GameState.player_name
	
	# Affiche le nom de la zone actuelle
	var current_zone = world[GameState.current_zone_index]
	zone_name_label.text = "Lieu: " + current_zone.name
	
	# Affiche l'essence magique
	essence_label.text = "Essence: " + str(GameState.magic_essence)
	
	# Met à jour le texte du bouton d'amélioration
	var power_cost = floor(10 * pow(1.5, GameState.stats["power"] - 1))
	upgrade_power_button.text = "Améliorer Puissance (" + str(power_cost) + " E)"
	
	# Met à jour les stats du monstre
	if is_instance_valid(current_monster):
		# TODO: Remplacer par les vraies données du monstre (HP, etc.)
		monster_stats_label.text = "Monstre: Mannequin | HP: 100/100"
	else:
		monster_stats_label.text = "Aucun monstre"
	
	# Crée les boutons de voyage rapide
	# D'abord, on nettoie les anciens boutons
	for button in fast_travel_bar.get_children():
		button.queue_free()
	
	# Ensuite, on crée les nouveaux
	for i in range(world.size()):
		var zone = world[i]
		var button = Button.new()
		button.text = zone.name
		fast_travel_bar.add_child(button)
		
		# Si c'est la zone actuelle, on désactive le bouton
		if i == GameState.current_zone_index:
			button.disabled = true
		
		# On connecte le clic du bouton à la fonction de changement de zone
		# On passe l'index 'i' en argument
		button.pressed.connect(Callable(self, "change_zone").bind(i))


# Fonction pour changer de zone
func change_zone(new_index: int):
	print("Voyage vers la zone : ", world[new_index].name)
	GameState.current_zone_index = new_index
	
	# TODO: Ajouter la logique de transition visuelle
	
	# --- Logique d'apparition/disparition du monstre ---
	# 1. On supprime le monstre précédent s'il existe
	if is_instance_valid(current_monster):
		current_monster.queue_free()
		current_monster = null
	
	# 2. On regarde si la nouvelle zone a un monstre
	var zone_data = world[new_index]
	if zone_data.monster != null:
		# 3. On charge et on crée la scène du monstre
		var monster_scene = load(zone_data.monster)
		current_monster = monster_scene.instantiate()
		
		# 4. On le positionne et on l'ajoute à la scène principale
		var screen_size = get_viewport_rect().size
		current_monster.position = Vector2(screen_size.x - 250, screen_size.y - 110)
		add_child(current_monster)
		
		# 5. On connecte son signal de mort à notre fonction de gestion
		current_monster.died.connect(self._on_monster_died)
		
		# On dit au joueur qui est sa nouvelle cible
		player.set_target(current_monster)
	else:
		# S'il n'y a pas de monstre, on le dit au joueur pour qu'il arrête de tirer
		player.set_target(null)

	# Met à jour l'interface pour refléter le changement
	update_ui()

# Fonction appelée automatiquement lorsque le signal 'essence_updated' est émis
func on_essence_updated(new_value: int):
	# Met à jour le label d'essence directement
	essence_label.text = "Essence: " + str(new_value)
	print("Essence mise à jour : ", new_value)

# Fonction appelée automatiquement lorsque le signal 'died' du monstre est émis
func _on_monster_died():
	print("Le monstre est vaincu !")
	
	# On donne la récompense au joueur
	if is_instance_valid(current_monster):
		GameState.add_essence(current_monster.essence_reward)
	
	# On dit au joueur qu'il n'a plus de cible
	player.set_target(null)
	
	# On supprime l'ancien monstre
	if is_instance_valid(current_monster):
		current_monster.queue_free()
		current_monster = null
	
	# On attend 2 secondes avant de faire réapparaître un nouveau monstre
	await get_tree().create_timer(2.0).timeout
	
	# On recrée un monstre (uniquement si on est toujours dans une zone de combat)
	var zone_data = world[GameState.current_zone_index]
	if zone_data.monster != null:
		var monster_scene = load(zone_data.monster)
		current_monster = monster_scene.instantiate()
		var screen_size = get_viewport_rect().size
		current_monster.position = Vector2(screen_size.x - 250, screen_size.y - 110)
		add_child(current_monster)
		current_monster.died.connect(self._on_monster_died)
		player.set_target(current_monster)

# --- Fonctions connectées aux signaux ---

func _on_upgrade_power_pressed():
	if GameState.upgrade_stat("power"):
		# Si l'amélioration a réussi, on met à jour l'UI
		update_ui()
