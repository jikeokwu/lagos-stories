extends Node
## World Generator Orchestrator
## Coordinates generation phases for world creation
## 
## Phases are handled by specialized scripts in scripts/generation/phases/

# Phase generators (loaded as scripts, instantiated as RefCounted)
const DistrictGenerator = preload("res://scripts/generation/phases/district_generator.gd")
const OrganizationGenerator = preload("res://scripts/generation/phases/organization_generator.gd")
const PopulationGenerator = preload("res://scripts/generation/phases/population_generator.gd")
const LocationAssignment = preload("res://scripts/generation/phases/location_assignment.gd")
const RelationshipGenerator = preload("res://scripts/generation/phases/relationship_generator.gd")
const EventGenerator = preload("res://scripts/generation/phases/event_generator.gd")

# Template data (loaded once, shared with phase generators)
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

# Generation stats (shared with phase generators)
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
	await get_tree().process_frame
	ui_screen = get_tree().get_first_node_in_group("world_gen_ui")
	if ui_screen == null:
		ui_screen = get_parent() if get_parent() is Control else null
	if ui_screen:
		print("[WorldGenerator] Found UI screen for progress updates")
	else:
		print("[WorldGenerator] UI screen not found - progress updates disabled")
	
	print("\n" + "=".repeat(60))
	print("WORLD GENERATOR - ORCHESTRATOR MODE")
	print("=".repeat(60) + "\n")
	
	# Load templates
	if not _load_templates():
		print("❌ Failed to load templates")
		await get_tree().create_timer(1.0).timeout
		get_tree().quit()
		return
	
	# Get config from GameState
	var config = GameState.current_world_config if GameState.current_world_config else {}
	
	# Initialize database
	if GameState.current_world_id != "":
		var world_db_path = WorldManager.get_world_db_path(GameState.current_world_id)
		print("1. Initializing database for world: %s" % GameState.current_world_id)
		if not DB.initialize(world_db_path):
			print("❌ Database initialization failed")
			await get_tree().create_timer(1.0).timeout
			get_tree().quit()
			return
	else:
		print("1. Initializing database (default)...")
	if not DB.initialize():
		print("❌ Database initialization failed")
		await get_tree().create_timer(1.0).timeout
		get_tree().quit()
		return
	print("✅ Database ready\n")
	
	# Run generation
	await get_tree().process_frame
	var result = await _run_generation(config)
	
	# Notify GameState
	if result is Dictionary:
		GameState.world_generation_complete(
			result.get("stats", {}),
			result.get("timings", {}),
			result.get("db_stats", {}),
			result.get("validation_stats", {})
		)
	
	# Print summary
	_print_summary(result.get("validation_stats", {}))

func _run_generation(config: Dictionary) -> Dictionary:
	"""Main generation orchestration - runs all phases in sequence."""
	var total_start = Time.get_ticks_msec()
	
	# Extract config values with defaults
	var target_npcs = config.get("target_npcs", 500)
	var seed_value = config.get("seed", 0)
	var family_ratio = config.get("family_composition_ratio", 0.30)
	var district_density = config.get("district_density_ratio", 1.0)
	var org_density = config.get("org_density_ratio", 1.0)
	var location_density = config.get("location_density_ratio", 1.0)
	var start_date = config.get("start_date", "2025-01-01")
	var start_time = config.get("start_time", "08:00")
	
	print("2. Configuration:")
	print("   • Target NPCs: %d" % target_npcs)
	print("   • Seed: %d" % seed_value)
	print("   • Family ratio: %.0f%%" % (family_ratio * 100))
	print("   • Densities: District=%.1f, Org=%.1f, Location=%.1f\n" % [district_density, org_density, location_density])
	
	# =========================================================================
	# PHASE 1: World State Initialization
	# =========================================================================
	_update_progress("Initializing world state...", 5.0)
	var phase1_start = Time.get_ticks_msec()
	DB.initialize_world_state(str(seed_value), start_date, start_time)
	timings.world_state = (Time.get_ticks_msec() - phase1_start) / 1000.0
	print("✅ Phase 1: World state initialized (%.3fs)\n" % timings.world_state)
	await get_tree().process_frame
	
	# =========================================================================
	# PHASE 2: District Generation
	# =========================================================================
	_update_progress("Creating districts...", 10.0)
	var phase2_start = Time.get_ticks_msec()
	print("3. Creating districts...")
	
	var district_gen = DistrictGenerator.new(stats, district_templates, name_data)
	var district_archetypes = district_gen.generate(target_npcs, district_density)
	
	timings.districts = (Time.get_ticks_msec() - phase2_start) / 1000.0
	print("✅ Phase 2: %d districts created (%.3fs)\n" % [stats.districts, timings.districts])
	await get_tree().process_frame
	
	# =========================================================================
	# PHASE 3: Family Frame Generation
	# =========================================================================
	_update_progress("Generating family frames...", 15.0)
	var phase3_start = Time.get_ticks_msec()
	print("4. Generating families and NPCs (MULTI-PASS)...")
	
	var pop_gen = PopulationGenerator.new(stats, family_templates, name_data, appearance_data, cultural_data, skill_trees_data)
	var target_singles = pop_gen.generate_family_frames(target_npcs, family_ratio)
	
	timings.family_frames = (Time.get_ticks_msec() - phase3_start) / 1000.0
	await get_tree().process_frame
	
	# =========================================================================
	# PHASE 4: NPC Generation (Multi-Pass)
	# =========================================================================
	_update_progress("Generating NPCs (founders)...", 25.0)
	var phase4_start = Time.get_ticks_msec()
	
	pop_gen.pass1_generate_founders()
	await get_tree().process_frame
	
	_update_progress("Generating NPCs (spouses)...", 35.0)
	pop_gen.pass2_generate_spouses()
	await get_tree().process_frame
	
	_update_progress("Generating NPCs (children)...", 45.0)
	pop_gen.pass3_generate_children()
	await get_tree().process_frame
	
	_update_progress("Generating NPCs (extended family)...", 50.0)
	pop_gen.pass4_generate_extended()
	await get_tree().process_frame
	
	_update_progress("Generating NPCs (singles)...", 55.0)
	pop_gen.pass5_generate_singles(target_singles)
	await get_tree().process_frame
	
	var family_frames = pop_gen.get_family_frames()
	timings.npc_generation = (Time.get_ticks_msec() - phase4_start) / 1000.0
	timings.families_total = timings.family_frames + timings.npc_generation
	print("✅ Phase 4: NPCs generated (%.3fs)\n" % timings.npc_generation)
	
	# =========================================================================
	# PHASE 5: Organization Generation
	# =========================================================================
	_update_progress("Generating organizations...", 60.0)
	var phase5_start = Time.get_ticks_msec()
	print("5. Generating organization frames (Phase 2B)...")
	
	var org_gen = OrganizationGenerator.new(stats, org_templates)
	var organization_frames = org_gen.generate(target_npcs, org_density)
	
	timings.org_frames = (Time.get_ticks_msec() - phase5_start) / 1000.0
	print("✅ Phase 5: %d organizations created (%.3fs)\n" % [stats.organizations, timings.org_frames])
	await get_tree().process_frame
	
	# =========================================================================
	# PHASE 6: Location Creation
	# =========================================================================
	_update_progress("Creating locations...", 70.0)
	var phase6_start = Time.get_ticks_msec()
	
	var loc_assign = LocationAssignment.new(stats, location_templates, district_archetypes)
	loc_assign.set_family_frames(family_frames)
	loc_assign.set_organization_frames(organization_frames)
	loc_assign.set_singles_count(target_singles)
	loc_assign.create_locations_need_based(location_density)
	
	timings.locations = (Time.get_ticks_msec() - phase6_start) / 1000.0
	print("✅ Phase 6: %d locations created (%.3fs)\n" % [stats.locations, timings.locations])
	await get_tree().process_frame
	
	# =========================================================================
	# PHASE 7: Location Assignment
	# =========================================================================
	_update_progress("Assigning locations...", 75.0)
	var phase7_start = Time.get_ticks_msec()
	print("7. Assigning locations (Phase 9)...")
	
	loc_assign.assign_families_to_housing()
	loc_assign.assign_organizations_to_locations()
	
	timings.location_assignment = (Time.get_ticks_msec() - phase7_start) / 1000.0
	print("✅ Phase 7: Locations assigned (%.3fs)\n" % timings.location_assignment)
	await get_tree().process_frame
	
	# =========================================================================
	# PHASE 7b: Location Ownership Assignment
	# =========================================================================
	_update_progress("Assigning ownership...", 77.0)
	var phase7b_start = Time.get_ticks_msec()
	print("7b. Assigning ownership (Phase 9b)...")
	
	loc_assign.assign_location_ownership()
	
	timings.ownership = (Time.get_ticks_msec() - phase7b_start) / 1000.0
	print("✅ Phase 7b: Ownership assigned (%.3fs)\n" % timings.ownership)
	await get_tree().process_frame
	
	# =========================================================================
	# PHASE 8: Career & Affiliation Assignment
	# =========================================================================
	_update_progress("Assigning careers & affiliations...", 80.0)
	var phase8_start = Time.get_ticks_msec()
	print("8. Assigning careers and affiliations (Phase 6)...")
	
	var rel_gen = RelationshipGenerator.new(stats, org_templates)
	rel_gen.set_family_frames(family_frames)
	rel_gen.set_organization_frames(organization_frames)
	rel_gen.assign_npc_careers_and_affiliations()
	
	timings.org_filling = (Time.get_ticks_msec() - phase8_start) / 1000.0
	print("✅ Phase 8: Careers assigned (%.3fs)\n" % timings.org_filling)
	await get_tree().process_frame
	
	# =========================================================================
	# PHASE 8b: School & Religious Validation
	# =========================================================================
	_update_progress("Validating affiliations...", 82.0)
	var phase8b_start = Time.get_ticks_msec()
	print("8b. Validating school & religious assignments (Phase 6)...")
	
	rel_gen.validate_npc_affiliations()
	
	timings.validation_affiliations = (Time.get_ticks_msec() - phase8b_start) / 1000.0
	print("✅ Phase 8b: School & religious affiliations validated (%.3fs)\n" % timings.validation_affiliations)
	await get_tree().process_frame
	
	# =========================================================================
	# PHASE 9: Social Relationship Generation
	# =========================================================================
	_update_progress("Generating relationships...", 90.0)
	var phase9_start = Time.get_ticks_msec()
	print("9. Generating social relationships (Phase 7-8)...")
	
	rel_gen.generate_social_relationships()
	
	timings.relationships = (Time.get_ticks_msec() - phase9_start) / 1000.0
	print("✅ Phase 9: Relationships generated (%.3fs)\n" % timings.relationships)
	await get_tree().process_frame
	
	# =========================================================================
	# PHASE 10: Historical Events
	# =========================================================================
	_update_progress("Generating historical events...", 92.0)
	var phase10_start = Time.get_ticks_msec()
	print("10. Generating historical events (Phase 8)...")
	
	var event_gen = EventGenerator.new(stats)
	event_gen.generate_historical_events()
	
	timings.events = (Time.get_ticks_msec() - phase10_start) / 1000.0
	print("✅ Phase 10: Historical events generated (%.3fs)\n" % timings.events)
	await get_tree().process_frame
	
	# =========================================================================
	# PHASE 11: Comprehensive Validation
	# =========================================================================
	_update_progress("Running validation...", 95.0)
	var validation_stats = await _run_comprehensive_validation()
	
	_update_progress("Generation complete!", 100.0)
	
	# Calculate totals
	timings.total = (Time.get_ticks_msec() - total_start) / 1000.0
	
	return {
		"stats": stats.duplicate(),
		"timings": timings.duplicate(),
		"db_stats": DB.get_db_stats() if DB.has_method("get_db_stats") else {},
		"validation_stats": validation_stats
	}

func _run_comprehensive_validation() -> Dictionary:
	"""Run comprehensive post-generation validation and fixes."""
	print("11. Running validation and polish (Phase 10)...")
	var validation_stats = {
		"issues_found": 0,
		"issues_fixed": 0
	}
	
	print("   🔍 Running validation checks...")
	
	# Validate NPC locations
	var unassigned = DB.count_npcs_without_location() if DB.has_method("count_npcs_without_location") else 0
	if unassigned > 0:
		validation_stats.issues_found += 1
		validation_stats.npcs_without_location = unassigned
		print("      ⚠️ %d NPCs without location assignment" % unassigned)
	
	# Validate organization employees
	var orgs_without_employees = DB.get_orgs_without_employees() if DB.has_method("get_orgs_without_employees") else []
	if orgs_without_employees.size() > 0:
		validation_stats.issues_found += 1
		validation_stats.orgs_without_employees = orgs_without_employees.size()
		print("      ℹ️ %d organizations with no current members (new/defunct)" % orgs_without_employees.size())
	
	# Validate relationship symmetry
	var missing_rels = DB.get_asymmetric_relationships([], 100000)
	if missing_rels.size() > 0:
		validation_stats.issues_found += 1
		var type_counts = {}
		for rel in missing_rels:
			var t = rel.get("type", "unknown")
			type_counts[t] = type_counts.get(t, 0) + 1
		print("      🔧 Found %d asymmetric relationships (fixing...)" % missing_rels.size())
		print("         Types: %s" % str(type_counts))
		
		var opposite_types = {
			"parent": "child",
			"child": "parent",
			"landlord": "tenant",
			"tenant": "landlord",
			"boss": "subordinate",
			"subordinate": "boss",
			"friend": "friend",
			"colleague": "colleague"
		}
		
		for rel in missing_rels:
			var reverse_type = opposite_types.get(rel.type, rel.type)
			DB.create_relationship(rel.target_npc_id, rel.source_npc_id, reverse_type, 50, 50, 0, 50)
			validation_stats.issues_fixed += 1
		print("      ✅ Fixed %d asymmetric relationships" % validation_stats.issues_fixed)
	
	# Validate age consistency
	var age_issues = DB.get_age_inconsistencies() if DB.has_method("get_age_inconsistencies") else 0
	if age_issues > 0:
		validation_stats.issues_found += age_issues
		print("      ⚠️ %d parent-child age inconsistencies found" % age_issues)
	
	print("      Found %d issues, fixed %d" % [validation_stats.issues_found, validation_stats.issues_fixed])
	print("✅ Phase 11: Validation complete (%.3fs)\n" % (timings.get("validation_polish", 0.0)))
	return validation_stats

func _update_progress(status: String, percent: float):
	"""Update UI with generation progress."""
	if ui_screen and ui_screen.has_method("update_status"):
		ui_screen.call_deferred("update_status", status)
	if ui_screen and ui_screen.has_method("update_progress"):
		ui_screen.call_deferred("update_progress", percent)

func _print_summary(validation_stats: Dictionary = {}):
	"""Print comprehensive final generation summary."""
	var db_stats = DB.get_statistics() if DB.has_method("get_statistics") else {}
	
	print("\n" + "═".repeat(60))
	print("                    WORLD GENERATION COMPLETE")
	print("═".repeat(60))
	
	print("\n📊 POPULATION")
	print("   NPCs: %d" % db_stats.get("npcs", stats.npcs))
	print("   Families: %d" % stats.families)
	print("   Organizations: %d" % db_stats.get("organizations", stats.organizations))
	print("   Locations: %d" % db_stats.get("locations", stats.locations))
	
	print("\n🤝 SOCIAL NETWORK")
	var rel_count = db_stats.get("relationships", 0)
	var npc_count = db_stats.get("npcs", stats.npcs)
	print("   Relationships: %d" % rel_count)
	if npc_count > 0:
		print("   Avg per NPC: %.1f" % (float(rel_count) / npc_count))
	
	print("\n📅 HISTORY")
	print("   Events: %d" % db_stats.get("events", 0))
	print("   Memories: %d" % db_stats.get("npc_memories", 0))
	
	print("\n⏱️ TIMINGS")
	for key in timings.keys():
		print("   %s: %.3fs" % [key, timings[key]])
	
	print("\n✅ VALIDATION")
	var val_stats = validation_stats if validation_stats.has("issues_found") else {}
	print("   Issues Found: %d" % val_stats.get("issues_found", 0))
	print("   Issues Fixed: %d" % val_stats.get("issues_fixed", 0))
	
	print("\n" + "═".repeat(60))
	print("World generation complete in %.2f seconds" % timings.get("total", 0.0))
	print("═".repeat(60) + "\n")

func _load_templates() -> bool:
	"""Load all template data files."""
	print("Loading templates...")
	
	name_data = Utils.load_json_file("res://data/templates/name_catalog.json")
	if name_data.is_empty():
		push_error("❌ Failed to load name_catalog.json")
		return false
	print("   ✅ Names loaded")
	
	family_templates = Utils.load_json_file("res://data/templates/family_templates.json")
	if family_templates.is_empty():
		push_error("❌ Failed to load family_templates.json")
		return false
	print("   ✅ Family templates loaded")
	
	location_templates = Utils.load_json_file("res://data/templates/location_templates.json")
	if location_templates.is_empty():
		push_error("❌ Failed to load location_templates.json")
		return false
	print("   ✅ Location templates loaded")
	
	skill_trees_data = Utils.load_json_file("res://data/templates/skill_trees.json")
	if skill_trees_data.is_empty():
		push_error("❌ Failed to load skill_trees.json")
		return false
	print("   ✅ Skill trees loaded")
	
	appearance_data = Utils.load_json_file("res://data/templates/appearance_templates.json")
	if appearance_data.is_empty():
		push_error("❌ Failed to load appearance_templates.json")
		return false
	print("   ✅ Appearance templates loaded")
	
	org_templates = Utils.load_json_file("res://data/templates/organization_templates.json")
	if org_templates.is_empty():
		push_error("❌ Failed to load organization_templates.json")
		return false
	print("   ✅ Organization templates loaded")
	
	cultural_data = Utils.load_json_file("res://data/templates/cultural_data.json")
	if cultural_data.is_empty():
		push_error("❌ Failed to load cultural_data.json")
		return false
	print("   ✅ Cultural data loaded")
	
	relationship_templates = Utils.load_json_file("res://data/templates/relationship_templates.json")
	if relationship_templates.is_empty():
		push_error("❌ Failed to load relationship_templates.json")
		return false
	print("   ✅ Relationship templates loaded")
	
	district_templates = Utils.load_json_file("res://data/templates/district_templates.json")
	if district_templates.is_empty():
		push_error("❌ Failed to load district_templates.json")
		return false
	print("   ✅ District templates loaded")
	
	print("✅ All templates loaded successfully\n")
	return true
