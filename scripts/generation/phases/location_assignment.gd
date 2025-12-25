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
	var loc_id_counter = 0
	
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
			loc_id_counter += 1
			var building_id = "loc_b_%d" % loc_id_counter
			
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
				loc_id_counter += 1
				var unit_id = "loc_u_%d" % loc_id_counter
				_create_location_entry(unit_id, {"name": "apartment_unit", "display_name": "Unit %d" % (u + 1)}, district.id, building_id, 5, "residential_unit")
				district_housing += 1
		
		# Generate commercial
		while district_commercial < commercial_share:
			loc_id_counter += 1
			var building_id = "loc_b_%d" % loc_id_counter
			
			var template = _pick_location_template("commercial", "medium")
			var capacity = rng.randi_range(template.capacity_range[0], template.capacity_range[1])
			
			_create_location_entry(building_id, template, district.id, null, capacity, "commercial")
			
			var num_units = max(1, capacity / 20)
			for u in range(num_units):
				loc_id_counter += 1
				var unit_id = "loc_u_%d" % loc_id_counter
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
		
		var district = npc.identity.get("district", "central") if npc.get("identity") else "central"
		
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
		var gender = "male" if rng.randf() < 0.6 else "female"
		var age = rng.randi_range(45, 70)
		
		# Create basic landlord NPC (simplified - using DB.create_npc directly)
		var npc_data = {
			"id": landlord_id,
			"name": "Landlord %d" % i,
			"definite": JSON.stringify({
				"gender": gender,
				"age": age,
				"alive": true,
				"orientation": rng.randi_range(60, 100)
			}),
			"attributes": JSON.stringify({"strength": 40, "intelligence": 70, "charisma": 65}),
			"appearance": JSON.stringify({}),
			"identity": JSON.stringify({
				"tribe": "yoruba",
				"spoken_languages": ["English", "Yoruba"],
				"education": {"level": "postgraduate", "institution": null},
				"religious_path": "christian",
				"occupation": "Property Investor",
				"family_id": null,
				"district": district
			}),
			"personality": JSON.stringify({}),
			"political_ideology": JSON.stringify({}),
			"skills": JSON.stringify({"business": {"investing": 8, "negotiation": 7}}),
			"resources": JSON.stringify({
				"liquid_assets": [{"type": "bank_account", "amount": rng.randi_range(50000000, 200000000)}],
				"property": [],
				"access": [],
				"annual_income": rng.randi_range(20000000, 80000000)
			}),
			"status": JSON.stringify({"health": 70, "stress": 30, "reputation": 70}),
			"demographic_affinities": JSON.stringify({"capitalist_class": 80}),
			"current_location_id": null
		}
		
		DB.create_npc(npc_data)
		landlord_npcs.append(landlord_id)
		stats.npcs = stats.get("npcs", 0) + 1

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
			var parsed = JSON.parse_string(unit.access)
			if parsed is Dictionary:
				access_data = parsed
		
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
			var parsed = JSON.parse_string(unit.access)
			if parsed is Dictionary:
				access_data = parsed
		
		if unit.org_id == null:
			# No org assigned, landlord owns empty commercial space
			if landlord_npcs.size() > 0:
				var landlord_id = landlord_npcs[rng.randi() % landlord_npcs.size()]
				access_data["owner_npc_id"] = landlord_id
				access_data["ownership_type"] = "vacant"
				_add_property_to_landlord(landlord_id, unit.location_id)
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

