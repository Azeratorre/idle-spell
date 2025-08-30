extends Control

@onready var new_game_button = $CenterContainer/VBoxContainer/NewGameButton
@onready var load_game_button = $CenterContainer/VBoxContainer/LoadGameButton
@onready var options_button = $CenterContainer/VBoxContainer/OptionsButton

func _ready():
	new_game_button.pressed.connect(_on_new_game_pressed)
	load_game_button.pressed.connect(_on_load_game_pressed)
	options_button.pressed.connect(_on_options_pressed)

func _on_new_game_pressed():
	print("Nouvelle partie lancée !")
	# On réinitialise l'état du jeu avant de commencer
	GameState.reset_to_default()
	# On change pour la scène de jeu
	SceneManager.change_scene("res://scenes/Game.tscn")

func _on_load_game_pressed():
	print("Chargement de la partie...")
	if GameState.load_game():
		# Si le chargement réussit, on va à la scène de jeu
		SceneManager.change_scene("res://scenes/Game.tscn")
	else:
		# Si aucune sauvegarde n'est trouvée, on le signale
		# (On ajoutera une notification visuelle plus tard)
		print("Aucune sauvegarde trouvée.")

func _on_options_pressed():
	print("Le menu Options n'est pas encore implémenté.")
