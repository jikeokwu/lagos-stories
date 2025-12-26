extends Control
## Chronicles Mode - Browse and explore world data

# Preload utility classes
const NPCLoader = preload("res://scripts/chronicles/loaders/npc_loader.gd")
const LocationLoader = preload("res://scripts/chronicles/loaders/location_loader.gd")
const OrganizationLoader = preload("res://scripts/chronicles/loaders/organization_loader.gd")
const EventLoader = preload("res://scripts/chronicles/loaders/event_loader.gd")
const StatisticsLoader = preload("res://scripts/chronicles/loaders/statistics_loader.gd")
const NPCDisplay = preload("res://scripts/chronicles/displays/npc_display.gd")
const LocationDisplay = preload("res://scripts/chronicles/displays/location_display.gd")
const OrganizationDisplay = preload("res://scripts/chronicles/displays/organization_display.gd")
const EventDisplay = preload("res://scripts/chronicles/displays/event_display.gd")
const ItemFactory = preload("res://scripts/chronicles/ui/item_factory.gd")
const ChroniclesUtils = preload("res://scripts/chronicles/utils.gd")

@onready var tab_container = $VBoxContainer/MainContainer/TabContainer
@onready var npcs_list = $VBoxContainer/MainContainer/TabContainer/NPCs/ScrollContainer/NPCsList
@onready var locations_list = $VBoxContainer/MainContainer/TabContainer/Locations/ScrollContainer/LocationsList
@onready var orgs_list = $VBoxContainer/MainContainer/TabContainer/Organizations/ScrollContainer/OrgsList
@onready var events_list = $VBoxContainer/MainContainer/TabContainer/Events/ScrollContainer/EventsList
@onready var stats_list = $VBoxContainer/MainContainer/TabContainer/Statistics/ScrollContainer/StatsList
@onready var detail_panel = $VBoxContainer/MainContainer/DetailPanel
@onready var detail_scroll = $VBoxContainer/MainContainer/DetailPanel/ScrollContainer
@onready var detail_content = $VBoxContainer/MainContainer/DetailPanel/ScrollContainer/DetailContent
@onready var back_button = $VBoxContainer/TopBar/BackButton
@onready var refresh_button = $VBoxContainer/TopBar/RefreshButton
@onready var world_name_label = $VBoxContainer/TopBar/WorldNameLabel

var current_selection = null
var current_selection_type = ""

func _ready():
	# Connect buttons
	back_button.pressed.connect(_on_back_pressed)
	refresh_button.pressed.connect(_on_refresh_pressed)
	
	# Connect tab changed
	tab_container.tab_changed.connect(_on_tab_changed)
	
	# Load world name
	var world_id = GameState.selected_world_id
	var world_data = GameState.get_world_by_id(world_id)
	world_name_label.text = "Chronicles: %s" % world_data.get("name", "Unknown World")
	
	# Initialize database and load data
	_initialize_world()
	_load_all_data()

func _initialize_world():
	# Initialize database
	if not DB.initialize():
		push_error("Failed to initialize database")
		return
	
	print("Chronicles mode initialized for world: ", GameState.selected_world_id)

func _load_all_data():
	# Create factory functions with callbacks
	var npc_item_factory = func(npc): return ItemFactory.create_npc_item(npc, _on_npc_selected)
	var location_item_factory = func(location): return ItemFactory.create_location_item(location, _on_location_selected)
	var org_item_factory = func(org): return ItemFactory.create_org_item(org, _on_org_selected)
	var event_item_factory = func(event): return ItemFactory.create_event_item(event, _on_event_selected, ChroniclesUtils.format_timestamp)
	var empty_label_factory = func(text): return ItemFactory.create_empty_label(text)
	
	# Load all data using loader classes
	NPCLoader.load_npcs(npcs_list, npc_item_factory, empty_label_factory)
	LocationLoader.load_locations(locations_list, location_item_factory, empty_label_factory)
	OrganizationLoader.load_organizations(orgs_list, org_item_factory, empty_label_factory)
	EventLoader.load_events(events_list, event_item_factory, empty_label_factory)
	StatisticsLoader.load_statistics(stats_list)

func _on_npc_selected(npc_id: String):
	var npc = DB.get_npc(npc_id)
	if npc.is_empty():
		return
	
	current_selection = npc
	current_selection_type = "NPC"
	NPCDisplay.display_npc_details(npc, detail_panel, detail_content)

func _on_location_selected(location_id: String):
	var location = DB.get_location(location_id)
	if location.is_empty():
		return
	
	current_selection = location
	current_selection_type = "Location"
	LocationDisplay.display_location_details(location, detail_panel, detail_content)

func _on_org_selected(org_id: String):
	var org = DB.get_organization(org_id)
	if org.is_empty():
		return
	
	current_selection = org
	current_selection_type = "Organization"
	OrganizationDisplay.display_org_details(org, detail_panel, detail_content)

func _on_event_selected(event_id: String):
	var event = DB.get_event(event_id)
	if event.is_empty():
		return
	
	current_selection = event
	current_selection_type = "Event"
	EventDisplay.display_event_details(event, detail_panel, detail_content)

func _on_tab_changed(_tab: int):
	# Hide detail panel when switching tabs
	detail_panel.visible = false

func _on_refresh_pressed():
	_load_all_data()
	detail_panel.visible = false

func _on_back_pressed():
	GameState.exit_chronicles()

