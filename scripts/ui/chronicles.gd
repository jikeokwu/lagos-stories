extends Control
## Chronicles Mode - Browse and explore world data

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
	_load_npcs()
	_load_locations()
	_load_organizations()
	_load_events()
	_load_statistics()

func _load_npcs():
	_clear_list(npcs_list)
	
	var db_npcs = DB.get_all_npcs()
	
	if db_npcs.size() == 0:
		var label = _create_empty_label("No NPCs found. Generate a world first.")
		npcs_list.add_child(label)
		return
	
	for npc in db_npcs:
		var item = _create_npc_item(npc)
		npcs_list.add_child(item)

func _create_npc_item(npc: Dictionary) -> Control:
	var button = Button.new()
	button.custom_minimum_size = Vector2(0, 40)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	var name = npc.get("name", "Unknown")
	var age = npc.get("definite", {}).get("age", "?")
	var gender = npc.get("definite", {}).get("gender", "?")
	var alive = npc.get("definite", {}).get("alive", true)
	var status = "✓" if alive else "†"
	
	button.text = "  %s  |  %s, %s, Age %s" % [status, name, gender.capitalize(), age]
	button.add_theme_font_size_override("font_size", 14)
	
	var npc_id = npc.get("id", "")
	button.pressed.connect(_on_npc_selected.bind(npc_id))
	
	return button

func _load_locations():
	_clear_list(locations_list)
	
	var db_locations = DB.get_all_locations()
	
	if db_locations.size() == 0:
		var label = _create_empty_label("No locations found.")
		locations_list.add_child(label)
		return
	
	for location in db_locations:
		var item = _create_location_item(location)
		locations_list.add_child(item)

func _create_location_item(location: Dictionary) -> Control:
	var button = Button.new()
	button.custom_minimum_size = Vector2(0, 40)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	var name = location.get("name", "Unknown")
	var type_val = location.get("type", "?")
	var district = location.get("district_id", "?")
	
	button.text = "  %s  |  Type: %s  |  District: %s" % [name, type_val, district]
	button.add_theme_font_size_override("font_size", 14)
	
	var loc_id = location.get("id", "")
	button.pressed.connect(_on_location_selected.bind(loc_id))
	
	return button

func _load_organizations():
	_clear_list(orgs_list)
	
	var db_orgs = DB.get_all_organizations()
	
	if db_orgs.size() == 0:
		var label = _create_empty_label("No organizations found.")
		orgs_list.add_child(label)
		return
	
	for org in db_orgs:
		var item = _create_org_item(org)
		orgs_list.add_child(item)

func _create_org_item(org: Dictionary) -> Control:
	var button = Button.new()
	button.custom_minimum_size = Vector2(0, 40)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	var name = org.get("name", "Unknown")
	var type_val = org.get("type", "?")
	
	button.text = "  %s  |  Type: %s" % [name, type_val]
	button.add_theme_font_size_override("font_size", 14)
	
	var org_id = org.get("id", "")
	button.pressed.connect(_on_org_selected.bind(org_id))
	
	return button

func _load_events():
	_clear_list(events_list)
	
	var db_events = DB.get_all_events()
	
	if db_events.size() == 0:
		var label = _create_empty_label("No events found.")
		events_list.add_child(label)
		return
	
	for event in db_events:
		var item = _create_event_item(event)
		events_list.add_child(item)

func _create_event_item(event: Dictionary) -> Control:
	var button = Button.new()
	button.custom_minimum_size = Vector2(0, 40)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	var event_type = event.get("type", "Unknown")
	var timestamp = event.get("timestamp", 0)
	
	button.text = "  %s  |  Type: %s" % [_format_timestamp(timestamp), event_type]
	button.add_theme_font_size_override("font_size", 14)
	
	var event_id = event.get("id", "")
	button.pressed.connect(_on_event_selected.bind(event_id))
	
	return button

func _load_statistics():
	_clear_list(stats_list)
	
	var npc_count = DB.get_all_npcs().size()
	var location_count = DB.get_all_locations().size()
	var org_count = DB.get_all_organizations().size()
	var event_count = DB.get_all_events().size()
	var relationship_count = DB.get_all_relationships().size()
	
	var stats = [
		"NPCs: %d" % npc_count,
		"Locations: %d" % location_count,
		"Organizations: %d" % org_count,
		"Events: %d" % event_count,
		"Relationships: %d" % relationship_count,
	]
	
	for stat in stats:
		var label = Label.new()
		label.text = stat
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
		stats_list.add_child(label)
		
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 10)
		stats_list.add_child(spacer)

func _on_npc_selected(npc_id: String):
	var npc = DB.get_npc(npc_id)
	if npc.is_empty():
		return
	
	current_selection = npc
	current_selection_type = "NPC"
	_display_npc_details(npc)

func _on_location_selected(location_id: String):
	var location = DB.get_location(location_id)
	if location.is_empty():
		return
	
	current_selection = location
	current_selection_type = "Location"
	_display_location_details(location)

func _on_org_selected(org_id: String):
	var org = DB.get_organization(org_id)
	if org.is_empty():
		return
	
	current_selection = org
	current_selection_type = "Organization"
	_display_org_details(org)

func _on_event_selected(event_id: String):
	var event = DB.get_event(event_id)
	if event.is_empty():
		return
	
	current_selection = event
	current_selection_type = "Event"
	_display_event_details(event)

func _display_npc_details(npc: Dictionary):
	detail_panel.visible = true
	_clear_detail()
	
	_add_detail_header("NPC Details: %s" % npc.get("name", "Unknown"))
	_add_detail_section("Basic Info", {
		"ID": npc.get("id", ""),
		"Name": npc.get("name", ""),
		"Age": npc.get("definite", {}).get("age", "?"),
		"Gender": npc.get("definite", {}).get("gender", "?"),
		"Alive": "Yes" if npc.get("definite", {}).get("alive", true) else "No"
	})
	
	var identity = npc.get("identity", {})
	if not identity.is_empty():
		_add_detail_section("Identity", identity)
	
	var personality = npc.get("personality", {})
	if not personality.is_empty():
		_add_detail_section("Personality", personality)
	
	var status = npc.get("status", {})
	if not status.is_empty():
		_add_detail_section("Status", status)
	
	# Get relationships
	var relationships = DB.get_relationships_for_npc(npc.get("id", ""))
	if relationships.size() > 0:
		_add_detail_text("\n[RELATIONSHIPS]", 16, Color(0.9, 0.85, 0.6, 1))
		for rel in relationships:
			var other_id = rel.get("npc_b_id", "")
			var other_npc = DB.get_npc(other_id)
			var rel_type = rel.get("relationship_type", "unknown")
			_add_detail_text("  → %s: %s" % [rel_type.capitalize(), other_npc.get("name", "Unknown")], 14)

func _display_location_details(location: Dictionary):
	detail_panel.visible = true
	_clear_detail()
	
	_add_detail_header("Location: %s" % location.get("name", "Unknown"))
	_add_detail_section("Basic Info", {
		"ID": location.get("id", ""),
		"Name": location.get("name", ""),
		"Type": location.get("type", ""),
		"District": location.get("district_id", ""),
		"Parent": location.get("parent_id", "None")
	})
	
	var features = location.get("features", {})
	if not features.is_empty():
		_add_detail_section("Features", features)

func _display_org_details(org: Dictionary):
	detail_panel.visible = true
	_clear_detail()
	
	_add_detail_header("Organization: %s" % org.get("name", "Unknown"))
	_add_detail_section("Basic Info", {
		"ID": org.get("id", ""),
		"Name": org.get("name", ""),
		"Type": org.get("type", ""),
		"HQ Location": org.get("hq_location_id", "None")
	})
	
	var effective = org.get("effective", {})
	if not effective.is_empty():
		_add_detail_section("Effective Values", effective)

func _display_event_details(event: Dictionary):
	detail_panel.visible = true
	_clear_detail()
	
	_add_detail_header("Event: %s" % event.get("type", "Unknown"))
	_add_detail_section("Basic Info", {
		"ID": event.get("id", ""),
		"Type": event.get("type", ""),
		"Timestamp": _format_timestamp(event.get("timestamp", 0)),
		"Location": event.get("location_id", "None")
	})
	
	var participants = event.get("participants", [])
	if participants.size() > 0:
		_add_detail_text("\n[PARTICIPANTS]", 16, Color(0.9, 0.85, 0.6, 1))
		for p_id in participants:
			var npc = DB.get_npc(p_id)
			_add_detail_text("  → %s" % npc.get("name", "Unknown"), 14)
	
	var description = event.get("description", "")
	if description != "":
		_add_detail_text("\n[DESCRIPTION]", 16, Color(0.9, 0.85, 0.6, 1))
		_add_detail_text(description, 14)

func _add_detail_header(text: String):
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6, 1))
	detail_content.add_child(label)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 15)
	detail_content.add_child(spacer)

func _add_detail_section(title: String, data: Dictionary):
	var title_label = Label.new()
	title_label.text = "[%s]" % title.to_upper()
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6, 1))
	detail_content.add_child(title_label)
	
	for key in data.keys():
		var value_label = Label.new()
		value_label.text = "  %s: %s" % [key, str(data[key])]
		value_label.add_theme_font_size_override("font_size", 14)
		value_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
		detail_content.add_child(value_label)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 15)
	detail_content.add_child(spacer)

func _add_detail_text(text: String, size: int = 14, color: Color = Color(0.9, 0.9, 0.9, 1)):
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	detail_content.add_child(label)

func _clear_detail():
	for child in detail_content.get_children():
		child.queue_free()

func _clear_list(list: Control):
	for child in list.get_children():
		child.queue_free()

func _create_empty_label(text: String) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
	return label

func _format_timestamp(timestamp: int) -> String:
	var date = Time.get_datetime_dict_from_unix_time(timestamp)
	return "%04d-%02d-%02d %02d:%02d" % [date.year, date.month, date.day, date.hour, date.minute]

func _on_tab_changed(tab: int):
	# Hide detail panel when switching tabs
	detail_panel.visible = false

func _on_refresh_pressed():
	_load_all_data()
	detail_panel.visible = false

func _on_back_pressed():
	GameState.exit_chronicles()
