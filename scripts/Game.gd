extends Node2D

# Références aux nœuds de l'interface utilisateur pour un accès facile
@onready var player_name_label = $UI/MarginContainer/VBoxContainer/TopBar/PlayerStats/PlayerNameLabel
@onready var zone_name_label = $UI/MarginContainer/VBoxContainer/TopBar/PlayerStats/ZoneNameLabel
@onready var essence_label = $UI/MarginContainer/VBoxContainer/TopBar/PlayerStats/EssenceLabel
@onready var monster_stats_label = $UI/MarginContainer/VBoxContainer/TopBar/MonsterStats
@onready var fast_travel_bar = $UI/MarginContainer/VBoxContainer/FastTravelBar
@onready var player = $Player
@onready var pause_menu = $UI/PauseMenu
@onready var character_panel = $UI/CharacterPanel
@onready var grimoire_panel = $UI/GrimoirePanel
@onready var magic_school_panel = $UI/MagicSchoolPanel
@onready var hud_spell_bar = $UI/MarginContainer/VBoxContainer/HudSpellBar
@onready var transition_overlay = $UI/TransitionOverlay

# Le monde du jeu, avec les informations sur les monstres
var world = [
	{"name": "Village", "monster": null},
	{"name": "École de Magie", "monster": null},
	{"name": "Zone d'entraînement", "monster": "res://scenes/Monster.tscn"},
	{"name": "Forêt", "monster": "res://scenes/Slime.tscn"}
]

var current_monster = null

# S'exécute lorsque la scène est prête
func _ready():
	# Configure les menus pour qu'ils fonctionnent même en pause
	pause_menu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	character_panel.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	grimoire_panel.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	magic_school_panel.process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	# Met à jour l'interface
	update_ui()
	update_hud_spell_bar()
	
	# Positionne le joueur
	var screen_size = get_viewport_rect().size
	player.position = Vector2(screen_size.x / 2, screen_size.y - 100)
	
	# Connecte les signaux et les boutons
	GameState.essence_updated.connect(on_essence_updated)
	pause_menu.get_node("MenuButtons/ResumeButton").pressed.connect(toggle_pause)
	pause_menu.get_node("MenuButtons/CharacterButton").pressed.connect(_on_character_button_pressed)
	pause_menu.get_node("MenuButtons/GrimoireButton").pressed.connect(_on_grimoire_button_pressed)
	# Ajout de la connexion pour le bouton Sauvegarder
	pause_menu.get_node("MenuButtons/SaveButton").pressed.connect(GameState.save_game)
	character_panel.get_node("MarginContainer/VBoxContainer/BackButton").pressed.connect(_on_back_to_pause_menu_pressed)
	grimoire_panel.get_node("MarginContainer/VBoxContainer/BackButton").pressed.connect(_on_back_to_pause_menu_pressed)

# Gère les entrées clavier
func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	get_tree().paused = not get_tree().paused
	pause_menu.visible = get_tree().paused

# Met à jour l'UI principale
func update_ui():
	player_name_label.text = "Mage: " + GameState.player_name
	var current_zone = world[GameState.current_zone_index]
	zone_name_label.text = "Lieu: " + current_zone.name
	essence_label.text = "Essence: " + str(GameState.magic_essence)
	
	if is_instance_valid(current_monster):
		update_monster_stats_label()
	else:
		monster_stats_label.text = "Aucun monstre"
	
	for button in fast_travel_bar.get_children():
		button.queue_free()
	
	for i in range(world.size()):
		var zone = world[i]
		var button = Button.new()
		button.text = zone.name
		fast_travel_bar.add_child(button)
		if i == GameState.current_zone_index:
			button.disabled = true
		button.pressed.connect(Callable(self, "change_zone").bind(i))

# Change de zone et gère l'apparition des monstres
func change_zone(new_index: int):
	if transition_overlay.visible:
		return

	GameState.current_zone_index = new_index
	
	# --- Animation de transition ---
	var tween = create_tween()
	tween.tween_property(transition_overlay, "modulate:a", 1.0, 0.3)
	transition_overlay.show()
	await tween.finished
	
	# On change le décor pendant que l'écran est noir
	update_world_display()
	
	# Le personnage entre toujours par la gauche
	player.set_direction("right")
	var screen_size = get_viewport_rect().size
	var start_pos = Vector2(-100, player.position.y)
	
	# La destination dépend de la présence d'un monstre
	var target_x = screen_size.x / 2
	if is_instance_valid(current_monster):
		target_x = screen_size.x * 0.25
		
	var target_pos = Vector2(target_x, player.position.y)

	# On place le joueur à sa position de départ et on lance le mouvement
	player.position = start_pos
	player.move_to(target_pos, 0.5)
	
	# Fondu au clair
	tween = create_tween()
	tween.tween_property(transition_overlay, "modulate:a", 0.0, 0.3)
	await tween.finished
	transition_overlay.hide()

func update_world_display():
	# Cette fonction met à jour ce qui est dans la zone (monstre, panneaux, etc.)
	var screen_size = get_viewport_rect().size
	
	if is_instance_valid(current_monster):
		current_monster.queue_free()
		current_monster = null
	
	var zone_data = world[GameState.current_zone_index]
	if zone_data.monster != null:
		var monster_scene = load(zone_data.monster)
		current_monster = monster_scene.instantiate()
		current_monster.position = Vector2(screen_size.x - 250, screen_size.y - 110)
		add_child(current_monster)
		
		current_monster.died.connect(self._on_monster_died)
		current_monster.hit_by_spell.connect(self._on_monster_hit)
		
		player.set_target(current_monster)
	else:
		player.set_target(null)

	if zone_data.name == "École de Magie":
		magic_school_panel.show()
		update_magic_school_panel()
	else:
		magic_school_panel.hide()

	update_ui()

func update_monster_stats_label():
	if not is_instance_valid(current_monster):
		return
	
	var monster_name = "Mannequin" # Par défaut
	if "Slime" in current_monster.get_script().resource_path:
		monster_name = "Slime"
		
	monster_stats_label.text = "Monstre: %s (Niv. %d) | HP: %d/%d" % [monster_name, current_monster.level, int(current_monster.current_hp), current_monster.max_hp]

# --- Fonctions de mise à jour des panneaux ---

func update_hud_spell_bar():
	for child in hud_spell_bar.get_children():
		child.queue_free()
	
	for spell in GameState.spell_slots:
		var slot_container = VBoxContainer.new()
		slot_container.alignment = BoxContainer.ALIGNMENT_CENTER
		
		var label = Label.new()
		label.custom_minimum_size = Vector2(70, 30)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		if spell != null:
			var spell_data = GameState.SPELL_DATA[spell.id]
			label.text = spell_data.symbol + " " + str(spell.level)
			
			var xp_bar = ProgressBar.new()
			xp_bar.max_value = spell.xp_to_next_level
			xp_bar.value = spell.xp
			xp_bar.custom_minimum_size = Vector2(60, 5)
			xp_bar.show_percentage = false
			
			slot_container.add_child(label)
			slot_container.add_child(xp_bar)
		else:
			label.text = "[+]"
			slot_container.add_child(label)
			
		hud_spell_bar.add_child(slot_container)

func update_character_panel():
	var stats_container = character_panel.get_node("MarginContainer/VBoxContainer/StatsContainer")
	for child in stats_container.get_children():
		child.queue_free()
	
	for stat_name in GameState.stats:
		var level = GameState.stats[stat_name]
		var cost = floor(10 * pow(1.5, level - 1))
		var hbox = HBoxContainer.new()
		var label = Label.new()
		label.text = stat_name.capitalize() + ": " + str(level)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var button = Button.new()
		button.text = "Améliorer (" + str(cost) + " E)"
		button.pressed.connect(Callable(self, "_on_generic_upgrade_pressed").bind(stat_name))
		hbox.add_child(label)
		hbox.add_child(button)
		stats_container.add_child(hbox)
	
	# Met à jour le bouton d'achat d'emplacement
	var buy_slot_button = character_panel.get_node("MarginContainer/VBoxContainer/BuySlotButton")
	var slot_cost = floor(100 * pow(3, GameState.spell_slots.size() - 1))
	buy_slot_button.text = "Acheter Emplacement (%d E)" % slot_cost
	# On connecte le bouton (on le déconnecte d'abord pour éviter les connexions multiples)
	if buy_slot_button.is_connected("pressed", Callable(self, "_on_buy_slot_pressed")):
		buy_slot_button.disconnect("pressed", Callable(self, "_on_buy_slot_pressed"))
	buy_slot_button.pressed.connect(self._on_buy_slot_pressed)

func update_grimoire_panel():
	var slots_container = grimoire_panel.get_node("MarginContainer/VBoxContainer/ActiveSlotsContainer")
	var book_container = grimoire_panel.get_node("MarginContainer/VBoxContainer/SpellbookContainer")
	
	for child in slots_container.get_children(): child.queue_free()
	for child in book_container.get_children(): child.queue_free()

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

	for spell in GameState.spellbook:
		var spell_data = GameState.SPELL_DATA[spell.id]
		var spell_container = VBoxContainer.new()
		spell_container.alignment = BoxContainer.ALIGNMENT_CENTER
		var button = Button.new()
		button.text = spell_data.symbol + " " + str(spell.level)
		button.pressed.connect(Callable(self, "_on_equip_spell_pressed").bind(spell))
		var xp_bar = ProgressBar.new()
		xp_bar.max_value = spell.xp_to_next_level
		xp_bar.value = spell.xp
		xp_bar.custom_minimum_size = Vector2(60, 5)
		xp_bar.show_percentage = false
		spell_container.add_child(button)
		spell_container.add_child(xp_bar)
		book_container.add_child(spell_container)

func update_magic_school_panel():
	var spell_list = magic_school_panel.get_node("MarginContainer/VBoxContainer/ScrollContainer/SpellList")
	for child in spell_list.get_children():
		child.queue_free()
	
	# On récupère la liste des IDs des sorts déjà appris
	var learned_spell_ids = GameState.spellbook.map(func(s): return s.id)
	
	# On affiche un bouton pour chaque sort qui n'est pas encore appris
	for spell_id in GameState.SPELL_DATA:
		if not spell_id in learned_spell_ids:
			var spell_data = GameState.SPELL_DATA[spell_id]
			var cost = 0
			if not GameState.spellbook.is_empty():
				cost = floor(50 * pow(2, GameState.spellbook.size() - 1))
			
			var button = Button.new()
			button.text = "%s %s (Coût: %d E)" % [spell_data.symbol, spell_data.name, cost]
			button.pressed.connect(Callable(self, "_on_learn_spell_pressed").bind(spell_id))
			spell_list.add_child(button)

# --- Fonctions connectées aux signaux et boutons ---

func _on_learn_spell_pressed(spell_id: String):
	if GameState.learn_new_spell(spell_id):
		# Si l'apprentissage réussit, on met à jour les panneaux
		update_magic_school_panel()
		update_grimoire_panel()

func _on_buy_slot_pressed():
	if GameState.buy_spell_slot():
		# Si l'achat réussit, on met à jour les panneaux
		update_character_panel()
		update_grimoire_panel()
		update_hud_spell_bar()
		# On doit aussi dire au joueur de redimensionner son tableau de progression
		player.resize_cast_progress()

func on_essence_updated(new_value: int):
	essence_label.text = "Essence: " + str(new_value)

func _on_monster_died():
	if is_instance_valid(current_monster):
		GameState.add_essence(current_monster.essence_reward)
	player.set_target(null)
	if is_instance_valid(current_monster):
		current_monster.queue_free()
		current_monster = null
	
	await get_tree().create_timer(2.0).timeout
	
	var zone_data = world[GameState.current_zone_index]
	if zone_data.monster != null:
		var monster_scene = load(zone_data.monster)
		current_monster = monster_scene.instantiate()
		var screen_size = get_viewport_rect().size
		current_monster.position = Vector2(screen_size.x - 250, screen_size.y - 110)
		add_child(current_monster)
		current_monster.died.connect(self._on_monster_died)
		current_monster.hit_by_spell.connect(self._on_monster_hit)
		player.set_target(current_monster)

func _on_monster_hit(spell_info):
	GameState.gain_spell_xp(spell_info, 15)
	if grimoire_panel.visible:
		update_grimoire_panel()
	update_hud_spell_bar()
	# On met à jour les HP du monstre sur l'HUD à chaque coup
	update_monster_stats_label()

func _on_generic_upgrade_pressed(stat_name: String):
	if GameState.upgrade_stat(stat_name):
		# Si l'amélioration réussit, on met à jour les panneaux pertinents
		update_ui()
		update_character_panel()

func _on_character_button_pressed():
	pause_menu.hide()
	character_panel.show()
	update_character_panel()

func _on_grimoire_button_pressed():
	pause_menu.hide()
	grimoire_panel.show()
	update_grimoire_panel()

func _on_back_to_pause_menu_pressed():
	character_panel.hide()
	grimoire_panel.hide()
	pause_menu.show()

func _on_equip_spell_pressed(spell_to_equip):
	var empty_slot_index = GameState.spell_slots.find(null)
	if empty_slot_index != -1:
		var is_already_equipped = false
		for equipped_spell in GameState.spell_slots:
			if equipped_spell != null and equipped_spell.id == spell_to_equip.id:
				is_already_equipped = true
				break
		if not is_already_equipped:
			GameState.spell_slots[empty_slot_index] = spell_to_equip
			update_grimoire_panel()
			update_hud_spell_bar()
		else:
			print("Ce sort est déjà équipé.")
	else:
		print("Aucun emplacement de sort libre.")
