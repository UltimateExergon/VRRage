extends Node

var highscores : Dictionary = {"birthday": 0, "markt": 0, "pub": 0, "office": 0, "testlevel": 0, "level_select": -1, "exit": -1}

#Position of main node in get_tree().root.get_children()
const main_order : int = 3

const levelPath : String = "res://scenes/Level/"
const itemPath : String = "res://scenes/items/"
const recipePath : String = "res://craftingRecipes/"
const musicPath : String = "res://assets/sound/music/"
const soundeffectPath : String = "res://assets/sound/sound_effects/"
const sceneFormat : String = ".tscn"
const recipeFormat : String = ".csv"
const soundFormat : String = ".mp3"

@onready var destructionScore = preload("res://scenes/destruction_score.tscn")

@onready var outline_shader = preload("res://shader/outline.gdshader")
const outline_color : Color = Color8(255, 255, 255, 50)
const outline_color_near : Color = Color8(91, 255, 92, 255)
const outline_color_crafting : Color = Color8(196, 195, 0, 150)
const outline_color_crafting_near : Color = Color8(196, 195, 0, 200)
const outline_color_none : Color = Color8(0, 0, 0, 0)
const outline_width : float = 3.0

@onready var default_music : AudioStreamMP3 = preload("res://assets/sound/music/level_music.mp3")
@onready var default_destruction_sound : AudioStreamMP3 = preload("res://assets/sound/sound_effects/default_destructionSound.mp3")
@onready var levelTimerAlertSound : AudioStreamMP3 = preload("res://assets/sound/sound_effects/levelTimerAlertSound.mp3")
@onready var craftingSound : AudioStreamMP3 = preload("res://assets/sound/sound_effects/crafting_sound.mp3")
@onready var office_redlight_music : AudioStreamMP3 = preload("res://assets/sound/music/office_redlight_music.mp3")
@onready var multiplikatorStartSound : AudioStreamMP3 = preload("res://assets/sound/sound_effects/multiplikatorStartSound.mp3")
@onready var multiplikatorEndSound : AudioStreamMP3 = preload("res://assets/sound/sound_effects/multiplikatorEndSound.mp3")
const maxDB : float = 2.0
const volumeDB : float = 0.0
const MusicVolumeDB : float = -10.0

@onready var default_particleEmitter = preload("res://scenes/default_particle_emitter.tscn")

func update_highscore(score : int, level : String) -> void:
	var current_highscore : int = highscores.get(level)

	if score > current_highscore:
		highscores[level] = score
		
func get_highscore(level : String) -> int:
	return highscores.get(level)
