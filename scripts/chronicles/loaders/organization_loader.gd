extends RefCounted
## Organization Loader - Loads organization data into list container

const ListUtils = preload("res://scripts/chronicles/ui/list_utils.gd")

static func load_organizations(list_container: Control, item_factory, empty_label_factory) -> void:
	ListUtils.clear_list(list_container)
	
	var db_orgs = DB.get_all_organizations()
	
	if db_orgs.size() == 0:
		var label = empty_label_factory.call("No organizations found.")
		list_container.add_child(label)
		return
	
	for org in db_orgs:
		var item = item_factory.call(org)
		list_container.add_child(item)

