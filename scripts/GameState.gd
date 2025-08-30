extends Node

# Signal émis lorsque la quantité d'essence magique change
signal essence_updated(new_value)

# Données du joueur
var player_name: String = "Apprenti Anonyme"
var magic_essence: int = 0:
	set(value):
		magic_essence = value
		emit_signal("essence_updated", magic_essence)

# Statistiques du joueur
var stats: Dictionary = {
	"intelligence": 1,
	"power": 1,
	"celerity": 1,
	"wisdom": 1
}

# Emplacements de sorts actifs
var spell_slots: Array = [null]

# Grimoire de tous les sorts appris
var spellbook: Array = []

# Niveaux des monstres rencontrés
var monster_levels: Dictionary = {}

# Pour assigner un ID unique à chaque nouveau sort
var next_spell_id: int = 0

# Index de la zone actuelle
var current_zone_index: int = 0

# --- Fonctions de modification des données ---

func add_essence(amount: int):
	self.magic_essence += amount
	print(str(amount) + " essence magique gagnée. Total : " + str(magic_essence))

func upgrade_stat(stat_name: String):
	# Calcule le coût basé sur le niveau actuel de la stat
	var current_level = stats[stat_name]
	var cost = floor(10 * pow(1.5, current_level - 1))
	
	if magic_essence >= cost:
		# Si on a assez d'essence, on paie le coût
		self.magic_essence -= cost
		# On augmente le niveau de la stat
		stats[stat_name] += 1
		print(stat_name + " amélioré au niveau " + str(stats[stat_name]))
		return true # L'amélioration a réussi
	else:
		# Sinon, on signale que l'amélioration a échoué
		print("Pas assez d'essence pour améliorer " + stat_name)
		return false # L'amélioration a échoué

# --- Fonctions de Sauvegarde et Chargement ---

func save_game():
	# La logique de sauvegarde sera implémentée ici
	print("Partie sauvegardée (logique à faire)")

func load_game():
	# La logique de chargement sera implémentée ici
	print("Partie chargée (logique à faire)")
