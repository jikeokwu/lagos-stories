extends Node
## Game State Manager - Handles transitions between game screens/modes

## Game states enum
enum GameState {
	HOME,              # Main menu / home screen
	WORLD_CONFIG,      # World generation configuration
	WORLD_GENERATION,  # World generation in progress
	WORLD_SUMMARY,     # World generation complete - show summary
	WORLD_SELECTION,   # Select from generated worlds
	CHRONICLES,        # Chronicles mode - explore world data
	INSTANCE_PLAY      # Active gameplay instance (future)
}

## Current game state
var current_state = GameState.HOME

## World data for state transitions
var current_world_config = {}
var current_world_id = ""
var current_world_metadata = {}
var current_world_generation_stats = {}
var generated_worlds = []
var selected_world_id = ""

## Signals for state changes
signal state_changed(new_state)
signal world_generated(world_data: Dictionary)
signal world_selected(world_id: String)

## Scene paths for each state
const SCENES = {
	GameState.HOME: "res://scenes/home_screen.tscn",
	GameState.WORLD_CONFIG: "res://scenes/world_config.tscn",
	GameState.WORLD_GENERATION: "res://scenes/world_gen.tscn",
	GameState.WORLD_SUMMARY: "res://scenes/world_summary.tscn",
	GameState.WORLD_SELECTION: "res://scenes/world_selection.tscn",
	GameState.CHRONICLES: "res://scenes/chronicles.tscn"
}

func _ready():
	print("GameStateManager initialized")
	# Load any saved worlds from database
	_load_saved_worlds()

## Transition to a new state
func transition_to(new_state) -> void:
	print("State transition: %s -> %s" % [GameState.keys()[current_state], GameState.keys()[new_state]])
	current_state = new_state
	state_changed.emit(new_state)
	_load_scene_for_state(new_state)

## Load the appropriate scene for a state
func _load_scene_for_state(state) -> void:
	if state in SCENES:
		var scene_path = SCENES[state]
		if ResourceLoader.exists(scene_path):
			get_tree().change_scene_to_file(scene_path)
		else:
			push_error("Scene not found: %s" % scene_path)
	else:
		push_error("No scene defined for state: %s" % GameState.keys()[state])

## Home screen actions
func start_new_world() -> void:
	transition_to(GameState.WORLD_CONFIG)

func load_existing_world() -> void:
	if generated_worlds.size() > 0:
		transition_to(GameState.WORLD_SELECTION)
	else:
		push_warning("No saved worlds found")

func exit_game() -> void:
	get_tree().quit()

## World configuration actions
func save_world_config(config: Dictionary) -> void:
	current_world_config = config.duplicate()
	print("World config saved: ", config)

func start_world_generation() -> void:
	print("Starting world generation with config: ", current_world_config)
	
	# Generate world_id if not already set
	if current_world_id == "":
		current_world_id = "world_%s" % Utils.generate_uuid()
	
	# Create world directory
	if not WorldManager.create_world_directory(current_world_id):
		push_error("Failed to create world directory")
		return
	
	# Initialize database with world-specific path
	var world_db_path = WorldManager.get_world_db_path(current_world_id)
	if not DB.initialize(world_db_path):
		push_error("Failed to initialize database for world")
		return
	
	# Create initial metadata (will be updated after generation)
	current_world_metadata = {
		"id": current_world_id,
		"name": current_world_config.get("world_name", "Unnamed World"),
		"seed": current_world_config.get("seed", 0),
		"created_at": Time.get_unix_time_from_system(),
		"last_played": Time.get_unix_time_from_system(),
		"play_time_seconds": 0,
		"config": current_world_config.duplicate(),
		"stats": {},
		"generation_timings": {},
		"validation_stats": {}
	}
	
	# Transition to world generation scene
	transition_to(GameState.WORLD_GENERATION)

func cancel_world_config() -> void:
	current_world_config.clear()
	transition_to(GameState.HOME)

## World selection actions
func select_world(world_id: String) -> void:
	selected_world_id = world_id
	
	# Close current database if open
	DB.close_database()
	
	# Initialize with world's database
	var world_db_path = WorldManager.get_world_db_path(world_id)
	if not DB.initialize(world_db_path):
		push_error("Failed to load world database")
		return
	
	# Load metadata
	current_world_metadata = WorldManager.load_world_metadata(world_id)
	if current_world_metadata.is_empty():
		push_error("Failed to load world metadata")
		return
	
	world_selected.emit(world_id)
	print("World selected: ", world_id)

func enter_chronicles() -> void:
	if selected_world_id != "":
		# Database should already be initialized by select_world()
		# But ensure it's loaded
		if not DB.is_initialized:
			var world_db_path = WorldManager.get_world_db_path(selected_world_id)
			DB.initialize(world_db_path)
		transition_to(GameState.CHRONICLES)
	else:
		push_warning("No world selected")

func delete_world(world_id: String) -> void:
	# Delete world using WorldManager
	if WorldManager.delete_world(world_id):
		# Remove from local list
		for i in range(generated_worlds.size()):
			if generated_worlds[i].get("id", "") == world_id:
				generated_worlds.remove_at(i)
				break
		print("World deleted: ", world_id)
	else:
		push_error("Failed to delete world: %s" % world_id)

func back_to_home_from_selection() -> void:
	transition_to(GameState.HOME)

## Chronicles mode actions
func exit_chronicles() -> void:
	selected_world_id = ""
	transition_to(GameState.HOME)

func start_instance_from_chronicles() -> void:
	# Future: transition to instance gameplay
	print("Starting instance gameplay (not yet implemented)")

## World management
func add_generated_world(world_data: Dictionary) -> void:
	generated_worlds.append(world_data)
	_save_worlds_list()
	world_generated.emit(world_data)

func get_generated_worlds() -> Array:
	return generated_worlds.duplicate()

func get_world_by_id(world_id: String) -> Dictionary:
	for world in generated_worlds:
		if world.get("id", "") == world_id:
			return world
	return {}

## Persistence
func _load_saved_worlds() -> void:
	# Load worlds from WorldManager
	generated_worlds = WorldManager.get_all_worlds()
	print("Loaded %d saved worlds" % generated_worlds.size())
	
	# Migrate old saved_worlds.json if it exists
	var old_save_path = "user://saved_worlds.json"
	if FileAccess.file_exists(old_save_path):
		print("Migrating old worlds list...")
		var file = FileAccess.open(old_save_path, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			if parse_result == OK:
				var old_worlds = json.get_data()
				if old_worlds is Array:
					# Migrate each old world
					for old_world in old_worlds:
						var world_id = old_world.get("id", "")
						if world_id != "":
							# Try to create metadata for old world
							WorldManager.add_world_to_list(old_world)
			# Remove old file after migration
			DirAccess.remove_absolute(old_save_path)

func _save_worlds_list() -> void:
	# Worlds are now managed by WorldManager, no need to save separately
	pass

## World generation completion handler
func world_generation_complete(stats: Dictionary, timings: Dictionary, db_stats: Dictionary, validation_stats: Dictionary = {}) -> void:
	# Update metadata with final stats
	current_world_metadata["stats"] = db_stats.duplicate()
	current_world_metadata["generation_timings"] = timings.duplicate()
	current_world_metadata["validation_stats"] = validation_stats.duplicate()
	current_world_metadata["last_played"] = Time.get_unix_time_from_system()
	
	# Store generation stats for summary screen
	current_world_generation_stats = {
		"stats": stats.duplicate(),
		"timings": timings.duplicate(),
		"db_stats": db_stats.duplicate(),
		"validation_stats": validation_stats.duplicate()
	}
	
	# Save metadata
	WorldManager.save_world_metadata(current_world_id, current_world_metadata)
	WorldManager.add_world_to_list(current_world_metadata)
	
	# Reload worlds list
	generated_worlds = WorldManager.get_all_worlds()
	
	# Transition to world summary
	transition_to(GameState.WORLD_SUMMARY)

## Get current state name as string
func get_current_state_name() -> String:
	return GameState.keys()[current_state]

## Check if in a specific state
func is_in_state(state) -> bool:
	return current_state == state
