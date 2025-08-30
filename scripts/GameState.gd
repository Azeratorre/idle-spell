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
var spell_slots: Array = [null, null]

# Grimoire de tous les sorts appris
var spellbook: Array = []

# Niveaux des monstres rencontrés
var monster_levels: Dictionary = {}

# Pour assigner un ID unique à chaque nouveau sort
var next_spell_id: int = 0

# Index de la zone actuelle
var current_zone_index: int = 0

# --- Données des sorts (similaire à skillTiers en JS) ---
const SPELL_DATA = {
	"spark": { "name": "Étincelle", "symbol": "✨", "base_damage": 5, "element": "Feu" },
	"bubble": { "name": "Bulle", "symbol": "💧", "base_damage": 4, "element": "Eau" }
}

func _ready():
	# Pour les tests, on commence avec deux sorts appris
	if spellbook.is_empty():
		var spell_spark = { "id": "spark", "level": 1, "xp": 0, "xp_to_next_level": 100 }
		var spell_bubble = { "id": "bubble", "level": 1, "xp": 0, "xp_to_next_level": 100 }
		spellbook.append(spell_spark)
		spellbook.append(spell_bubble)

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

func gain_spell_xp(spell_info: Dictionary, amount: int):
	# On cherche le sort correspondant dans le grimoire
	for spell in spellbook:
		if spell.id == spell_info.id:
			# On augmente son XP (avec le bonus d'intelligence)
			var intelligence_bonus = 1 + (stats["intelligence"] - 1) * 0.1
			spell.xp += round(amount * intelligence_bonus)
			
			# On vérifie s'il monte de niveau
			if spell.xp >= spell.xp_to_next_level:
				spell.level += 1
				spell.xp = 0
				# On augmente le coût en XP pour le prochain niveau
				spell.xp_to_next_level = floor(spell.xp_to_next_level * 1.8)
				var spell_name = SPELL_DATA[spell.id].name
				print(spell_name + " a atteint le niveau " + str(spell.level) + " !")
			
			# On a trouvé et mis à jour le sort, on peut arrêter la boucle
			break

# --- Fonctions de Sauvegarde et Chargement ---

func save_game():
	# La logique de sauvegarde sera implémentée ici
	print("Partie sauvegardée (logique à faire)")

func load_game():
	# La logique de chargement sera implémentée ici
	print("Partie chargée (logique à faire)")
