extends RefCounted
## NPC Loader - Loads NPC data into list container

const ListUtils = preload("res://scripts/chronicles/ui/list_utils.gd")

static func load_npcs(list_container: Control, item_factory, empty_label_factory) -> void:
	ListUtils.clear_list(list_container)
	
	var db_npcs = DB.get_all_npcs()
	
	if db_npcs.size() == 0:
		var label = empty_label_factory.call("No NPCs found. Generate a world first.")
		list_container.add_child(label)
		return
	
	for npc in db_npcs:
		var item = item_factory.call(npc)
		list_container.add_child(item)

