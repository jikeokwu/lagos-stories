extends Node
## WorldManager - Manages world metadata and directory structure
## Handles per-world database storage and metadata persistence

const WORLDS_DIR = "user://worlds"
const WORLDS_LIST_FILE = "worlds_list.json"
const METADATA_FILE = "metadata.json"

# ============================================================
# DIRECTORY MANAGEMENT
# ============================================================

## Create directory structure for a new world
func create_world_directory(world_id: String) -> bool:
	var world_path = "%s/%s" % [WORLDS_DIR, world_id]
	
	if not DirAccess.dir_exists_absolute(world_path):
		var error = DirAccess.make_dir_recursive_absolute(world_path)
		if error != OK:
			push_error("[WorldManager] Failed to create world directory: %s" % world_path)
			return false
		print("[WorldManager] Created world directory: %s" % world_path)
	
	return true

## Get full path to world directory
func get_world_directory(world_id: String) -> String:
	return "%s/%s" % [WORLDS_DIR, world_id]

## Get database path for a world
func get_world_db_path(world_id: String) -> String:
	return DB.get_world_db_path(world_id)

# ============================================================
# METADATA OPERATIONS
# ============================================================

## Save world metadata to JSON file
func save_world_metadata(world_id: String, metadata: Dictionary) -> bool:
	var world_dir = get_world_directory(world_id)
	var metadata_path = "%s/%s" % [world_dir, METADATA_FILE]
	
	var file = FileAccess.open(metadata_path, FileAccess.WRITE)
	if file == null:
		push_error("[WorldManager] Failed to open metadata file for writing: %s" % metadata_path)
		return false
	
	var json_string = JSON.stringify(metadata, "\t")
	file.store_string(json_string)
	file.close()
	
	print("[WorldManager] Saved metadata for world: %s" % world_id)
	return true

## Load world metadata from JSON file
func load_world_metadata(world_id: String) -> Dictionary:
	var world_dir = get_world_directory(world_id)
	var metadata_path = "%s/%s" % [world_dir, METADATA_FILE]
	
	if not FileAccess.file_exists(metadata_path):
		print("[WorldManager] Metadata file not found: %s" % metadata_path)
		return {}
	
	var file = FileAccess.open(metadata_path, FileAccess.READ)
	if file == null:
		push_error("[WorldManager] Failed to open metadata file: %s" % metadata_path)
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		push_error("[WorldManager] Failed to parse metadata JSON: %s" % json.get_error_message())
		return {}
	
	var metadata = json.get_data()
	if not metadata is Dictionary:
		push_error("[WorldManager] Metadata is not a dictionary")
		return {}
	
	return metadata

# ============================================================
# WORLD LIST MANAGEMENT
# ============================================================

## Get all saved worlds
func get_all_worlds() -> Array:
	var list_path = "%s/%s" % [WORLDS_DIR, WORLDS_LIST_FILE]
	
	if not FileAccess.file_exists(list_path):
		# If list doesn't exist, scan directories and create it
		return _scan_world_directories()
	
	var file = FileAccess.open(list_path, FileAccess.READ)
	if file == null:
		push_error("[WorldManager] Failed to open worlds list file")
		return []
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		push_error("[WorldManager] Failed to parse worlds list JSON")
		return []
	
	var worlds = json.get_data()
	if not worlds is Array:
		return []
	
	return worlds

## Add world to list (or update if exists)
func add_world_to_list(world_metadata: Dictionary) -> bool:
	var worlds = get_all_worlds()
	var world_id = world_metadata.get("id", "")
	
	if world_id.is_empty():
		push_error("[WorldManager] Cannot add world without ID")
		return false
	
	# Remove existing entry if present
	for i in range(worlds.size()):
		if worlds[i].get("id", "") == world_id:
			worlds[i] = world_metadata
			return _save_worlds_list(worlds)
	
	# Add new entry
	worlds.append(world_metadata)
	return _save_worlds_list(worlds)

## Remove world from list
func remove_world_from_list(world_id: String) -> bool:
	var worlds = get_all_worlds()
	
	for i in range(worlds.size()):
		if worlds[i].get("id", "") == world_id:
			worlds.remove_at(i)
			return _save_worlds_list(worlds)
	
	return true  # Already removed or never existed

## Save worlds list to file
func _save_worlds_list(worlds: Array) -> bool:
	# Ensure worlds directory exists
	if not DirAccess.dir_exists_absolute(WORLDS_DIR):
		var error = DirAccess.make_dir_recursive_absolute(WORLDS_DIR)
		if error != OK:
			push_error("[WorldManager] Failed to create worlds directory")
			return false
	
	var list_path = "%s/%s" % [WORLDS_DIR, WORLDS_LIST_FILE]
	var file = FileAccess.open(list_path, FileAccess.WRITE)
	if file == null:
		push_error("[WorldManager] Failed to open worlds list for writing")
		return false
	
	var json_string = JSON.stringify(worlds, "\t")
	file.store_string(json_string)
	file.close()
	
	return true

## Scan world directories and build list from metadata files
func _scan_world_directories() -> Array:
	var worlds = []
	
	if not DirAccess.dir_exists_absolute(WORLDS_DIR):
		return []
	
	var dir = DirAccess.open(WORLDS_DIR)
	if dir == null:
		return []
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if dir.current_is_dir() and not file_name.begins_with("."):
			var world_id = file_name
			var metadata = load_world_metadata(world_id)
			if not metadata.is_empty():
				worlds.append(metadata)
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	# Save the scanned list
	_save_worlds_list(worlds)
	
	return worlds

# ============================================================
# WORLD DELETION
# ============================================================

## Delete a world (removes directory and all files)
func delete_world(world_id: String) -> bool:
	var world_dir = get_world_directory(world_id)
	
	if not DirAccess.dir_exists_absolute(world_dir):
		print("[WorldManager] World directory does not exist: %s" % world_dir)
		return false
	
	# Remove from list first
	remove_world_from_list(world_id)
	
	# Delete directory recursively
	var dir = DirAccess.open(world_dir)
	if dir == null:
		push_error("[WorldManager] Failed to open world directory for deletion")
		return false
	
	# Delete all files in directory
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir():
			dir.remove(file_name)
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	# Remove directory itself
	var error = DirAccess.remove_absolute(world_dir)
	if error != OK:
		push_error("[WorldManager] Failed to remove world directory: %s" % world_dir)
		return false
	
	print("[WorldManager] Deleted world: %s" % world_id)
	return true

# ============================================================
# UTILITY FUNCTIONS
# ============================================================

## Check if world exists
func world_exists(world_id: String) -> bool:
	var world_dir = get_world_directory(world_id)
	return DirAccess.dir_exists_absolute(world_dir)

## Get world metadata summary (for display in lists)
func get_world_summary(world_id: String) -> Dictionary:
	var metadata = load_world_metadata(world_id)
	if metadata.is_empty():
		return {}
	
	return {
		"id": metadata.get("id", ""),
		"name": metadata.get("name", "Unnamed World"),
		"created_at": metadata.get("created_at", 0),
		"last_played": metadata.get("last_played", 0),
		"stats": metadata.get("stats", {})
	}

