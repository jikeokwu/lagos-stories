extends RefCounted
## Event Loader - Loads event data into list container

const ListUtils = preload("res://scripts/chronicles/ui/list_utils.gd")

static func load_events(list_container: Control, item_factory, empty_label_factory) -> void:
	ListUtils.clear_list(list_container)
	
	var db_events = DB.get_all_events()
	
	if db_events.size() == 0:
		var label = empty_label_factory.call("No events found.")
		list_container.add_child(label)
		return
	
	for event in db_events:
		var item = item_factory.call(event)
		list_container.add_child(item)

