extends RefCounted
## Item Factory - Creates UI items for lists (NPCs, locations, organizations, events)

## Create an NPC list item button
static func create_npc_item(npc: Dictionary, selection_callback: Callable) -> Control:
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
	button.pressed.connect(selection_callback.bind(npc_id))
	
	return button

## Create a location list item button
static func create_location_item(location: Dictionary, selection_callback: Callable) -> Control:
	var button = Button.new()
	button.custom_minimum_size = Vector2(0, 40)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	var name = location.get("name", "Unknown")
	var type_val = location.get("type", "?")
	var district = location.get("district_id", "?")
	
	button.text = "  %s  |  Type: %s  |  District: %s" % [name, type_val, district]
	button.add_theme_font_size_override("font_size", 14)
	
	var loc_id = location.get("id", "")
	button.pressed.connect(selection_callback.bind(loc_id))
	
	return button

## Create an organization list item button
static func create_org_item(org: Dictionary, selection_callback: Callable) -> Control:
	var button = Button.new()
	button.custom_minimum_size = Vector2(0, 40)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	var name = org.get("name", "Unknown")
	var type_val = org.get("type", "?")
	
	button.text = "  %s  |  Type: %s" % [name, type_val]
	button.add_theme_font_size_override("font_size", 14)
	
	var org_id = org.get("id", "")
	button.pressed.connect(selection_callback.bind(org_id))
	
	return button

## Create an event list item button
static func create_event_item(event: Dictionary, selection_callback: Callable, timestamp_formatter: Callable) -> Control:
	var button = Button.new()
	button.custom_minimum_size = Vector2(0, 40)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	var event_type = event.get("type", "Unknown")
	var timestamp = event.get("timestamp", 0)
	
	button.text = "  %s  |  Type: %s" % [timestamp_formatter.call(timestamp), event_type]
	button.add_theme_font_size_override("font_size", 14)
	
	var event_id = event.get("id", "")
	button.pressed.connect(selection_callback.bind(event_id))
	
	return button

## Create an empty state label
static func create_empty_label(text: String) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
	return label

