extends RefCounted
## Statistics Loader - Loads statistics into list container

const ListUtils = preload("res://scripts/chronicles/ui/list_utils.gd")

static func load_statistics(list_container: Control) -> void:
	ListUtils.clear_list(list_container)
	
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
		list_container.add_child(label)
		
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 10)
		list_container.add_child(spacer)

