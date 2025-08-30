extends Node

signal essence_updated(new_value)

const SAVE_FILE_PATH = "user://savegame.json"

# --- Données du joueur ---
var player_name: String = "Apprenti Anonyme"
var magic_essence: int = 0:
	set(value):
		magic_essence = value
		emit_signal("essence_updated", magic_essence)

var stats: Dictionary = { "intelligence": 1, "power": 1, "celerity": 1, "wisdom": 1 }
var spell_slots: Array = [null, null]
var spellbook: Array = []
var monster_levels: Dictionary = {}
var next_spell_id: int = 0
var current_zone_index: int = 0

# --- Données des sorts ---
const SPELL_DATA = {
	"spark": { "name": "Étincelle", "symbol": "✨", "base_damage": 5, "element": "Feu" },
	"bubble": { "name": "Bulle", "symbol": "💧", "base_damage": 4, "element": "Eau" },
	"rock": { "name": "Caillou", "symbol": "🗿", "base_damage": 7, "element": "Terre" }
}

func _ready():
	reset_to_default()

# --- Fonctions de gestion des données ---

func reset_to_default():
	player_name = "Apprenti Anonyme"
	magic_essence = 0
	stats = { "intelligence": 1, "power": 1, "celerity": 1, "wisdom": 1 }
	spell_slots = [null, null]
	spellbook = []
	monster_levels = {}
	next_spell_id = 0
	current_zone_index = 0
	
	# On donne les sorts de base au joueur
	var spell_spark = { "id": "spark", "level": 1, "xp": 0, "xp_to_next_level": 100 }
	var spell_bubble = { "id": "bubble", "level": 1, "xp": 0, "xp_to_next_level": 100 }
	spellbook.append(spell_spark)
	spellbook.append(spell_bubble)
	print("GameState réinitialisé aux valeurs par défaut.")

func add_essence(amount: int):
	self.magic_essence += amount

func upgrade_stat(stat_name: String) -> bool:
	var current_level = stats[stat_name]
	var cost = floor(10 * pow(1.5, current_level - 1))
	
	if magic_essence >= cost:
		magic_essence -= cost
		stats[stat_name] += 1
		print(stat_name + " amélioré au niveau " + str(stats[stat_name]))
		return true
	else:
		print("Pas assez d'essence pour améliorer " + stat_name)
		return false

		return false # L'amélioration a échoué

func learn_new_spell(spell_id: String) -> bool:
	# On vérifie que le sort existe et qu'on ne l'a pas déjà
	if not SPELL_DATA.has(spell_id) or spellbook.any(func(s): return s.id == spell_id):
		return false

	# Le premier sort est gratuit, les autres ont un coût évolutif
	var cost = 0
	if not spellbook.is_empty():
		cost = floor(50 * pow(2, spellbook.size() -1))
	
	if magic_essence >= cost:
		magic_essence -= cost
		var new_spell = {
			"id": spell_id,
			"level": 1,
			"xp": 0,
			"xp_to_next_level": 100
		}
		spellbook.append(new_spell)
		print("Nouveau sort appris : ", SPELL_DATA[spell_id].name)
		return true
	else:
		print("Pas assez d'essence. Coût : ", cost)
		return false

func buy_spell_slot() -> bool:
	var cost = floor(100 * pow(3, spell_slots.size() - 1))
	if magic_essence >= cost:
		magic_essence -= cost
		spell_slots.append(null)
		print("Nouvel emplacement de sort acheté ! Total : ", spell_slots.size())
		return true
	else:
		print("Pas assez d'essence pour acheter un emplacement. Coût : ", cost)
		return false

func get_monster_data(monster_id: String):
	return monster_levels.get(monster_id, {"level": 1, "xp": 0})

func update_monster_data(monster_id: String, data: Dictionary):
	monster_levels[monster_id] = data

func gain_spell_xp(spell_info: Dictionary, amount: int):
	for spell in spellbook:
		if spell.id == spell_info.id:
			var intelligence_bonus = 1 + (stats["intelligence"] - 1) * 0.1
			spell.xp += round(amount * intelligence_bonus)
			if spell.xp >= spell.xp_to_next_level:
				spell.level += 1
				spell.xp = 0
				spell.xp_to_next_level = floor(spell.xp_to_next_level * 1.8)
				var spell_name = SPELL_DATA[spell.id].name
				print(spell_name + " a atteint le niveau " + str(spell.level) + " !")
			break

# --- Fonctions de Sauvegarde et Chargement ---

func save_game():
	# On rassemble toutes les données à sauvegarder dans un dictionnaire
	var save_data = {
		"player_name": player_name,
		"magic_essence": magic_essence,
		"stats": stats,
		"spell_slots": spell_slots,
		"spellbook": spellbook,
		"monster_levels": monster_levels,
		"next_spell_id": next_spell_id,
		"current_zone_index": current_zone_index
	}
	
	# On ouvre le fichier de sauvegarde en mode écriture
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		# On convertit le dictionnaire en texte JSON
		var json_string = JSON.stringify(save_data, "\t")
		# On écrit le texte dans le fichier
		file.store_string(json_string)
		file.close()
		print("Partie sauvegardée avec succès dans " + SAVE_FILE_PATH)
	else:
		print("Erreur lors de la sauvegarde de la partie.")

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("Fichier de sauvegarde non trouvé.")
		return false

	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var parse_result = JSON.parse_string(json_string)
		if parse_result != null:
			var data = parse_result
			# On charge les données dans notre état de jeu
			player_name = data.get("player_name", "Apprenti")
			magic_essence = data.get("magic_essence", 0)
			stats = data.get("stats", { "intelligence": 1, "power": 1, "celerity": 1, "wisdom": 1 })
			spell_slots = data.get("spell_slots", [null, null])
			spellbook = data.get("spellbook", [])
			monster_levels = data.get("monster_levels", {})
			next_spell_id = data.get("next_spell_id", 0)
			current_zone_index = data.get("current_zone_index", 0)
			print("Partie chargée avec succès.")
			return true
		else:
			print("Erreur lors de la lecture du fichier de sauvegarde (JSON invalide).")
			return false
	else:
		print("Erreur lors de l'ouverture du fichier de sauvegarde.")
		return false
