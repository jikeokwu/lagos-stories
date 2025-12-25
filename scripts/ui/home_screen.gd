extends Control
## Home Screen - Main menu for Lagos Stories

@onready var title_label = $VBoxContainer/TitleLabel
@onready var new_world_button = $VBoxContainer/ButtonContainer/NewWorldButton
@onready var load_world_button = $VBoxContainer/ButtonContainer/LoadWorldButton
@onready var exit_button = $VBoxContainer/ButtonContainer/ExitButton
@onready var version_label = $VersionLabel

func _ready():
	# Connect buttons
	new_world_button.pressed.connect(_on_new_world_pressed)
	load_world_button.pressed.connect(_on_load_world_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	
	# Update load button state based on available worlds
	_update_load_button()
	
	# Set version info
	version_label.text = "v0.1.0-alpha | Milestone 2: Game State"

func _update_load_button():
	var worlds = GameState.get_generated_worlds()
	load_world_button.disabled = worlds.size() == 0
	if worlds.size() == 0:
		load_world_button.text = "Load World (None Available)"
	else:
		load_world_button.text = "Load World (%d available)" % worlds.size()

func _on_new_world_pressed():
	print("New World clicked")
	GameState.start_new_world()

func _on_load_world_pressed():
	print("Load World clicked")
	GameState.load_existing_world()

func _on_exit_pressed():
	print("Exit clicked")
	GameState.exit_game()

