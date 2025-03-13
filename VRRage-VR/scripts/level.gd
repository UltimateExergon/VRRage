extends Node3D

@export var start_pos : Vector3 : get = get_startPos ##Position at which the player spawns
@export var level_music : String = "" ##File name in assets/sound/music/ without .mp3
@export var level_time : float = 60.0

@onready var musicPlayer : AudioStreamPlayer = AudioStreamPlayer.new()

func _ready():
	print("Loaded level: ", self.name)
	
	for i in get_children():
		if i.is_in_group("room"):
			i.set_collision_mask_value(1, false)
			i.set_collision_layer_value(1, true)
			
	add_levelMusic()
			
func add_levelMusic() -> void:
	var music_stream : AudioStreamMP3
	if not level_music == "":
		music_stream = load(Globals.musicPath + level_music + Globals.soundFormat)
	else:
		music_stream = Globals.default_music
		
	musicPlayer.stream = music_stream
	musicPlayer.volume_db = Globals.MusicVolumeDB
	add_child(musicPlayer)
	
	musicPlayer.play()

func get_startPos() -> Vector3:
	return start_pos
	
func get_level_time() -> float:
	return level_time
