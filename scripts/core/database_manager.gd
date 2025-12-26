extends Node
## DatabaseManager - Core database interface for Lagos Stories
## Handles all SQLite operations and provides high-level API for game systems

## Singleton instance
var db = null  # Will be SQLite instance
var db_path: String = ""
var is_initialized: bool = false

## Database file name
const DB_FILE_NAME = "lagos_stories.db"

# ============================================================
# INITIALIZATION
# ============================================================

func _ready() -> void:
	print("[DatabaseManager] Ready - call initialize() to set up database")

## Initialize the database connection and create tables
## If already initialized with a different path, closes current connection first
func initialize(custom_path: String = "") -> bool:
	# If already initialized with same path, return success
	var target_path = custom_path if not custom_path.is_empty() else "user://database/" + DB_FILE_NAME
	if is_initialized and db_path == target_path:
		print("[DatabaseManager] Already initialized with same path")
		return true
	
	# Close existing connection if switching worlds
	if is_initialized:
		print("[DatabaseManager] Closing existing database connection")
		close_database()
	
	# Determine database path
	if custom_path.is_empty():
		db_path = "user://database/" + DB_FILE_NAME
	else:
		db_path = custom_path
	
	# Ensure directory exists
	var dir_path = db_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)
		print("[DatabaseManager] Created database directory: ", dir_path)
	
	# Initialize SQLite (GDExtension class)
	db = SQLite.new()
	db.path = db_path
	db.verbosity_level = 0  # Quiet mode
	
	# Open database
	if not db.open_db():
		push_error("[DatabaseManager] Failed to open database at: " + db_path)
		return false
	
	print("[DatabaseManager] Database opened successfully at: ", db_path)
	
	# Enable foreign keys
	db.query("PRAGMA foreign_keys = ON;")
	
	# Create tables from schema
	if not _create_tables():
		push_error("[DatabaseManager] Failed to create tables")
		return false
	
	is_initialized = true
	print("[DatabaseManager] Database initialized successfully")
	return true

## Create all tables from schema file
func _create_tables() -> bool:
	var schema_path = "res://database/schema.sql"
	
	# Read schema file
	var file = FileAccess.open(schema_path, FileAccess.READ)
	if file == null:
		push_error("[DatabaseManager] Cannot open schema file: " + schema_path)
		return false
	
	var schema_sql = file.get_as_text()
	file.close()
	
	# Remove PRAGMA statements - they cause issues
	schema_sql = schema_sql.replace("PRAGMA foreign_keys = ON;", "")
	
	# Parse SQL statements properly (handle BEGIN...END blocks)
	var statements = _parse_sql_statements(schema_sql)
	var executed_count = 0
	var failed_count = 0
	
	for statement in statements:
		var trimmed = statement.strip_edges()
		if trimmed.is_empty() or trimmed.begins_with("--") or trimmed.begins_with("PRAGMA"):
			continue
		
		# Use db.query() - returns true on success
		var success = db.query(trimmed)
		
		if success:
			executed_count += 1
		else:
			failed_count += 1
			var preview = trimmed.substr(0, 60).replace("\n", " ")
			print("[DatabaseManager] Failed to execute: " + preview + "...")
	
	print("[DatabaseManager] Executed %d SQL statements (%d failed)" % [executed_count, failed_count])
	
	# Verify tables were created
	if db.query("SELECT COUNT(*) as count FROM sqlite_master WHERE type='table';"):
		var result = db.query_result
		if result and result.size() > 0:
			var count = result[0].get("count", 0)
			if count >= 12:
				print("[DatabaseManager] All tables created successfully (%d tables)" % count)
				return true
			else:
				push_error("[DatabaseManager] Only %d tables created, expected 12" % count)
				return false
	
	push_error("[DatabaseManager] Could not verify table creation")
	return false

## Parse SQL statements, handling BEGIN...END blocks properly
func _parse_sql_statements(sql: String) -> Array:
	var statements = []
	var current_statement = ""
	var in_begin_end = false
	var lines = sql.split("\n")
	
	for line in lines:
		var trimmed = line.strip_edges()
		
		# Skip comments and empty lines
		if trimmed.is_empty() or trimmed.begins_with("--"):
			continue
		
		# Track BEGIN...END blocks
		if trimmed.begins_with("BEGIN"):
			in_begin_end = true
		
		# Add line to current statement
		current_statement += line + "\n"
		
		# Check if statement ends
		if trimmed.ends_with(";"):
			if in_begin_end and trimmed == "END;":
				in_begin_end = false
				statements.append(current_statement.strip_edges())
				current_statement = ""
			elif not in_begin_end:
				statements.append(current_statement.strip_edges())
				current_statement = ""
	
	# Add any remaining statement
	if not current_statement.strip_edges().is_empty():
		statements.append(current_statement.strip_edges())
	
	return statements

## Close database connection
func close_database() -> void:
	if db != null:
		db.close_db()
		db = null
		db_path = ""
		is_initialized = false
		print("[DatabaseManager] Database closed")

## Get database path for a world ID
## Returns the standard path format: user://worlds/{world_id}/lagos_stories.db
func get_world_db_path(world_id: String) -> String:
	return "user://worlds/%s/%s" % [world_id, DB_FILE_NAME]

# ============================================================
# HELPER FUNCTIONS
# ============================================================

## Generic insert function - builds and executes INSERT query
func _insert(table: String, data: Dictionary) -> bool:
	if data.is_empty():
		push_error("[DatabaseManager] Cannot insert empty data")
		return false
	
	var columns = []
	var values = []
	
	for key in data.keys():
		columns.append(key)
		var value = data[key]
		
		# Handle different types
		if value == null:
			values.append("NULL")
		elif typeof(value) == TYPE_STRING:
			# Escape single quotes
			values.append("'%s'" % value.replace("'", "''"))
		elif typeof(value) == TYPE_DICTIONARY or typeof(value) == TYPE_ARRAY:
			# Convert to JSON
			var json_str = JSON.stringify(value).replace("'", "''")
			values.append("'%s'" % json_str)
		elif typeof(value) == TYPE_BOOL:
			values.append("1" if value else "0")
		else:
			# Numbers and other types
			values.append(str(value))
	
	var query = "INSERT INTO %s (%s) VALUES (%s);" % [
		table,
		", ".join(columns),
		", ".join(values)
	]
	
	return db.query(query)

# ============================================================
# WORLD STATE OPERATIONS
# ============================================================

## Initialize world state (must be called once per new world)
func initialize_world_state(seed: String, start_date: String = "2025-01-01", start_time: String = "08:00") -> bool:
	var global_signals = JSON.stringify({
		"economy": 55,
		"stability": 70,
		"corruption": 45,
		"public_order": 65
	})
	
	# Escape single quotes in strings
	var escaped_seed = seed.replace("'", "''")
	var escaped_signals = global_signals.replace("'", "''")
	
	var query = """
	INSERT INTO world_state (id, seed, tick, date, time, global_signals)
	VALUES (1, '%s', 0, '%s', '%s', '%s')
	ON CONFLICT(id) DO UPDATE SET
		seed = excluded.seed,
		tick = excluded.tick,
		date = excluded.date,
		time = excluded.time,
		global_signals = excluded.global_signals,
		updated_at = strftime('%%s', 'now');
	""" % [escaped_seed, start_date, start_time, escaped_signals]
	
	db.query(query)
	return true  # If query fails, subsequent operations will fail

## Get current world state
func get_world_state() -> Dictionary:
	var query = "SELECT * FROM world_state WHERE id = 1;"
	if db.query(query):
		var result = db.query_result
		if result and result.size() > 0:
			return result[0]
	return {}

## Update world tick
func increment_tick() -> bool:
	db.query("UPDATE world_state SET tick = tick + 1 WHERE id = 1;")
	return true

## Update global signals
func update_global_signals(signals: Dictionary) -> bool:
	var json_str = JSON.stringify(signals).replace("'", "''")
	var query = "UPDATE world_state SET global_signals = '%s' WHERE id = 1;" % json_str
	db.query(query)
	return true

# ============================================================
# DISTRICT OPERATIONS
# ============================================================

## Create a new district
func create_district(district_data: Dictionary) -> bool:
	return _insert("districts", district_data)

## Get district by ID
func get_district(district_id: String) -> Dictionary:
	var query = "SELECT * FROM districts WHERE id = '%s';" % district_id
	if db.query(query):
		var result = db.query_result
		if result and result.size() > 0:
			return result[0]
	return {}

## Get all districts
func get_all_districts() -> Array:
	var query = "SELECT * FROM districts;"
	if db.query(query):
		return db.query_result if db.query_result else []
	return []

## Update district metrics
func update_district_metrics(district_id: String, prosperity: int = -1, safety: int = -1, infrastructure: int = -1) -> bool:
	var updates = []
	
	if prosperity >= 0:
		updates.append("prosperity = %d" % prosperity)
	if safety >= 0:
		updates.append("safety = %d" % safety)
	if infrastructure >= 0:
		updates.append("infrastructure = %d" % infrastructure)
	
	if updates.is_empty():
		return true
	
	var query = "UPDATE districts SET %s WHERE id = '%s';" % [", ".join(updates), district_id]
	db.query(query)
	return true

# ============================================================
# NPC OPERATIONS
# ============================================================

## Create a new NPC
func create_npc(npc_data: Dictionary) -> bool:
	return _insert("npcs", npc_data)

## Get NPC by ID
func get_npc(npc_id: String) -> Dictionary:
	var query = "SELECT * FROM npcs WHERE id = '%s';" % npc_id
	if not db.query(query):
		return {}
	
	var result = db.query_result
	if not result or typeof(result) != TYPE_ARRAY or result.size() == 0:
		return {}
	
	var npc = result[0]
	# Parse JSON fields back to dictionaries
	for key in ["definite", "attributes", "appearance", "identity", "personality", "political_ideology", "skills", "resources", "status", "demographic_affinities"]:
		if key in npc and npc[key] is String:
			npc[key] = JSON.parse_string(npc[key])
	
	return npc

## Get all NPCs (with optional alive filter)
func get_all_npcs(alive_only: bool = true) -> Array:
	var query = "SELECT * FROM npcs"
	if alive_only:
		query += " WHERE json_extract(definite, '$.alive') = 1"
	query += ";"
	
	if not db.query(query):
		return []
	
	var results = db.query_result
	if not results or not (results is Array) or results.is_empty():
		return []
	
	# Parse JSON fields for each NPC
	for npc in results:
		for key in ["definite", "attributes", "appearance", "identity", "personality", "political_ideology", "skills", "resources", "status", "demographic_affinities"]:
			if key in npc and npc[key] is String:
				npc[key] = JSON.parse_string(npc[key])
	
	return results

## Get all child NPCs (under 18)
func get_all_child_npcs() -> Array:
	var query = "SELECT * FROM npcs WHERE json_extract(definite, '$.alive') = 1 AND json_extract(definite, '$.age') < 18;"
	
	if not db.query(query):
		return []
	
	var results = db.query_result
	if not results or not (results is Array) or results.is_empty():
		return []
	
	# Parse JSON fields for each NPC
	for npc in results:
		for key in ["definite", "attributes", "appearance", "identity", "personality", "political_ideology", "skills", "resources", "status", "demographic_affinities"]:
			if key in npc and npc[key] is String:
				npc[key] = JSON.parse_string(npc[key])
	
	return results

## Update NPC data
func update_npc(npc_id: String, updates: Dictionary) -> bool:
	# Convert nested dictionaries to JSON strings
	var processed_updates = updates.duplicate()
	for key in ["definite", "attributes", "appearance", "identity", "personality", "political_ideology", "skills", "resources", "status", "demographic_affinities"]:
		if key in processed_updates and processed_updates[key] is Dictionary:
			processed_updates[key] = JSON.stringify(processed_updates[key])
	
	# Build UPDATE query
	var set_clauses = []
	for key in processed_updates:
		var value = processed_updates[key]
		if value is String:
			set_clauses.append("%s = '%s'" % [key, value.replace("'", "''")])
		else:
			set_clauses.append("%s = %s" % [key, str(value)])
	
	var query = "UPDATE npcs SET %s WHERE id = '%s';" % [", ".join(set_clauses), npc_id]
	db.query(query)
	return true

## Get NPCs by location
func get_npcs_at_location(location_id: String) -> Array:
	var query = "SELECT * FROM npcs WHERE current_location_id = '%s';" % location_id
	var results = db.query(query)
	if not results:
		return []
	
	# Parse JSON fields
	for npc in results:
		for key in ["definite", "attributes", "appearance", "identity", "personality", "political_ideology", "skills", "resources", "status", "demographic_affinities"]:
			if key in npc and npc[key] is String:
				npc[key] = JSON.parse_string(npc[key])
	
	return results

# ============================================================
# RELATIONSHIP OPERATIONS
# ============================================================

## Create a relationship (directional, or bidirectional for symmetric types)
func create_relationship(source_id: String, target_id: String, rel_type: String, affection: int = 0, trust: int = 0, attraction: int = 0, respect: int = 0, formed_date: String = "") -> bool:
	# Symmetric relationship types that need both directions created automatically
	# These relationships are bidirectional by nature
	var symmetric_types = ["friend", "colleague", "neighbor", "acquaintance", "sibling", "cousin"]
	var is_symmetric = rel_type in symmetric_types
	
	# Create A→B
	var success_ab = _create_single_relationship(source_id, target_id, rel_type, affection, trust, attraction, respect, formed_date)
	
	# Create B→A for symmetric types
	if is_symmetric:
		_create_single_relationship(target_id, source_id, rel_type, affection, trust, attraction, respect, formed_date)
	
	return success_ab

## Internal helper to create a single directional relationship
func _create_single_relationship(source_id: String, target_id: String, rel_type: String, affection: int, trust: int, attraction: int, respect: int, formed_date: String) -> bool:
	# Check if relationship already exists to avoid duplicates
	var check_query = "SELECT 1 FROM relationships WHERE source_npc_id = '%s' AND target_npc_id = '%s' LIMIT 1;" % [source_id, target_id]
	if db.query(check_query) and db.query_result and db.query_result.size() > 0:
		return true  # Already exists
	
	var data = {
		"source_npc_id": source_id,
		"target_npc_id": target_id,
		"type": rel_type,
		"affection": affection,
		"trust": trust,
		"attraction": attraction,
		"respect": respect
	}
	
	if not formed_date.is_empty():
		data["formed_date"] = formed_date
	
	return _insert("relationships", data)

## Calculate attraction between two NPCs (directional)
## Returns -100 to 100 based on orientation, attributes, status
func calculate_attraction(source_id: String, target_id: String) -> int:
	var source = get_npc(source_id)
	var target = get_npc(target_id)
	
	if source.is_empty() or target.is_empty():
		return 0
	
	var source_gender = source.definite.get("gender", "male")
	var target_gender = target.definite.get("gender", "male")
	var source_orientation = source.definite.get("orientation", 100)  # Default hetero
	
	# Base attraction from orientation compatibility
	var orientation_match = 0
	var same_gender = (source_gender == target_gender)
	
	if same_gender:
		# Same gender: attraction increases as orientation goes negative
		orientation_match = -source_orientation  # -100 becomes 100, 100 becomes -100
	else:
		# Different gender: attraction increases as orientation goes positive
		orientation_match = source_orientation  # 100 stays 100, -100 becomes -100
	
	# Normalize to 0-100
	var orientation_factor = (orientation_match + 100) / 2.0  # Maps -100...100 to 0...100
	
	# Attribute factors (beauty, charisma contribute most)
	var target_attrs = target.get("attributes", {})
	var beauty = target_attrs.get("beauty", 50)
	var charisma = target_attrs.get("charisma", 50)
	var attribute_score = (beauty * 0.6 + charisma * 0.4)  # 0-100
	
	# Status factor (reputation)
	var target_status = target.get("status", {})
	var reputation = target_status.get("reputation", 50)
	
	# Weighted formula
	var attraction = (
		orientation_factor * 0.50 +  # Orientation is 50% of attraction
		attribute_score * 0.35 +      # Attributes are 35%
		reputation * 0.15             # Reputation is 15%
	)
	
	# Add some randomness (-10 to +10)
	attraction += randf_range(-10, 10)
	
	# Map to -100 to 100 scale (where 0-50 is negative, 50+ is positive)
	var final_attraction = int((attraction - 50) * 2)
	
	return clampi(final_attraction, -100, 100)

## Get all relationships
func get_all_relationships() -> Array:
	var query = "SELECT * FROM relationships;"
	if not db.query(query):
		return []
	return db.query_result if db.query_result else []

## Get all relationships for an NPC (both outgoing and incoming)
func get_npc_relationships(npc_id: String) -> Dictionary:
	var query_out = "SELECT * FROM relationships WHERE source_npc_id = '%s';" % npc_id
	var query_in = "SELECT * FROM relationships WHERE target_npc_id = '%s';" % npc_id
	
	var outgoing = db.query(query_out)
	var incoming = db.query(query_in)
	
	return {
		"outgoing": outgoing if outgoing else [], # What this NPC feels about others
		"incoming": incoming if incoming else []   # What others feel about this NPC
	}

## Get relationships for an NPC (returns array format expected by chronicles)
func get_relationships_for_npc(npc_id: String) -> Array:
	var query_out = "SELECT * FROM relationships WHERE source_npc_id = '%s';" % npc_id
	var query_in = "SELECT * FROM relationships WHERE target_npc_id = '%s';" % npc_id
	
	var relationships = []
	
	# Get outgoing relationships (this NPC -> others)
	if db.query(query_out) and db.query_result:
		var outgoing_results = db.query_result.duplicate()
		for rel in outgoing_results:
			var formatted_rel = rel.duplicate()
			formatted_rel["npc_b_id"] = rel.get("target_npc_id", "")
			formatted_rel["relationship_type"] = rel.get("type", "unknown")
			relationships.append(formatted_rel)
	
	# Get incoming relationships (others -> this NPC)
	if db.query(query_in) and db.query_result:
		var incoming_results = db.query_result.duplicate()
		for rel in incoming_results:
			var formatted_rel = rel.duplicate()
			formatted_rel["npc_b_id"] = rel.get("source_npc_id", "")
			formatted_rel["relationship_type"] = rel.get("type", "unknown")
			relationships.append(formatted_rel)
	
	return relationships

## Get relationship between two NPCs (directional)
func get_relationship(source_id: String, target_id: String) -> Dictionary:
	var query = "SELECT * FROM relationships WHERE source_npc_id = '%s' AND target_npc_id = '%s';" % [source_id, target_id]
	if not db.query(query):
		return {}
	
	var result = db.query_result
	if not result or typeof(result) != TYPE_ARRAY or result.size() == 0:
		return {}
	return result[0]

## Update relationship values
func update_relationship(source_id: String, target_id: String, updates: Dictionary) -> bool:
	var set_clauses = []
	for key in updates:
		set_clauses.append("%s = %s" % [key, updates[key]])
	
	var query = "UPDATE relationships SET %s WHERE source_npc_id = '%s' AND target_npc_id = '%s';" % [", ".join(set_clauses), source_id, target_id]
	db.query(query)
	return true

## Apply delta to relationship values
func modify_relationship(source_id: String, target_id: String, affection_delta: int = 0, trust_delta: int = 0, attraction_delta: int = 0, respect_delta: int = 0) -> bool:
	var query = """
	UPDATE relationships 
	SET 
		affection = MAX(-100, MIN(100, affection + %d)),
		trust = MAX(-100, MIN(100, trust + %d)),
		attraction = MAX(-100, MIN(100, attraction + %d)),
		respect = MAX(-100, MIN(100, respect + %d))
	WHERE source_npc_id = '%s' AND target_npc_id = '%s';
	""" % [affection_delta, trust_delta, attraction_delta, respect_delta, source_id, target_id]
	db.query(query)
	return true

# ============================================================
# LOCATION OPERATIONS
# ============================================================

## Create a new location
func create_location(location_data: Dictionary) -> bool:
	return _insert("locations", location_data)

## Get location by ID
func get_location(location_id: String) -> Dictionary:
	var query = "SELECT * FROM locations WHERE id = '%s';" % location_id
	var result = db.query(query)
	if not result or result.is_empty():
		return {}
	
	var location = result[0]
	# Parse JSON fields
	for key in ["physical_properties", "access", "reputation", "features", "current_occupants"]:
		if key in location and location[key] is String:
			location[key] = JSON.parse_string(location[key])
	
	return location

## Get all locations in a district
func get_locations_in_district(district_id: String) -> Array:
	var query = "SELECT * FROM locations WHERE district_id = '%s';" % district_id
	if not db.query(query):
		return []
	
	var results = db.query_result if db.query_result else []
	
	# Parse JSON fields
	for location in results:
		for key in ["physical_properties", "access", "reputation", "features", "current_occupants"]:
			if key in location and location[key] is String:
				location[key] = JSON.parse_string(location[key])
	
	return results

## Get all locations
func get_all_locations() -> Array:
	var query = "SELECT * FROM locations ORDER BY district_id, id;"
	if not db.query(query):
		return []
	
	var results = db.query_result if db.query_result else []
	
	# Parse JSON fields
	for location in results:
		for key in ["physical_properties", "access", "reputation", "features", "current_occupants"]:
			if key in location and location[key] is String:
				location[key] = JSON.parse_string(location[key])
	
	return results

# ============================================================
# ORGANIZATION OPERATIONS
# ============================================================

## Create a new organization
func create_organization(org_data: Dictionary) -> bool:
	return _insert("organizations", org_data)

## Get organization by ID
func get_organization(org_id: String) -> Dictionary:
	var query = "SELECT * FROM organizations WHERE id = '%s';" % org_id
	if not db.query(query):
		return {}
	var result = db.query_result
	if not result or not (result is Array) or result.is_empty():
		return {}
	
	var org = result[0]
	# Parse JSON fields
	for key in ["pillars", "reputation", "resources", "computed_values"]:
		if key in org and org[key] is String:
			org[key] = JSON.parse_string(org[key])
	
	return org

## Get all organizations
func get_all_organizations() -> Array:
	var query = "SELECT * FROM organizations;"
	if not db.query(query):
		return []
	
	var results = db.query_result
	if not results or not (results is Array) or results.is_empty():
		return []
	
	# Parse JSON fields for each organization
	for org in results:
		for key in ["pillars", "reputation", "resources", "computed_values"]:
			if key in org and org[key] is String:
				org[key] = JSON.parse_string(org[key])
	
	return results

## Create organization membership
func create_membership(npc_id: String, org_id: String, role: String, weight: int = 1, tenure_years: int = 0, loyalty: int = 50, investment: int = 50, alignment: int = 50) -> bool:
	var data = {
		"npc_id": npc_id,
		"org_id": org_id,
		"role": role,
		"weight": weight,
		"tenure_years": tenure_years,
		"loyalty": loyalty,
		"investment": investment,
		"alignment": alignment
	}
	return _insert("organization_memberships", data)

## Get all members of an organization
## Get all memberships for an NPC
func get_npc_memberships(npc_id: String) -> Array:
	var query = "SELECT * FROM organization_memberships WHERE npc_id = '%s';" % npc_id
	if not db.query(query):
		return []
	return db.query_result if db.query_result else []

## Get all organizations an NPC belongs to
func get_npc_organizations(npc_id: String) -> Array:
	var query = "SELECT * FROM organization_memberships WHERE npc_id = '%s';" % npc_id
	if not db.query(query):
		return []
	return db.query_result if db.query_result else []

## Get all members of an organization
func get_organization_members(org_id: String) -> Array:
	var query = "SELECT npc_id, role FROM organization_memberships WHERE org_id = '%s';" % org_id
	if db.query(query):
		return db.query_result if db.query_result else []
	return []

## Get the highest-ranking member of an organization
func get_organization_leader(org_id: String) -> Dictionary:
	var query = """
		SELECT npc_id, role, weight 
		FROM organization_memberships 
		WHERE org_id = '%s' 
		ORDER BY weight DESC LIMIT 1;
	""" % org_id
	
	if db.query(query) and db.query_result and db.query_result.size() > 0:
		return db.query_result[0]
	return {}

## Get all members of an organization with full details
func get_organization_members_full(org_id: String) -> Array:
	var query = """
		SELECT m.npc_id, m.role, m.tenure_years, n.name as npc_name, 
		       json_extract(n.identity, '$.district') as district
		FROM organization_memberships m
		JOIN npcs n ON m.npc_id = n.id
		WHERE m.org_id = '%s';
	""" % org_id
	
	if db.query(query):
		return db.query_result if db.query_result else []
	return []

# ============================================================
# EVENT OPERATIONS
# ============================================================

## Create a new event
func create_event(event_data: Dictionary) -> String:
	# Convert JSON fields
	var processed_data = event_data.duplicate()
	
	# Generate ID if not provided
	if not processed_data.has("id"):
		processed_data["id"] = "evt_%d" % (Time.get_unix_time_from_system() * 1000 + randi() % 1000)
	
	for key in ["details", "impact", "consequences", "affected_nodes"]:
		if key in processed_data:
			if processed_data[key] is Dictionary or processed_data[key] is Array:
				processed_data[key] = JSON.stringify(processed_data[key])
	
	var success = _insert("events", processed_data)
	return processed_data["id"] if success else ""

## Get event by ID
func get_event(event_id: String) -> Dictionary:
	var query = "SELECT * FROM events WHERE id = '%s';" % event_id
	var result = db.query(query)
	if not result or result.is_empty():
		return {}
	
	var event = result[0]
	# Parse JSON fields
	for key in ["details", "impact", "consequences", "affected_nodes"]:
		if key in event and event[key] is String:
			event[key] = JSON.parse_string(event[key])
	
	# Map summary to description for chronicles compatibility
	if "summary" in event:
		event["description"] = event["summary"]
	
	# Get participants
	var participants_query = "SELECT entity_id FROM event_participants WHERE event_id = '%s' AND entity_type = 'npc';" % event_id
	if db.query(participants_query) and db.query_result:
		var participants = []
		for p in db.query_result:
			participants.append(p.get("entity_id", ""))
		event["participants"] = participants
	else:
		event["participants"] = []
	
	return event

## Get all events
func get_all_events() -> Array:
	var query = "SELECT * FROM events ORDER BY timestamp DESC;"
	var results = db.query(query)
	
	# Parse JSON fields and add participants
	if results:
		for event in results:
			for key in ["details", "impact", "consequences", "affected_nodes"]:
				if key in event and event[key] is String:
					event[key] = JSON.parse_string(event[key])
			
			# Map summary to description for chronicles compatibility
			if "summary" in event:
				event["description"] = event["summary"]
			
			# Get participants for this event
			var participants_query = "SELECT entity_id FROM event_participants WHERE event_id = '%s' AND entity_type = 'npc';" % event.get("id", "")
			if db.query(participants_query) and db.query_result:
				var participants = []
				for p in db.query_result:
					participants.append(p.get("entity_id", ""))
				event["participants"] = participants
			else:
				event["participants"] = []
	
	return results if results else []

## Get recent events (limit by count)
func get_recent_events(limit: int = 50) -> Array:
	var query = "SELECT * FROM events ORDER BY timestamp DESC LIMIT %d;" % limit
	var results = db.query(query)
	
	# Parse JSON fields
	if results:
		for event in results:
			for key in ["details", "impact", "consequences", "affected_nodes"]:
				if key in event and event[key] is String:
					event[key] = JSON.parse_string(event[key])
	
	return results if results else []

## Add event participant
func add_event_participant(event_id: String, entity_id: String, entity_type: String, role: String) -> bool:
	var data = {
		"event_id": event_id,
		"entity_id": entity_id,
		"entity_type": entity_type,
		"role": role
	}
	return _insert("event_participants", data)

## Get all participants of an event
func get_event_participants(event_id: String) -> Array:
	var query = "SELECT * FROM event_participants WHERE event_id = '%s';" % event_id
	var result = db.query(query)
	return result if result else []

# ============================================================
# MEMORY OPERATIONS
# ============================================================

## Create NPC memory
func create_memory(memory_data: Dictionary) -> int:
	var success = _insert("npc_memories", memory_data)
	return db.last_insert_rowid if success else -1

## Get all memories for an NPC
func get_npc_memories(npc_id: String, limit: int = 100) -> Array:
	var query = "SELECT * FROM npc_memories WHERE npc_id = '%s' ORDER BY timestamp DESC LIMIT %d;" % [npc_id, limit]
	var results = db.query(query)
	return results if results else []

## Get memories of a specific event
func get_event_memories(event_id: String) -> Array:
	var query = "SELECT * FROM npc_memories WHERE event_id = '%s';" % event_id
	var result = db.query(query)
	return result if result else []

# ============================================================
# ITEM OPERATIONS
# ============================================================

## Create a new item
func create_item(item_data: Dictionary) -> bool:
	# Convert JSON fields
	var processed_data = item_data.duplicate()
	for key in ["physical", "value", "metadata"]:
		if key in processed_data and processed_data[key] is Dictionary:
			processed_data[key] = JSON.stringify(processed_data[key])
	
	return _insert("items", processed_data)

## Get item by ID
func get_item(item_id: String) -> Dictionary:
	var query = "SELECT * FROM items WHERE id = '%s';" % item_id
	var result = db.query(query)
	if not result or result.is_empty():
		return {}
	
	var item = result[0]
	# Parse JSON fields
	for key in ["physical", "value", "metadata"]:
		if key in item and item[key] is String:
			item[key] = JSON.parse_string(item[key])
	
	return item

## Get all items owned by an NPC
func get_npc_items(npc_id: String) -> Array:
	var query = "SELECT * FROM items WHERE owner_id = '%s';" % npc_id
	var results = db.query(query)
	if not results:
		return []
	
	# Parse JSON fields
	for item in results:
		for key in ["physical", "value", "metadata"]:
			if key in item and item[key] is String:
				item[key] = JSON.parse_string(item[key])
	
	return results

# ============================================================
# UTILITY FUNCTIONS
# ============================================================

## Get all location units of a specific type
func get_location_units(type: String) -> Array:
	# Use proper SQL escaping to prevent issues
	var escaped_type = type.replace("'", "''")
	var query = "SELECT id, district_id FROM locations WHERE type = '%s' ORDER BY district_id, id;" % escaped_type
	if db.query(query):
		var result = db.query_result if db.query_result else []
		print("[DatabaseManager] Found %d locations of type '%s'" % [result.size(), type])
		return result
	print("[DatabaseManager] Query failed or returned empty for type '%s'" % type)
	return []

## Get residential units with ownership details
func get_residential_units_with_details() -> Array:
	var query = """
		SELECT l.id as location_id, l.district_id, l.access,
		       n.id as tenant_id, json_extract(n.resources, '$.annual_income') as income
		FROM locations l
		LEFT JOIN npcs n ON n.current_location_id = l.id
		WHERE l.type = 'residential_unit';
	"""
	if db.query(query):
		return db.query_result if db.query_result else []
	return []

## Get commercial units with ownership details
func get_commercial_units_with_details() -> Array:
	var query = """
		SELECT l.id as location_id, l.access, o.id as org_id, 
		       json_extract(o.resources, '$.liquid_assets') as org_assets
		FROM locations l
		LEFT JOIN organizations o ON o.location_id = l.id
		WHERE l.type = 'commercial_unit';
	"""
	if db.query(query):
		return db.query_result if db.query_result else []
	return []

## Get all rented units with landlord/tenant info
func get_rented_units_info() -> Array:
	var query = """
		SELECT json_extract(access, '$.owner_npc_id') as landlord_id,
		       json_extract(access, '$.tenant_npc_id') as tenant_npc_id,
		       json_extract(access, '$.tenant_org_id') as tenant_org_id,
		       json_extract(access, '$.ownership_type') as ownership_type
		FROM locations
		WHERE json_extract(access, '$.ownership_type') = 'rented';
	"""
	if db.query(query):
		return db.query_result if db.query_result else []
	return []

## Update location access/ownership
func update_location_access(location_id: String, access_data: Dictionary) -> bool:
	var json_str = JSON.stringify(access_data).replace("'", "''")
	var query = "UPDATE locations SET access = '%s' WHERE id = '%s';" % [json_str, location_id]
	return db.query(query)

## Get single adult NPCs for matchmaking
func get_single_adults() -> Array:
	var query = """
		SELECT n.id, json_extract(n.definite, '$.age') as age,
		       json_extract(n.definite, '$.gender') as gender,
		       json_extract(n.definite, '$.orientation') as orientation,
		       json_extract(n.identity, '$.district') as district
		FROM npcs n
		WHERE NOT EXISTS (
			SELECT 1 FROM relationships r 
			WHERE (r.source_npc_id = n.id OR r.target_npc_id = n.id)
			AND r.type = 'spouse'
		)
		AND json_extract(n.definite, '$.age') >= 18;
	"""
	if db.query(query):
		return db.query_result if db.query_result else []
	return []

## Get isolated NPCs (fewer than N relationships)
func get_isolated_npcs(min_rels: int = 3) -> Array:
	var query = """
		SELECT n.id, json_extract(n.identity, '$.district') as district,
		       (SELECT COUNT(*) FROM relationships r WHERE r.source_npc_id = n.id OR r.target_npc_id = n.id) as rel_count
		FROM npcs n
		GROUP BY n.id
		HAVING rel_count < %d;
	""" % min_rels
	if db.query(query):
		return db.query_result if db.query_result else []
	return []

## Get NPC district
func get_npc_district(npc_id: String) -> String:
	var query = "SELECT json_extract(identity, '$.district') as district FROM npcs WHERE id = '%s';" % npc_id
	if db.query(query) and db.query_result and db.query_result.size() > 0:
		return db.query_result[0].district
	return ""

## Get NPC basic info (id, district)
func get_all_npcs_basic() -> Array:
	var query = "SELECT id, json_extract(identity, '$.district') as district FROM npcs;"
	if db.query(query):
		return db.query_result if db.query_result else []
	return []

## Get all existing relationship pairs (to avoid duplicates)
func get_all_relationship_pairs() -> Dictionary:
	var pairs = {}
	var query = "SELECT source_npc_id, target_npc_id FROM relationships;"
	if db.query(query) and db.query_result:
		for rel in db.query_result:
			pairs["%s-%s" % [rel.source_npc_id, rel.target_npc_id]] = true
	return pairs

## Get NPCs for birth event generation
func get_npcs_for_birth_events() -> Array:
	var query = """
		SELECT n.id, n.name, json_extract(n.definite, '$.age') as age,
		       json_extract(n.identity, '$.district') as district
		FROM npcs n;
	"""
	if db.query(query):
		return db.query_result if db.query_result else []
	return []

## Get parent-child relationships map
func get_parent_child_map() -> Dictionary:
	var map = {}
	var query = "SELECT source_npc_id, target_npc_id FROM relationships WHERE type = 'parent';"
	if db.query(query) and db.query_result:
		for rel in db.query_result:
			if not map.has(rel.target_npc_id):
				map[rel.target_npc_id] = []
			map[rel.target_npc_id].append(rel.source_npc_id)
	return map

## Get married couples
func get_married_couples() -> Array:
	var query = """
		SELECT r.source_npc_id, r.target_npc_id,
		       n1.name as spouse1_name, n2.name as spouse2_name,
		       json_extract(n1.definite, '$.age') as age1,
		       json_extract(n2.definite, '$.age') as age2,
		       json_extract(n1.identity, '$.district') as district
		FROM relationships r
		JOIN npcs n1 ON r.source_npc_id = n1.id
		JOIN npcs n2 ON r.target_npc_id = n2.id
		WHERE r.type = 'spouse'
		GROUP BY MIN(r.source_npc_id, r.target_npc_id), MAX(r.source_npc_id, r.target_npc_id);
	"""
	if db.query(query):
		return db.query_result if db.query_result else []
	return []

## Get oldest child age for parents (for marriage date calculation)
func get_oldest_child_ages() -> Dictionary:
	var ages = {}
	var query = """
		SELECT r.source_npc_id as parent, json_extract(n.definite, '$.age') as child_age
		FROM relationships r
		JOIN npcs n ON r.target_npc_id = n.id
		WHERE r.type = 'parent';
	"""
	if db.query(query) and db.query_result:
		for row in db.query_result:
			if not ages.has(row.parent):
				ages[row.parent] = 999
			if row.child_age != null and row.child_age < ages[row.parent]:
				ages[row.parent] = row.child_age
	return ages

## Get all employments for event generation
func get_all_employments() -> Array:
	var query = """
		SELECT m.npc_id, m.org_id, m.role, m.tenure_years,
		       n.name as npc_name, o.name as org_name,
		       json_extract(n.identity, '$.district') as district
		FROM organization_memberships m
		JOIN npcs n ON m.npc_id = n.id
		JOIN organizations o ON m.org_id = o.id;
	"""
	if db.query(query):
		return db.query_result if db.query_result else []
	return []

## Get key relationships for event generation
func get_relationships_for_events(types: Array, limit: int = 500) -> Array:
	var type_list = "'" + "','".join(types) + "'"
	var query = """
		SELECT r.source_npc_id, r.target_npc_id, r.type,
		       n1.name as name1, n2.name as name2,
		       json_extract(n1.identity, '$.district') as district
		FROM relationships r
		JOIN npcs n1 ON r.source_npc_id = n1.id
		JOIN npcs n2 ON r.target_npc_id = n2.id
		WHERE r.type IN (%s)
		AND r.source_npc_id < r.target_npc_id
		LIMIT %d;
	""" % [type_list, limit]
	
	if db.query(query):
		return db.query_result if db.query_result else []
	return []

## Count NPCs without location assignment
func count_npcs_without_location() -> int:
	var query = "SELECT COUNT(*) as count FROM npcs WHERE current_location_id IS NULL;"
	if db.query(query) and db.query_result:
		return db.query_result[0].count
	return 0

## Get organizations without employees
func get_orgs_without_employees() -> int:
	var query = """
		SELECT COUNT(*) as count FROM organizations o
		WHERE NOT EXISTS (SELECT 1 FROM organization_memberships m WHERE m.org_id = o.id);
	"""
	if db.query(query) and db.query_result:
		return db.query_result[0].count
	return 0

## Find asymmetric relationships
func get_asymmetric_relationships(exclude_types: Array, limit: int = 100) -> Array:
	var type_list = "'" + "','".join(exclude_types) + "'"
	var query = """
		SELECT r1.source_npc_id, r1.target_npc_id, r1.type
		FROM relationships r1
		WHERE r1.type NOT IN (%s)
		AND NOT EXISTS (
			SELECT 1 FROM relationships r2 
			WHERE r2.source_npc_id = r1.target_npc_id 
			AND r2.target_npc_id = r1.source_npc_id
		)
		LIMIT %d;
	""" % [type_list, limit]
	
	if db.query(query):
		return db.query_result if db.query_result else []
	return []

## Check parent-child age consistency
func get_age_inconsistencies() -> int:
	var query = """
		SELECT COUNT(*) as count
		FROM relationships r
		JOIN npcs child ON r.source_npc_id = child.id
		JOIN npcs parent ON r.target_npc_id = parent.id
		WHERE r.type = 'parent'
		AND json_extract(child.definite, '$.age') >= json_extract(parent.definite, '$.age');
	"""
	if db.query(query) and db.query_result:
		return db.query_result[0].count
	return 0

## Generate UUID (simple implementation)
func generate_uuid() -> String:
	return "%08x-%04x-%04x-%04x-%012x" % [
		randi(),
		randi() & 0xFFFF,
		randi() & 0xFFFF,
		randi() & 0xFFFF,
		(randi() << 16) | (randi() & 0xFFFF)
	]

## Execute raw SQL query
func execute_query(query: String, _bindings: Array = []) -> bool:
	# Note: godot-sqlite doesn't support bindings the way we need
	# This is a simple passthrough for now
	db.query(query)
	return true

## Execute raw SQL query and return results
func fetch_query(query: String, _bindings: Array = []) -> Array:
	# Note: godot-sqlite doesn't support bindings in the same way, so we'll just use query
	var success = db.query(query)
	if success and db.query_result:
		return db.query_result
	return []

## Get database statistics
func get_statistics() -> Dictionary:
	var stats = {}
	
	var tables = ["npcs", "locations", "organizations", "events", "relationships", "items", "npc_memories", "instances"]
	
	for table in tables:
		var success = db.query("SELECT COUNT(*) as count FROM %s;" % table)
		if success and db.query_result and db.query_result.size() > 0:
			stats[table] = db.query_result[0]["count"]
		else:
			stats[table] = 0
	
	return stats

## Print database statistics
func print_statistics() -> void:
	var stats = get_statistics()
	print("\n[DatabaseManager] Database Statistics:")
	print("  NPCs: ", stats.get("npcs", 0))
	print("  Locations: ", stats.get("locations", 0))
	print("  Organizations: ", stats.get("organizations", 0))
	print("  Relationships: ", stats.get("relationships", 0))
	print("  Events: ", stats.get("events", 0))
	print("  Memories: ", stats.get("npc_memories", 0))
	print("  Items: ", stats.get("items", 0))
	print("  Instances: ", stats.get("instances", 0))
	print()
