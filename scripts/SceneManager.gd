extends Node

# Fonction pour changer la scène actuellement affichée
func change_scene(scene_path: String):
	# change_scene_to_file est la fonction de Godot pour charger et afficher une nouvelle scène
	get_tree().change_scene_to_file(scene_path)
