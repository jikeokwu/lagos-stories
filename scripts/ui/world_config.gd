extends Control
## World Configuration Screen - Set up world generation parameters
## Supports both Preset and Custom configuration modes

# Mode selection
@onready var mode_selection = $VBoxContainer/ScrollContainer/ConfigPanel/ModeSelectionContainer/ModeSelection
@onready var preset_container = $VBoxContainer/ScrollContainer/ConfigPanel/PresetContainer
@onready var custom_container = $VBoxContainer/ScrollContainer/ConfigPanel/CustomContainer

# Common fields (visible in both modes)
@onready var world_name_edit = $VBoxContainer/ScrollContainer/ConfigPanel/CommonFieldsContainer/WorldNameContainer/WorldNameEdit
@onready var seed_edit = $VBoxContainer/ScrollContainer/ConfigPanel/CommonFieldsContainer/SeedContainer/HBoxContainer/SeedEdit
@onready var random_seed_button = $VBoxContainer/ScrollContainer/ConfigPanel/CommonFieldsContainer/SeedContainer/HBoxContainer/RandomSeedButton

# Preset mode
@onready var preset_dropdown = $VBoxContainer/ScrollContainer/ConfigPanel/PresetContainer/PresetDropdown
@onready var preset_description = $VBoxContainer/ScrollContainer/ConfigPanel/PresetContainer/PresetDescription
@onready var preset_spec_label = $VBoxContainer/ScrollContainer/ConfigPanel/PresetContainer/PresetSpecLabel

# Custom mode
@onready var target_npcs_slider = $VBoxContainer/ScrollContainer/ConfigPanel/CustomContainer/TargetNPCsContainer/TargetNPCsSlider
@onready var target_npcs_label = $VBoxContainer/ScrollContainer/ConfigPanel/CustomContainer/TargetNPCsContainer/TargetNPCsLabel
@onready var family_composition_slider = $VBoxContainer/ScrollContainer/ConfigPanel/CustomContainer/FamilyCompositionContainer/FamilyCompositionSlider
@onready var family_composition_label = $VBoxContainer/ScrollContainer/ConfigPanel/CustomContainer/FamilyCompositionContainer/FamilyCompositionLabel
@onready var district_density_slider = $VBoxContainer/ScrollContainer/ConfigPanel/CustomContainer/DistrictDensityContainer/DistrictDensitySlider
@onready var district_density_label = $VBoxContainer/ScrollContainer/ConfigPanel/CustomContainer/DistrictDensityContainer/DistrictDensityLabel
@onready var org_density_slider = $VBoxContainer/ScrollContainer/ConfigPanel/CustomContainer/OrgDensityContainer/OrgDensitySlider
@onready var org_density_label = $VBoxContainer/ScrollContainer/ConfigPanel/CustomContainer/OrgDensityContainer/OrgDensityLabel
@onready var location_density_slider = $VBoxContainer/ScrollContainer/ConfigPanel/CustomContainer/LocationDensityContainer/LocationDensitySlider
@onready var location_density_label = $VBoxContainer/ScrollContainer/ConfigPanel/CustomContainer/LocationDensityContainer/LocationDensityLabel

# Buttons
@onready var generate_button = $VBoxContainer/ButtonContainer/GenerateButton
@onready var cancel_button = $VBoxContainer/ButtonContainer/CancelButton

var config = {
	"world_name": "",
	"target_npcs": 1000,
	"seed": 0,
	"family_composition_ratio": 0.3,  # 30% singles, 70% families
	"district_density_ratio": 1.0,     # 100% of base calculation
	"org_density_ratio": 1.0,         # 100% of need-based calculation
	"location_density_ratio": 1.0,     # 100% of need-based calculation
	"start_date": "2025-01-01",
	"start_time": "08:00"
}

var current_mode = "preset"  # "preset" or "custom"
var presets: Array = []
var selected_preset_id = ""

func _ready():
	# Load presets
	# Note: Restart Godot if you see "WorldPresets not declared" errors
	# This happens when autoloads are added but Godot hasn't reloaded yet
	presets = WorldPresets.get_presets()
	
	# Initialize mode selection dropdown
	mode_selection.add_item("Select Preset")
	mode_selection.add_item("Custom World")
	mode_selection.selected = 0
	
	# Connect mode selection
	mode_selection.item_selected.connect(_on_mode_selected)
	
	# Connect preset dropdown
	preset_dropdown.item_selected.connect(_on_preset_selected)
	
	# Connect custom sliders
	target_npcs_slider.value_changed.connect(_on_target_npcs_changed)
	family_composition_slider.value_changed.connect(_on_family_composition_changed)
	district_density_slider.value_changed.connect(_on_district_density_changed)
	org_density_slider.value_changed.connect(_on_org_density_changed)
	location_density_slider.value_changed.connect(_on_location_density_changed)
	
	# Connect buttons
	random_seed_button.pressed.connect(_on_random_seed_pressed)
	generate_button.pressed.connect(_on_generate_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	
	# Connect text edits
	world_name_edit.text_changed.connect(_on_world_name_changed)
	seed_edit.text_changed.connect(_on_seed_changed)
	
	# Initialize UI
	_initialize_preset_dropdown()
	_load_defaults()
	_update_ui_for_mode()

func _initialize_preset_dropdown():
	preset_dropdown.clear()
	for preset in presets:
		var display_name = WorldPresets.get_preset_display_name(preset)
		preset_dropdown.add_item(display_name)
		preset_dropdown.set_item_metadata(preset_dropdown.get_item_count() - 1, preset.id)
	
	# Select first preset by default
	if presets.size() > 0:
		preset_dropdown.selected = 0
		selected_preset_id = presets[0].id
		_update_preset_info()

func _load_defaults():
	# Start with empty world name - user must enter it
	world_name_edit.text = ""
	config.world_name = ""
	_generate_random_seed()
	
	# Load default preset config
	if presets.size() > 0:
		var default_preset = presets[0]
		_apply_preset_config(default_preset.config)
	else:
		# Fallback to default custom config
		target_npcs_slider.value = config.target_npcs
		family_composition_slider.value = config.family_composition_ratio * 100.0
		district_density_slider.value = config.district_density_ratio * 100.0
		org_density_slider.value = config.org_density_ratio * 100.0
		location_density_slider.value = config.location_density_ratio * 100.0

func _update_ui_for_mode():
	if current_mode == "preset":
		preset_container.visible = true
		custom_container.visible = false
		_update_preset_info()
	else:
		preset_container.visible = false
		custom_container.visible = true
		_update_all_labels()

func _update_preset_info():
	if selected_preset_id == "":
		return
	
	var preset = WorldPresets.get_preset(selected_preset_id)
	if preset == null:
		return
	
	preset_description.text = preset.description
	preset_spec_label.text = preset.spec_description
	
	# Apply preset config to internal config
	_apply_preset_config(preset.config)

func _apply_preset_config(preset_config: Dictionary):
	config.target_npcs = preset_config.get("target_npcs", 1000)
	config.family_composition_ratio = preset_config.get("family_composition_ratio", 0.3)
	config.district_density_ratio = preset_config.get("district_density_ratio", 1.0)
	config.org_density_ratio = preset_config.get("org_density_ratio", 1.0)
	config.location_density_ratio = preset_config.get("location_density_ratio", 1.0)
	config.start_date = preset_config.get("start_date", "2025-01-01")
	config.start_time = preset_config.get("start_time", "08:00")
	
	# Update custom sliders if visible (for reference)
	if custom_container.visible:
		target_npcs_slider.value = config.target_npcs
		family_composition_slider.value = config.family_composition_ratio * 100.0
		district_density_slider.value = config.district_density_ratio * 100.0
		org_density_slider.value = config.org_density_ratio * 100.0
		location_density_slider.value = config.location_density_ratio * 100.0
		_update_all_labels()

func _update_all_labels():
	target_npcs_label.text = "Target NPCs: %d" % int(target_npcs_slider.value)
	family_composition_label.text = "Singles Ratio: %d%% (Families: %d%%)" % [int(family_composition_slider.value), int(100 - family_composition_slider.value)]
	district_density_label.text = "District Density: %d%%" % int(district_density_slider.value)
	org_density_label.text = "Organization Density: %d%%" % int(org_density_slider.value)
	location_density_label.text = "Location Density: %d%%" % int(location_density_slider.value)

func _on_mode_selected(index: int):
	current_mode = "preset" if index == 0 else "custom"
	_update_ui_for_mode()

func _on_preset_selected(index: int):
	selected_preset_id = preset_dropdown.get_item_metadata(index)
	_update_preset_info()

func _on_target_npcs_changed(value: float):
	config.target_npcs = int(value)
	if custom_container.visible:
		target_npcs_label.text = "Target NPCs: %d" % config.target_npcs

func _on_family_composition_changed(value: float):
	config.family_composition_ratio = value / 100.0
	if custom_container.visible:
		family_composition_label.text = "Singles Ratio: %d%% (Families: %d%%)" % [int(value), int(100 - value)]

func _on_district_density_changed(value: float):
	config.district_density_ratio = value / 100.0
	if custom_container.visible:
		district_density_label.text = "District Density: %d%%" % int(value)

func _on_org_density_changed(value: float):
	config.org_density_ratio = value / 100.0
	if custom_container.visible:
		org_density_label.text = "Organization Density: %d%%" % int(value)

func _on_location_density_changed(value: float):
	config.location_density_ratio = value / 100.0
	if custom_container.visible:
		location_density_label.text = "Location Density: %d%%" % int(value)

func _on_world_name_changed(new_text: String):
	# Update config when user types (strip whitespace)
	config.world_name = new_text.strip_edges()

func _on_seed_changed(new_text: String):
	if new_text.is_valid_int():
		config.seed = new_text.to_int()
	else:
		config.seed = new_text.hash()

func _generate_random_seed():
	randomize()
	config.seed = randi()
	seed_edit.text = str(config.seed)

func _on_random_seed_pressed():
	_generate_random_seed()

func _on_generate_pressed():
	# Validate world name
	if config.world_name.strip_edges() == "":
		push_warning("World name cannot be empty")
		world_name_edit.grab_focus()
		return
	
	print("Generating world with config: ", config)
	GameState.save_world_config(config)
	
	# Generate world_id
	var world_id = "world_%s" % Utils.generate_uuid()
	
	# Create initial world metadata (will be updated after generation)
	var world_data = {
		"id": world_id,
		"name": config.world_name,
		"seed": config.seed,
		"created_at": Time.get_unix_time_from_system(),
		"last_played": Time.get_unix_time_from_system(),
		"play_time_seconds": 0,
		"config": config.duplicate(),
		"stats": {
			"npcs": 0,
			"families": 0,
			"districts": 0,
			"organizations": 0,
			"locations": 0,
			"relationships": 0,
			"events": 0,
			"memories": 0
		},
		"generation_timings": {},
		"validation_stats": {
			"issues_found": 0,
			"issues_fixed": 0
		}
	}
	
	# Save config and world data to GameState
	GameState.save_world_config(config)
	GameState.current_world_id = world_id
	GameState.current_world_metadata = world_data
	
	# Start world generation
	GameState.start_world_generation()

func _on_cancel_pressed():
	GameState.cancel_world_config()
