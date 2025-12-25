extends Node
## Simple World Generator - Creates NPCs, families, locations, districts

var rng = RandomNumberGenerator.new()
var name_data = {}
var family_templates = {}
var location_templates = {}
var skill_trees_data = {}
var appearance_data = {}
var org_templates = {}
var cultural_data = {}
var relationship_templates = {}
var event_templates = {}
var district_templates = {}

# Multi-pass generation storage
var family_frames = []  # Family structures generated first, NPCs filled in passes
var singles_pool = []  # Available singles for spouse matching
var organization_frames = []  # Organization structures with positions defined, filled in passes
var target_singles_count = 0  # Track how many single NPCs will be generated
var district_archetypes = {}  # Maps district_id -> archetype_type for location generation

# Generation stats
var stats = {
	"npcs": 0,
	"families": 0,
	"districts": 0,
	"locations": 0,
	"organizations": 0
}
var timings = {}

# UI reference for progress updates
var ui_screen: Control = null

func _ready():
	# Find UI screen for progress updates
	# Wait a frame for UI to be ready
	await get_tree().process_frame
	ui_screen = get_tree().get_first_node_in_group("world_gen_ui")
	if ui_screen == null:
		# Try to find it as parent
		ui_screen = get_parent() if get_parent() is Control else null
	if ui_screen:
		print("[WorldGenerator] Found UI screen for progress updates")
	else:
		print("[WorldGenerator] UI screen not found - progress updates disabled")
	print("\n" + "=".repeat(60))
	print("WORLD GENERATOR - STATISTICAL ANALYSIS")
	print("=".repeat(60) + "\n")
	
	# Load templates
	if not _load_templates():
		print("❌ Failed to load templates")
		await get_tree().create_timer(1.0).timeout
		get_tree().quit()
		return
	
	# Get config from GameState (if available)
	var config = GameState.current_world_config if GameState.current_world_config else {}
	
	# Initialize database with world-specific path if world_id exists
	if GameState.current_world_id != "":
		var world_db_path = WorldManager.get_world_db_path(GameState.current_world_id)
		print("1. Initializing database for world: %s" % GameState.current_world_id)
		if not DB.initialize(world_db_path):
			print("❌ Database initialization failed")
			await get_tree().create_timer(1.0).timeout
			get_tree().quit()
			return
	else:
		# Fallback to default database (for testing)
		print("1. Initializing database (default)...")
		if not DB.initialize():
			print("❌ Database initialization failed")
			await get_tree().create_timer(1.0).timeout
			get_tree().quit()
			return
	print("✅ Database ready\n")
	
	# Generate world with config
	await get_tree().process_frame
	var result = await _generate_world(config)
	
	# If result is provided, notify GameState
	if result is Dictionary:
		GameState.world_generation_complete(
			result.get("stats", {}),
			result.get("timings", {}),
			result.get("db_stats", {}),
			result.get("validation_stats", {})
		)
	
	# Print detailed stats
	print("\n" + "=".repeat(60))
	print("GENERATION COMPLETE")
	print("=".repeat(60))
	print("Population: %d NPCs" % stats.npcs)
	print("Total Time: %.3fs" % timings.get("total", 0.0))
	print("-" .repeat(60))
	print("PHASE TIMINGS:")
	print("1. World State:    %6.3fs" % timings.get("world_state", 0.0))
	print("2. Districts:      %6.3fs" % timings.get("districts", 0.0))
	print("3. Families:       %6.3fs (Frames: %.3fs, NPCs: %.3fs)" % [timings.get("families_total", 0.0), timings.get("family_frames", 0.0), timings.get("npc_generation", 0.0)])
	print("4. Locations:      %6.3fs" % timings.get("locations", 0.0))
	print("5. Org Frames:     %6.3fs" % timings.get("org_frames", 0.0))
	print("6. Org Filling:    %6.3fs" % timings.get("org_filling", 0.0))
	print("7. Relationships:  %6.3fs" % timings.get("relationships", 0.0))
	print("-" .repeat(60))
	print("METRICS:")
	print("- Districts: %d" % stats.districts)
	print("- Families: %d" % stats.families)
	print("- Locations: %d" % stats.locations)
	print("- Organizations: %d" % organization_frames.size())
	print("- NPCs: %d" % stats.npcs)
	print("=".repeat(60))
	print("BIG O COMPLEXITY ANALYSIS (10,000 NPCs Estimate):")
	print("- Total Time: ~%.1fs" % (timings.get("total", 0.0) * 10))
	print("- Bottleneck: Likely Relationship Generation O(N^2) or Org Filling O(N*M)")
	print("=".repeat(60) + "\n")

func _load_templates() -> bool:
	print("Loading templates...")
	
	name_data = Utils.load_json_file("res://data/templates/name_catalog.json")
	if name_data == null:
		push_error("❌ CRITICAL: name_catalog.json not found or invalid!")
		return false
	
	family_templates = Utils.load_json_file("res://data/templates/family_templates.json")
	if family_templates == null:
		return false
	
	location_templates = Utils.load_json_file("res://data/templates/location_templates.json")
	if location_templates == null:
		return false
	
	# Load new template submissions - REQUIRED, NO FALLBACKS
	skill_trees_data = Utils.load_json_file("res://data/templates/skill_trees.json")
	if skill_trees_data == null:
		push_error("❌ CRITICAL: skill_trees.json not found or invalid!")
		return false
	
	appearance_data = Utils.load_json_file("res://data/templates/appearance_templates.json")
	if appearance_data == null:
		push_error("❌ CRITICAL: appearance_templates.json not found or invalid!")
		return false
	
	org_templates = Utils.load_json_file("res://data/templates/organization_templates.json")
	if org_templates == null:
		push_error("❌ CRITICAL: organization_templates.json not found or invalid!")
		return false
	
	cultural_data = Utils.load_json_file("res://data/templates/cultural_data.json")
	if cultural_data == null:
		push_error("❌ CRITICAL: cultural_data.json not found or invalid!")
		return false
	
	relationship_templates = Utils.load_json_file("res://data/templates/relationship_templates.json")
	if relationship_templates == null:
		push_error("❌ CRITICAL: relationship_templates.json not found or invalid!")
		return false
	
	event_templates = Utils.load_json_file("res://data/templates/event_templates.json")
	if event_templates == null:
		push_error("❌ CRITICAL: event_templates.json not found or invalid!")
		return false
	
	district_templates = Utils.load_json_file("res://data/templates/district_templates.json")
	if district_templates == null:
		push_error("❌ CRITICAL: district_templates.json not found or invalid!")
		return false
	
	print("✅ All templates loaded successfully\n")
	return true

func _generate_world(config: Dictionary = {}) -> Dictionary:
	# Extract config values with defaults
	var target_npcs = config.get("target_npcs", 1000)
	var seed_value = config.get("seed", 0)
	var family_composition_ratio = config.get("family_composition_ratio", 0.3)
	var district_density_ratio = config.get("district_density_ratio", 1.0)
	var org_density_ratio = config.get("org_density_ratio", 1.0)
	var location_density_ratio = config.get("location_density_ratio", 1.0)
	var start_date = config.get("start_date", "2025-01-01")
	var start_time = config.get("start_time", "08:00")
	
	# Initialize RNG with seed
	if seed_value > 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	
	var total_start = Time.get_ticks_msec()
	var step_start = 0
	
	_update_progress("Creating world state...", 5.0)
	await get_tree().process_frame
	print("2. Creating world state...")
	step_start = Time.get_ticks_msec()
	_create_world_state(str(seed_value), start_date, start_time)
	timings["world_state"] = (Time.get_ticks_msec() - step_start) / 1000.0
	print("✅ World state created (%.3fs)\n" % timings["world_state"])
	
	_update_progress("Creating districts...", 10.0)
	await get_tree().process_frame
	print("3. Creating districts...")
	step_start = Time.get_ticks_msec()
	_generate_districts_dynamic(target_npcs, district_density_ratio)
	timings["districts"] = (Time.get_ticks_msec() - step_start) / 1000.0
	print("✅ %d districts created (%.3fs, O(n))\n" % [stats.districts, timings["districts"]])
	
	_update_progress("Generating families and NPCs...", 20.0)
	await get_tree().process_frame
	print("4. Generating families and NPCs (MULTI-PASS)...")
	step_start = Time.get_ticks_msec()
	
	# Phase 2A: Generate family frames
	print("   Phase 2A: Family Frames")
	var p2a_start = Time.get_ticks_msec()
	var target_singles = _generate_family_frames(target_npcs, family_composition_ratio)
	target_singles_count = target_singles  # Store for location generation
	timings["family_frames"] = (Time.get_ticks_msec() - p2a_start) / 1000.0
	
	# Phase 4: Multi-pass NPC generation
	print("   Phase 4: Multi-Pass NPC Generation")
	var p4_start = Time.get_ticks_msec()
	_pass1_generate_founders()
	_pass2_generate_spouses()
	_pass3_generate_children()
	_pass4_generate_extended_family()
	_pass5_generate_singles(target_singles)
	timings["npc_generation"] = (Time.get_ticks_msec() - p4_start) / 1000.0
	
	timings["families_total"] = (Time.get_ticks_msec() - step_start) / 1000.0
	print("✅ %d families, %d NPCs created (%.3fs, O(n))\n" % [stats.families, stats.npcs, timings["families_total"]])
	
	_update_progress("Generating organizations...", 35.0)
	await get_tree().process_frame
	print("5. Generating organization frames (Phase 2B)...")
	step_start = Time.get_ticks_msec()
	_generate_organization_frames(target_npcs, org_density_ratio)
	timings["org_frames"] = (Time.get_ticks_msec() - step_start) / 1000.0
	print("✅ Organization frames created: %d orgs (%.3fs, O(n))\n" % [organization_frames.size(), timings["org_frames"]])

	_update_progress("Creating locations...", 45.0)
	await get_tree().process_frame
	print("6. Creating locations (Phase 3 - Need-Based)...")
	step_start = Time.get_ticks_msec()
	_create_locations_need_based(location_density_ratio)
	timings["locations"] = (Time.get_ticks_msec() - step_start) / 1000.0
	print("✅ %d locations created (%.3fs, O(n))\n" % [stats.locations, timings["locations"]])
	
	print("6b. Assigning locations (Phase 9)...")
	step_start = Time.get_ticks_msec()
	_assign_families_to_housing()
	_assign_organizations_to_locations()
	timings["location_assignment"] = (Time.get_ticks_msec() - step_start) / 1000.0
	print("✅ Families & orgs assigned to locations (%.3fs, O(n))\n" % timings["location_assignment"])
	
	print("6c. Assigning ownership (Phase 9b)...")
	step_start = Time.get_ticks_msec()
	_assign_location_ownership()
	timings["ownership"] = (Time.get_ticks_msec() - step_start) / 1000.0
	print("✅ Ownership assigned (%.3fs, O(n))\n" % timings["ownership"])
	
	_update_progress("Assigning NPCs to organizations...", 55.0)
	await get_tree().process_frame
	print("7. Assigning NPCs to organizations (Phase 5)...")
	step_start = Time.get_ticks_msec()
	_assign_npc_careers_and_affiliations()
	timings["org_filling"] = (Time.get_ticks_msec() - step_start) / 1000.0
	print("✅ NPCs assigned to organizations (%.3fs, O(n*m))\n" % timings["org_filling"])
	
	_update_progress("Validating affiliations...", 65.0)
	await get_tree().process_frame
	print("8. Validating school & religious assignments (Phase 6)...")
	step_start = Time.get_ticks_msec()
	_validate_npc_affiliations()
	timings["validation"] = (Time.get_ticks_msec() - step_start) / 1000.0
	print("✅ School & religious affiliations validated (%.3fs, O(n))\n" % timings["validation"])
	
	_update_progress("Generating relationships...", 75.0)
	await get_tree().process_frame
	print("9. Generating relationships (Multi-Pass - Phase 7)...")
	step_start = Time.get_ticks_msec()
	_generate_context_based_relationships()
	timings["relationships"] = (Time.get_ticks_msec() - step_start) / 1000.0
	print("✅ Context-based relationships created (%.3fs, O(n^2))\n" % timings["relationships"])
	
	_update_progress("Generating historical events...", 85.0)
	await get_tree().process_frame
	print("10. Generating historical events (Phase 8)...")
	step_start = Time.get_ticks_msec()
	_generate_historical_events()
	timings["events"] = (Time.get_ticks_msec() - step_start) / 1000.0
	print("✅ Historical events generated (%.3fs, O(n))\n" % timings["events"])
	
	_update_progress("Validating and polishing...", 95.0)
	await get_tree().process_frame
	print("11. Running validation and polish (Phase 10)...")
	step_start = Time.get_ticks_msec()
	_run_validation_and_polish()
	timings["validation_polish"] = (Time.get_ticks_msec() - step_start) / 1000.0
	print("✅ Validation and polish complete (%.3fs)\n" % timings["validation_polish"])
	
	_update_progress("Generation complete!", 100.0)
	
	timings["total"] = (Time.get_ticks_msec() - total_start) / 1000.0
	
	# Print final summary
	_print_world_summary()
	
	# Return stats dictionary for GameState
	var db_stats = DB.get_statistics()
	return {
		"stats": stats.duplicate(),
		"timings": timings.duplicate(),
		"db_stats": db_stats,
		"validation_stats": validation_stats.duplicate() if "validation_stats" in self else {}
	}

func _create_world_state(seed_str: String, start_date: String, start_time: String):
	DB.initialize_world_state(seed_str, start_date, start_time)

func _generate_districts_dynamic(target_npcs: int, density_ratio: float):
	# 1. Determine number of districts (calculated from NPC count with ratio)
	# Base calculation: ~1 district per 150 NPCs, minimum 3
	var base_districts = max(3, target_npcs / 150)
	var target_districts = int(base_districts * density_ratio)
	target_districts = clamp(target_districts, 3, 20)
	print("   🌍 Generating %d dynamic districts (base: %d, ratio: %.0f%%)..." % [target_districts, base_districts, density_ratio * 100])
	
	# 2. Select Archetypes
	var selected_archetypes = []
	var archetypes = district_templates.get("archetypes", {})
	var available_types = archetypes.keys()
	
	# Ensure mandatory types
	for type_id in available_types:
		if archetypes[type_id].get("mandatory", false):
			selected_archetypes.append(type_id)
	
	# Fill remaining slots with weighted random selection
	while selected_archetypes.size() < target_districts:
		var weights = []
		for type_id in available_types:
			weights.append(archetypes[type_id].get("weight", 10))
		
		var idx = Utils.weighted_random(available_types, weights)
		var type_id = available_types[idx]
		
		# Check max_count constraint
		var count = 0
		for t in selected_archetypes:
			if t == type_id: count += 1
			
		if count < archetypes[type_id].get("max_count", 999):
			selected_archetypes.append(type_id)
	
	# 3. Create Districts
	var district_names = name_data.get("locations", {}).get("districts", []).duplicate()
	district_names.shuffle()
	
	for i in range(selected_archetypes.size()):
		var type_id = selected_archetypes[i]
		var template = archetypes[type_id]
		var district_name = district_names.pop_back() if not district_names.is_empty() else "District %d" % (i+1)
		var district_id = "dist_%d_%s" % [i, type_id]
		
		var district_data = {
			"id": district_id,
			"name": district_name,
			"prosperity": rng.randi_range(template.stats.prosperity_range[0], template.stats.prosperity_range[1]),
			"safety": rng.randi_range(template.stats.safety_range[0], template.stats.safety_range[1]),
			"infrastructure": rng.randi_range(template.stats.infrastructure_range[0], template.stats.infrastructure_range[1])
		}
		
		DB.create_district(district_data)
		district_archetypes[district_id] = template  # Store full archetype in memory for location generation
		stats.districts += 1
		print("      📍 Created %s (%s)" % [district_name, template.display_name])

## PHASE 2A: Generate family frames (structures without NPCs)
## Creates family "frames" with all metadata but no NPCs yet
## NPCs will be filled in multiple passes (Phase 4)
## Returns: target_singles count for pass 5
func _generate_family_frames(target_npcs: int, family_composition_ratio: float) -> int:
	var start_time = Time.get_ticks_msec()
	
	# Use actual district IDs from the database (not hardcoded names)
	var all_districts = DB.get_all_districts()
	var districts = []
	for d in all_districts:
		districts.append(d.id)
	
	if districts.is_empty():
		push_error("❌ CRITICAL: No districts found in database for family generation!")
		districts = ["central"]  # Fallback
	
	var template_names = []
	for key in family_templates.keys():
		if not key.begins_with("_"):
			template_names.append(key)
	
	if template_names.size() == 0:
		push_error("❌ CRITICAL: No family templates found!")
		return 0
	
	# Calculate target family NPCs vs singles
	var target_family_npcs = int(target_npcs * (1.0 - family_composition_ratio))
	var target_singles = target_npcs - target_family_npcs
	
	# Generate family frames until we can accommodate target family NPCs
	var potential_npc_count = 0
	var family_id = 0
	
	print("   📦 Generating family frames for ~%d family NPCs (%d singles will be generated separately)..." % [target_family_npcs, target_singles])
	
	while potential_npc_count < target_family_npcs:
		family_id += 1
		
		# Pick random family template
		var template_name = template_names[rng.randi() % template_names.size()]
		var template = family_templates[template_name]
		
		# Generate family metadata
		var tribe = _random_tribe()
		var last_name = _random_last_name(tribe)
		var district = districts[rng.randi() % districts.size()]
		
		# Determine wealth level from template distribution
		var wealth_dist = template.get("wealth_distribution", {})
		var wealth_options = []
		var wealth_weights = []
		for wealth_level in wealth_dist.keys():
			wealth_options.append(wealth_level)
			wealth_weights.append(wealth_dist[wealth_level])
		
		var wealth_level = "middle_class"  # Default
		if wealth_options.size() > 0:
			var wealth_idx = Utils.weighted_random(wealth_options, wealth_weights)
			if wealth_idx >= 0:
				wealth_level = wealth_options[wealth_idx]
		
		# Determine target size for this family
		var size_range = template.get("size_range", [2, 4])
		var target_size = rng.randi_range(size_range[0], size_range[1])
		
		# Create family frame
		var frame = {
			"id": "family_%d" % family_id,
			"family_id": family_id,
			"template_name": template_name,
			"template": template,
			"tribe": tribe,
			"last_name": last_name,
			"district": district,
			"wealth_level": wealth_level,
			"target_size": target_size,
			"structure": template.structure,
			"common_values": template.get("common_values", {}),
			"housing_preference": template.get("housing_preference", []),
			"generated_npcs": []  # Will be filled in passes
		}
		
		family_frames.append(frame)
		potential_npc_count += target_size
		
		# Progress feedback every 5 frames
		if family_frames.size() % 5 == 0:
			var progress = float(potential_npc_count) / float(target_family_npcs) * 100.0
			var elapsed = (Time.get_ticks_msec() - start_time) / 1000.0
			var eta = 0.0
			if progress > 0:
				eta = (elapsed / progress) * (100.0 - progress)
			print("      [%3.0f%%] %d frames (%d capacity) | ETA: %.1fs" % [progress, family_frames.size(), potential_npc_count, eta])
	
	var total_time = (Time.get_ticks_msec() - start_time) / 1000.0
	print("   ✅ Created %d family frames (capacity: ~%d NPCs) in %.2fs" % [family_frames.size(), potential_npc_count, total_time])
	stats.families = family_frames.size()
	
	return target_singles

## PHASE 4 - PASS 1: Generate family founders (parent_1)
## Creates the first parent for each family
func _pass1_generate_founders():
	var start_time = Time.get_ticks_msec()
	var total = family_frames.size()
	print("   👤 Pass 1: Generating %d family founders..." % total)
	var created_count = 0
	var processed = 0
	
	for frame in family_frames:
		processed += 1
		var structure = frame.structure
		
		# Check if this family has parent_1
		if not structure.has("parent_1"):
			continue
		
		var parent1_def = structure["parent_1"]
		var age = rng.randi_range(parent1_def.age_min, parent1_def.age_max)
		
		# 50/50 male/female for founder
		var gender = "male" if rng.randf() < 0.5 else "female"
		var first_name = _random_first_name(frame.tribe, gender)
		
		# Generate NPC ID
		var npc_id = "npc_%d" % (stats.npcs + 1)
		
		# Create founder NPC
		_create_npc(npc_id, first_name, frame.last_name, age, gender, frame.tribe, frame.family_id, frame.district)
		
		# Store in frame
		frame.generated_npcs.append({
			"id": npc_id,
			"role": "parent_1",
			"age": age,
			"gender": gender
		})
		
		# Add to singles pool (needs spouse in Pass 2)
		singles_pool.append({
			"id": npc_id,
			"family_id": frame.family_id,
			"age": age,
			"gender": gender,
			"tribe": frame.tribe,
			"needs_spouse": true
		})
		
		stats.npcs += 1
		created_count += 1
		
		# Progress feedback every 10 NPCs
		if created_count % 10 == 0:
			var progress = float(processed) / float(total) * 100.0
			var elapsed = (Time.get_ticks_msec() - start_time) / 1000.0
			var eta = (elapsed / progress) * (100.0 - progress)
			print("      [%3.0f%%] %d/%d founders | ETA: %.1fs" % [progress, created_count, total, eta])
	
	var total_time = (Time.get_ticks_msec() - start_time) / 1000.0
	print("      ✅ Created %d founders in %.2fs" % [created_count, total_time])

## PHASE 4 - PASS 2: Generate/match spouses (parent_2)
## Matches existing singles or creates new spouses
func _pass2_generate_spouses():
	var start_time = Time.get_ticks_msec()
	var total = family_frames.size()
	print("   💑 Pass 2: Generating spouses for %d families..." % total)
	var created_count = 0
	var processed = 0
	
	for frame in family_frames:
		processed += 1
		var structure = frame.structure
		
		# Check if this family needs parent_2
		if not structure.has("parent_2"):
			continue
		
		var parent2_def = structure["parent_2"]
		
		# Skip if optional and random chance
		if parent2_def.get("optional", false) and rng.randf() < 0.3:
			continue
		
		# Find parent_1 from this family
		var parent1_data = null
		for npc in frame.generated_npcs:
			if npc.role == "parent_1":
				parent1_data = npc
				break
		
		if parent1_data == null:
			continue
		
		# Determine spouse gender (opposite of parent_1)
		var spouse_gender = "female" if parent1_data.gender == "male" else "male"
		var age = rng.randi_range(parent2_def.age_min, parent2_def.age_max)
		var first_name = _random_first_name(frame.tribe, spouse_gender)
		
		# Generate NPC ID
		var npc_id = "npc_%d" % (stats.npcs + 1)
		
		# Create spouse NPC
		_create_npc(npc_id, first_name, frame.last_name, age, spouse_gender, frame.tribe, frame.family_id, frame.district)
		
		# Store in frame
		frame.generated_npcs.append({
			"id": npc_id,
			"role": "parent_2",
			"age": age,
			"gender": spouse_gender
		})
		
		# Create marriage relationship between parent_1 and parent_2
		var affection = rng.randi_range(40, 90)
		var trust = rng.randi_range(50, 95)
		var respect = rng.randi_range(40, 85)
		
		# Calculate marriage date (between 2-20 years ago, depending on children's ages)
		var years_married = rng.randi_range(2, 20)
		var marriage_date = "%d-01-01" % (2025 - years_married)
		
		DB.create_relationship(parent1_data.id, npc_id, "spouse", affection, trust, 0, respect, marriage_date)
		DB.create_relationship(npc_id, parent1_data.id, "spouse", affection, trust, 0, respect, marriage_date)
		
		stats.npcs += 1
		created_count += 1
		
		# Progress feedback every 10 NPCs
		if created_count % 10 == 0:
			var progress = float(processed) / float(total) * 100.0
			var elapsed = (Time.get_ticks_msec() - start_time) / 1000.0
			var eta = (elapsed / progress) * (100.0 - progress)
			print("      [%3.0f%%] %d spouses created | ETA: %.1fs" % [progress, created_count, eta])
	
	var total_time = (Time.get_ticks_msec() - start_time) / 1000.0
	print("      ✅ Created %d spouses in %.2fs" % [created_count, total_time])

## PHASE 4 - PASS 3: Generate children WITH inheritance
## Children inherit personality and appearance from parents
func _pass3_generate_children():
	var start_time = Time.get_ticks_msec()
	var total = family_frames.size()
	print("   👶 Pass 3: Generating children with inheritance for %d families..." % total)
	var created_count = 0
	var processed = 0
	
	for frame in family_frames:
		processed += 1
		var structure = frame.structure
		
		# Check if this family has children
		if not structure.has("children"):
			continue
		
		var children_def = structure["children"]
		var child_count = rng.randi_range(children_def.count_min, children_def.count_max)
		
		# Find parents
		var parent1_id = null
		var parent2_id = null
		
		for npc in frame.generated_npcs:
			if npc.role == "parent_1":
				parent1_id = npc.id
			elif npc.role == "parent_2":
				parent2_id = npc.id
		
		if parent1_id == null:
			continue  # Can't have children without at least one parent
		
		# Get parent data from database for inheritance
		var parent1_data = DB.get_npc(parent1_id)
		var parent2_data = null
		if parent2_id != null:
			parent2_data = DB.get_npc(parent2_id)
		
		# Find youngest parent age to enforce minimum age gap
		var youngest_parent_age = parent1_data.definite.age
		if parent2_data != null and parent2_data.definite.age < youngest_parent_age:
			youngest_parent_age = parent2_data.definite.age
		
		# Generate children
		for i in range(child_count):
			# Ensure child is at least 18 years younger than youngest parent
			const MIN_PARENT_AGE_GAP = 18
			var max_child_age = youngest_parent_age - MIN_PARENT_AGE_GAP
			
			# Constraint child age to template range AND parent age
			var child_age_min = children_def.age_min
			var child_age_max = min(children_def.age_max, max(max_child_age, 0))
			
			# Skip if impossible (parent too young to have children)
			if child_age_max < child_age_min:
				continue
			
			var age = rng.randi_range(child_age_min, child_age_max)
			var gender = "male" if rng.randf() < 0.5 else "female"
			var first_name = _random_first_name(frame.tribe, gender)
			
			# Generate NPC ID
			var npc_id = "npc_%d" % (stats.npcs + 1)
			
			# Create child NPC WITH INHERITANCE
			_create_child_npc(npc_id, first_name, frame.last_name, age, gender, frame.tribe, frame.family_id, frame.district, parent1_data, parent2_data)
			
			# Store in frame
			frame.generated_npcs.append({
				"id": npc_id,
				"role": "child",
				"age": age,
				"gender": gender
			})
			
			# Create parent-child relationships
			var child_affection = rng.randi_range(60, 95)
			var child_trust = rng.randi_range(70, 100)
			var child_respect = rng.randi_range(50, 90)
			
			DB.create_relationship(npc_id, parent1_id, "parent", child_affection, child_trust, 0, child_respect)
			DB.create_relationship(parent1_id, npc_id, "child", rng.randi_range(70, 100), rng.randi_range(70, 100), 0, rng.randi_range(60, 90))
			
			if parent2_id != null:
				DB.create_relationship(npc_id, parent2_id, "parent", child_affection, child_trust, 0, child_respect)
				DB.create_relationship(parent2_id, npc_id, "child", rng.randi_range(70, 100), rng.randi_range(70, 100), 0, rng.randi_range(60, 90))
			
			stats.npcs += 1
			created_count += 1
			
			# Progress feedback every 5 children
			if created_count % 5 == 0:
				var progress = float(processed) / float(total) * 100.0
				var elapsed = (Time.get_ticks_msec() - start_time) / 1000.0
				var eta = (elapsed / progress) * (100.0 - progress) if progress > 0 else 0.0
				print("      [%3.0f%%] %d children created | ETA: %.1fs" % [progress, created_count, eta])
	
	var children_time = (Time.get_ticks_msec() - start_time) / 1000.0
	print("      ✅ Created %d children in %.2fs" % [created_count, children_time])
	
	# Create sibling relationships
	print("      🔗 Creating sibling relationships...")
	var sibling_start = Time.get_ticks_msec()
	var sibling_count = 0
	for frame in family_frames:
		var children = []
		for npc in frame.generated_npcs:
			if npc.role == "child":
				children.append(npc)
		
		# Create bidirectional sibling relationships
		for i in range(children.size()):
			for j in range(i + 1, children.size()):
				var affection = rng.randi_range(20, 80)
				var trust = rng.randi_range(30, 90)
				DB.create_relationship(children[i].id, children[j].id, "sibling", affection, trust, 0, rng.randi_range(30, 70))
				DB.create_relationship(children[j].id, children[i].id, "sibling", affection, trust, 0, rng.randi_range(30, 70))
				sibling_count += 2
	
	var sibling_time = (Time.get_ticks_msec() - sibling_start) / 1000.0
	var total_pass3_time = (Time.get_ticks_msec() - start_time) / 1000.0
	print("      ✅ Created %d sibling relationships in %.2fs" % [sibling_count, sibling_time])
	print("   ✅ Pass 3 complete: %d children with inheritance in %.2fs" % [created_count, total_pass3_time])

## PHASE 4 - PASS 4: Generate extended family members
## Creates additional family members like grandparents, aunts/uncles, cousins
func _pass4_generate_extended_family():
	var start_time = Time.get_ticks_msec()
	var total = family_frames.size()
	print("   👴 Pass 4: Generating extended family for %d families..." % total)
	var created_count = 0
	var processed = 0
	
	for frame in family_frames:
		processed += 1
		var structure = frame.structure
		
		# Check if this family has extended family definitions
		if not structure.has("extended"):
			continue
		
		var extended_def = structure["extended"]
		
		# Generate each type of extended family member
		for member_type in extended_def.keys():
			var member_def = extended_def[member_type]
			var count = 1
			
			if member_def.has("count"):
				count = member_def["count"]
			elif member_def.has("count_min") and member_def.has("count_max"):
				count = rng.randi_range(member_def.count_min, member_def.count_max)
			
			# Skip if optional and random chance
			if member_def.get("optional", false) and rng.randf() < 0.5:
				continue
			
			for i in range(count):
				var age = rng.randi_range(member_def.age_min, member_def.age_max)
				var gender = "male" if rng.randf() < 0.5 else "female"
				var first_name = _random_first_name(frame.tribe, gender)
				
				# Extended family may have different last names
				var last_name = frame.last_name
				if member_type in ["aunt", "uncle", "cousin"] and rng.randf() < 0.5:
					last_name = _random_last_name(frame.tribe)
				
				# Generate NPC ID
				var npc_id = "npc_%d" % (stats.npcs + 1)
				
				# Create extended family NPC (no inheritance for extended family)
				_create_npc(npc_id, first_name, last_name, age, gender, frame.tribe, frame.family_id, frame.district)
				
				# Store in frame
				frame.generated_npcs.append({
					"id": npc_id,
					"role": member_type,
					"age": age,
					"gender": gender
				})
				
				stats.npcs += 1
				created_count += 1
	
	var total_time = (Time.get_ticks_msec() - start_time) / 1000.0
	print("      ✅ Created %d extended family members in %.2fs" % [created_count, total_time])

## PHASE 4 - PASS 5: Generate remaining single NPCs
## Creates singles to fill remaining population quota
func _pass5_generate_singles(target_count: int):
	var start_time = Time.get_ticks_msec()
	var created_count = 0
	
	# Use actual district IDs from the database
	var all_districts = DB.get_all_districts()
	var districts = []
	for d in all_districts:
		districts.append(d.id)
	if districts.is_empty():
		districts = ["central"]  # Fallback
	
	# Use target_count directly (calculated from family composition ratio)
	var remaining = target_count
	
	if remaining <= 0:
		print("   ✅ Pass 5: No singles needed")
		return
	
	print("   🚶 Pass 5: Generating %d single NPCs..." % remaining)
	
	for i in range(remaining):
		var age = rng.randi_range(18, 65)
		var gender = "male" if rng.randf() < 0.5 else "female"
		var tribe = _random_tribe()
		var first_name = _random_first_name(tribe, gender)
		var last_name = _random_last_name(tribe)
		var district = districts[rng.randi() % districts.size()]
		
		# Generate NPC ID
		var npc_id = "npc_%d" % (stats.npcs + 1)
		
		# Singles don't have family_id (or have their own single-person family)
		var single_family_id = 999000 + i  # High ID range for singles
		
		# Create single NPC
		_create_npc(npc_id, first_name, last_name, age, gender, tribe, single_family_id, district)
		
		# Add to singles pool (available for relationships)
		singles_pool.append({
			"id": npc_id,
			"family_id": single_family_id,
			"age": age,
			"gender": gender,
			"tribe": tribe,
			"needs_spouse": false
		})
		
		stats.npcs += 1
		created_count += 1
		
		# Progress feedback every 10 NPCs
		if created_count % 10 == 0:
			var progress = float(created_count) / float(remaining) * 100.0
			var elapsed = (Time.get_ticks_msec() - start_time) / 1000.0
			var eta = (elapsed / progress) * (100.0 - progress) if progress > 0 else 0.0
			print("      [%3.0f%%] %d/%d singles | ETA: %.1fs" % [progress, created_count, remaining, eta])
	
	var total_time = (Time.get_ticks_msec() - start_time) / 1000.0
	print("   ✅ Pass 5 complete: Created %d single NPCs in %.2fs" % [created_count, total_time])

## OLD SINGLE-PASS IMPLEMENTATION (TO BE REPLACED)
func _generate_families_and_npcs(target_npcs: int):
	var created_npcs = 0
	var family_id = 0
	
	# Use actual district IDs from the database
	var all_districts = DB.get_all_districts()
	var districts = []
	for d in all_districts:
		districts.append(d.id)
	if districts.is_empty():
		districts = ["central"]  # Fallback
	
	# Keep generating families until we hit target
	while created_npcs < target_npcs:
		family_id += 1
		
		# Pick random family template
		var template_names = []
		for key in family_templates.keys():
			if not key.begins_with("_"):
				template_names.append(key)
		
		var template_name = template_names[rng.randi() % template_names.size()]
		var template = family_templates[template_name]
		
		# Generate family
		var tribe = _random_tribe()
		var last_name = _random_last_name(tribe)
		var district = districts[rng.randi() % districts.size()]
		
		# Determine family size
		var size_range = template.size_range
		var target_size = rng.randi_range(size_range[0], size_range[1])
		
		# Generate NPCs for this family
		var family_npcs = _generate_family_npcs(family_id, template, tribe, last_name, district, target_size)
		
		created_npcs += family_npcs
		stats.families += 1
		stats.npcs = created_npcs
		
		if created_npcs % 10 == 0:
			print("   Generated %d/%d NPCs..." % [created_npcs, target_npcs])

func _generate_family_npcs(family_id: int, template: Dictionary, tribe: String, last_name: String, district: String, target_size: int) -> int:
	var created = 0
	var structure = template.structure
	var parent_ids = []
	
	# Generate parent 1
	if structure.has("parent_1"):
		var p1_data = structure.parent_1
		var npc_id = "npc_%d_%d" % [family_id, created + 1]
		var age = rng.randi_range(p1_data.age_min, p1_data.age_max)
		var gender = ["male", "female"][rng.randi() % 2]
		
		_create_npc(npc_id, _random_first_name(tribe, gender), last_name, age, gender, tribe, family_id, district)
		parent_ids.append(npc_id)
		created += 1
	
	# Generate parent 2
	if structure.has("parent_2") and not structure.parent_2.get("optional", false):
		var p2_data = structure.parent_2
		var npc_id = "npc_%d_%d" % [family_id, created + 1]
		var age = rng.randi_range(p2_data.age_min, p2_data.age_max)
		var gender = "male" if parent_ids.size() > 0 and _get_npc_gender(parent_ids[0]) == "female" else "female"
		
		_create_npc(npc_id, _random_first_name(tribe, gender), last_name, age, gender, tribe, family_id, district)
		parent_ids.append(npc_id)
		created += 1
		
		# Create marriage relationship
		if parent_ids.size() == 2:
			_create_relationship(parent_ids[0], parent_ids[1], "spouse", 80)
	
	# Generate children
	var child_ids = []
	if structure.has("children") and created < target_size:
		var child_data = structure.children
		var num_children = min(target_size - created, child_data.count_max)
		
		for i in range(num_children):
			var npc_id = "npc_%d_%d" % [family_id, created + 1]
			var age = rng.randi_range(child_data.age_min, child_data.age_max)
			var gender = ["male", "female"][rng.randi() % 2]
			
			_create_npc(npc_id, _random_first_name(tribe, gender), last_name, age, gender, tribe, family_id, district)
			child_ids.append(npc_id)
			
			# Create parent-child relationships
			for parent_id in parent_ids:
				_create_relationship(parent_id, npc_id, "parent", 85)
				_create_relationship(npc_id, parent_id, "child", 85)
			
			created += 1
	
	# Create sibling relationships (after all children are generated)
	if child_ids.size() > 1:
		for i in range(child_ids.size()):
			for j in range(i + 1, child_ids.size()):
				# Sibling affection varies widely (-20 to 90)
				var affection = rng.randi_range(-20, 90)
				_create_relationship(child_ids[i], child_ids[j], "sibling", affection)
				_create_relationship(child_ids[j], child_ids[i], "sibling", affection)
	
	return created

func _create_npc(id: String, first_name: String, last_name: String, age: int, gender: String, tribe: String, family_id: int, district: String):
	var npc_data = {
		"id": id,
		"name": "%s %s" % [first_name, last_name],
		"definite": {
			"gender": gender,
			"age": age,
			"alive": true,
			"orientation": _generate_orientation()  # -100 (same-sex) to 100 (hetero)
		},
		"attributes": _generate_attributes(age),  # RPG stats for attraction/interactions
		"appearance": _generate_appearance(gender, age, tribe, []),  # Physical appearance
		"identity": {
			"tribe": tribe,
			"spoken_languages": ["english", "pidgin"],
			"education": {
				"level": _random_education(),
				"institution": null  # Will be assigned in Phase 6
			},
			"religious_path": _random_religion(tribe),
			"occupation": "",  # Will be set below
			"family_id": "family_%d" % family_id,
			"district": district
		},
		"personality": _generate_personality(tribe),
		"political_ideology": _generate_political_ideology(),
		"skills": {},  # Will be set below

		"resources": {
			"liquid_assets": [],
			"property": [],
			"access": [],
			"annual_income": 0  # Will be set below
		},
		"status": {
			"health": rng.randi_range(70, 100),
			"stress": rng.randi_range(10, 50),
			"reputation": rng.randi_range(30, 70)
		},
		"demographic_affinities": {}
	}
	
	# Generate occupation based on education and age
	var education = npc_data.identity.education.level
	var occupation = _random_occupation(education, age)
	npc_data.identity.occupation = occupation
	
	# Generate skills based on occupation and age
	npc_data.skills = _generate_skills(occupation, age)
	
	# Generate salary based on occupation and age
	npc_data.resources.annual_income = _generate_salary_for_occupation(occupation, age)
	
	DB.create_npc(npc_data)

## Create child NPC WITH inheritance from parents
func _create_child_npc(id, first_name, last_name, age, gender, tribe, family_id, district, parent1_data, parent2_data):
	# Get parent personality and appearance for inheritance
	var p1_personality = parent1_data.get("personality", {})
	var p1_political = parent1_data.get("political_ideology", {})
	var p1_appearance = parent1_data.get("appearance", {})
	
	var p2_personality = {}
	var p2_political = {}
	var p2_appearance = {}
	
	if parent2_data != null and parent2_data is Dictionary:
		p2_personality = parent2_data.get("personality", {})
		p2_political = parent2_data.get("political_ideology", {})
		p2_appearance = parent2_data.get("appearance", {})
	
	# Generate child personality WITH INHERITANCE
	var child_personality = {}
	var p1_traits = p1_personality.keys()
	for i in range(p1_traits.size()):
		var trait_name = p1_traits[i]
		if p2_personality.has(trait_name):
			# Both parents have this trait - inherit
			child_personality[trait_name] = Utils.inherit_value(p1_personality[trait_name], p2_personality[trait_name])
		else:
			# Only one parent - use their value with variation
			child_personality[trait_name] = Utils.inherit_value(p1_personality[trait_name], p1_personality[trait_name])
	
	# Apply cultural modifiers on top of inheritance
	if cultural_data.has("tribes") and cultural_data.tribes.has(tribe):
		var tribe_data = cultural_data.tribes[tribe]
		if tribe_data.has("personality_modifiers"):
			var modifiers = tribe_data.personality_modifiers
			var modifier_keys = modifiers.keys()
			for i in range(modifier_keys.size()):
				var trait_name = modifier_keys[i]
				if child_personality.has(trait_name):
					var adjustment = modifiers[trait_name]
					child_personality[trait_name] = clamp(child_personality[trait_name] + adjustment, -100, 100)
	
	# Generate child political ideology WITH INHERITANCE
	var child_political = {}
	var p1_ideologies = p1_political.keys()
	for i in range(p1_ideologies.size()):
		var ideology = p1_ideologies[i]
		if p2_political.has(ideology):
			child_political[ideology] = Utils.inherit_value(p1_political[ideology], p2_political[ideology])
		else:
			child_political[ideology] = Utils.inherit_value(p1_political[ideology], p1_political[ideology])
	
	# Generate child appearance WITH INHERITANCE
	var child_appearance = {}
	if p2_appearance.size() > 0:
		# Both parents - blend appearance
		child_appearance = Utils.inherit_appearance(p1_appearance, p2_appearance, gender)
	else:
		# Single parent - child resembles parent with variation
		child_appearance = Utils.inherit_appearance(p1_appearance, p1_appearance, gender)
	
	# Complete appearance with age-appropriate details
	child_appearance = _complete_child_appearance(child_appearance, gender, age, tribe)
	
	var npc_data = {
		"id": id,
		"name": "%s %s" % [first_name, last_name],
		"definite": {
			"gender": gender,
			"age": age,
			"alive": true,
			"orientation": _generate_orientation()
		},
		"attributes": _generate_attributes(age),
		"appearance": child_appearance,
		"identity": {
			"tribe": tribe,
			"spoken_languages": ["english", "pidgin"],
			"education": {
				"level": _random_education(),
				"institution": null  # Will be assigned in Phase 6
			},
			"religious_path": _random_religion(tribe),
			"occupation": "",  # Will be set below
			"family_id": "family_%d" % family_id,
			"district": district
		},
		"personality": child_personality,  # INHERITED
		"political_ideology": child_political,  # INHERITED
		"skills": {},  # Will be set below
		"resources": {
			"liquid_assets": [],
			"property": [],
			"access": [],
			"annual_income": 0
		},
		"status": {
			"health": rng.randi_range(70, 100),
			"stress": rng.randi_range(10, 50),
			"reputation": rng.randi_range(30, 70)
		},
		"demographic_affinities": {}
	}
	
	# Generate occupation based on education and age
	var education = npc_data.identity.education.level
	var occupation = _random_occupation(education, age)
	npc_data.identity.occupation = occupation
	
	# Generate skills based on occupation and age
	npc_data.skills = _generate_skills(occupation, age)
	
	# Generate salary based on occupation and age
	npc_data.resources.annual_income = _generate_salary_for_occupation(occupation, age)
	
	DB.create_npc(npc_data)

## Complete child appearance with age-appropriate details
func _complete_child_appearance(inherited_appearance: Dictionary, gender: String, age: int, tribe: String) -> Dictionary:
	var appearance = inherited_appearance.duplicate(true)
	
	# Age-appropriate hair style
	if age < 10:
		appearance["hair"]["style"] = "short" if gender == "male" else ["short", "ponytail", "braids"][rng.randi() % 3]
	elif age < 18:
		# Teen styles
		var styles = appearance_data.hair.styles.get(gender, ["short"])
		appearance["hair"]["style"] = styles[rng.randi() % styles.size()]
	
	# Facial hair (only for older males)
	if gender == "male" and age >= 16:
		var has_facial_hair = rng.randf() < 0.3  # 30% chance for teens
		if has_facial_hair:
			var facial_styles = appearance_data.get("facial_hair", {}).get("styles", ["stubble"])
			appearance["facial_hair"] = facial_styles[rng.randi() % facial_styles.size()]
		else:
			appearance["facial_hair"] = "none"
	else:
		appearance["facial_hair"] = "none"
	
	# Eyesight (random, not inherited)
	var eyesight_options = appearance_data.get("eyesight", {}).get("types", ["normal"])
	var eyesight_probs = appearance_data.get("eyesight", {}).get("probabilities", [1.0])
	var eyesight_idx = Utils.weighted_random(eyesight_options, eyesight_probs)
	appearance["eyesight"] = eyesight_options[eyesight_idx] if eyesight_idx >= 0 else "normal"
	
	# Age effects (children have none)
	appearance["age_effects"] = []
	
	return appearance

func _create_relationship(npc1_id: String, npc2_id: String, type: String, affection: int, trust: int = 50, attraction: int = 0, respect: int = 50, formed_date: String = ""):
	# Define reverse relationship types
	var reverse_type = type
	if type == "parent": reverse_type = "child"
	elif type == "child": reverse_type = "parent"
	elif type == "landlord": reverse_type = "tenant"
	elif type == "tenant": reverse_type = "landlord"
	elif type == "boss": reverse_type = "subordinate"
	elif type == "subordinate": reverse_type = "boss"
	# Other types (friend, colleague, spouse, sibling) are their own reverse
	
	# Create relationship 1 -> 2
	DB.create_relationship(npc1_id, npc2_id, type, affection, trust, attraction, respect, formed_date)
	
	# Create relationship 2 -> 1
	DB.create_relationship(npc2_id, npc1_id, reverse_type, affection, trust, attraction, respect, formed_date)

func _create_locations_need_based(density_ratio: float = 1.0):
	var _start_time = Time.get_ticks_msec()
	
	# 1. Calculate Demand
	# Housing: 1 unit per family + 1 unit per single (can share 2-3 singles per unit)
	var singles_units_needed = int(ceil(float(target_singles_count) / 2.0))  # 2 singles per unit on average
	var housing_units_needed = stats.families + singles_units_needed
	# Commercial: 1 unit per organization
	var commercial_units_needed = organization_frames.size()
	
	# Add buffers (20% vacancy) and apply density ratio
	var target_housing_units = int(housing_units_needed * 1.2 * density_ratio)
	var target_commercial_units = int(commercial_units_needed * 1.2 * density_ratio)
	
	print("   🏠 Housing Demand: %d units (Families: %d + Singles: %d → %d singles units)" % [target_housing_units, stats.families, target_singles_count, singles_units_needed])
	print("   🏢 Commercial Demand: %d units (Orgs: %d)" % [target_commercial_units, organization_frames.size()])
	
	# 2. Get Dynamic Districts from Database
	var districts = DB.get_all_districts()
	var num_districts = districts.size()
	
	if num_districts == 0:
		push_error("❌ No districts found! Cannot generate locations.")
		return
	
	var total_created_housing = 0
	var total_created_commercial = 0
	var location_id_counter = 0
	
	# 3. Calculate weighted sums for proportional distribution
	var total_res_weight = 0.0
	var total_comm_weight = 0.0
	var district_weights = {}
	
	for district in districts:
		var district_id = district.id
		var archetype = district_archetypes.get(district_id, null)
		if archetype == null:
			continue
		
		var ratios = archetype.get("ratios", {})
		var res_ratio = ratios.get("residential", 0.5)
		var comm_ratio = ratios.get("commercial", 0.3)
		
		district_weights[district_id] = {"res": res_ratio, "comm": comm_ratio}
		total_res_weight += res_ratio
		total_comm_weight += comm_ratio
	
	# 4. Generate Buildings per District (proportionally distributed)
	for district in districts:
		var district_id = district.id
		var archetype = district_archetypes.get(district_id, null)
		
		if archetype == null:
			push_error("❌ Archetype not found for district: %s" % district_id)
			continue
		
		var ratios = archetype.get("ratios", {})
		var demographics = archetype.get("demographics", {})
		
		# Calculate this district's proportional share
		var weights = district_weights[district_id]
		var housing_share = 0
		var commercial_share = 0
		
		if total_res_weight > 0:
			housing_share = int((weights.res / total_res_weight) * target_housing_units)
		if total_comm_weight > 0:
			commercial_share = int((weights.comm / total_comm_weight) * target_commercial_units)
		
		var district_housing_created = 0
		var district_commercial_created = 0
		
		# Generate Housing for this district
		while district_housing_created < housing_share:
			location_id_counter += 1
			var building_id = "loc_b_%d" % location_id_counter
			
			# Pick template based on wealth from demographics
			var wealth = demographics.get("wealth_preference", ["middle_class"])[0] if demographics.has("wealth_preference") else "medium"
			var template = _pick_location_template("residential", wealth)
			var capacity = rng.randi_range(template.capacity_range[0], template.capacity_range[1])
			
			# Create Building (Parent)
			_create_location_entry(building_id, template, district_id, null, capacity, "residential")
			
			# Create Units (Children)
			# Assume 1 unit = 5 capacity (avg family size)
			var num_units = max(1, capacity / 5)
			for u in range(num_units):
				location_id_counter += 1
				var unit_id = "loc_u_%d" % location_id_counter
				var unit_name = "Unit %d" % (u + 1)
				_create_location_entry(unit_id, {"name": "apartment_unit", "display_name": unit_name}, district_id, building_id, 5, "residential_unit")
				district_housing_created += 1
		
		# Generate Commercial for this district
		while district_commercial_created < commercial_share:
			location_id_counter += 1
			var building_id = "loc_b_%d" % location_id_counter
			
			var wealth = demographics.get("wealth_preference", ["middle_class"])[0] if demographics.has("wealth_preference") else "medium"
			var template = _pick_location_template("commercial", wealth)
			var capacity = rng.randi_range(template.capacity_range[0], template.capacity_range[1])
			
			_create_location_entry(building_id, template, district_id, null, capacity, "commercial")
			
			# Commercial units (Offices/Shops)
			var num_units = max(1, capacity / 20) # Assume 20 capacity per org unit
			for u in range(num_units):
				location_id_counter += 1
				var unit_id = "loc_u_%d" % location_id_counter
				var unit_name = "Suite %d" % (u + 1)
				_create_location_entry(unit_id, {"name": "office_unit", "display_name": unit_name}, district_id, building_id, 20, "commercial_unit")
				district_commercial_created += 1
				
		total_created_housing += district_housing_created
		total_created_commercial += district_commercial_created

	print("   ✅ Generated %d housing units (Target: %d)" % [total_created_housing, target_housing_units])
	print("   ✅ Generated %d commercial units (Target: %d)" % [total_created_commercial, target_commercial_units])

func _pick_location_template(category: String, wealth_level: String) -> Dictionary:
	# Fallback for missing categories (e.g., industrial)
	var target_category = category
	if not location_templates.has(target_category):
		if target_category == "industrial":
			target_category = "commercial" # Fallback
		elif target_category == "public":
			target_category = "commercial" # Fallback
		else:
			target_category = "residential" # Ultimate fallback
			
	var types = location_templates[target_category].types
	
	# Future enhancement: Filter by wealth_level
	# e.g. if wealth_level == "luxury", pick types with high prestige/condition
	
	return types[rng.randi() % types.size()]

func _create_location_entry(id: String, template: Dictionary, district: String, parent_id: Variant, capacity: int, type: String):
	# Generate name directly: use template name generator for buildings, display name for units
	var location_name = template.get("display_name", "Building")
	if parent_id == null and template.has("names"):
		# Building - generate proper name
		location_name = _generate_location_name(template, district)
	
	# Create location data for BOTH buildings and units
	var loc_data = {
		"id": id,
		"name": location_name,
		"type": type,
		"district_id": district,
		"building_id": parent_id if parent_id else null,
		"parent_location_id": parent_id if parent_id else null,
		"physical_properties": JSON.stringify({
			"capacity": capacity,
			"condition": rng.randi_range(50, 100)
		}),
		"access": JSON.stringify({"control_type": "private"}),
		"reputation": JSON.stringify({"safety": 50}),
		"features": JSON.stringify({"utilities": {}})
	}
	
	DB.create_location(loc_data)
	stats.locations += 1

# Helper functions

func _random_tribe() -> String:
	# NO FALLBACK - cultural_data is required
	if not cultural_data.has("tribes"):
		push_error("❌ CRITICAL: cultural_data missing 'tribes' field!")
		return "ERROR_NO_TRIBES"
	
	var tribes = []
	var weights = []
	
	for tribe_key in cultural_data.tribes.keys():
		var tribe_data = cultural_data.tribes[tribe_key]
		if tribe_data.has("population_percentage"):
			tribes.append(tribe_key)
			weights.append(tribe_data.population_percentage)
	
	if tribes.is_empty():
		push_error("❌ CRITICAL: No tribes with population_percentage found!")
		return "ERROR_NO_TRIBES"
	
	var index = Utils.weighted_random(tribes, weights)
	if index < 0:
		push_error("❌ CRITICAL: weighted_random failed for tribe selection!")
		return tribes[0]  # Fallback to first tribe
	
	return tribes[index]

func _random_first_name(tribe: String, gender: String) -> String:
	# NO FALLBACK - name_data is required
	if not name_data.has("people"):
		push_error("❌ CRITICAL: name_data missing 'people' field!")
		return "ERROR_NO_PEOPLE"
	
	var key = "given_names_male" if gender == "male" else "given_names_female"
	
	if not name_data.people.has(key):
		push_error("❌ CRITICAL: name_data.people missing '%s' field!" % key)
		return "ERROR_NO_GENDER_NAMES"
	
	var names = name_data.people[key]
	if not names is Array or names.is_empty():
		push_error("❌ CRITICAL: %s array is empty!" % key)
		return "ERROR_EMPTY_NAMES"
	
	return names[rng.randi() % names.size()]

func _random_last_name(_tribe: String) -> String:
	# NO FALLBACK - name_data is required
	if not name_data.has("people"):
		push_error("❌ CRITICAL: name_data missing 'people' field!")
		return "ERROR_NO_PEOPLE"
	
	if not name_data.people.has("surnames"):
		push_error("❌ CRITICAL: name_data.people missing 'surnames' field!")
		return "ERROR_NO_SURNAMES"
	
	var surnames = name_data.people.surnames
	if not surnames is Array or surnames.is_empty():
		push_error("❌ CRITICAL: surnames array is empty!")
		return "ERROR_EMPTY_SURNAMES"
	
	return surnames[rng.randi() % surnames.size()]

func _random_occupation(education: String, age: int) -> String:
	# NO FALLBACK - template is required
	if not skill_trees_data.has("occupations"):
		push_error("❌ CRITICAL: skill_trees_data missing 'occupations' field!")
		return "ERROR_NO_TEMPLATE"
	
	# Convert Dictionary to Array of occupation data
	var occupations_dict = skill_trees_data.occupations
	if occupations_dict.is_empty():
		push_error("❌ CRITICAL: skill_trees_data.occupations is empty!")
		return "ERROR_EMPTY_OCCUPATIONS"
	
	var occupations_list = occupations_dict.values()
	
	# Filter by education requirement
	var filtered = Utils.filter_by_education(occupations_list, education)
	
	if filtered.is_empty():
		# No occupations match this education level - this is an error in the template
		push_error("❌ WARNING: No occupations available for education level: %s" % education)
		return "student" if age < 25 else "unemployed"
	
	# Weight occupations by salary to correlate education with income
	# Higher education should tend toward higher-paying jobs
	var occupation_options = []
	var weights = []
	
	for occ in filtered:
		occupation_options.append(occ)
		
		# Use average salary as weight
		var salary_weight = 1.0
		if occ.has("typical_salary_range") and occ.typical_salary_range is Array and occ.typical_salary_range.size() == 2:
			var avg_salary = (occ.typical_salary_range[0] + occ.typical_salary_range[1]) / 2.0
			# Normalize to reasonable weight (salary in millions = weight)
			salary_weight = max(1.0, avg_salary / 1000000.0)
		
		weights.append(salary_weight)
	
	# Use weighted random selection
	var selected_index = Utils.weighted_random(occupation_options, weights)
	if selected_index < 0 or selected_index >= occupation_options.size():
		# Fallback to first option
		selected_index = 0
	
	var occupation_data = occupation_options[selected_index]
	if not occupation_data.has("display_name"):
		push_error("❌ CRITICAL: Occupation template missing 'display_name' field!")
		return "ERROR_MALFORMED_TEMPLATE"
	
	return occupation_data.display_name

func _random_education() -> String:
	# 5-level education system: none, primary, secondary, undergraduate, postgraduate
	var options = ["none", "primary", "secondary", "undergraduate", "postgraduate"]
	var weights = [0.10, 0.20, 0.35, 0.25, 0.10]
	var roll = rng.randf()
	var cumulative = 0.0
	for i in range(options.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			return options[i]
	return "secondary"  # Default fallback

func _random_religion(tribe: String) -> String:
	# NO FALLBACK - cultural data is required
	if not cultural_data.has("tribes"):
		push_error("❌ CRITICAL: cultural_data missing 'tribes' field!")
		return "ERROR_NO_TRIBES"
	
	if not cultural_data.tribes.has(tribe):
		push_error("❌ CRITICAL: cultural_data.tribes missing tribe: %s" % tribe)
		return "ERROR_UNKNOWN_TRIBE"
	
	var tribe_data = cultural_data.tribes[tribe]
	if not tribe_data.has("religion_distribution"):
		push_error("❌ CRITICAL: tribe %s missing 'religion_distribution' field!" % tribe)
		return "ERROR_NO_RELIGION_DATA"
	
	var dist = tribe_data.religion_distribution
	var options = []
	var weights = []
	for religion in dist.keys():
		options.append(religion)
		weights.append(dist[religion])
	
	if options.is_empty():
		push_error("❌ CRITICAL: tribe %s has empty religious_distribution!" % tribe)
		return "ERROR_EMPTY_RELIGIONS"
	
	var index = Utils.weighted_random(options, weights)
	if index < 0:
		push_error("❌ CRITICAL: weighted_random failed for religion selection!")
		return "ERROR_RANDOM_FAILED"
	
	return options[index]

func _get_npc_gender(npc_id: String) -> String:
	var npc = DB.get_npc(npc_id)
	if npc.is_empty():
		return "male"
	if npc.has("definite") and npc.definite is Dictionary:
		return npc.definite.get("gender", "male")
	return "male"

func _generate_personality(tribe: String) -> Dictionary:
	# Base personality
	var personality = {
		"ambition": rng.randi_range(30, 90),
		"compassion": rng.randi_range(30, 90),
		"volatility": rng.randi_range(20, 70),
		"openness": rng.randi_range(30, 80),
		"gender_bias": rng.randi_range(0, 50),
		"ethnic_prejudice": rng.randi_range(0, 40),
		"class_bias": rng.randi_range(0, 60),
		"religious_intolerance": rng.randi_range(0, 50),
		"social_conformity": rng.randi_range(30, 80)
	}
	
	# Apply cultural modifiers if available
	if cultural_data.has("tribes") and cultural_data.tribes.has(tribe):
		var tribe_data = cultural_data.tribes[tribe]
		if tribe_data.has("cultural_values"):
			var values = tribe_data.cultural_values
			
			# Apply modifiers (±10-20 points based on cultural values)
			if values.has("individualism"):
				var modifier = (values.individualism - 50) * 0.3
				personality.ambition = clampi(int(personality.ambition + modifier), 0, 100)
			
			if values.has("collectivism"):
				var modifier = (values.collectivism - 50) * 0.3
				personality.social_conformity = clampi(int(personality.social_conformity + modifier), 0, 100)
			
			if values.has("achievement_orientation"):
				var modifier = (values.achievement_orientation - 50) * 0.3
				personality.ambition = clampi(int(personality.ambition + modifier), 0, 100)
	
	return personality

func _generate_political_ideology() -> Dictionary:
	return {
		"social_conservatism": rng.randi_range(20, 80),
		"economic_conservatism": rng.randi_range(20, 80),
		"authoritarianism": rng.randi_range(10, 60),
		"nationalism": rng.randi_range(30, 80),
		"religious_devotion": rng.randi_range(30, 90),
		"environmentalism": rng.randi_range(20, 70)
	}

func _generate_skills(occupation: String, age: int) -> Dictionary:
	# NO FALLBACK - skill_trees template is required
	if not skill_trees_data.has("occupations"):
		push_error("❌ CRITICAL: skill_trees_data missing 'occupations' field!")
		return {}
	
	if skill_trees_data.occupations.is_empty():
		push_error("❌ CRITICAL: skill_trees_data.occupations is empty!")
		return {}
	
	# Find occupation in template by matching display_name
	var occ_data = null
	for occ_key in skill_trees_data.occupations.keys():
		var occ = skill_trees_data.occupations[occ_key]
		if occ.get("display_name", "") == occupation:
			occ_data = occ
			break
	
	if occ_data == null:
		# Occupation not found in template - this is an error!
		push_error("❌ CRITICAL: Occupation '%s' not found in skill_trees template!" % occupation)
		return {}
	
	# Build skill-to-category mapping from skill_categories
	var skill_to_category = {}
	if skill_trees_data.has("skill_categories"):
		for cat_key in skill_trees_data.skill_categories.keys():
			var cat_data = skill_trees_data.skill_categories[cat_key]
			if cat_data.has("specific_skills"):
				for skill_name in cat_data.specific_skills.keys():
					# Map "tech_skills" → "tech", "business_skills" → "business", etc.
					var simplified_cat = cat_key.replace("_skills", "")
					skill_to_category[skill_name] = simplified_cat
	
	# Reorganize flat skills into categorized structure
	var occupation_skills = {}
	
	# Add primary skills
	if occ_data.has("primary_skills"):
		for skill_name in occ_data.primary_skills.keys():
			var skill_range = occ_data.primary_skills[skill_name]
			var category = skill_to_category.get(skill_name, "street")  # Fallback to "street" if unknown
			if not occupation_skills.has(category):
				occupation_skills[category] = {}
			occupation_skills[category][skill_name] = skill_range
	
	# Add secondary skills
	if occ_data.has("secondary_skills"):
		for skill_name in occ_data.secondary_skills.keys():
			var skill_range = occ_data.secondary_skills[skill_name]
			var category = skill_to_category.get(skill_name, "street")
			if not occupation_skills.has(category):
				occupation_skills[category] = {}
			occupation_skills[category][skill_name] = skill_range
	
	# Map to NPC structure with age factoring
	return Utils.map_template_skills_to_npc(occupation_skills, age)

func _generate_appearance(gender: String, age: int, tribe: String, _parent_ids: Array) -> Dictionary:
	# NO FALLBACK - appearance template is required
	if appearance_data.is_empty():
		push_error("❌ CRITICAL: appearance_data is empty!")
		return {}
	
	# Generate appearance from template
	if not appearance_data.is_empty():  # Keep original structure
		var appearance = {}
		
		# Height - gender-specific normal distribution
		var height_data = appearance_data.get("height", {})
		if gender == "male":
			var male_height = height_data.get("male", {"mean": 172, "std_dev": 7, "min": 155, "max": 200})
			appearance["height"] = int(Utils.generate_normal(float(male_height.mean), float(male_height.std_dev), float(male_height.min), float(male_height.max)))
		else:
			var female_height = height_data.get("female", {"mean": 162, "std_dev": 6, "min": 145, "max": 190})
			appearance["height"] = int(Utils.generate_normal(float(female_height.mean), float(female_height.std_dev), float(female_height.min), float(female_height.max)))
		
		# Body build - weighted probabilities with age modifiers
		var build_data = appearance_data.get("body_build", {})
		var build_types = []
		var build_probabilities = []
		
		# Convert dictionary structure to arrays
		for build_type in build_data.keys():
			if build_type == "age_modifiers":
				continue  # Skip the age_modifiers key
			build_types.append(build_type)
			build_probabilities.append(build_data[build_type].get("probability", 0.25))
		
		# Ensure we have data before applying age modifiers
		if build_types.is_empty():
			# Fallback to defaults if template has no build data
			build_types = ["slim", "average", "athletic", "heavy"]
			build_probabilities = [0.25, 0.40, 0.20, 0.15]
		
		# Apply age modifiers only if we have exactly 4 build types (slim, average, athletic, heavy)
		if build_types.size() == 4:
			if age < 18:
				# Children: more slim
				build_probabilities = [0.50, 0.35, 0.10, 0.05]
			elif age < 30:
				# Young adults: more athletic
				build_probabilities = [0.20, 0.35, 0.30, 0.15]
			elif age > 60:
				# Elders: more heavy/average
				build_probabilities = [0.15, 0.40, 0.10, 0.35]
		
		var build_index = Utils.weighted_random(build_types, build_probabilities)
		appearance["build"] = build_types[build_index] if build_index >= 0 else "average"
		
		# Skin tone - weighted probabilities
		var skin_data = appearance_data.get("skin_tone", {})
		var skin_categories = skin_data.get("categories", {})
		var skin_types = []
		var skin_probs = []
		for skin_type in skin_categories.keys():
			skin_types.append(skin_type)
			skin_probs.append(skin_categories[skin_type].get("probability", 0.2))
		
		var skin_index = Utils.weighted_random(skin_types, skin_probs)
		if skin_index >= 0:
			appearance["skin_tone"] = skin_types[skin_index]
			appearance["skin_tone_hex"] = skin_categories[skin_types[skin_index]].get("hex", "#8D5524")
		else:
			appearance["skin_tone"] = "medium"
			appearance["skin_tone_hex"] = "#8D5524"
		
		# Facial features
		var facial_data = appearance_data.get("facial_features", {})
		appearance["facial_features"] = {
			"nose": _weighted_select(facial_data.get("nose", ["narrow", "average", "broad"])),
			"eyes": _weighted_select(facial_data.get("eyes", ["small", "average", "large"])),
			"lips": _weighted_select(facial_data.get("lips", ["thin", "medium", "full"])),
			"face_shape": _weighted_select(facial_data.get("face_shape", ["oval", "round", "square", "heart"]))
		}
		
		# Hair
		var hair_data = appearance_data.get("hair", {})
		var hair_textures = hair_data.get("texture", {})
		var texture_types = []
		var texture_probs = []
		for texture in hair_textures.keys():
			texture_types.append(texture)
			texture_probs.append(hair_textures[texture].get("probability", 0.25))
		
		var hair_texture = "coily"  # Default
		if not texture_types.is_empty():
			var texture_index = Utils.weighted_random(texture_types, texture_probs)
			if texture_index >= 0 and texture_index < texture_types.size():
				hair_texture = texture_types[texture_index]
		
		appearance["hair"] = {
			"texture": hair_texture,
			"style": _select_hair_style(gender, age, hair_data)
		}
		
		# Facial hair (males only)
		if gender == "male":
			appearance["facial_hair"] = _generate_facial_hair(age, appearance_data.get("facial_hair", {}))
		else:
			appearance["facial_hair"] = "none"
		
		# Eyesight
		var _eyesight_data = appearance_data.get("eyesight", {})  # Reserved for future detailed eyesight generation
		var eyesight_types = ["normal", "short_sighted", "long_sighted", "color_blind"]
		var eyesight_probs = [0.75, 0.15, 0.07, 0.03]
		var eyesight_index = Utils.weighted_random(eyesight_types, eyesight_probs)
		appearance["eyesight"] = eyesight_types[eyesight_index] if eyesight_index >= 0 else "normal"
		
		# Distinguishing marks
		appearance["marks"] = _generate_marks(age, tribe, appearance_data.get("distinguishing_marks", {}))
		
		# Age effects
		appearance["age_effects"] = _generate_age_effects(age)
		
		return appearance
	
	# Should never reach here
	push_error("❌ CRITICAL: Unexpected state in _generate_appearance!")
	return {}

func _weighted_select(options: Array) -> String:
	if options.is_empty():
		return ""
	return options[rng.randi() % options.size()]

func _select_hair_style(gender: String, age: int, hair_data: Dictionary) -> String:
	var styles_key = "male_styles" if gender == "male" else "female_styles"
	var styles = hair_data.get(styles_key, ["short", "medium", "long"])
	
	# Apply age restrictions
	if age < 18:
		styles = ["short", "medium"]  # Simpler styles for children
	elif age > 60:
		styles = ["short", "medium"]  # More conservative styles for elders
	
	return _weighted_select(styles)

func _generate_facial_hair(age: int, facial_hair_data: Dictionary) -> String:
	var styles = facial_hair_data.get("styles", ["none", "beard", "mustache", "goatee"])
	var _probabilities = facial_hair_data.get("age_probability", {})  # Reserved for future use
	
	# Age-based probability of having facial hair
	var has_facial_hair_chance = 0.0
	if age < 18:
		has_facial_hair_chance = 0.05
	elif age < 30:
		has_facial_hair_chance = 0.45
	elif age < 60:
		has_facial_hair_chance = 0.55
	else:
		has_facial_hair_chance = 0.40
	
	if rng.randf() > has_facial_hair_chance:
		return "none"
	
	# Select style (excluding "none")
	var style_options = []
	for style in styles:
		if style != "none":
			style_options.append(style)
	
	return _weighted_select(style_options)

func _generate_marks(age: int, tribe: String, marks_data: Dictionary) -> Dictionary:
	var overall_probability = marks_data.get("overall_probability", 0.35)
	
	if rng.randf() > overall_probability:
		return {"has_marks": false}
	
	var mark_types = marks_data.get("types", ["scar", "birthmark", "tribal_mark", "tattoo", "burn_mark"])
	var selected_type = _weighted_select(mark_types)
	
	# Special handling for tribal marks
	if selected_type == "tribal_mark":
		# Only for certain tribes and older NPCs (declining practice)
		if age > 50 or (tribe in ["yoruba", "edo"] and age > 30 and rng.randf() < 0.3):
			return {
				"has_marks": true,
				"type": "tribal_mark",
				"location": _weighted_select(["face", "arms", "chest"])
			}
		else:
			# Switch to another mark type
			selected_type = _weighted_select(["scar", "birthmark"])
	
	return {
		"has_marks": true,
		"type": selected_type,
		"location": _weighted_select(["face", "arms", "legs", "back", "chest"])
	}

func _generate_age_effects(age: int) -> Dictionary:
	var effects = {
		"gray_hair": false,
		"wrinkles": false,
		"posture_change": false
	}
	
	if age >= 40:
		# Hair graying starts at 40, progressively increases
		var gray_chance = (age - 40) * 0.05  # 0% at 40, 100% at 60
		effects["gray_hair"] = rng.randf() < gray_chance
	
	if age >= 45:
		# Wrinkles start at 45
		var wrinkle_chance = (age - 45) * 0.04
		effects["wrinkles"] = rng.randf() < wrinkle_chance
	
	if age >= 60:
		# Posture changes at 60
		effects["posture_change"] = true
	
	return effects

func _generate_orientation() -> int:
	# Generate sexual orientation on a slider
	# -100 = purely same-sex attracted
	# 0 = bisexual
	# 100 = purely heterosexual
	# Most people are hetero, with some variation
	
	var roll = rng.randf()
	
	# 85% heterosexual leaning (50 to 100)
	if roll < 0.85:
		return rng.randi_range(50, 100)
	# 5% bisexual (-30 to 30)
	elif roll < 0.90:
		return rng.randi_range(-30, 30)
	# 10% same-sex leaning (-100 to -50)
	else:
		return rng.randi_range(-100, -50)

func _generate_salary_for_occupation(occupation: String, age: int) -> int:
	# NO FALLBACK - skill_trees template is required
	if not skill_trees_data.has("occupations"):
		push_error("❌ CRITICAL: skill_trees_data missing 'occupations' field!")
		return 0
	
	# Find occupation in template by matching display_name
	var occ_data = null
	for occ_key in skill_trees_data.occupations.keys():
		var occ = skill_trees_data.occupations[occ_key]
		if occ.get("display_name", "") == occupation:
			occ_data = occ
			break
	
	if occ_data == null:
		# Occupation not found - this is an error!
		push_error("❌ CRITICAL: Occupation '%s' not found in skill_trees for salary!" % occupation)
		return 0
	
	if not occ_data.has("typical_salary_range"):
		push_error("❌ CRITICAL: Occupation '%s' missing 'typical_salary_range' field!" % occupation)
		return 0
	
	if not occ_data.typical_salary_range is Array or occ_data.typical_salary_range.size() != 2:
		push_error("❌ CRITICAL: Occupation '%s' has malformed salary_range!" % occupation)
		return 0
	
	var salary_range = occ_data.typical_salary_range
	var min_salary = float(salary_range[0])
	var max_salary = float(salary_range[1])
	
	# Factor in age/experience
	# Younger workers (18-30) get lower end, older (45+) get upper end
	var experience_factor = 0.5
	if age >= 45:
		experience_factor = 1.0
	elif age >= 30:
		experience_factor = 0.7 + float(age - 30) * 0.02
	else:
		experience_factor = 0.5 + float(age - 18) * 0.016
	
	var range_width = max_salary - min_salary
	var adjusted_min = min_salary + range_width * (experience_factor - 0.3)
	var adjusted_max = min_salary + range_width * (experience_factor + 0.3)
	
	adjusted_min = max(min_salary, int(adjusted_min))
	adjusted_max = min(max_salary, int(adjusted_max))
	
	return rng.randi_range(int(adjusted_min), int(adjusted_max))

func _generate_org_name(org_type: String, org_id: int) -> String:
	# TODO: Implement proper template-based name generation (Phase 5)
	# For now, return a simple placeholder name
	return "%s Organization %d" % [org_type.capitalize(), org_id]

func _get_random_nigerian_name() -> String:
	# Get a random Nigerian name from cultural_data - NO FALLBACK
	if not cultural_data.has("tribes"):
		push_error("❌ CRITICAL: cultural_data missing 'tribes' for org name generation!")
		return "ERROR_NO_TRIBES"
	
	var tribes = cultural_data.tribes.keys()
	if tribes.is_empty():
		push_error("❌ CRITICAL: cultural_data.tribes is empty!")
		return "ERROR_EMPTY_TRIBES"
	
	var tribe = tribes[rng.randi() % tribes.size()]
	var tribe_data = cultural_data.tribes[tribe]
	
	if not tribe_data.has("names"):
		push_error("❌ CRITICAL: tribe %s missing 'names'!" % tribe)
		return "ERROR_NO_NAMES"
	
	if not tribe_data.names.has("surnames"):
		push_error("❌ CRITICAL: tribe %s names missing 'surnames'!" % tribe)
		return "ERROR_NO_SURNAMES"
	
	var surnames = tribe_data.names.surnames
	if not surnames is Array or surnames.is_empty():
		push_error("❌ CRITICAL: tribe %s surnames is empty!" % tribe)
		return "ERROR_EMPTY_SURNAMES"
	
	return surnames[rng.randi() % surnames.size()]

func _get_random_saint_name() -> String:
	var saints = ["Michael", "Paul", "Peter", "John", "Mary", "Joseph", "Francis", "Teresa", "Anthony"]
	return saints[rng.randi() % saints.size()]

func _get_random_lagos_location() -> String:
	var locations = ["Victoria Island", "Lekki", "Ikeja", "Surulere", "Yaba", "Maryland", "Festac"]
	return locations[rng.randi() % locations.size()]

func _get_random_descriptor() -> String:
	var descriptors = ["Premier", "Royal", "Grand", "Central", "New", "Modern", "Elite", "Supreme"]
	return descriptors[rng.randi() % descriptors.size()]

func _generate_attributes(age: int) -> Dictionary:
	# Generate RPG-style attributes
	# These affect attraction, interactions, and gameplay
	# Age affects some attributes (strength/agility decline, wisdom increases)
	
	var base_strength = rng.randi_range(30, 90)
	var base_agility = rng.randi_range(30, 90)
	
	# Adjust for age
	if age > 50:
		base_strength -= (age - 50) / 2  # Decline with age
		base_agility -= (age - 50) / 2
	elif age < 25:
		base_strength -= (25 - age) * 0.5  # Still developing
	
	return {
		"beauty": rng.randi_range(20, 95),  # Physical attractiveness
		"strength": max(10, int(base_strength)),  # Physical power
		"intellect": rng.randi_range(30, 95),  # Mental capacity
		"charisma": rng.randi_range(20, 95),  # Social charm/persuasion
		"constitution": rng.randi_range(40, 95),  # Health/endurance
		"agility": max(10, int(base_agility))  # Speed/reflexes
	}

func _generate_location_name(template: Dictionary, district: String) -> String:
	if template.has("names"):
		var name_options = template.names
		return "%s (%s)" % [name_options[rng.randi() % name_options.size()], district.capitalize()]
	else:
		return "%s (%s)" % [template.name.capitalize(), district.capitalize()]

## Phase 2B: Generate Organization Frames (Demand-Based System)
## Organizations emerge from population needs, not arbitrary counts
## Scaling: 500 NPCs → ~25-35 orgs, 1000 NPCs → ~45-60 orgs, 5000 NPCs → ~150-200 orgs

# Track created orgs to prevent duplicates
var _created_org_types = {}  # district_id -> {subcategory -> count}
var _org_id_counter = 0

func _generate_organization_frames(target_npcs: int, density_ratio: float = 1.0):
	if not org_templates.has("categories"):
		push_error("❌ CRITICAL: organization_templates.json missing 'categories'!")
		return
	
	# Get districts from database
	var all_districts = DB.get_all_districts()
	var districts = []
	for d in all_districts:
		districts.append(d.id)
	
	if districts.is_empty():
		push_error("❌ CRITICAL: No districts found in database!")
		return
	
	# Reset tracking
	_created_org_types.clear()
	_org_id_counter = 0
	
	# Calculate demand based on simulated world needs
	var demand = _calculate_org_demand(target_npcs, districts.size(), density_ratio)
	
	print("   📊 Demand-based org generation for %d NPCs, %d districts:" % [target_npcs, districts.size()])
	print("      • Essential infrastructure: %d" % demand.essential_total)
	print("      • Religious orgs: %d" % demand.religious_total)
	print("      • Employment orgs: %d" % demand.employment_total)
	print("      • Social/other orgs: %d" % demand.social_total)
	print("      • Target total: %d orgs" % demand.total_orgs)
	
	# Step 1: Essential Infrastructure (guaranteed, 1 per district)
	_generate_essential_infrastructure(districts, demand)
	
	# Step 2: Religious Organizations (match demographics)
	_generate_religious_orgs_by_demand(districts, demand)
	
	# Step 3: Employment Organizations (businesses, fill workforce)
	_generate_employment_orgs(districts, demand)
	
	# Step 4: Social & Criminal Organizations
	_generate_social_criminal_orgs(districts, demand)
	
	print("   ✅ Created %d organizations total" % organization_frames.size())

func _calculate_org_demand(target_npcs: int, district_count: int, density_ratio: float) -> Dictionary:
	# Population breakdown (simulated)
	var adults = int(target_npcs * 0.58)  # 58% adults (18+)
	var children = target_npcs - adults
	var workers = int(adults * 0.65)  # 65% employment rate
	
	# Religious demographics (typical Lagos mix)
	var christian_pct = 0.65
	var muslim_pct = 0.25
	var traditional_pct = 0.10
	
	# --- ESSENTIAL INFRASTRUCTURE ---
	# 1 school + 1 clinic + 1 police per district = 3 per district
	var essential_per_district = 3
	var essential_total = district_count * essential_per_district
	
	# --- RELIGIOUS ORGANIZATIONS ---
	# Congregation sizes: Churches ~60-100, Mosques ~80-120, Shrines ~30-50
	var christian_npcs = int(target_npcs * christian_pct)
	var muslim_npcs = int(target_npcs * muslim_pct)
	var traditional_npcs = int(target_npcs * traditional_pct)
	
	# Scale: 1 church per 80 Christians, 1 mosque per 100 Muslims, 1 shrine per 100 Traditional
	var churches_needed = max(district_count, int(ceil(float(christian_npcs) / 80.0)))
	var mosques_needed = max(1, int(ceil(float(muslim_npcs) / 100.0)))
	var shrines_needed = max(1, int(ceil(float(traditional_npcs) / 100.0)))
	var religious_total = churches_needed + mosques_needed + shrines_needed
	
	# --- EMPLOYMENT ORGANIZATIONS ---
	# Average org employs 15-25 people in simulation (use 20 as baseline for consistent calculation)
	# Target: enough orgs to potentially employ ~80% of workers (some unemployed is realistic)
	var avg_org_size = 20  # Fixed average for consistent scaling
	var employment_capacity_needed = int(workers * 0.80)
	var employment_orgs_needed = max(district_count, int(ceil(float(employment_capacity_needed) / float(avg_org_size))))
	
	# Apply density ratio
	employment_orgs_needed = int(employment_orgs_needed * density_ratio)
	
	# --- SOCIAL & CRIMINAL ---
	# 1 ethnic association per major tribe represented
	# 1 sports club per 400 NPCs
	# 1 gang per 2 districts (if tense)
	var ethnic_associations = min(3, max(1, district_count))  # Yoruba, Igbo, Hausa
	var sports_clubs = max(1, int(ceil(float(target_npcs) / 400.0)))
	var gangs = max(1, int(ceil(float(district_count) / 2.0)))
	var social_total = ethnic_associations + sports_clubs + gangs
	
	var total_orgs = essential_total + religious_total + employment_orgs_needed + social_total
	
	return {
		"target_npcs": target_npcs,
		"district_count": district_count,
		"adults": adults,
		"children": children,
		"workers": workers,
		"density_ratio": density_ratio,
		
		# Essential
		"essential_per_district": essential_per_district,
		"essential_total": essential_total,
		
		# Religious breakdown
		"christian_pct": christian_pct,
		"muslim_pct": muslim_pct,
		"traditional_pct": traditional_pct,
		"churches_needed": churches_needed,
		"mosques_needed": mosques_needed,
		"shrines_needed": shrines_needed,
		"religious_total": religious_total,
		
		# Employment
		"employment_total": employment_orgs_needed,
		"avg_org_size": avg_org_size,
		
		# Social
		"ethnic_associations": ethnic_associations,
		"sports_clubs": sports_clubs,
		"gangs": gangs,
		"social_total": social_total,
		
		"total_orgs": total_orgs
	}

func _generate_essential_infrastructure(districts: Array, demand: Dictionary):
	print("   🏛️ Generating essential infrastructure...")
	
	for district in districts:
		# 1. School (Primary or Secondary based on simulation needs)
		var school_type = "primary_schools" if rng.randf() < 0.6 else "secondary_schools"
		_create_org_tracked("education", school_type, district)
		
		# 2. Healthcare (Clinic for most, Hospital for larger districts)
		var health_type = "clinics" if demand.target_npcs < 2000 else "hospitals"
		_create_org_tracked("healthcare", health_type, district)
		
		# 3. Police/Government
		_create_org_tracked("government", "police", district)
	
	# City-wide institutions (only 1 each)
	if demand.target_npcs >= 1000:
		# Add a hospital if world is large enough
		_create_org_tracked("healthcare", "hospitals", districts[0])
	
	if demand.target_npcs >= 500:
		# Local government council
		_create_org_tracked("government", "local_government", districts[0])

func _generate_religious_orgs_by_demand(districts: Array, demand: Dictionary):
	print("   ⛪ Generating religious organizations by demographic demand...")
	
	var district_idx = 0
	
	# Churches - distribute across districts
	for i in range(demand.churches_needed):
		var district = districts[district_idx % districts.size()]
		_create_org_tracked("religious", "christian_churches", district)
		district_idx += 1
	
	# Mosques - distribute across districts
	for i in range(demand.mosques_needed):
		var district = districts[district_idx % districts.size()]
		_create_org_tracked("religious", "mosques", district)
		district_idx += 1
	
	# Traditional shrines
	for i in range(demand.shrines_needed):
		var district = districts[district_idx % districts.size()]
		_create_org_tracked("religious", "traditional_shrines", district)
		district_idx += 1
	
	print("      Created: %d churches, %d mosques, %d shrines" % [
		demand.churches_needed, demand.mosques_needed, demand.shrines_needed
	])

func _generate_employment_orgs(districts: Array, demand: Dictionary):
	print("   🏢 Generating employment organizations...")
	
	# Business type distribution (weighted for Lagos economy)
	var business_types = [
		{"subcategory": "markets", "weight": 20, "category": "business"},
		{"subcategory": "restaurants_and_bukas", "weight": 25, "category": "business"},
		{"subcategory": "tech_companies", "weight": 10, "category": "business"},
		{"subcategory": "banks_and_mfb", "weight": 8, "category": "business"},
		{"subcategory": "media_and_entertainment", "weight": 5, "category": "business"},
		{"subcategory": "transport_unions", "weight": 12, "category": "transport"},
		{"subcategory": "logistics_companies", "weight": 10, "category": "transport"},
		{"subcategory": "professional_associations", "weight": 5, "category": "social"},
		{"subcategory": "courts", "weight": 5, "category": "government"}
	]
	
	var type_names = []
	var type_weights = []
	for bt in business_types:
		type_names.append(bt)
		type_weights.append(bt.weight)
	
	var orgs_created = 0
	var district_idx = 0
	
	for i in range(demand.employment_total):
		# Pick business type
		var type_idx = Utils.weighted_random(type_names, type_weights)
		var biz_type = business_types[type_idx]
		
		# Distribute across districts
		var district = districts[district_idx % districts.size()]
		district_idx += 1
		
		# Check if we already have too many of this type in this district
		var existing = _get_org_count(district, biz_type.subcategory)
		if existing >= 3:  # Max 3 of same type per district
			# Try a different type
			type_idx = (type_idx + 1) % business_types.size()
			biz_type = business_types[type_idx]
		
		_create_org_tracked(biz_type.category, biz_type.subcategory, district)
		orgs_created += 1
	
	print("      Created %d employment organizations" % orgs_created)

func _generate_social_criminal_orgs(districts: Array, demand: Dictionary):
	print("   🤝 Generating social and criminal organizations...")
	
	# Ethnic associations
	var tribes = ["Yoruba", "Igbo", "Hausa"]
	for i in range(min(demand.ethnic_associations, tribes.size())):
		var district = districts[i % districts.size()]
		_create_org_tracked("social", "ethnic_associations", district)
	
	# Sports clubs
	for i in range(demand.sports_clubs):
		var district = districts[i % districts.size()]
		_create_org_tracked("social", "sports_clubs", district)
	
	# Criminal - gangs and fraud rings
	for i in range(demand.gangs):
		var district = districts[i % districts.size()]
		if rng.randf() < 0.7:
			_create_org_tracked("criminal", "street_gangs", district)
		else:
			_create_org_tracked("criminal", "fraud_rings", district)
	
	print("      Created %d ethnic associations, %d sports clubs, %d criminal orgs" % [
		demand.ethnic_associations, demand.sports_clubs, demand.gangs
	])

func _create_org_tracked(category: String, subcategory: String, district: String):
	"""Create an org and track it to prevent duplicates"""
	_org_id_counter += 1
	_create_organization_from_template(category, _org_id_counter, district, subcategory)
	
	# Track creation
	if not _created_org_types.has(district):
		_created_org_types[district] = {}
	_created_org_types[district][subcategory] = _created_org_types[district].get(subcategory, 0) + 1

func _get_org_count(district: String, subcategory: String) -> int:
	"""Get count of orgs of this type already created in district"""
	if not _created_org_types.has(district):
		return 0
	return _created_org_types[district].get(subcategory, 0)

func _create_organization_from_template(category: String, id_num: int, district: String, forced_subcategory: String = ""):
	# Get category data from template
	if not org_templates.categories.has(category):
		push_error("❌ Category '%s' not found in org_templates!" % category)
		return
	
	var category_data = org_templates.categories[category]
	
	# Select subcategory
	var subcategory_key = forced_subcategory
	if subcategory_key == "":
		var subcategory_keys = category_data.keys()
		if subcategory_keys.is_empty():
			return
		subcategory_key = subcategory_keys[rng.randi() % subcategory_keys.size()]
	
	var subcategory_data = category_data[subcategory_key]
	
	# Handle array of templates (pick one)
	var template_data = subcategory_data
	if subcategory_data is Array:
		if subcategory_data.is_empty():
			return
		template_data = subcategory_data[rng.randi() % subcategory_data.size()]
	
	if not (template_data is Dictionary):
		return
	
	# Select size
	var org_size = "medium"
	var member_range = [20, 100]
	if template_data.has("size_distribution"):
			var sizes = []
			var weights = []
			var size_dist = template_data.size_distribution
			for size_key in size_dist.keys():
				sizes.append(size_key)
				var size_data = size_dist[size_key]
				if size_data is Dictionary:
					weights.append(size_data.get("weight", 1))
				elif size_data is Array and size_data.size() >= 1:
					weights.append(size_data[0] if size_data[0] is int or size_data[0] is float else 1)
				else:
					weights.append(1)
			
			if sizes.size() > 0:
				var size_idx = Utils.weighted_random(sizes, weights)
				org_size = sizes[size_idx]
				var size_entry = size_dist[org_size]
				if size_entry is Dictionary and size_entry.has("member_range"):
					member_range = size_entry.member_range
				elif size_entry is Array and size_entry.size() >= 2 and size_entry[1] is Array:
					member_range = size_entry[1]
	
	# Generate name
	var org_name = _generate_org_name_from_template(template_data, category, id_num)
	
	# Get positions
	var positions = []
	if template_data.has("positions"):
		positions = template_data.positions.duplicate(true)
	
	# Generate reputation/resources
	var reputation_base = _get_reputation_for_category(category)
	var wealth_base = _get_wealth_for_category(category)
	var size_multiplier = _get_size_multiplier(org_size)
	
	# Determine legal status based on category
	var legal_status = "registered"
	if category == "criminal":
		legal_status = "illegal"
	elif category == "social":
		legal_status = "informal"
	
	# Get pillars from template or use defaults
	var pillars = ["service", "community"]
	if template_data.has("typical_pillars"):
		pillars = template_data.typical_pillars.duplicate()
	
	var org_frame = {
		"id": "org_%d" % id_num,
		"name": org_name,
		"category": category,           # High-level: religious, education, business, etc.
		"subcategory": subcategory_key, # Specific: christian_churches, tech_companies, etc.
		"type": subcategory_key,        # For DB queries - use subcategory as type
		"size": org_size,
		"member_range": member_range,
		"district": district,
		"founded": 2025 - rng.randi_range(5, 50),
		"location_id": null,
		"legal_status": legal_status,
		"pillars": pillars,
		"reputation": {
			"trustworthiness": reputation_base,
			"innovation": rng.randi_range(30, 70),
			"morality": rng.randi_range(40, 80),
			"conservatism": rng.randi_range(30, 70),
			"influence": int(reputation_base * size_multiplier)
		},
		"resources": {
			"liquid_assets": int(wealth_base * size_multiplier),
			"property": []
		},
		"computed_values": {},
		"positions": positions,
		"filled_positions": []
	}
	
	organization_frames.append(org_frame)
	
	# Create DB record - store both category and type for flexible querying
	var org_data = {
		"id": org_frame.id,
		"name": org_frame.name,
		"type": org_frame.category,     # Store category as type for backward compat
		"founded": org_frame.founded,
		"location_id": org_frame.location_id,
		"legal_status": org_frame.legal_status,
		"pillars": JSON.stringify(org_frame.pillars),
		"reputation": JSON.stringify(org_frame.reputation),
		"resources": JSON.stringify(org_frame.resources),
		"computed_values": JSON.stringify({
			"category": org_frame.category,
			"subcategory": org_frame.subcategory,
			"district_id": district,
			"size": org_size
		})
	}
	
	DB.create_organization(org_data)
	stats.organizations += 1

func _generate_org_name_from_template(subcategory_data: Dictionary, category: String, org_id: int) -> String:
	if subcategory_data.has("name_template"):
		var template = subcategory_data.name_template
		var org_name = template
		
		# Replace {denomination} or similar
		if template.find("{denomination}") != -1 and subcategory_data.has("denominations"):
			var denoms = subcategory_data.denominations
			org_name = org_name.replace("{denomination}", denoms[rng.randi() % denoms.size()])
		
		# Replace {location_suffix}
		if template.find("{location_suffix}") != -1 and subcategory_data.has("location_suffixes"):
			var suffixes = subcategory_data.location_suffixes
			org_name = org_name.replace("{location_suffix}", suffixes[rng.randi() % suffixes.size()])
		
		# Replace other common placeholders
		if template.find("{type}") != -1:
			org_name = org_name.replace("{type}", category.capitalize())
		if template.find("{number}") != -1:
			org_name = org_name.replace("{number}", str(org_id))
		
		return org_name
	else:
		# Fallback to old method
		return "%s Organization %d" % [category.capitalize(), org_id]

func _get_reputation_for_category(category: String) -> int:
	match category:
		"business": return rng.randi_range(40, 70)
		"religious": return rng.randi_range(60, 90)
		"educational": return rng.randi_range(70, 90)
		"government": return rng.randi_range(50, 80)
		"social": return rng.randi_range(40, 70)
		_: return 50

func _get_wealth_for_category(category: String) -> int:
	match category:
		"business": return rng.randi_range(40, 80)
		"religious": return rng.randi_range(30, 60)
		"educational": return rng.randi_range(40, 70)
		"government": return rng.randi_range(60, 90)
		"social": return rng.randi_range(20, 50)
		_: return 50

func _get_size_multiplier(size: String) -> float:
	match size:
		"small", "micro": return 0.7
		"medium": return 1.0
		"large": return 1.5
		"very_large", "mega_church": return 2.0
		_: return 1.0

## Phase 5: Multi-Pass Organization Position Filling
## Fill leadership → key positions → remaining positions
func _assign_npc_careers_and_affiliations():
	print("   📋 Assigning careers and affiliations to NPCs...")
	
	# Get all NPCs
	var all_npcs = DB.get_all_npcs(true) # adults only
	var children = DB.get_all_child_npcs()
	
	# Get organizations by category and district
	var orgs_by_type_dist = {}
	for org in organization_frames:
		var type = org.category # "education", "healthcare", "religious", etc.
		var district = org.district
		
		if not orgs_by_type_dist.has(type): orgs_by_type_dist[type] = {}
		if not orgs_by_type_dist[type].has(district): orgs_by_type_dist[type][district] = []
		
		orgs_by_type_dist[type][district].append(org)
	
	# 1. Assign SCHOOLS to Children
	for child in children:
		var identity = child.get("identity", {})
		if not identity is Dictionary:
			continue
		
		var district = identity.get("district", "central")
		var school_org = _find_local_org(orgs_by_type_dist, "education", district)
		
		if school_org and not school_org.is_empty():
			# Check if already has membership to avoid duplicates
			var existing_memberships = DB.get_npc_memberships(child.id)
			var already_member = false
			for mem in existing_memberships:
				if mem.get("org_id") == school_org.id:
					already_member = true
					break
			
			if not already_member:
				# Create student membership
				DB.create_membership(child.id, school_org.id, "Student", 1, 0, 50, 50, 50)
				
				# Update identity
				if not identity.has("education"):
					identity["education"] = {}
				identity.education["institution"] = school_org.id
				DB.update_npc(child.id, {"identity": identity})
	
	# 2. Assign JOBS to Adults
	for npc in all_npcs:
		# 60% chance to be employed (if not already)
		if rng.randf() > 0.6: continue
		
		# Check if already has employment membership
		var existing_memberships = DB.get_npc_memberships(npc.id)
		var already_employed = false
		for mem in existing_memberships:
			var role = mem.get("role", "")
			# Check if it's an employment role (not student, member, etc.)
			if role != "Student" and role != "Member" and role != "":
				already_employed = true
				break
		
		if already_employed:
			continue
		
		var identity = npc.get("identity", {})
		if not identity is Dictionary:
			continue
		
		var occupation = identity.get("occupation", "")
		var org_type = _get_org_type_for_occupation(occupation)
		var district = identity.get("district", "central")
		
		# Find suitable employer
		var employer = _find_local_org(orgs_by_type_dist, org_type, district)
		
		if employer and not employer.is_empty():
			# Check if already has membership to this org
			var already_member = false
			for mem in existing_memberships:
				if mem.get("org_id") == employer.id:
					already_member = true
					break
			
			if not already_member:
				# Create employment membership
				var role = occupation if occupation != "" else "Employee"
				var weight = 1
				if "Manager" in role or "Director" in role: weight = 5
				if "CEO" in role or "Owner" in role: weight = 10
				
				DB.create_membership(npc.id, employer.id, role, weight, rng.randi_range(0, 10), rng.randi_range(40, 90), 50, 50)
				
				# Update filled positions in frame
				employer.filled_positions.append({"npc_id": npc.id, "title": role, "weight": weight})
	
	# 3. Assign RELIGIOUS Affiliations
	for npc in all_npcs:
		var identity = npc.get("identity", {})
		if not identity is Dictionary:
			continue
		
		var religion = identity.get("religious_path", "none")
		# Handle case where religion might be a Dictionary or other type
		if religion is Dictionary or religion == null:
			religion = "none"
		if religion == "none" or religion == "":
			continue
		
		# Find religious org (simple check for now)
		var district = identity.get("district", "central")
		var church = _find_local_org(orgs_by_type_dist, "religious", district)
		
		if church and not church.is_empty():
			# Check if already has membership to avoid duplicates
			var existing_memberships = DB.get_npc_memberships(npc.id)
			var already_member = false
			for mem in existing_memberships:
				if mem.get("org_id") == church.id:
					already_member = true
					break
			
			if not already_member:
				DB.create_membership(npc.id, church.id, "Member", 1, rng.randi_range(0, 20), 80, 50, 80)

func _find_local_org(org_index: Dictionary, type: String, district: String) -> Dictionary:
	# Try local district first
	if org_index.has(type) and org_index[type].has(district):
		var options = org_index[type][district]
		if not options.is_empty():
			return options[rng.randi() % options.size()]
	
	# Fallback: Pick any district
	if org_index.has(type):
		var all_districts = org_index[type].keys()
		if not all_districts.is_empty():
			var rand_dist = all_districts[rng.randi() % all_districts.size()]
			var options = org_index[type][rand_dist]
			if not options.is_empty():
				return options[rng.randi() % options.size()]
	
	return {}

func _get_org_type_for_occupation(occupation: String) -> String:
	occupation = occupation.to_lower()
	if "teacher" in occupation or "professor" in occupation: return "education"
	if "doctor" in occupation or "nurse" in occupation: return "healthcare"
	if "priest" in occupation or "pastor" in occupation: return "religious"
	if "police" in occupation or "officer" in occupation: return "government"
	return "business" # Default to business

## Helper: Determine meta-category for organization
func _get_org_meta_category(category: String) -> String:
	match category:
		"business", "government", "education", "healthcare", "transport": return "employment"
		"religious": return "religious"
		"social": return "social"
		"criminal": return "criminal"
		_: return "employment"

## Helper: Fill positions for a group of organizations
func _fill_org_group_positions(orgs: Array, npcs_by_district: Dictionary, meta_category: String, limit: int, npc_assignments: Dictionary, fill_stats: Dictionary):
	# Pass 1: Leadership (weight >= 7)
	for org_frame in orgs:
		var positions = org_frame.positions
		if positions.is_empty(): continue
		positions.sort_custom(func(a, b): return a.get("weight", 0) > b.get("weight", 0))
		
		for position_def in positions:
			var weight = position_def.get("weight", 1)
			if weight < 7: continue
			
			var count = _get_position_count(position_def, org_frame.size)
			fill_stats.total += count
			
			for i in range(count):
				var candidate = _find_npc_for_position(npcs_by_district, org_frame, position_def.title, weight, org_frame.filled_positions, npc_assignments, meta_category, limit)
				if candidate:
					_assign_npc_to_org(candidate, org_frame, position_def.title, weight)
					npc_assignments[candidate.id][meta_category] += 1
					fill_stats.filled += 1
					fill_stats.leadership += 1

	# Pass 2: Mid-level (weight 4-6)
	for org_frame in orgs:
		var positions = org_frame.positions
		if positions.is_empty(): continue
		
		for position_def in positions:
			var weight = position_def.get("weight", 1)
			if weight < 4 or weight >= 7: continue
			
			var count = _get_position_count(position_def, org_frame.size)
			fill_stats.total += count
			
			for i in range(count):
				var candidate = _find_npc_for_position(npcs_by_district, org_frame, position_def.title, weight, org_frame.filled_positions, npc_assignments, meta_category, limit)
				if candidate:
					_assign_npc_to_org(candidate, org_frame, position_def.title, weight)
					npc_assignments[candidate.id][meta_category] += 1
					fill_stats.filled += 1
					fill_stats.mid += 1

	# Pass 3: Entry-level (weight < 4)
	for org_frame in orgs:
		var positions = org_frame.positions
		if positions.is_empty(): continue
		
		for position_def in positions:
			var weight = position_def.get("weight", 1)
			if weight >= 4: continue
			
			var count = _get_position_count(position_def, org_frame.size)
			fill_stats.total += count
			
			for i in range(count):
				var candidate = _find_npc_for_position(npcs_by_district, org_frame, position_def.title, weight, org_frame.filled_positions, npc_assignments, meta_category, limit)
				if candidate:
					_assign_npc_to_org(candidate, org_frame, position_def.title, weight)
					npc_assignments[candidate.id][meta_category] += 1
					fill_stats.filled += 1
					fill_stats.entry += 1

## Helper: Get scaled count for position
func _get_position_count(position_def: Dictionary, org_size: String) -> int:
	var count_def = position_def.get("count", 1)
	var count = count_def
	if count_def is Array:
		count = rng.randi_range(count_def[0], count_def[1])
	return _scale_position_count(count, org_size)

## Helper: Assign NPC to organization and update occupation
func _assign_npc_to_org(npc: Dictionary, org_frame: Dictionary, title: String, weight: int):
	# Create membership record
	var tenure = rng.randi_range(0, 15)
	var loyalty = rng.randi_range(40, 90)
	var investment = rng.randi_range(30, 80)
	var alignment = rng.randi_range(40, 85)
	
	DB.create_membership(npc.id, org_frame.id, title, weight, tenure, loyalty, investment, alignment)
	
	# Track in frame
	org_frame.filled_positions.append({
		"npc_id": npc.id,
		"title": title,
		"weight": weight
	})
	
	# Update NPC occupation if high-weight position AND it's an employment org
	var meta = _get_org_meta_category(org_frame.category)
	if meta == "employment" and weight >= 4:
		npc.identity.occupation = title
		# Only update the identity field, not the entire NPC
		DB.update_npc(npc.id, {"identity": npc.identity})

## Helper: Get positions from organization template
func _get_org_positions(category: String, size: String) -> Array:
	if not org_templates.has("categories"):
		return []
	
	var categories = org_templates.categories
	
	# Navigate the template structure to find positions
	# Template structure: categories -> category_type -> subcategory array -> positions
	for cat_key in categories.keys():
		if cat_key.begins_with("_"):
			continue
		
		var cat_data = categories[cat_key]
		if cat_data is Dictionary:
			for subcat_key in cat_data.keys():
				if cat_data[subcat_key] is Array:
					for template in cat_data[subcat_key]:
						if template.has("positions"):
							# Return first matching template's positions
							# In a full implementation, we'd match more precisely
							return template.positions
	
	# Return generic positions if no template found
	return [
		{"title": "Leader", "count": 1, "weight": 10, "required": true},
		{"title": "Senior Member", "count": [2, 4], "weight": 5, "required": false},
		{"title": "Member", "count": [5, 15], "weight": 1, "required": false}
	]

## Helper: Scale position count based on org size
## Conservative scaling for world gen - positions can be added dynamically later
func _scale_position_count(base_count: int, org_size: String) -> int:
	var multiplier = 1.0
	match org_size:
		"mega", "mega_church":
			multiplier = 0.3  # Very conservative for mega churches at world gen
		"large":
			multiplier = 0.5  # Reduce large orgs
		"medium":
			multiplier = 0.6
		"small", "micro":
			multiplier = 0.8  # Small orgs keep more of their positions
		_:
			multiplier = 0.6
	
	return max(1, int(base_count * multiplier))

## Helper: Find best NPC match for a position
func _find_npc_for_position(npcs_by_district: Dictionary, org_frame: Dictionary, title: String, weight: int, filled_positions: Array, npc_assignments: Dictionary, meta_category: String, limit: int) -> Dictionary:
	var candidates = []
	var org_district = org_frame.get("district", "central")
	
	# Get list of already assigned NPC IDs for THIS org
	var assigned_npc_ids = []
	for filled in filled_positions:
		assigned_npc_ids.append(filled.npc_id)
	
	# Optimization: Search local district first
	# If we find valid candidates locally, we skip searching the whole world
	# This reduces complexity from O(N) to O(N/D) where D is number of districts
	var search_queue = [org_district]
	
	# Add other districts as fallback
	var other_districts = []
	for dist in npcs_by_district.keys():
		if dist != org_district:
			other_districts.append(dist)
	other_districts.shuffle() # Randomize fallback order
	search_queue.append_array(other_districts)
	
	for dist in search_queue:
		if not npcs_by_district.has(dist): continue
		
		var dist_candidates_found = false
		
		for npc in npcs_by_district[dist]:
			if npc.id in assigned_npc_ids: continue
			
			# CATEGORY CHECK: Skip if NPC has reached limit for this meta-category
			var current_count = npc_assignments[npc.id].get(meta_category, 0)
			if current_count >= limit: continue
			
			# Age requirements based on position weight
			var age = npc.definite.get("age", 25)
			if weight >= 7 and age < 30: continue
			if weight >= 4 and age < 22: continue
			if age < 18: continue
			
			# Calculate compatibility score
			var score = 0.0
			
			# District proximity bonus
			if dist == org_district:
				score += 20.0
			
			# Age-weight alignment
			if weight >= 7:
				if age >= 35: score += 15.0
				elif age >= 30: score += 10.0
			elif weight >= 4:
				if age >= 25: score += 10.0
			else:
				if age >= 18 and age <= 35: score += 5.0
			
			# Prioritize NPCs with fewer positions IN THIS CATEGORY
			if current_count == 0:
				score += 20.0
			
			# Random factor
			score += rng.randf_range(0, 10)
			
			candidates.append({"npc": npc, "score": score})
			dist_candidates_found = true
		
		# Optimization: If we found local candidates, STOP.
		# We prefer local candidates over better-skilled remote ones for performance + realism
		if dist == org_district and dist_candidates_found:
			break
	
	if candidates.is_empty():
		return {}
	
	# Sort by score and pick best
	candidates.sort_custom(func(a, b): return a.score > b.score)
	return candidates[0].npc

## Phase 6: Validation Pass - Schools and Religious Organizations
## Ensures all NPCs have appropriate educational and religious affiliations
func _validate_npc_affiliations():
	print("   🏫 Assigning schools to educated NPCs...")
	var schools_assigned = _assign_schools_to_npcs()
	print("      ✅ %d schools assigned" % schools_assigned)
	
	print("   ⛪ Assigning religious organizations to religious NPCs...")
	var religious_assigned = _assign_religious_orgs_to_npcs()
	print("      ✅ %d religious org memberships created" % religious_assigned)

## Assign schools to NPCs with education
func _assign_schools_to_npcs() -> int:
	var all_npcs = DB.get_all_npcs()
	var assigned_count = 0
	var school_orgs = {}  # Cache: district -> [school_ids]
	
	for npc in all_npcs:
		var edu_level = npc.identity.get("education", {}).get("level", "none")
		var current_school = npc.identity.get("education", {}).get("institution", null)
		
		# Skip if no education or already has school
		if edu_level == "none" or current_school != null:
			continue
		
		var district = npc.identity.get("district", "central")
		
		# Find or create appropriate school in district
		var school_id = _find_or_create_school(district, edu_level, school_orgs)
		
		if school_id != "":
			# Update NPC's education.institution
			npc.identity.education.institution = school_id
			DB.update_npc(npc.id, {"identity": npc.identity})
			assigned_count += 1
	
	return assigned_count

## Find or create a school organization for a district and education level
func _find_or_create_school(district: String, edu_level: String, school_cache: Dictionary) -> String:
	# Check cache first
	var cache_key = "%s_%s" % [district, edu_level]
	if school_cache.has(cache_key):
		return school_cache[cache_key]
	
	# Determine school type based on education level
	var school_type = ""
	var school_name_prefix = ""
	match edu_level:
		"primary":
			school_type = "primary_school"
			school_name_prefix = "Primary School"
		"secondary":
			school_type = "secondary_school"
			school_name_prefix = "Secondary School"
		"university", "postgraduate":
			school_type = "university"
			school_name_prefix = "University"
		_:
			return ""  # No school needed for "none"
	
	# Search for existing school of this type in district
	var all_orgs = DB.get_all_organizations()
	for org in all_orgs:
		# computed_values is already parsed as Dictionary by get_all_organizations()
		var cv = org.get("computed_values")
		if not (cv is Dictionary):
			cv = {}
		
		var org_type = org.get("type", "")
		var cv_category = cv.get("category", "")
		var org_district = cv.get("district_id", "")
		
		var is_education = org_type == "education" or cv_category == "education"
		
		# District matching - check substring match
		var district_match = false
		if org_district == "" or district == "":
			district_match = true
		elif org_district == district:
			district_match = true
		elif district.to_lower() in org_district.to_lower():
			district_match = true
		elif org_district.to_lower() in district.to_lower():
			district_match = true
		
		if is_education and district_match:
			# Check if it matches the education level (simple heuristic: name contains level)
			if school_type in org.name.to_lower() or school_name_prefix.to_lower() in org.name.to_lower():
				school_cache[cache_key] = org.id
				return org.id
	
	# No existing school found - create one
	# Use district ID directly for the name
	var district_name = district.replace("dist_", "").replace("_", " ").capitalize()
	var school_name = "%s of %s" % [school_name_prefix, district_name]
	
	var school_id = "org_school_%d" % (rng.randi() % 100000)
	var school_data = {
		"id": school_id,
		"name": school_name,
		"type": "education",
		"founded": 2025 - rng.randi_range(10, 50),
		"location_id": null,
		"legal_status": "registered",
		"pillars": JSON.stringify(["education", "community development"]),
		"reputation": JSON.stringify({
			"trustworthiness": rng.randi_range(60, 90),
			"innovation": rng.randi_range(40, 70),
			"morality": rng.randi_range(70, 95),
			"conservatism": rng.randi_range(50, 80),
			"influence": rng.randi_range(40, 80)
		}),
		"resources": JSON.stringify({
			"liquid_assets": [],
			"property": []
		}),
		"computed_values": JSON.stringify({})
	}
	
	DB.create_organization(school_data)
	school_cache[cache_key] = school_id
	stats.organizations += 1
	
	return school_id

## Assign religious organizations to NPCs with religious paths
func _assign_religious_orgs_to_npcs() -> int:
	var all_npcs = DB.get_all_npcs()
	var assigned_count = 0
	var religious_orgs = {}  # Cache: district_religion -> org_id
	
	# DEBUG: Check religious NPCs and orgs
	var npcs_with_religion = 0
	var religion_counts = {}
	var all_orgs_debug = DB.get_all_organizations()
	var religious_orgs_debug = []
	for org in all_orgs_debug:
		# Check type field or computed_values.category
		var org_type = org.get("type", "")
		var cv = org.get("computed_values")
		var cv_category = cv.get("category", "") if cv is Dictionary else ""
		var cv_subcategory = cv.get("subcategory", "") if cv is Dictionary else ""
		var cv_district = cv.get("district_id", "unknown") if cv is Dictionary else "unknown"
		
		var is_religious = org_type == "religious" or cv_category == "religious" or cv_subcategory in ["christian_churches", "mosques", "traditional_shrines"]
		if is_religious:
			religious_orgs_debug.append({"id": org.id, "name": org.name, "type": org_type, "category": cv_category, "subcategory": cv_subcategory, "district": cv_district})
	
	for npc in all_npcs:
		if not npc.has("identity") or not (npc.identity is Dictionary):
			continue
		
		var religious_path = npc.identity.get("religious_path", "")
		
		# Handle case where religious_path might be a Dictionary (old format)
		if religious_path is Dictionary:
			religious_path = religious_path.get("religion", "")
		
		# Skip if no religion or religion is "none"
		if not (religious_path is String) or religious_path == "" or religious_path == "none" or religious_path == "None":
			continue
		
		npcs_with_religion += 1
		religion_counts[religious_path] = religion_counts.get(religious_path, 0) + 1
		
		var district = npc.identity.get("district", "central")
		
		# Check if NPC is already a member of a religious org
		var memberships = DB.get_npc_organizations(npc.id)
		var has_religious_membership = false
		for membership in memberships:
			var org = DB.get_organization(membership.org_id)
			if org != null and (org.get("type") == "religious" or org.get("category") == "religious"):
				has_religious_membership = true
				break
		
		if has_religious_membership:
			continue  # Already has religious org
		
		# Find or create appropriate religious org in district
		var org_id = _find_or_create_religious_org(district, religious_path, religious_orgs)
		
		if org_id != "":
			# Create membership record using the correct function name
			DB.create_membership(
				npc.id,
				org_id,
				"member",
				1,  # weight - regular member
				rng.randi_range(0, 5),  # tenure_years
				rng.randi_range(40, 80),  # loyalty
				rng.randi_range(30, 70),  # investment
				rng.randi_range(50, 90)   # alignment
			)
			assigned_count += 1
	
	# DEBUG: Print findings
	print("      🔍 DEBUG: Found %d NPCs with religion: %s" % [npcs_with_religion, str(religion_counts)])
	print("      🔍 DEBUG: Found %d religious orgs in DB: %s" % [religious_orgs_debug.size(), str(religious_orgs_debug)])
	
	return assigned_count

## Find or create a religious organization for a district and religion
func _find_or_create_religious_org(district: String, religion: String, org_cache: Dictionary) -> String:
	var cache_key = "%s_%s" % [district, religion]
	if org_cache.has(cache_key):
		return org_cache[cache_key]
	
	# Map religion to expected subcategory
	var expected_subcategory = ""
	match religion.to_lower():
		"christian":
			expected_subcategory = "christian_churches"
		"muslim":
			expected_subcategory = "mosques"
		"traditional":
			expected_subcategory = "traditional_shrines"
	
	# Search for existing religious org of this type
	var all_orgs = DB.get_all_organizations()
	for org in all_orgs:
		# computed_values is already parsed as Dictionary by get_all_organizations()
		var cv = org.get("computed_values")
		if not (cv is Dictionary):
			cv = {}
		
		# Check if religious org type
		var org_type = org.get("type", "")
		var cv_category = cv.get("category", "")
		var cv_subcategory = cv.get("subcategory", "")
		
		var is_religious = org_type == "religious" or cv_category == "religious" or cv_subcategory in ["christian_churches", "mosques", "traditional_shrines"]
		
		if is_religious:
			var org_district = cv.get("district_id", "")
			
			# Match by district - check if NPC district is contained in org district or vice versa
			var district_match = false
			if org_district == "" or district == "":
				district_match = true
			elif org_district == district:
				district_match = true
			elif district.to_lower() in org_district.to_lower():
				district_match = true
			elif org_district.to_lower() in district.to_lower():
				district_match = true
			
			var type_match = (cv_subcategory == expected_subcategory) or (religion.to_lower() in org.name.to_lower())
			
			if district_match and type_match:
				org_cache[cache_key] = org.id
				return org.id
	
	# No existing org found - create one
	var org_name = ""
	match religion.to_lower():
		"christian":
			org_name = "Church of %s" % district.capitalize()
		"muslim":
			org_name = "Mosque of %s" % district.capitalize()
		"traditional":
			org_name = "Traditional Shrine of %s" % district.capitalize()
		_:
			org_name = "%s Community of %s" % [religion.capitalize(), district.capitalize()]
	
	var org_id = "org_religious_%d" % (rng.randi() % 100000)
	var org_data = {
		"id": org_id,
		"name": org_name,
		"type": "religious",
		"founded": 2025 - rng.randi_range(20, 100),
		"location_id": null,
		"legal_status": "registered",
		"pillars": JSON.stringify(["faith", "community", "spiritual growth"]),
		"reputation": JSON.stringify({
			"trustworthiness": rng.randi_range(70, 95),
			"innovation": rng.randi_range(20, 50),
			"morality": rng.randi_range(80, 100),
			"conservatism": rng.randi_range(60, 90),
			"influence": rng.randi_range(50, 85)
		}),
		"resources": JSON.stringify({
			"liquid_assets": [],
			"property": []
		}),
		"computed_values": JSON.stringify({
			"category": "religious",
			"subcategory": expected_subcategory if expected_subcategory != "" else "other",
			"district_id": district
		})
	}
	
	DB.create_organization(org_data)
	org_cache[cache_key] = org_id
	stats.organizations += 1
	
	return org_id

## Phase 9: Location Assignment
## Assign families to housing and organizations to commercial spaces
func _assign_families_to_housing():
	print("   🏠 Assigning families to housing units...")
	
	# Debug: Check all locations first
	var all_locs = DB.get_all_locations()
	print("      ℹ️ Total locations in database: %d" % all_locs.size())
	if all_locs.size() > 0:
		var type_counts = {}
		for loc in all_locs:
			var loc_type = loc.get("type", "unknown")
			type_counts[loc_type] = type_counts.get(loc_type, 0) + 1
		print("      ℹ️ Location types: %s" % str(type_counts))
	
	# Get all residential units by district
	var residential_units = DB.get_location_units("residential_unit")
	if residential_units.is_empty():
		print("      ⚠️ No residential units found - skipping assignment")
		return
	
	# Group units by district
	var units_by_district = {}
	for unit in residential_units:
		var district = unit.district_id
		if not units_by_district.has(district):
			units_by_district[district] = []
		units_by_district[district].append(unit.id)
	
	# Assign each family to a unit in their district
	var assigned_count = 0
	for frame in family_frames:
		var district = frame.district
		
		# Get available units in this district
		if not units_by_district.has(district) or units_by_district[district].is_empty():
			# Fallback to any district if preferred district has no units
			for d in units_by_district.keys():
				if not units_by_district[d].is_empty():
					district = d
					break
		
		if not units_by_district.has(district) or units_by_district[district].is_empty():
			continue  # No units available
		
		# Pick a unit and assign all family members to it
		var unit_id = units_by_district[district].pop_back()
		
		for npc_data in frame.generated_npcs:
			var npc_id = npc_data.id if typeof(npc_data) == TYPE_DICTIONARY else npc_data
			DB.update_npc(npc_id, {"current_location_id": unit_id})
		
		assigned_count += 1
	
	print("      ✅ %d families assigned to housing" % assigned_count)
	
	# Also assign single NPCs to remaining units (2 singles per unit)
	var single_npcs = DB.get_single_adults()
	var singles_assigned = 0
	
	# Track how many singles are in each unit (unit_id -> count)
	var singles_per_unit = {}
	var current_unit_id = null
	var current_unit_count = 0
	
	for npc in single_npcs:
		# Skip if already has location
		if npc.get("current_location_id") and npc.current_location_id != null and npc.current_location_id != "":
			continue
		
		var district = npc.identity.get("district", "central") if npc.get("identity") else "central"
		
		# If current unit is full (2 singles) or doesn't exist, get a new unit
		if current_unit_id == null or current_unit_count >= 2:
			# Find available unit
			if not units_by_district.has(district) or units_by_district[district].is_empty():
				# Fallback to any district
				for d in units_by_district.keys():
					if not units_by_district[d].is_empty():
						district = d
						break
			
			if units_by_district.has(district) and not units_by_district[district].is_empty():
				current_unit_id = units_by_district[district].pop_back()
				current_unit_count = 0
				singles_per_unit[current_unit_id] = 0
			else:
				# No more units available
				break
		
		# Assign NPC to current unit
		if current_unit_id != null:
			DB.update_npc(npc.id, {"current_location_id": current_unit_id})
			current_unit_count += 1
			singles_per_unit[current_unit_id] = current_unit_count
			singles_assigned += 1
	
	var units_used = singles_per_unit.size()
	print("      ✅ %d single NPCs assigned to housing (%d units used, avg %.1f per unit)" % [singles_assigned, units_used, float(singles_assigned) / float(units_used) if units_used > 0 else 0.0])

func _assign_organizations_to_locations():
	print("   🏢 Assigning organizations to commercial units...")
	
	# Get all commercial units by district
	var commercial_units = DB.get_location_units("commercial_unit")
	if commercial_units.is_empty():
		print("      ⚠️ No commercial units found - skipping assignment")
		return
	
	# Group units by district
	var units_by_district = {}
	for unit in commercial_units:
		var district = unit.district_id
		if not units_by_district.has(district):
			units_by_district[district] = []
		units_by_district[district].append(unit.id)
	
	# Get all organizations
	var all_orgs = DB.get_all_organizations()
	var assigned_count = 0
	
	for org in all_orgs:
		# Educational and religious orgs might not need commercial locations
		# They might use public buildings instead
		if org.type in ["education", "educational", "religious", "religion"]:
			# For now, skip assigning these to commercial units
			# They could have dedicated building types in the future
			continue
		
		# Get org's district (from its members or random)
		var org_district = null
		var members = DB.get_organization_members(org.id)
		if members.size() > 0:
			# Use the district of the first member
			var first_member_id = members[0].npc_id
			var district = DB.get_npc_district(first_member_id)
			if not district.is_empty():
				org_district = district
		
		if org_district == null:
			# Try to pick a district from available units
			for d in units_by_district.keys():
				if not units_by_district[d].is_empty():
					org_district = d
					break
		
		if org_district == null or not units_by_district.has(org_district) or units_by_district[org_district].is_empty():
			continue  # No units available
		
		# Assign org to a commercial unit
		var unit_id = units_by_district[org_district].pop_back()
		var update_query = "UPDATE organizations SET location_id = '%s' WHERE id = '%s';" % [unit_id, org.id]
		DB.db.query(update_query)
		assigned_count += 1
	
	print("      ✅ %d organizations assigned to commercial units" % assigned_count)

## Phase 9b: Ownership Tracking
## Determine who owns each location (owner-occupied, rented, organization-owned)
var landlord_npcs: Array = []  # Track generated landlord NPCs

func _assign_location_ownership():
	print("   🏠 Determining location ownership...")
	
	# Step 1: Generate landlord NPCs (wealthy property investors)
	_generate_landlord_npcs()
	
	# Step 2: Assign residential ownership
	var residential_stats = _assign_residential_ownership()
	
	# Step 3: Assign commercial ownership
	var commercial_stats = _assign_commercial_ownership()
	
	# Step 4: Create landlord-tenant relationships
	var landlord_rels = _create_landlord_tenant_relationships()
	
	print("      ✅ %d landlords created, %d owner-occupied, %d rented" % [landlord_npcs.size(), residential_stats.owner_occupied, residential_stats.rented])
	print("      ✅ %d commercial org-owned, %d commercial rented" % [commercial_stats.org_owned, commercial_stats.rented])
	print("      ✅ %d landlord-tenant relationships created" % landlord_rels)

func _generate_landlord_npcs():
	# Generate 5-10 wealthy property investor NPCs
	var landlord_count = rng.randi_range(5, 10)
	print("      Generating %d landlord NPCs..." % landlord_count)
	
	# Get districts for distribution
	var districts = []
	var all_districts = DB.get_all_districts()
	for d in all_districts:
		districts.append(d.id)
	
	if districts.is_empty():
		push_error("❌ No districts found for landlord generation!")
		return
	
	for i in range(landlord_count):
		var landlord_id = "npc-landlord-%d" % i
		var district = districts[rng.randi() % districts.size()]
		var gender = "male" if rng.randf() < 0.6 else "female"  # Bias towards male landlords (realistic for Lagos)
		var age = rng.randi_range(45, 70)  # Older, established
		var tribe = _random_tribe()
		var last_name = _random_last_name(tribe)
		var first_name = _random_first_name(tribe, gender)
		
		# Create wealthy landlord NPC
		var npc_data = {
			"id": landlord_id,
			"name": first_name + " " + last_name,
			"definite": JSON.stringify({
				"gender": gender,
				"age": age,
				"alive": true,
				"orientation": rng.randi_range(60, 100)
			}),
			"attributes": JSON.stringify(_generate_attributes(age)),
			"appearance": JSON.stringify(_generate_appearance(gender, age, tribe, [])),
			"identity": JSON.stringify({
				"tribe": tribe,
				"spoken_languages": ["English", "Yoruba", "Pidgin"],
				"education": {"level": "postgraduate", "institution": null},
				"religious_path": _random_religion(tribe),
				"occupation": "Property Investor",
				"family_id": null,
				"district": district
			}),
			"personality": JSON.stringify(_generate_personality(tribe)),
			"political_ideology": JSON.stringify(_generate_political_ideology()),
			"skills": JSON.stringify({"business": {"investing": 8, "negotiation": 7, "management": 6}}),
			"resources": JSON.stringify({
				"liquid_assets": [{"type": "bank_account", "amount": rng.randi_range(50000000, 200000000)}],
				"property": [],  # Will be filled as properties are assigned
				"access": [],
				"annual_income": rng.randi_range(20000000, 80000000)
			}),
			"status": JSON.stringify({"health": rng.randi_range(60, 90), "stress": rng.randi_range(20, 50), "reputation": rng.randi_range(60, 90)}),
			"demographic_affinities": JSON.stringify({"capitalist_class": 80, "working_class": -20}),
			"current_location_id": null
		}
		
		DB.create_npc(npc_data)
		landlord_npcs.append(landlord_id)
		stats.npcs += 1

func _assign_residential_ownership() -> Dictionary:
	var result = {"owner_occupied": 0, "rented": 0}
	
	# Get all residential units with their occupants
	var units = DB.get_residential_units_with_details()
	
	for unit in units:
		if unit.tenant_id == null:
			continue  # Empty unit, skip
		
		# Determine ownership based on income
		var income = unit.income if unit.income else 0
		var ownership_chance = 0.0
		
		if income >= 5000000:  # High income (5M+)
			ownership_chance = 0.70
		elif income >= 1500000:  # Middle income (1.5M-5M)
			ownership_chance = 0.40
		else:  # Low income
			ownership_chance = 0.10
		
		var is_owner = rng.randf() < ownership_chance
		
		# Parse existing access JSON
		var access_data = {}
		if unit.access and unit.access != "":
			access_data = JSON.parse_string(unit.access)
			if access_data == null:
				access_data = {}
		
		if is_owner:
			# Owner-occupied
			access_data["owner_npc_id"] = unit.tenant_id
			access_data["ownership_type"] = "owner_occupied"
			result.owner_occupied += 1
		else:
			# Rented - assign a landlord
			if landlord_npcs.size() > 0:
				var landlord_id = landlord_npcs[rng.randi() % landlord_npcs.size()]
				access_data["owner_npc_id"] = landlord_id
				access_data["ownership_type"] = "rented"
				access_data["tenant_npc_id"] = unit.tenant_id
				result.rented += 1
				
				# Update landlord's property list
				_add_property_to_landlord(landlord_id, unit.location_id)
		
		# Update location with ownership info
		DB.update_location_access(unit.location_id, access_data)
	
	return result

func _assign_commercial_ownership() -> Dictionary:
	var result = {"org_owned": 0, "rented": 0}
	
	# Get commercial units with their assigned organizations
	var units = DB.get_commercial_units_with_details()
	
	for unit in units:
		var access_data = {}
		if unit.access and unit.access != "":
			access_data = JSON.parse_string(unit.access)
			if access_data == null:
				access_data = {}
		
		if unit.org_id == null:
			# No org assigned, landlord owns empty commercial space
			if landlord_npcs.size() > 0:
				var landlord_id = landlord_npcs[rng.randi() % landlord_npcs.size()]
				access_data["owner_npc_id"] = landlord_id
				access_data["ownership_type"] = "vacant"
				_add_property_to_landlord(landlord_id, unit.location_id)
		else:
			# Org is assigned - determine if they own or rent
			# Larger/wealthier orgs more likely to own
			var org_owns_chance = 0.3  # Default 30% own
			
			# Check if org has substantial assets
			if unit.org_assets:
				var assets = unit.org_assets
				# Parse if it's a string
				if assets is String:
					assets = JSON.parse_string(assets)
				if assets and assets is Array and assets.size() > 0:
					org_owns_chance = 0.6  # Wealthier orgs more likely to own
			
			if rng.randf() < org_owns_chance:
				# Organization owns the building
				access_data["owner_org_id"] = unit.org_id
				access_data["ownership_type"] = "org_owned"
				result.org_owned += 1
			else:
				# Organization rents from landlord
				if landlord_npcs.size() > 0:
					var landlord_id = landlord_npcs[rng.randi() % landlord_npcs.size()]
					access_data["owner_npc_id"] = landlord_id
					access_data["ownership_type"] = "rented"
					access_data["tenant_org_id"] = unit.org_id
					result.rented += 1
					_add_property_to_landlord(landlord_id, unit.location_id)
		
		DB.update_location_access(unit.location_id, access_data)
	
	return result

func _add_property_to_landlord(landlord_id: String, location_id: String):
	# Update landlord's resources.property array
	var npc = DB.get_npc(landlord_id)
	if npc.is_empty():
		return
	
	var resources = npc.get("resources", {})
	if resources == null:
		resources = {"property": [], "liquid_assets": [], "access": [], "annual_income": 0}
	
	if not resources.has("property"):
		resources["property"] = []
	
	resources["property"].append(location_id)
	
	DB.update_npc(landlord_id, {"resources": resources})

func _create_landlord_tenant_relationships() -> int:
	var count = 0
	
	# Query all rented locations with landlord and tenant info
	var rented_units = DB.get_rented_units_info()
	var processed_pairs = {}
	
	for unit in rented_units:
		if unit.landlord_id == null:
			continue
		
		# For NPC tenants, create landlord relationship
		if unit.tenant_npc_id and unit.tenant_npc_id != null:
			var pair_key = "%s-%s" % [unit.landlord_id, unit.tenant_npc_id]
			if processed_pairs.has(pair_key):
				continue
			processed_pairs[pair_key] = true
			
			# Create bidirectional landlord-tenant relationship
			# Landlord -> Tenant: professional, neutral
			DB.create_relationship(unit.landlord_id, unit.tenant_npc_id, "landlord", 10, 30, 0, 20)
			# Tenant -> Landlord: professional, may be slightly negative (paying rent)
			DB.create_relationship(unit.tenant_npc_id, unit.landlord_id, "tenant", 0, 20, 0, 30)
			count += 2
		
		# For organization tenants, create relationship with org leader
		if unit.tenant_org_id and unit.tenant_org_id != null:
			var leader = DB.get_organization_leader(unit.tenant_org_id)
			if not leader.is_empty():
				var leader_id = leader.npc_id
				var pair_key = "%s-%s" % [unit.landlord_id, leader_id]
				if not processed_pairs.has(pair_key):
					processed_pairs[pair_key] = true
					DB.create_relationship(unit.landlord_id, leader_id, "business_partner", 20, 40, 0, 50)
					DB.create_relationship(leader_id, unit.landlord_id, "business_partner", 20, 40, 0, 50)
					count += 2
	
	return count

## Phase 7: Multi-Pass Relationship Generation (per world_generation.md)
## Generate relationships based on shared contexts: school, work, neighborhood, romantic
func _generate_context_based_relationships():
	var school_rels = 0
	var work_rels = 0
	var neighbor_rels = 0
	var romantic_rels = 0
	var filler_rels = 0
	
	# Pass 2: School-based relationships
	print("   Pass 2: School relationships...")
	school_rels = _generate_school_relationships()
	print("      Created %d school friendships" % school_rels)
	
	# Pass 3: Work-based relationships  
	print("   Pass 3: Work relationships...")
	work_rels = _generate_work_relationships()
	print("      Created %d colleague relationships" % work_rels)
	
	# Pass 4: Neighborhood relationships
	print("   Pass 4: Neighborhood relationships...")
	neighbor_rels = _generate_neighborhood_relationships()
	print("      Created %d neighbor relationships" % neighbor_rels)
	
	# Pass 5: Romantic relationships
	print("   Pass 5: Romantic history...")
	romantic_rels = _generate_romantic_relationships()
	print("      Created %d romantic relationships" % romantic_rels)
	
	# Pass 6: Fill isolated NPCs
	print("   Pass 6: Filling isolated NPCs...")
	filler_rels = _fill_isolated_npcs()
	print("      Created %d filler relationships" % filler_rels)
	
	stats.relationships = school_rels + work_rels + neighbor_rels + romantic_rels + filler_rels
	print("   Total non-family relationships: %d" % stats.relationships)

func _generate_school_relationships() -> int:
	var count = 0
	var processed_pairs = {}
	
	# Get all educational organizations
	var all_orgs = DB.get_all_organizations()
	var schools = []
	for org in all_orgs:
		if org.type in ["education", "educational"]:
			schools.append(org)
	
	# For each school, create friendships between students
	for school in schools:
		var members = DB.get_organization_members(school.id)
		if members.size() < 2:
			continue
		
		# Generate friendships (each student has 1-3 school friends)
		for member in members:
			var npc_id = member.npc_id
			var num_friends = rng.randi_range(1, min(3, members.size() - 1))
			
			for i in range(num_friends):
				var friend_idx = rng.randi() % members.size()
				var friend_id = members[friend_idx].npc_id
				
				if friend_id == npc_id:
					continue
				
				# Ensure we don't create duplicate relationships
				var id1 = npc_id if npc_id < friend_id else friend_id
				var id2 = friend_id if npc_id < friend_id else npc_id
				var pair_key = "%s_%s" % [id1, id2]
				if processed_pairs.has(pair_key):
					continue
				
				processed_pairs[pair_key] = true
				DB.create_relationship(npc_id, friend_id, "friend", 60, 60, 0, 50)
				count += 1
	
	return count

func _generate_work_relationships() -> int:
	var count = 0
	var processed_pairs = {}
	
	# Get all non-educational, non-religious organizations (employment orgs)
	var all_orgs = DB.get_all_organizations()
	var workplaces = []
	for org in all_orgs:
		if org.type not in ["education", "educational", "religious", "religion"]:
			workplaces.append(org)
	
	# For each workplace, create colleague relationships
	for workplace in workplaces:
		var members = DB.get_organization_members(workplace.id)
		if members.size() < 2:
			continue
		
		# Generate colleague relationships (each employee has 1-2 work friends)
		for member in members:
			var npc_id = member.npc_id
			var num_colleagues = rng.randi_range(1, min(2, members.size() - 1))
			
			for i in range(num_colleagues):
				var colleague_idx = rng.randi() % members.size()
				var colleague_id = members[colleague_idx].npc_id
				
				if colleague_id == npc_id:
					continue
				
				# Ensure we don't create duplicate relationships
				var id1 = npc_id if npc_id < colleague_id else colleague_id
				var id2 = colleague_id if npc_id < colleague_id else npc_id
				var pair_key = "%s_%s" % [id1, id2]
				if processed_pairs.has(pair_key):
					continue
				
				processed_pairs[pair_key] = true
				DB.create_relationship(npc_id, colleague_id, "colleague", 40, 50, 0, 40)
				count += 1
	
	return count

func _generate_neighborhood_relationships() -> int:
	var count = 0
	var processed_pairs = {}
	
	# Group NPCs by district
	var npcs_by_district = {}
	var all_npcs = DB.get_all_npcs()
	
	for npc in all_npcs:
		var identity = npc.get("identity", {})
		var district = identity.get("district", "unknown")
		if not npcs_by_district.has(district):
			npcs_by_district[district] = []
		npcs_by_district[district].append(npc)
	
	# For each district, create neighbor relationships
	for district_id in npcs_by_district.keys():
		var neighbors = npcs_by_district[district_id]
		if neighbors.size() < 2:
			continue
		
		# Each NPC has 0-2 neighbor relationships (neighbors are less common)
		for npc in neighbors:
			if rng.randf() > 0.4:  # 40% chance to have neighbor friends
				continue
				
			var num_neighbor_friends = rng.randi_range(1, min(2, neighbors.size() - 1))
			
			for i in range(num_neighbor_friends):
				var neighbor_idx = rng.randi() % neighbors.size()
				var neighbor_id = neighbors[neighbor_idx].id
				
				if neighbor_id == npc.id:
					continue
				
				# Ensure we don't create duplicate relationships
				var id1 = npc.id if npc.id < neighbor_id else neighbor_id
				var id2 = neighbor_id if npc.id < neighbor_id else npc.id
				var pair_key = "%s_%s" % [id1, id2]
				if processed_pairs.has(pair_key):
					continue
				
				# Check if relationship already exists in database
				if DB.get_relationship(npc.id, neighbor_id).size() > 0:
					processed_pairs[pair_key] = true
					continue
				
				processed_pairs[pair_key] = true
				DB.create_relationship(npc.id, neighbor_id, "friend", 50, 50, 0, 40)
				count += 1
	
	return count

func _generate_romantic_relationships() -> int:
	# 30% of single adults have an ex-partner
	var count = 0
	
	# Get all single adult NPCs (not married)
	var singles = DB.get_single_adults()
	if singles.is_empty():
		return count
	
	# Build a pool of singles by district for matching
	var singles_by_district = {}
	for npc in singles:
		var district = npc.district if npc.district else "unknown"
		if not singles_by_district.has(district):
			singles_by_district[district] = []
		singles_by_district[district].append(npc)
	
	var processed_npcs = {}
	
	for npc in singles:
		# Skip if already processed or not selected (30% chance)
		if processed_npcs.has(npc.id):
			continue
		if rng.randf() > 0.30:
			continue
		
		var age = npc.age if npc.age else 25
		var gender = npc.gender if npc.gender else "male"
		var orientation = npc.orientation if npc.orientation else 50
		var district = npc.district if npc.district else "unknown"
		
		# Find compatible ex-partner
		var candidates = []
		
		# Prioritize same district, then expand
		var districts_to_check = [district]
		for d in singles_by_district.keys():
			if d != district:
				districts_to_check.append(d)
		
		for d in districts_to_check:
			if not singles_by_district.has(d):
				continue
			for candidate in singles_by_district[d]:
				if candidate.id == npc.id or processed_npcs.has(candidate.id):
					continue
				
				var cand_age = candidate.age if candidate.age else 25
				var cand_gender = candidate.gender if candidate.gender else "female"
				
				# Age compatibility (within 10 years)
				if abs(age - cand_age) > 10:
					continue
				
				# Sexual orientation compatibility
				var compatible = false
				if gender == "male":
					if orientation >= 0:  # Attracted to females
						compatible = (cand_gender == "female")
					else:  # Attracted to males
						compatible = (cand_gender == "male")
				else:  # female
					if orientation >= 0:  # Attracted to males
						compatible = (cand_gender == "male")
					else:  # Attracted to females
						compatible = (cand_gender == "female")
				
				# Bisexual (orientation near 0) is compatible with anyone
				if abs(orientation) < 30:
					compatible = true
				
				if compatible:
					candidates.append(candidate)
					if candidates.size() >= 5:
						break
			
			if candidates.size() >= 5:
				break
		
		if candidates.is_empty():
			continue
		
		# Pick random ex-partner
		var ex = candidates[rng.randi() % candidates.size()]
		processed_npcs[npc.id] = true
		processed_npcs[ex.id] = true
		
		# Check if relationships already exist
		if DB.get_relationship(npc.id, ex.id).size() > 0 or DB.get_relationship(ex.id, npc.id).size() > 0:
			continue
		
		# Create ex-lover relationships (can be negative to neutral)
		var affection = rng.randi_range(-40, 30)  # Often negative after breakup
		var trust = rng.randi_range(-30, 20)  # Low trust after breakup
		var attraction = rng.randi_range(-20, 60)  # May still find them attractive
		var respect = rng.randi_range(10, 60)  # Usually maintain some respect
		
		DB.create_relationship(npc.id, ex.id, "ex_lover", affection, trust, attraction, respect)
		DB.create_relationship(ex.id, npc.id, "ex_lover", affection + rng.randi_range(-20, 20), trust + rng.randi_range(-10, 10), attraction + rng.randi_range(-20, 20), respect + rng.randi_range(-10, 10))
		count += 2
	
	return count

func _fill_isolated_npcs() -> int:
	# Ensure all NPCs have at least 3 relationships
	var count = 0
	
	# Find NPCs with fewer than 3 relationships
	var isolated = DB.get_isolated_npcs(3)
	
	if isolated.is_empty():
		return count
	
	# Build pool of NPCs by district for matching
	var npcs_by_district = {}
	var all_npcs = DB.get_all_npcs_basic()
	for npc in all_npcs:
		var district = npc.district if npc.district else "unknown"
		if not npcs_by_district.has(district):
			npcs_by_district[district] = []
		npcs_by_district[district].append(npc.id)
	
	var existing_rels = DB.get_all_relationship_pairs()
	
	for iso in isolated:
		var needed = 3 - iso.rel_count
		if needed <= 0:
			continue
		
		var district = iso.district if iso.district else "unknown"
		
		# Find potential friends in same district
		var candidates = []
		if npcs_by_district.has(district):
			for cand_id in npcs_by_district[district]:
				if cand_id == iso.id:
					continue
				var key = "%s-%s" % [iso.id, cand_id]
				if existing_rels.has(key):
					continue
				candidates.append(cand_id)
				if candidates.size() >= needed + 3:
					break
		
		# Create friendships
		var created = 0
		for cand_id in candidates:
			if created >= needed:
				break
			
			# Check again to avoid duplicates
			var key = "%s-%s" % [iso.id, cand_id]
			if existing_rels.has(key):
				continue
			
			# Check if relationship already exists in database
			if DB.get_relationship(iso.id, cand_id).size() > 0 or DB.get_relationship(cand_id, iso.id).size() > 0:
				existing_rels[key] = true
				existing_rels["%s-%s" % [cand_id, iso.id]] = true
				continue
			
			# Create acquaintance/friend relationship
			var affection = rng.randi_range(20, 50)
			var trust = rng.randi_range(20, 50)
			var respect = rng.randi_range(20, 50)
			
			DB.create_relationship(iso.id, cand_id, "acquaintance", affection, trust, 0, respect)
			DB.create_relationship(cand_id, iso.id, "acquaintance", affection, trust, 0, respect)
			
			existing_rels[key] = true
			existing_rels["%s-%s" % [cand_id, iso.id]] = true
			count += 2
			created += 1
	
	return count

## ============================================================
## Phase 8: Historical Events and Memories
## ============================================================

var event_stats = {
	"birth": 0,
	"marriage": 0,
	"hiring": 0,
	"relationship": 0,
	"memories": 0
}

func _generate_historical_events():
	print("   📅 Generating historical events...")
	
	# Get simulation start date from world state
	var start_date = "2025-01-01"
	var world_state = DB.get_world_state()
	if not world_state.is_empty() and world_state.has("date"):
		start_date = world_state.date
	
	var start_year = int(start_date.split("-")[0])
	
	# Generate events in order
	_generate_birth_events(start_year)
	print("      ✅ %d birth events" % event_stats.birth)
	
	_generate_marriage_events(start_year)
	print("      ✅ %d marriage events" % event_stats.marriage)
	
	_generate_hiring_events(start_year)
	print("      ✅ %d hiring events" % event_stats.hiring)
	
	_generate_relationship_events(start_year)
	print("      ✅ %d relationship formation events" % event_stats.relationship)
	
	print("      ✅ %d total memories created" % event_stats.memories)

func _generate_birth_events(start_year: int):
	# Generate birth event for each NPC
	var npcs = DB.get_npcs_for_birth_events()
	
	# Get parents for memory generation
	var parents_cache = DB.get_parent_child_map()
	
	# Get valid districts for validation
	var valid_districts = {}
	for district in DB.get_all_districts():
		valid_districts[district.id] = true
	
	for npc in npcs:
		var age = npc.age if npc.age else 25
		var birth_year = start_year - age
		var birth_date = "%d-%02d-%02d" % [birth_year, rng.randi_range(1, 12), rng.randi_range(1, 28)]
		
		var event_id = "evt-birth-%s" % npc.id
		var summary = "%s was born" % npc.name
		
		# Validate district_id
		var district_id = null
		if npc.has("district") and npc.district and valid_districts.has(npc.district):
			district_id = npc.district
		
		var event_data = {
			"id": event_id,
			"type": "life",
			"subtype": "birth",
			"timestamp": _date_to_timestamp(birth_date),
			"date": birth_date,
			"time": "%02d:%02d" % [rng.randi_range(0, 23), rng.randi_range(0, 59)],
			"duration_minutes": 0,
			"location_id": null,
			"district_id": district_id,
			"summary": summary,
			"details": {"npc_id": npc.id, "birth_year": birth_year},
			"impact": {"severity": 50, "public_knowledge": 30, "emotional_weight": 90},
			"consequences": {},
			"ripple_depth": 0,
			"affected_nodes": [npc.id],
			"resolved": 1
		}
		
		var created_event_id = DB.create_event(event_data)
		if created_event_id:
			event_stats.birth += 1
			
			# Create participant record
			DB.add_event_participant(created_event_id, npc.id, "npc", "subject")
			
			# Create memories for parents
			if parents_cache.has(npc.id):
				for parent_id in parents_cache[npc.id]:
					DB.create_memory({
						"npc_id": parent_id,
						"event_id": created_event_id,
						"personal_summary": "My child %s was born" % npc.name.split(" ")[0],
						"knowledge_level": "participant",
						"belief_accuracy": 100,
						"emotional_impact": 95,
						"timestamp": _date_to_timestamp(birth_date),
						"date": birth_date
					})
					DB.add_event_participant(created_event_id, parent_id, "npc", "participant")
					event_stats.memories += 1

func _generate_marriage_events(start_year: int):
	# Find married couples and generate marriage events
	var marriages = DB.get_married_couples()
	
	# Get children to calculate marriage year (must be before oldest child)
	var children_ages = DB.get_oldest_child_ages()
	
	# Get valid districts for validation
	var valid_districts = {}
	for district in DB.get_all_districts():
		valid_districts[district.id] = true
	
	for marriage in marriages:
		var min_age = min(marriage.age1 if marriage.age1 else 30, marriage.age2 if marriage.age2 else 30)
		
		# Calculate marriage year
		var years_married = rng.randi_range(1, min(15, min_age - 18))
		
		# If they have children, marriage must be at least 1 year before oldest child
		var oldest_child_age = 0
		if children_ages.has(marriage.source_npc_id):
			oldest_child_age = max(oldest_child_age, children_ages[marriage.source_npc_id])
		if children_ages.has(marriage.target_npc_id):
			oldest_child_age = max(oldest_child_age, children_ages[marriage.target_npc_id])
		
		if oldest_child_age > 0 and oldest_child_age < 999:
			years_married = max(years_married, oldest_child_age + 1)
		
		var marriage_year = start_year - years_married
		var marriage_date = "%d-%02d-%02d" % [marriage_year, rng.randi_range(1, 12), rng.randi_range(1, 28)]
		
		var event_id = "evt-marriage-%s-%s" % [marriage.source_npc_id, marriage.target_npc_id]
		var summary = "%s and %s got married" % [marriage.spouse1_name, marriage.spouse2_name]
		
		# Validate district_id
		var district_id = null
		if marriage.has("district") and marriage.district and valid_districts.has(marriage.district):
			district_id = marriage.district
		
		var event_data = {
			"id": event_id,
			"type": "social",
			"subtype": "wedding",
			"timestamp": _date_to_timestamp(marriage_date),
			"date": marriage_date,
			"time": "14:00",
			"duration_minutes": 240,
			"location_id": null,
			"district_id": district_id,
			"summary": summary,
			"details": {"spouse1": marriage.source_npc_id, "spouse2": marriage.target_npc_id},
			"impact": {"severity": 60, "public_knowledge": 70, "emotional_weight": 95},
			"consequences": {},
			"ripple_depth": 1,
			"affected_nodes": [marriage.source_npc_id, marriage.target_npc_id],
			"resolved": 1
		}
		
		var created_event_id = DB.create_event(event_data)
		if created_event_id:
			event_stats.marriage += 1
			
			# Create participants
			DB.add_event_participant(created_event_id, marriage.source_npc_id, "npc", "primary_actor")
			DB.add_event_participant(created_event_id, marriage.target_npc_id, "npc", "primary_actor")
			
			# Create memories for both spouses
			DB.create_memory({
				"npc_id": marriage.source_npc_id,
				"event_id": created_event_id,
				"personal_summary": "I married %s" % marriage.spouse2_name.split(" ")[0],
				"knowledge_level": "participant",
				"belief_accuracy": 100,
				"emotional_impact": 98,
				"timestamp": _date_to_timestamp(marriage_date),
				"date": marriage_date
			})
			
			DB.create_memory({
				"npc_id": marriage.target_npc_id,
				"event_id": created_event_id,
				"personal_summary": "I married %s" % marriage.spouse1_name.split(" ")[0],
				"knowledge_level": "participant",
				"belief_accuracy": 100,
				"emotional_impact": 98,
				"timestamp": _date_to_timestamp(marriage_date),
				"date": marriage_date
			})
			
			event_stats.memories += 2

func _generate_hiring_events(start_year: int):
	# Generate hiring events for employed NPCs
	var employments = DB.get_all_employments()
	
	# Get valid districts for validation
	var valid_districts = {}
	for district in DB.get_all_districts():
		valid_districts[district.id] = true
	
	for emp in employments:
		var tenure = emp.tenure_years if emp.tenure_years else rng.randi_range(0, 5)
		var hire_year = start_year - tenure
		var hire_date = "%d-%02d-%02d" % [hire_year, rng.randi_range(1, 12), rng.randi_range(1, 28)]
		
		var event_id = "evt-hired-%s-%s" % [emp.npc_id, emp.org_id]
		var summary = "%s joined %s as %s" % [emp.npc_name, emp.org_name, emp.role]
		
		# Validate district_id
		var district_id = null
		if emp.has("district") and emp.district and valid_districts.has(emp.district):
			district_id = emp.district
		
		var event_data = {
			"id": event_id,
			"type": "work",
			"subtype": "hiring",
			"timestamp": _date_to_timestamp(hire_date),
			"date": hire_date,
			"time": "09:00",
			"duration_minutes": 60,
			"location_id": null,
			"district_id": district_id,
			"summary": summary,
			"details": {"npc_id": emp.npc_id, "org_id": emp.org_id, "role": emp.role},
			"impact": {"severity": 30, "public_knowledge": 20, "emotional_weight": 60},
			"consequences": {},
			"ripple_depth": 0,
			"affected_nodes": [emp.npc_id, emp.org_id],
			"resolved": 1
		}
		
		var created_event_id = DB.create_event(event_data)
		if created_event_id:
			event_stats.hiring += 1
			
			# Create participant
			DB.add_event_participant(created_event_id, emp.npc_id, "npc", "primary_actor")
			DB.add_event_participant(created_event_id, emp.org_id, "organization", "affected_entity")
			
			# Create memory
			DB.create_memory({
				"npc_id": emp.npc_id,
				"event_id": created_event_id,
				"personal_summary": "I started working at %s" % emp.org_name,
				"knowledge_level": "participant",
				"belief_accuracy": 95,
				"emotional_impact": 90,
				"timestamp": _date_to_timestamp(hire_date),
				"date": hire_date
			})
			
			event_stats.memories += 1

func _generate_relationship_events(start_year: int):
	# Generate "met at" events for key relationships (friends, colleagues)
	var relationships = DB.get_relationships_for_events(["friend", "colleague"])
	
	# Get valid districts for validation
	var valid_districts = {}
	for district in DB.get_all_districts():
		valid_districts[district.id] = true
	
	for rel in relationships:
		var years_ago = rng.randi_range(1, 10)
		var met_year = start_year - years_ago
		var met_date = "%d-%02d-%02d" % [met_year, rng.randi_range(1, 12), rng.randi_range(1, 28)]
		
		var context = "at a gathering" if rel.type == "friend" else "at work"
		var event_id = "evt-met-%s-%s-%s" % [rel.type, rel.source_npc_id, rel.target_npc_id]
		var summary = "%s and %s met %s" % [rel.name1.split(" ")[0], rel.name2.split(" ")[0], context]
		
		# Validate district_id
		var district_id = null
		if rel.has("district") and rel.district and valid_districts.has(rel.district):
			district_id = rel.district
		
		var event_data = {
			"id": event_id,
			"type": "social",
			"subtype": "meeting",
			"timestamp": _date_to_timestamp(met_date),
			"date": met_date,
			"time": "%02d:00" % rng.randi_range(9, 20),
			"duration_minutes": rng.randi_range(30, 120),
			"location_id": null,
			"district_id": district_id,
			"summary": summary,
			"details": {"npc1": rel.source_npc_id, "npc2": rel.target_npc_id, "context": context},
			"impact": {"severity": 20, "public_knowledge": 10, "emotional_weight": 40},
			"consequences": {},
			"ripple_depth": 0,
			"affected_nodes": [rel.source_npc_id, rel.target_npc_id],
			"resolved": 1
		}
		
		var created_event_id = DB.create_event(event_data)
		if created_event_id:
			event_stats.relationship += 1
			
			# Create participants
			DB.add_event_participant(created_event_id, rel.source_npc_id, "npc", "participant")
			DB.add_event_participant(created_event_id, rel.target_npc_id, "npc", "participant")
			
			# Create memories (only ~50% remember specific meeting)
			if rng.randf() < 0.5:
				DB.create_memory({
					"npc_id": rel.source_npc_id,
					"event_id": created_event_id,
					"personal_summary": "I first met %s %s" % [rel.name2.split(" ")[0], context],
					"knowledge_level": "participant",
					"belief_accuracy": 80,
					"emotional_impact": 70,
					"timestamp": _date_to_timestamp(met_date),
					"date": met_date
				})
				event_stats.memories += 1
			if rng.randf() < 0.5:
				DB.create_memory({
					"npc_id": rel.target_npc_id,
					"event_id": created_event_id,
					"personal_summary": "I first met %s %s" % [rel.name1.split(" ")[0], context],
					"knowledge_level": "participant",
					"belief_accuracy": 80,
					"emotional_impact": 70,
					"timestamp": _date_to_timestamp(met_date),
					"date": met_date
				})
				event_stats.memories += 1

func _date_to_timestamp(date_str: String) -> int:
	# Simple conversion: assume format YYYY-MM-DD
	var parts = date_str.split("-")
	if parts.size() != 3:
		return 0
	var year = int(parts[0])
	var month = int(parts[1])
	var day = int(parts[2])
	# Approximate Unix timestamp (not precise, but good enough for ordering)
	return (year - 1970) * 31536000 + (month - 1) * 2592000 + (day - 1) * 86400

## ============================================================
## Phase 10: Validation and Polish
## ============================================================

var validation_stats = {
	"issues_found": 0,
	"issues_fixed": 0,
	"npcs_without_location": 0,
	"orgs_without_employees": 0,
	"isolated_npcs": 0
}

func _run_validation_and_polish():
	print("   🔍 Running validation checks...")
	
	_validate_npc_locations()
	_validate_organization_employees()
	_validate_relationship_symmetry()
	_validate_age_consistency()
	
	print("      Found %d issues, fixed %d" % [validation_stats.issues_found, validation_stats.issues_fixed])

func _validate_npc_locations():
	# Check all NPCs have valid locations
	validation_stats.npcs_without_location = DB.count_npcs_without_location()
	if validation_stats.npcs_without_location > 0:
		validation_stats.issues_found += 1
		print("      ⚠️ %d NPCs without location assignment" % validation_stats.npcs_without_location)

func _validate_organization_employees():
	# Check for organizations with no employees
	validation_stats.orgs_without_employees = DB.get_orgs_without_employees()
	if validation_stats.orgs_without_employees > 0:
		validation_stats.issues_found += 1
		# Mark these as "startup" or "new" - not necessarily an error
		print("      ℹ️ %d organizations with no current members (new/defunct)" % validation_stats.orgs_without_employees)

func _validate_relationship_symmetry():
	# Ensure relationships have bidirectional entries
	# With the new _create_relationship, most should be symmetric already
	# But we check for any orphaned ones
	var missing_rels = DB.get_asymmetric_relationships([], 100000) # Check all types, high limit
	
	if missing_rels.size() > 0:
		# Count by type for debugging
		var type_counts = {}
		for rel in missing_rels:
			var t = rel.get("type", "unknown")
			type_counts[t] = type_counts.get(t, 0) + 1
		print("      🔧 Found %d asymmetric relationships (fixing...)" % missing_rels.size())
		print("         Types: %s" % str(type_counts))
	
	# Map of opposite relationship types
	var opposite_types = {
		"parent": "child",
		"child": "parent",
		"landlord": "tenant",
		"tenant": "landlord",
		"boss": "subordinate",
		"subordinate": "boss",
		"friend": "friend",  # Friendships are bidirectional
		"colleague": "colleague"  # Colleague relationships are bidirectional
	}
	
	for rel in missing_rels:
		var reverse_type = opposite_types.get(rel.type, rel.type)
		DB.create_relationship(rel.target_npc_id, rel.source_npc_id, reverse_type, 50, 50, 0, 50)
		validation_stats.issues_fixed += 1

func _validate_age_consistency():
	# Check that parents are older than children
	var issues = DB.get_age_inconsistencies()
	if issues > 0:
		validation_stats.issues_found += issues
		print("      ⚠️ %d parent-child age inconsistencies found" % issues)

## Update UI progress (if UI screen is available)
## Returns immediately after scheduling UI update, caller should await process_frame
func _update_progress(status: String, percent: float):
	# Try to find UI if not already found
	if ui_screen == null:
		ui_screen = get_tree().get_first_node_in_group("world_gen_ui")
		if ui_screen == null:
			ui_screen = get_parent() if get_parent() is Control else null
	
	if ui_screen:
		# Directly update UI (we'll yield after calling this)
		if ui_screen.has_method("update_status"):
			ui_screen.update_status(status)
		if ui_screen.has_method("update_progress"):
			ui_screen.update_progress(percent)

func _print_world_summary():
	print("\n" + "═".repeat(60))
	print("                    WORLD GENERATION COMPLETE")
	print("═".repeat(60))
	
	var db_stats = DB.get_statistics()
	
	print("\n📊 POPULATION")
	print("   NPCs: %d" % db_stats.npcs)
	print("   Families: %d" % stats.families)
	print("   Organizations: %d" % db_stats.organizations)
	print("   Locations: %d" % db_stats.locations)
	
	print("\n🤝 SOCIAL NETWORK")
	print("   Relationships: %d" % db_stats.relationships)
	print("   Avg per NPC: %.1f" % (float(db_stats.relationships) / max(db_stats.npcs, 1)))
	
	print("\n📅 HISTORY")
	print("   Events: %d" % db_stats.events)
	print("   Memories: %d" % db_stats.npc_memories)
	
	print("\n⏱️ TIMINGS")
	for key in timings.keys():
		print("   %s: %.3fs" % [key, timings[key]])
	
	print("\n✅ VALIDATION")
	print("   Issues Found: %d" % validation_stats.issues_found)
	print("   Issues Fixed: %d" % validation_stats.issues_fixed)
	
	print("\n" + "═".repeat(60))
	print("World generation complete in %.2f seconds" % timings["total"])
	print("═".repeat(60) + "\n")
