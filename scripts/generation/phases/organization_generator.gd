extends RefCounted
## Phase 2B: Organization Generation
## Creates organizations based on population demand

var rng = RandomNumberGenerator.new()
var org_templates = {}
var organization_frames = []  # Stores all created org frames
var _created_org_types = {}   # Track: district -> subcategory -> count
var _org_id_counter = 0

# Stats reference
var stats: Dictionary

func _init(p_stats: Dictionary, p_org_templates: Dictionary):
	stats = p_stats
	org_templates = p_org_templates
	rng.randomize()

func generate(target_npcs: int, density_ratio: float = 1.0) -> Array:
	"""
	Generate organizations based on population demand.
	Returns array of organization_frames for later use.
	"""
	if not org_templates.has("categories"):
		push_error("❌ CRITICAL: organization_templates.json missing 'categories'!")
		return []
	
	# Get districts from database
	var all_districts = DB.get_all_districts()
	var districts = []
	for d in all_districts:
		districts.append(d.id)
	
	if districts.is_empty():
		push_error("❌ CRITICAL: No districts found in database!")
		return []
	
	# Reset tracking
	_created_org_types.clear()
	_org_id_counter = 0
	organization_frames.clear()
	
	# Calculate demand based on simulated world needs
	var demand = _calculate_org_demand(target_npcs, districts.size(), density_ratio)
	
	print("   📊 Demand-based org generation for %d NPCs, %d districts:" % [target_npcs, districts.size()])
	print("      • Essential infrastructure: %d" % demand.essential_total)
	print("      • Religious orgs: %d" % demand.religious_total)
	print("      • Employment orgs: %d" % demand.employment_total)
	print("      • Social/other orgs: %d" % demand.social_total)
	print("      • Target total: %d orgs" % demand.total_orgs)
	
	# Step 1: Essential Infrastructure
	_generate_essential_infrastructure(districts, demand)
	
	# Step 2: Religious Organizations
	_generate_religious_orgs_by_demand(districts, demand)
	
	# Step 3: Employment Organizations
	_generate_employment_orgs(districts, demand)
	
	# Step 4: Social & Criminal Organizations
	_generate_social_criminal_orgs(districts, demand)
	
	print("   ✅ Created %d organizations total" % organization_frames.size())
	return organization_frames

func get_organization_frames() -> Array:
	return organization_frames

# --- DEMAND CALCULATION ---

func _calculate_org_demand(target_npcs: int, district_count: int, density_ratio: float) -> Dictionary:
	var adults = int(target_npcs * 0.58)
	var workers = int(adults * 0.65)
	
	# Religious demographics
	var christian_pct = 0.65
	var muslim_pct = 0.25
	var traditional_pct = 0.10
	
	# Essential: 1 school + 1 clinic + 1 police per district
	var essential_total = district_count * 3
	
	# Religious
	var christian_npcs = int(target_npcs * christian_pct)
	var muslim_npcs = int(target_npcs * muslim_pct)
	var traditional_npcs = int(target_npcs * traditional_pct)
	
	var churches_needed = max(district_count, int(ceil(float(christian_npcs) / 80.0)))
	var mosques_needed = max(1, int(ceil(float(muslim_npcs) / 100.0)))
	var shrines_needed = max(1, int(ceil(float(traditional_npcs) / 100.0)))
	var religious_total = churches_needed + mosques_needed + shrines_needed
	
	# Employment
	var avg_org_size = 20
	var employment_capacity_needed = int(workers * 0.80)
	var employment_orgs_needed = max(district_count, int(ceil(float(employment_capacity_needed) / float(avg_org_size))))
	employment_orgs_needed = int(employment_orgs_needed * density_ratio)
	
	# Social
	var ethnic_associations = min(3, max(1, district_count))
	var sports_clubs = max(1, int(ceil(float(target_npcs) / 400.0)))
	var gangs = max(1, int(ceil(float(district_count) / 2.0)))
	var social_total = ethnic_associations + sports_clubs + gangs
	
	return {
		"target_npcs": target_npcs,
		"district_count": district_count,
		"essential_total": essential_total,
		"churches_needed": churches_needed,
		"mosques_needed": mosques_needed,
		"shrines_needed": shrines_needed,
		"religious_total": religious_total,
		"employment_total": employment_orgs_needed,
		"ethnic_associations": ethnic_associations,
		"sports_clubs": sports_clubs,
		"gangs": gangs,
		"social_total": social_total,
		"total_orgs": essential_total + religious_total + employment_orgs_needed + social_total
	}

# --- GENERATION FUNCTIONS ---

func _generate_essential_infrastructure(districts: Array, demand: Dictionary):
	print("   🏛️ Generating essential infrastructure...")
	
	for district in districts:
		var school_type = "primary_schools" if rng.randf() < 0.6 else "secondary_schools"
		_create_org_tracked("education", school_type, district)
		
		var health_type = "clinics" if demand.target_npcs < 2000 else "hospitals"
		_create_org_tracked("healthcare", health_type, district)
		
		_create_org_tracked("government", "police", district)
	
	if demand.target_npcs >= 1000:
		_create_org_tracked("healthcare", "hospitals", districts[0])
	if demand.target_npcs >= 500:
		_create_org_tracked("government", "local_government", districts[0])

func _generate_religious_orgs_by_demand(districts: Array, demand: Dictionary):
	print("   ⛪ Generating religious organizations...")
	var idx = 0
	
	for i in range(demand.churches_needed):
		_create_org_tracked("religious", "christian_churches", districts[idx % districts.size()])
		idx += 1
	
	for i in range(demand.mosques_needed):
		_create_org_tracked("religious", "mosques", districts[idx % districts.size()])
		idx += 1
	
	for i in range(demand.shrines_needed):
		_create_org_tracked("religious", "traditional_shrines", districts[idx % districts.size()])
		idx += 1
	
	print("      Created: %d churches, %d mosques, %d shrines" % [
		demand.churches_needed, demand.mosques_needed, demand.shrines_needed
	])

func _generate_employment_orgs(districts: Array, demand: Dictionary):
	print("   🏢 Generating employment organizations...")
	
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
	
	var idx = 0
	for i in range(demand.employment_total):
		var type_idx = Utils.weighted_random(type_names, type_weights)
		var biz_type = business_types[type_idx]
		var district = districts[idx % districts.size()]
		idx += 1
		
		var existing = _get_org_count(district, biz_type.subcategory)
		if existing >= 3:
			type_idx = (type_idx + 1) % business_types.size()
			biz_type = business_types[type_idx]
		
		_create_org_tracked(biz_type.category, biz_type.subcategory, district)
	
	print("      Created %d employment organizations" % demand.employment_total)

func _generate_social_criminal_orgs(districts: Array, demand: Dictionary):
	print("   🤝 Generating social/criminal organizations...")
	
	for i in range(min(demand.ethnic_associations, 3)):
		_create_org_tracked("social", "ethnic_associations", districts[i % districts.size()])
	
	for i in range(demand.sports_clubs):
		_create_org_tracked("social", "sports_clubs", districts[i % districts.size()])
	
	for i in range(demand.gangs):
		var sub = "street_gangs" if rng.randf() < 0.7 else "fraud_rings"
		_create_org_tracked("criminal", sub, districts[i % districts.size()])
	
	print("      Created %d ethnic, %d sports, %d criminal orgs" % [
		demand.ethnic_associations, demand.sports_clubs, demand.gangs
	])

# --- TRACKING & CREATION ---

func _create_org_tracked(category: String, subcategory: String, district: String):
	var org_uuid = Utils.generate_uuid()
	_create_organization_from_template(category, org_uuid, district, subcategory)
	
	if not _created_org_types.has(district):
		_created_org_types[district] = {}
	_created_org_types[district][subcategory] = _created_org_types[district].get(subcategory, 0) + 1

func _get_org_count(district: String, subcategory: String) -> int:
	if not _created_org_types.has(district):
		return 0
	return _created_org_types[district].get(subcategory, 0)

func _create_organization_from_template(category: String, org_uuid: String, district: String, forced_subcategory: String = ""):
	if not org_templates.categories.has(category):
		push_error("❌ Category '%s' not found!" % category)
		return
	
	var category_data = org_templates.categories[category]
	
	var subcategory_key = forced_subcategory
	if subcategory_key == "":
		var keys = category_data.keys()
		if keys.is_empty(): return
		subcategory_key = keys[rng.randi() % keys.size()]
	
	var subcategory_data = category_data.get(subcategory_key, {})
	var template_data = subcategory_data
	if subcategory_data is Array:
		if subcategory_data.is_empty(): return
		template_data = subcategory_data[rng.randi() % subcategory_data.size()]
	
	if not (template_data is Dictionary): return
	
	# Size selection
	var org_size = "medium"
	var member_range = [20, 100]
	if template_data.has("size_distribution"):
		var sizes = []; var weights = []
		var size_dist = template_data.size_distribution
		for size_key in size_dist.keys():
			sizes.append(size_key)
			var sd = size_dist[size_key]
			if sd is Dictionary:
				weights.append(sd.get("weight", 1))
			elif sd is Array and sd.size() >= 1:
				weights.append(sd[0] if (sd[0] is int or sd[0] is float) else 1)
			else:
				weights.append(1)
		
		if sizes.size() > 0:
			var idx = Utils.weighted_random(sizes, weights)
			org_size = sizes[idx]
			var entry = size_dist[org_size]
			if entry is Dictionary and entry.has("member_range"):
				member_range = entry.member_range
			elif entry is Array and entry.size() >= 2 and entry[1] is Array:
				member_range = entry[1]
	
	var org_name = _generate_org_name_from_template(template_data, category, org_uuid)
	
	var positions = []
	if template_data.has("positions"):
		positions = template_data.positions.duplicate(true)
	
	var reputation_base = _get_reputation_for_category(category)
	var wealth_base = _get_wealth_for_category(category)
	var size_mult = _get_size_multiplier(org_size)
	
	var legal_status = "registered"
	if category == "criminal": legal_status = "illegal"
	elif category == "social": legal_status = "informal"
	
	var pillars = template_data.get("typical_pillars", ["service", "community"]).duplicate()
	
	var org_frame = {
		"id": "org_%s" % org_uuid,
		"name": org_name,
		"category": category,
		"subcategory": subcategory_key,
		"type": subcategory_key,
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
			"influence": int(reputation_base * size_mult)
		},
		"resources": {
			"liquid_assets": int(wealth_base * size_mult),
			"property": []
		},
		"positions": positions,
		"filled_positions": []
	}
	
	organization_frames.append(org_frame)
	
	var org_data = {
		"id": org_frame.id,
		"name": org_frame.name,
		"type": category,
		"founded": org_frame.founded,
		"location_id": null,
		"legal_status": legal_status,
		"pillars": JSON.stringify(pillars),
		"reputation": JSON.stringify(org_frame.reputation),
		"resources": JSON.stringify(org_frame.resources),
		"computed_values": JSON.stringify({
			"category": category,
			"subcategory": subcategory_key,
			"district_id": district,
			"size": org_size
		})
	}
	
	DB.create_organization(org_data)
	stats.organizations += 1

func _generate_org_name_from_template(template_data: Dictionary, category: String, org_uuid: String) -> String:
	if template_data.has("name_template"):
		var tpl = template_data.name_template
		var name_str = tpl
		
		if tpl.find("{denomination}") != -1 and template_data.has("denominations"):
			var denoms = template_data.denominations
			name_str = name_str.replace("{denomination}", denoms[rng.randi() % denoms.size()])
		
		if tpl.find("{location_suffix}") != -1 and template_data.has("location_suffixes"):
			var suffixes = template_data.location_suffixes
			name_str = name_str.replace("{location_suffix}", suffixes[rng.randi() % suffixes.size()])
		
		if tpl.find("{type}") != -1:
			name_str = name_str.replace("{type}", category.capitalize())
		if tpl.find("{number}") != -1:
			name_str = name_str.replace("{number}", org_uuid.substr(0, 8))
		
		return name_str
	else:
		return "%s Organization %s" % [category.capitalize(), org_uuid.substr(0, 8)]

func _get_reputation_for_category(category: String) -> int:
	match category:
		"business": return rng.randi_range(40, 70)
		"religious": return rng.randi_range(60, 90)
		"educational", "education": return rng.randi_range(70, 90)
		"government": return rng.randi_range(50, 80)
		"social": return rng.randi_range(40, 70)
		_: return 50

func _get_wealth_for_category(category: String) -> int:
	match category:
		"business": return rng.randi_range(40, 80)
		"religious": return rng.randi_range(30, 60)
		"educational", "education": return rng.randi_range(40, 70)
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

