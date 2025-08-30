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
@onready var character_panel = $UI/CharacterPanel
@onready var grimoire_panel = $UI/GrimoirePanel

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
	# On configure les menus pour qu'ils fonctionnent même en pause
	pause_menu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	character_panel.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	grimoire_panel.process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	# Met à jour l'interface avec les données initiales de GameState
	update_ui()
	
	# Positionne le joueur
	var screen_size = get_viewport_rect().size
	player.position = Vector2(screen_size.x / 2, screen_size.y - 100)
	
	# Connecte le signal 'essence_updated' de GameState à une fonction locale
	# pour mettre à jour l'UI automatiquement quand l'essence change.
	GameState.essence_updated.connect(on_essence_updated)
	
	# Connecte le clic du bouton d'amélioration de puissance
	upgrade_power_button.pressed.connect(Callable(self, "_on_generic_upgrade_pressed").bind("power"))
	
	# Connecte le bouton "Reprendre" du menu pause
	pause_menu.get_node("MenuButtons/ResumeButton").pressed.connect(toggle_pause)
	# Connecte le bouton "Personnage"
	pause_menu.get_node("MenuButtons/CharacterButton").pressed.connect(_on_character_button_pressed)
	# Connecte le bouton "Grimoire"
	pause_menu.get_node("MenuButtons/GrimoireButton").pressed.connect(_on_grimoire_button_pressed)
	# Connecte le bouton "Retour" du panneau personnage
	character_panel.get_node("MarginContainer/VBoxContainer/BackButton").pressed.connect(_on_back_to_pause_menu_pressed)
	# Connecte le bouton "Retour" du panneau grimoire
	grimoire_panel.get_node("MarginContainer/VBoxContainer/BackButton").pressed.connect(_on_back_to_pause_menu_pressed)


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

func _on_character_button_pressed():
	# On cache le menu pause et on affiche le panneau personnage
	pause_menu.hide()
	character_panel.show()
	# On met à jour les informations du panneau
	update_character_panel()

func _on_back_to_pause_menu_pressed():
	# On cache les deux panneaux (seul le visible sera affecté)
	character_panel.hide()
	grimoire_panel.hide()
	# On affiche le menu pause principal
	pause_menu.show()

func update_character_panel():
	# On récupère le conteneur des stats
	var stats_container = character_panel.get_node("MarginContainer/VBoxContainer/StatsContainer")
	# On supprime les anciennes entrées
	for child in stats_container.get_children():
		child.queue_free()
	
	# On crée une nouvelle entrée pour chaque stat
	for stat_name in GameState.stats:
		var level = GameState.stats[stat_name]
		var cost = floor(10 * pow(1.5, level - 1))
		
		# On crée un conteneur horizontal pour le label et le bouton
		var hbox = HBoxContainer.new()
		
		var label = Label.new()
		label.text = stat_name.capitalize() + ": " + str(level)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var button = Button.new()
		button.text = "Améliorer (" + str(cost) + " E)"
		# On connecte le bouton en passant le nom de la stat en argument
		button.pressed.connect(Callable(self, "_on_generic_upgrade_pressed").bind(stat_name))
		
		hbox.add_child(label)
		hbox.add_child(button)
		stats_container.add_child(hbox)

func _on_generic_upgrade_pressed(stat_name: String):
	if GameState.upgrade_stat(stat_name):
		# Si l'amélioration réussit, on met à jour l'UI principale et le panneau
		update_ui()
		update_character_panel()

func _on_grimoire_button_pressed():
	pause_menu.hide()
	grimoire_panel.show()
	update_grimoire_panel()

func update_grimoire_panel():
	var slots_container = grimoire_panel.get_node("MarginContainer/VBoxContainer/ActiveSlotsContainer")
	var book_container = grimoire_panel.get_node("MarginContainer/VBoxContainer/SpellbookContainer")
	
	# Nettoyage
	for child in slots_container.get_children(): child.queue_free()
	for child in book_container.get_children(): child.queue_free()

	# Affichage des emplacements actifs
	for spell in GameState.spell_slots:
		var label = Label.new()
		label.custom_minimum_size = Vector2(50, 50)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		if spell != null:
			var spell_data = GameState.SPELL_DATA[spell.id]
			label.text = spell_data.symbol
		else:
			label.text = "[Vide]"
		slots_container.add_child(label)

	# Affichage des sorts appris
	for spell in GameState.spellbook:
		var spell_data = GameState.SPELL_DATA[spell.id]
		var button = Button.new()
		button.text = spell_data.symbol + " " + str(spell.level)
		button.pressed.connect(Callable(self, "_on_equip_spell_pressed").bind(spell))
		book_container.add_child(button)

func _on_equip_spell_pressed(spell_to_equip):
	# On cherche un emplacement vide
	var empty_slot_index = GameState.spell_slots.find(null)
	
	if empty_slot_index != -1:
		# On vérifie que le sort n'est pas déjà équipé
		var is_already_equipped = false
		for equipped_spell in GameState.spell_slots:
			if equipped_spell != null and equipped_spell.id == spell_to_equip.id:
				is_already_equipped = true
				break
		
		if not is_already_equipped:
			GameState.spell_slots[empty_slot_index] = spell_to_equip
			print("Sort équipé : ", GameState.SPELL_DATA[spell_to_equip.id].name)
			update_grimoire_panel()
		else:
			print("Ce sort est déjà équipé.")
	else:
		print("Aucun emplacement de sort libre.")
