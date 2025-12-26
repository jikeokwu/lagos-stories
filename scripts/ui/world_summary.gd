extends Control
## World Summary Screen - Displays world generation results

@onready var world_name_label = $VBoxContainer/ScrollContainer/ContentPanel/WorldInfoContainer/WorldNameLabel
@onready var created_date_label = $VBoxContainer/ScrollContainer/ContentPanel/WorldInfoContainer/CreatedDateLabel
@onready var seed_label = $VBoxContainer/ScrollContainer/ContentPanel/WorldInfoContainer/SeedLabel

@onready var npcs_value = $VBoxContainer/ScrollContainer/ContentPanel/StatisticsContainer/StatsGrid/NPCsValue
@onready var families_value = $VBoxContainer/ScrollContainer/ContentPanel/StatisticsContainer/StatsGrid/FamiliesValue
@onready var districts_value = $VBoxContainer/ScrollContainer/ContentPanel/StatisticsContainer/StatsGrid/DistrictsValue
@onready var organizations_value = $VBoxContainer/ScrollContainer/ContentPanel/StatisticsContainer/StatsGrid/OrganizationsValue
@onready var locations_value = $VBoxContainer/ScrollContainer/ContentPanel/StatisticsContainer/StatsGrid/LocationsValue

@onready var relationships_value = $VBoxContainer/ScrollContainer/ContentPanel/SocialNetworkContainer/RelationshipsValue
@onready var avg_relationships_value = $VBoxContainer/ScrollContainer/ContentPanel/SocialNetworkContainer/AvgRelationshipsValue

@onready var events_value = $VBoxContainer/ScrollContainer/ContentPanel/HistoryContainer/EventsValue
@onready var memories_value = $VBoxContainer/ScrollContainer/ContentPanel/HistoryContainer/MemoriesValue

@onready var generation_time_value = $VBoxContainer/ScrollContainer/ContentPanel/GenerationInfoContainer/GenerationTimeValue
@onready var timings_text = $VBoxContainer/ScrollContainer/ContentPanel/GenerationInfoContainer/TimingsText

@onready var issues_found_value = $VBoxContainer/ScrollContainer/ContentPanel/ValidationContainer/IssuesFoundValue
@onready var issues_fixed_value = $VBoxContainer/ScrollContainer/ContentPanel/ValidationContainer/IssuesFixedValue

@onready var enter_chronicles_button = $VBoxContainer/ButtonContainer/EnterChroniclesButton
@onready var back_button = $VBoxContainer/ButtonContainer/BackButton
@onready var generate_another_button = $VBoxContainer/ButtonContainer/GenerateAnotherButton

func _ready():
	# Connect buttons
	enter_chronicles_button.pressed.connect(_on_enter_chronicles_pressed)
	back_button.pressed.connect(_on_back_pressed)
	generate_another_button.pressed.connect(_on_generate_another_pressed)
	
	# Load and display data
	_populate_world_info()
	_populate_statistics()
	_populate_social_network()
	_populate_history()
	_populate_generation_info()
	_populate_validation()

func _populate_world_info():
	var metadata = GameState.current_world_metadata
	if metadata.is_empty():
		metadata = WorldManager.load_world_metadata(GameState.current_world_id)
	
	world_name_label.text = metadata.get("name", "Unnamed World")
	
	var created_timestamp = metadata.get("created_at", Time.get_unix_time_from_system())
	var created_date = Time.get_datetime_dict_from_unix_time(created_timestamp)
	created_date_label.text = "Created: %d/%d/%d %02d:%02d" % [
		created_date.month, created_date.day, created_date.year,
		created_date.hour, created_date.minute
	]
	
	var seed_value = metadata.get("seed", 0)
	seed_label.text = "Seed: %d" % seed_value

func _populate_statistics():
	var db_stats = GameState.current_world_generation_stats.get("db_stats", {})
	if db_stats.is_empty():
		db_stats = DB.get_statistics()
	
	npcs_value.text = str(db_stats.get("npcs", 0))
	families_value.text = str(GameState.current_world_generation_stats.get("stats", {}).get("families", 0))
	districts_value.text = str(GameState.current_world_generation_stats.get("stats", {}).get("districts", 0))
	organizations_value.text = str(db_stats.get("organizations", 0))
	locations_value.text = str(db_stats.get("locations", 0))

func _populate_social_network():
	var db_stats = GameState.current_world_generation_stats.get("db_stats", {})
	if db_stats.is_empty():
		db_stats = DB.get_statistics()
	
	var total_relationships = db_stats.get("relationships", 0)
	var total_npcs = db_stats.get("npcs", 1)
	var avg_rels = float(total_relationships) / float(total_npcs) if total_npcs > 0 else 0.0
	
	relationships_value.text = str(total_relationships)
	avg_relationships_value.text = "%.1f" % avg_rels

func _populate_history():
	var db_stats = GameState.current_world_generation_stats.get("db_stats", {})
	if db_stats.is_empty():
		db_stats = DB.get_statistics()
	
	events_value.text = str(db_stats.get("events", 0))
	memories_value.text = str(db_stats.get("npc_memories", 0))

func _populate_generation_info():
	var timings = GameState.current_world_generation_stats.get("timings", {})
	var total_time = timings.get("total", 0.0)
	
	generation_time_value.text = "%.2f seconds" % total_time
	
	# Build timings breakdown text
	var timing_lines = []
	for key in timings.keys():
		if key != "total":
			timing_lines.append("  %s: %.3fs" % [key.replace("_", " ").capitalize(), timings[key]])
	
	timings_text.text = "\n".join(timing_lines)

func _populate_validation():
	var validation_stats = GameState.current_world_generation_stats.get("validation_stats", {})
	
	issues_found_value.text = str(validation_stats.get("issues_found", 0))
	issues_fixed_value.text = str(validation_stats.get("issues_fixed", 0))

func _on_enter_chronicles_pressed():
	GameState.selected_world_id = GameState.current_world_id
	GameState.enter_chronicles()

func _on_back_pressed():
	GameState.transition_to(GameState.WORLD_SELECTION)

func _on_generate_another_pressed():
	GameState.current_world_id = ""
	GameState.current_world_metadata = {}
	GameState.current_world_generation_stats = {}
	GameState.start_new_world()
