extends RefCounted
## Location Loader - Loads location data into list container

const ListUtils = preload("res://scripts/chronicles/ui/list_utils.gd")

static func load_locations(list_container: Control, item_factory, empty_label_factory) -> void:
	ListUtils.clear_list(list_container)
	
	var db_locations = DB.get_all_locations()
	
	if db_locations.size() == 0:
		var label = empty_label_factory.call("No locations found.")
		list_container.add_child(label)
		return
	
	for location in db_locations:
		var item = item_factory.call(location)
		list_container.add_child(item)

