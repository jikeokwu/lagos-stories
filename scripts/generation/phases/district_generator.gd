extends RefCounted
## Phase 1: District Generation
## Creates districts based on target NPC count and density ratio

var rng = RandomNumberGenerator.new()
var district_templates = {}
var name_data = {}
var district_archetypes = {}  # Maps district_id -> archetype for location generation

# Stats reference (passed from orchestrator)
var stats: Dictionary

func _init(p_stats: Dictionary, p_district_templates: Dictionary, p_name_data: Dictionary):
	stats = p_stats
	district_templates = p_district_templates
	name_data = p_name_data
	rng.randomize()

func generate(target_npcs: int, density_ratio: float) -> Dictionary:
	"""
	Generate districts based on population needs.
	Returns district_archetypes mapping for use by location generator.
	"""
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
	
	# Ensure mandatory types first
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
		var district_id = "dist_%s" % Utils.generate_uuid()
		
		var district_data = {
			"id": district_id,
			"name": district_name,
			"prosperity": rng.randi_range(template.stats.prosperity_range[0], template.stats.prosperity_range[1]),
			"safety": rng.randi_range(template.stats.safety_range[0], template.stats.safety_range[1]),
			"infrastructure": rng.randi_range(template.stats.infrastructure_range[0], template.stats.infrastructure_range[1])
		}
		
		DB.create_district(district_data)
		district_archetypes[district_id] = template  # Store full archetype for location generation
		stats.districts += 1
		print("      📍 Created %s (%s)" % [district_name, template.display_name])
	
	return district_archetypes

func get_district_ids() -> Array:
	"""Return list of created district IDs"""
	return district_archetypes.keys()

