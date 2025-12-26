extends RefCounted
## Phase 3 & 9: Location Creation and Assignment
## Creates locations based on demand and assigns NPCs/orgs to them

var rng = RandomNumberGenerator.new()
var location_templates = {}
var district_archetypes = {}

# Stats reference
var stats: Dictionary

# Generated data refs (from other phases)
var family_frames = []
var organization_frames = []
var target_singles_count = 0
var population_generator = null  # Reference to PopulationGenerator for landlord creation

func _init(p_stats: Dictionary, p_location_templates: Dictionary, p_district_archetypes: Dictionary):
	stats = p_stats
	location_templates = p_location_templates
	district_archetypes = p_district_archetypes
	rng.randomize()

func set_family_frames(frames: Array):
	family_frames = frames

func set_organization_frames(frames: Array):
	organization_frames = frames

func set_singles_count(count: int):
	target_singles_count = count

func set_population_generator(pop_gen):
	"""Set reference to PopulationGenerator for creating landlord NPCs."""
	population_generator = pop_gen

# =============================================================================
# PHASE 3: NEED-BASED LOCATION CREATION
# =============================================================================

func create_locations_need_based(density_ratio: float = 1.0):
	"""Create locations based on actual demand."""
	print("6. Creating locations (need-based)...")
	
	# Calculate demand
	var singles_units_needed = int(ceil(float(target_singles_count) / 2.0))
	var housing_units_needed = stats.families + singles_units_needed
	var commercial_units_needed = organization_frames.size()
	
	var target_housing = int(housing_units_needed * 1.2 * density_ratio)
	var target_commercial = int(commercial_units_needed * 1.2 * density_ratio)
	
	print("   🏠 Housing Demand: %d units (Families: %d + Singles: %d → %d singles units)" % [target_housing, stats.families, target_singles_count, singles_units_needed])
	print("   🏢 Commercial Demand: %d units (Orgs: %d)" % [target_commercial, organization_frames.size()])
	
	var districts = DB.get_all_districts()
	if districts.is_empty():
		push_error("❌ No districts found!")
		return
	
	var total_housing = 0
	var total_commercial = 0
	
	# Calculate weighted distribution
	var total_res_weight = 0.0
	var total_comm_weight = 0.0
	var district_weights = {}
	
	for district in districts:
		var archetype = district_archetypes.get(district.id, null)
		if archetype == null:
			continue
		
		var ratios = archetype.get("ratios", {})
		var res = ratios.get("residential", 0.5)
		var comm = ratios.get("commercial", 0.3)
		
		district_weights[district.id] = {"res": res, "comm": comm}
		total_res_weight += res
		total_comm_weight += comm
	
	# Generate locations per district
	for district in districts:
		var archetype = district_archetypes.get(district.id, null)
		if archetype == null:
			continue
		
		var weights = district_weights.get(district.id, {"res": 0.5, "comm": 0.3})
		var demographics = archetype.get("demographics", {})
		
		var housing_share = 0
		var commercial_share = 0
		
		if total_res_weight > 0:
			housing_share = int((weights.res / total_res_weight) * target_housing)
		if total_comm_weight > 0:
			commercial_share = int((weights.comm / total_comm_weight) * target_commercial)
		
		var district_housing = 0
		var district_commercial = 0
		
		# Generate housing
		while district_housing < housing_share:
			var building_id = "loc_b_%s" % Utils.generate_uuid()
			
			var wealth = "medium"
			if demographics.has("wealth_preference"):
				var wp = demographics.wealth_preference
				if wp is Array and wp.size() > 0:
					wealth = wp[0]
			
			var template = _pick_location_template("residential", wealth)
			var capacity = rng.randi_range(template.capacity_range[0], template.capacity_range[1])
			
			_create_location_entry(building_id, template, district.id, null, capacity, "residential")
			
			var num_units = max(1, capacity / 5)
			for u in range(num_units):
				var unit_id = "loc_u_%s" % Utils.generate_uuid()
				_create_location_entry(unit_id, {"name": "apartment_unit", "display_name": "Unit %d" % (u + 1)}, district.id, building_id, 5, "residential_unit")
				district_housing += 1
		
		# Generate commercial
		while district_commercial < commercial_share:
			var building_id = "loc_b_%s" % Utils.generate_uuid()
			
			var template = _pick_location_template("commercial", "medium")
			var capacity = rng.randi_range(template.capacity_range[0], template.capacity_range[1])
			
			_create_location_entry(building_id, template, district.id, null, capacity, "commercial")
			
			var num_units = max(1, capacity / 20)
			for u in range(num_units):
				var unit_id = "loc_u_%s" % Utils.generate_uuid()
				_create_location_entry(unit_id, {"name": "office_unit", "display_name": "Suite %d" % (u + 1)}, district.id, building_id, 20, "commercial_unit")
				district_commercial += 1
		
		total_housing += district_housing
		total_commercial += district_commercial
	
	print("   ✅ Generated %d housing units (Target: %d)" % [total_housing, target_housing])
	print("   ✅ Generated %d commercial units (Target: %d)" % [total_commercial, target_commercial])

func _pick_location_template(category: String, _wealth_level: String) -> Dictionary:
	var target = category
	if not location_templates.has(target):
		if target == "industrial":
			target = "commercial"
		elif target == "public":
			target = "commercial"
		else:
			target = "residential"
	
	var types = location_templates.get(target, {}).get("types", [])
	if types.is_empty():
		return {"name": "generic", "display_name": "Building", "capacity_range": [10, 50]}
	
	return types[rng.randi() % types.size()]

func _create_location_entry(id: String, template: Dictionary, district: String, parent_id, capacity: int, type: String):
	var location_name = template.get("display_name", "Building")
	if parent_id == null and template.has("names"):
		location_name = _generate_location_name(template, district)
	
	var loc_data = {
		"id": id,
		"name": location_name,
		"type": type,
		"district_id": district,
		"building_id": parent_id if parent_id else null,
		"parent_location_id": parent_id if parent_id else null,
		"physical_properties": JSON.stringify({"capacity": capacity, "condition": rng.randi_range(50, 100)}),
		"access": JSON.stringify({"control_type": "private"}),
		"reputation": JSON.stringify({"safety": 50}),
		"features": JSON.stringify({"utilities": {}})
	}
	
	DB.create_location(loc_data)
	stats.locations += 1

func _generate_location_name(template: Dictionary, _district: String) -> String:
	var names = template.get("names", [])
	if names.is_empty():
		return template.get("display_name", "Building")
	return names[rng.randi() % names.size()]

# =============================================================================
# PHASE 9: LOCATION ASSIGNMENT
# =============================================================================

func assign_families_to_housing():
	"""Assign families and singles to housing units."""
	print("   🏠 Assigning families to housing units...")
	
	var all_locs = DB.get_all_locations()
	print("      ℹ️ Total locations: %d" % all_locs.size())
	
	var residential_units = DB.get_location_units("residential_unit")
	if residential_units.is_empty():
		print("      ⚠️ No residential units found")
		return
	
	# Group by district
	var units_by_district = {}
	for unit in residential_units:
		var district = unit.district_id
		if not units_by_district.has(district):
			units_by_district[district] = []
		units_by_district[district].append(unit.id)
	
	# Assign families
	var assigned = 0
	for frame in family_frames:
		var district = frame.district
		
		if not units_by_district.has(district) or units_by_district[district].is_empty():
			for d in units_by_district.keys():
				if not units_by_district[d].is_empty():
					district = d
					break
		
		if not units_by_district.has(district) or units_by_district[district].is_empty():
			continue
		
		var unit_id = units_by_district[district].pop_back()
		
		for npc_data in frame.generated_npcs:
			var npc_id = npc_data.id if typeof(npc_data) == TYPE_DICTIONARY else npc_data
			DB.update_npc(npc_id, {"current_location_id": unit_id})
		
		assigned += 1
	
	print("      ✅ %d families assigned" % assigned)
	
	# Assign singles (2 per unit)
	var single_npcs = DB.get_single_adults()
	var singles_assigned = 0
	var current_unit_id = null
	var current_count = 0
	
	for npc in single_npcs:
		if npc.get("current_location_id") and npc.current_location_id != "":
			continue
		
		# Get district_id (standardized) or fall back to district (backward compatibility)
		var identity = npc.get("identity", {})
		var district = "central"
		if identity is Dictionary:
			district = identity.get("district_id", identity.get("district", "central"))
		
		if current_unit_id == null or current_count >= 2:
			if not units_by_district.has(district) or units_by_district[district].is_empty():
				for d in units_by_district.keys():
					if not units_by_district[d].is_empty():
						district = d
						break
			
			if units_by_district.has(district) and not units_by_district[district].is_empty():
				current_unit_id = units_by_district[district].pop_back()
				current_count = 0
			else:
				break
		
		if current_unit_id:
			DB.update_npc(npc.id, {"current_location_id": current_unit_id})
			current_count += 1
			singles_assigned += 1
	
	print("      ✅ %d singles assigned" % singles_assigned)

func assign_organizations_to_locations():
	"""Assign organizations to commercial units."""
	print("   🏢 Assigning organizations to commercial units...")
	
	var commercial_units = DB.get_location_units("commercial_unit")
	if commercial_units.is_empty():
		print("      ⚠️ No commercial units found")
		return
	
	# Group by district
	var units_by_district = {}
	for unit in commercial_units:
		var district = unit.district_id
		if not units_by_district.has(district):
			units_by_district[district] = []
		units_by_district[district].append(unit.id)
	
	var all_orgs = DB.get_all_organizations()
	var assigned = 0
	
	for org in all_orgs:
		if org.type in ["education", "educational", "religious", "religion"]:
			continue
		
		var org_district = null
		var members = DB.get_organization_members(org.id)
		if members.size() > 0:
			var district = DB.get_npc_district(members[0].npc_id)
			if not district.is_empty():
				org_district = district
		
		if org_district == null:
			for d in units_by_district.keys():
				if not units_by_district[d].is_empty():
					org_district = d
					break
		
		if org_district == null or not units_by_district.has(org_district) or units_by_district[org_district].is_empty():
			continue
		
		var unit_id = units_by_district[org_district].pop_back()
		DB.db.query("UPDATE organizations SET location_id = '%s' WHERE id = '%s';" % [unit_id, org.id])
		assigned += 1
	
	print("      ✅ %d organizations assigned" % assigned)

# =============================================================================
# PHASE 9b: LOCATION OWNERSHIP
# =============================================================================

var landlord_npcs: Array = []

func assign_location_ownership():
	"""Assign ownership to locations (owner-occupied vs rented)."""
	print("   🏠 Determining location ownership...")
	
	# Step 1: Assign residential ownership (determines rented vs owner-occupied)
	var residential_stats = _assign_residential_ownership()
	
	# Step 2: Assign commercial ownership
	var commercial_stats = _assign_commercial_ownership()
	
	# Step 3: Generate dynamic landlord NPCs based on rented units
	var total_rented = residential_stats.rented + commercial_stats.rented
	var landlord_count = _calculate_landlord_count(total_rented)
	_generate_landlord_npcs(landlord_count, residential_stats.rented_by_district)
	
	# Step 4: Assign landlords to rented properties
	_assign_landlords_to_properties(residential_stats.rented, commercial_stats.rented)
	
	# Step 5: Assign landlords to luxury home locations
	_assign_landlords_to_homes()
	
	# Step 6: Create landlord-tenant relationships
	var landlord_rels = _create_landlord_tenant_relationships()
	
	print("      ✅ %d landlords created (dynamic, ~%d properties each), %d owner-occupied, %d rented" % [landlord_npcs.size(), int(total_rented / max(1, landlord_npcs.size())), residential_stats.owner_occupied, residential_stats.rented])
	print("      ✅ %d commercial org-owned, %d commercial rented" % [commercial_stats.org_owned, commercial_stats.rented])
	print("      ✅ %d landlord-tenant relationships created" % landlord_rels)

func _calculate_landlord_count(total_rented: int) -> int:
	"""Calculate dynamic landlord count based on rented properties."""
	if total_rented == 0:
		return 0
	
	# Target: 1 landlord per 20-30 properties (realistic portfolio size)
	# Min 3 landlords, max reasonable (1 per 15 for large worlds)
	var target_ratio = 25.0  # Average properties per landlord
	var landlord_count = max(3, int(ceil(float(total_rented) / target_ratio)))
	
	# Cap at 1 per 15 properties for very large worlds
	var max_ratio = 15.0
	var max_landlords = int(ceil(float(total_rented) / max_ratio))
	landlord_count = min(landlord_count, max_landlords)
	
	return landlord_count

func _generate_landlord_npcs(count: int, rented_by_district: Dictionary):
	"""Generate dynamic landlord NPCs distributed across districts."""
	if count == 0:
		return
	
	if population_generator == null:
		push_error("❌ PopulationGenerator not set! Cannot create landlord NPCs.")
		return
	
	print("      Generating %d landlord NPCs (dynamic, based on %d rented properties)..." % [count, rented_by_district.values().reduce(func(a, b): return a + b, 0)])
	
	# Get districts with rented properties, weighted by count
	var district_weights = []
	var all_districts = DB.get_all_districts()
	var district_map = {}
	
	for d in all_districts:
		district_map[d.id] = d
		var rented_count = rented_by_district.get(d.id, 0)
		if rented_count > 0:
			district_weights.append({"id": d.id, "weight": rented_count})
	
	# If no rented properties by district, distribute evenly
	if district_weights.is_empty():
		for d in all_districts:
			district_weights.append({"id": d.id, "weight": 1})
	
	# Calculate total weight for distribution
	var total_weight = 0
	for dw in district_weights:
		total_weight += dw.weight
	
	# Generate landlords distributed by district weight
	for i in range(count):
		# Select district based on weight
		var target = rng.randi() % total_weight
		var current = 0
		var selected_district_id = district_weights[0].id
		for dw in district_weights:
			current += dw.weight
			if target < current:
				selected_district_id = dw.id
				break
		
		# Generate age (45-70)
		var age = rng.randi_range(45, 70)
		
		# Use population generator to create landlord NPC
		var landlord_id = population_generator.create_landlord_npc(selected_district_id, age)
		landlord_npcs.append(landlord_id)

func _assign_residential_ownership() -> Dictionary:
	var result = {"owner_occupied": 0, "rented": 0, "rented_by_district": {}}
	
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
			var parsed = JSON.parse_string(unit.access)
			if parsed is Dictionary:
				access_data = parsed
		
		if is_owner:
			# Owner-occupied
			access_data["owner_npc_id"] = unit.tenant_id
			access_data["ownership_type"] = "owner_occupied"
			result.owner_occupied += 1
		else:
			# Rented - mark for landlord assignment later
			access_data["ownership_type"] = "rented"
			access_data["tenant_npc_id"] = unit.tenant_id
			result.rented += 1
			
			# Track rented units by district for landlord distribution
			var district_id = unit.district_id if unit.has("district_id") else unit.district if unit.has("district") else "central"
			if not result.rented_by_district.has(district_id):
				result.rented_by_district[district_id] = 0
			result.rented_by_district[district_id] += 1
		
		# Update location with ownership info (without landlord yet)
		DB.update_location_access(unit.location_id, access_data)
	
	return result

func _assign_commercial_ownership() -> Dictionary:
	var result = {"org_owned": 0, "rented": 0}
	
	# Get commercial units with their assigned organizations
	var units = DB.get_commercial_units_with_details()
	
	for unit in units:
		var access_data = {}
		if unit.access and unit.access != "":
			var parsed = JSON.parse_string(unit.access)
			if parsed is Dictionary:
				access_data = parsed
		
		if unit.org_id == null:
			# No org assigned, mark as vacant (will assign landlord later)
			access_data["ownership_type"] = "vacant"
		else:
			# Org is assigned - determine if they own or rent
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
				# Organization rents from landlord (will assign landlord later)
				access_data["ownership_type"] = "rented"
				access_data["tenant_org_id"] = unit.org_id
				result.rented += 1
		
		DB.update_location_access(unit.location_id, access_data)
	
	return result

func _assign_landlords_to_properties(_residential_rented: int, _commercial_rented: int):
	"""Assign landlords to all rented residential and commercial properties."""
	if landlord_npcs.is_empty():
		return
	
	# Get all rented residential units
	var residential_units = DB.get_residential_units_with_details()
	var rented_residential = []
	for unit in residential_units:
		if unit.access and unit.access != "":
			var access = JSON.parse_string(unit.access) if unit.access is String else unit.access
			if access is Dictionary and access.get("ownership_type") == "rented":
				rented_residential.append(unit)
	
	# Get all rented/vacant commercial units
	var commercial_units = DB.get_commercial_units_with_details()
	var rented_commercial = []
	for unit in commercial_units:
		if unit.access and unit.access != "":
			var access = JSON.parse_string(unit.access) if unit.access is String else unit.access
			if access is Dictionary:
				var ownership = access.get("ownership_type")
				if ownership == "rented" or ownership == "vacant":
					rented_commercial.append(unit)
	
	# Distribute properties among landlords (round-robin for even distribution)
	var landlord_index = 0
	var properties_per_landlord = {}
	
	# Initialize property counts
	for landlord_id in landlord_npcs:
		properties_per_landlord[landlord_id] = []
	
	# Assign residential properties
	for unit in rented_residential:
		var landlord_id = landlord_npcs[landlord_index % landlord_npcs.size()]
		landlord_index += 1
		
		var access_data = {}
		if unit.access and unit.access != "":
			var parsed = JSON.parse_string(unit.access)
			if parsed is Dictionary:
				access_data = parsed
		
		access_data["owner_npc_id"] = landlord_id
		DB.update_location_access(unit.location_id, access_data)
		_add_property_to_landlord(landlord_id, unit.location_id)
		properties_per_landlord[landlord_id].append(unit.location_id)
	
	# Assign commercial properties
	for unit in rented_commercial:
		var landlord_id = landlord_npcs[landlord_index % landlord_npcs.size()]
		landlord_index += 1
		
		var access_data = {}
		if unit.access and unit.access != "":
			var parsed = JSON.parse_string(unit.access)
			if parsed is Dictionary:
				access_data = parsed
		
		access_data["owner_npc_id"] = landlord_id
		DB.update_location_access(unit.location_id, access_data)
		_add_property_to_landlord(landlord_id, unit.location_id)
		properties_per_landlord[landlord_id].append(unit.location_id)

func _assign_landlords_to_homes():
	"""Create a mansion for each landlord in their district."""
	if landlord_npcs.is_empty():
		return
	
	# Get mansion template from location_templates
	var mansion_template = null
	if location_templates.has("residential") and location_templates.residential.has("types"):
		for template in location_templates.residential.types:
			if template.get("name") == "mansion":
				mansion_template = template
				break
	
	if mansion_template == null:
		push_error("❌ Mansion template not found! Cannot create mansions for landlords.")
		return
	
	# Create a mansion for each landlord
	for landlord_id in landlord_npcs:
		# Get landlord's district
		var landlord = DB.get_npc(landlord_id)
		if landlord.is_empty():
			continue
		
		var landlord_district = "central"
		var identity = landlord.get("identity", {})
		if identity is String:
			identity = JSON.parse_string(identity)
		if identity is Dictionary:
			landlord_district = identity.get("district_id", identity.get("district", "central"))
		
		# Generate building ID and unit ID
		var building_id = "loc_b_%s" % Utils.generate_uuid()
		var unit_id = "loc_u_%s" % Utils.generate_uuid()
		
		# Get capacity, condition, security from mansion template
		var capacity_range = mansion_template.get("capacity_range", [8, 20])
		var condition_range = mansion_template.get("condition_range", [90, 100])
		var security_range = mansion_template.get("security_range", [85, 100])
		
		var building_capacity = rng.randi_range(capacity_range[0], capacity_range[1])
		var unit_capacity = rng.randi_range(8, 12)  # Smaller capacity for single unit
		var condition = rng.randi_range(condition_range[0], condition_range[1])
		var security = rng.randi_range(security_range[0], security_range[1])
		
		# Create mansion building
		var building_name = mansion_template.get("display_name", "Luxury Mansion")
		if mansion_template.has("names") and mansion_template.names.size() > 0:
			var name_template = mansion_template.names[rng.randi() % mansion_template.names.size()]
			# Simple name generation (could be enhanced with district name)
			building_name = name_template.replace("{Name}", landlord.get("name", "Estate").split(" ")[0])
		
		var building_data = {
			"id": building_id,
			"name": building_name,
			"type": "residential",
			"district_id": landlord_district,
			"building_id": null,
			"parent_location_id": null,
			"physical_properties": JSON.stringify({
				"capacity": building_capacity,
				"condition": condition,
				"security": security
			}),
			"access": JSON.stringify({
				"control_type": "private",
				"owner_npc_id": landlord_id,
				"ownership_type": "owner_occupied"
			}),
			"reputation": JSON.stringify(mansion_template.get("base_reputation", {"safety": 95, "prestige": 98, "activity_level": 25})),
			"features": JSON.stringify({
				"utilities": {},
				"amenities": _generate_mansion_amenities(mansion_template)
			})
		}
		
		DB.create_location(building_data)
		stats.locations += 1
		
		# Create residential unit within the mansion
		var unit_data = {
			"id": unit_id,
			"name": "Main Residence",
			"type": "residential_unit",
			"district_id": landlord_district,
			"building_id": building_id,
			"parent_location_id": building_id,
			"physical_properties": JSON.stringify({
				"capacity": unit_capacity,
				"condition": condition,
				"security": security
			}),
			"access": JSON.stringify({
				"control_type": "private",
				"owner_npc_id": landlord_id,
				"ownership_type": "owner_occupied"
			}),
			"reputation": JSON.stringify(mansion_template.get("base_reputation", {"safety": 95, "prestige": 98, "activity_level": 25})),
			"features": JSON.stringify({
				"utilities": {},
				"amenities": {}
			})
		}
		
		DB.create_location(unit_data)
		stats.locations += 1
		
		# Update landlord's current_location_id to the unit
		DB.update_npc(landlord_id, {"current_location_id": unit_id})
		
		# Add both building and unit to landlord's property list
		_add_property_to_landlord(landlord_id, building_id)
		_add_property_to_landlord(landlord_id, unit_id)

func _generate_mansion_amenities(template: Dictionary) -> Dictionary:
	"""Generate amenities for mansion based on template probabilities."""
	var amenities = {}
	var amenities_prob = template.get("amenities_probability", {})
	
	for amenity_name in amenities_prob.keys():
		var probability = amenities_prob[amenity_name]
		if rng.randf() < probability:
			amenities[amenity_name] = true
	
	return amenities

func _add_property_to_landlord(landlord_id: String, location_id: String):
	# Update landlord's resources.property array
	var npc = DB.get_npc(landlord_id)
	if npc.is_empty():
		return
	
	var resources = npc.get("resources", {})
	if resources == null or not resources is Dictionary:
		resources = {"property": [], "liquid_assets": [], "access": [], "annual_income": 0}
	
	if not resources.has("property"):
		resources["property"] = []
	
	if resources.property is Array:
		resources.property.append(location_id)
	
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

