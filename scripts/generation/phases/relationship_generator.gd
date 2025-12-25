extends RefCounted
## Phase 5-8: Career Assignment & Relationship Generation
## Assigns careers, affiliations, and generates social relationships

var rng = RandomNumberGenerator.new()
var org_templates = {}

# Stats reference
var stats: Dictionary

# Generated data refs
var family_frames = []
var organization_frames = []

func _init(p_stats: Dictionary, p_org_templates: Dictionary):
	stats = p_stats
	org_templates = p_org_templates
	rng.randomize()

func set_family_frames(frames: Array):
	family_frames = frames

func set_organization_frames(frames: Array):
	organization_frames = frames

# =============================================================================
# PHASE 5: CAREER & AFFILIATION ASSIGNMENT
# =============================================================================

func assign_npc_careers_and_affiliations():
	"""Assign NPCs to organizations based on occupation and religion."""
	print("   📋 Assigning careers and affiliations...")
	
	var all_npcs = DB.get_all_npcs(true)  # adults only
	var children = DB.get_all_child_npcs()
	
	# Index organizations by category and district
	var orgs_by_type_dist = {}
	for org in organization_frames:
		var type = org.category
		var district = org.district
		
		if not orgs_by_type_dist.has(type):
			orgs_by_type_dist[type] = {}
		if not orgs_by_type_dist[type].has(district):
			orgs_by_type_dist[type][district] = []
		
		orgs_by_type_dist[type][district].append(org)
	
	# 1. Assign schools to children
	var schools_assigned = 0
	for child in children:
		var identity = child.get("identity", {})
		if not identity is Dictionary:
			continue
		
		var district = identity.get("district", "central")
		var school = _find_local_org(orgs_by_type_dist, "education", district)
		
		if school and not school.is_empty():
			var existing = DB.get_npc_memberships(child.id)
			var already = false
			for mem in existing:
				if mem.get("org_id") == school.id:
					already = true
					break
			
			if not already:
				DB.create_membership(child.id, school.id, "Student", 1, 0, 50, 50, 50)
				if not identity.has("education"):
					identity["education"] = {}
				identity.education["institution"] = school.id
				schools_assigned += 1
	
	print("      ✅ %d children assigned to schools" % schools_assigned)
	
	# 2. Assign jobs to adults
	var jobs_assigned = 0
	for npc in all_npcs:
		var identity = npc.get("identity", {})
		if not identity is Dictionary:
			continue
		
		var occupation = identity.get("occupation", "")
		if occupation.is_empty() or occupation == "unemployed" or occupation == "retired":
			continue
		
		# Check if already employed
		var existing = DB.get_npc_memberships(npc.id)
		var has_job = false
		for mem in existing:
			if mem.get("role", "") not in ["Student", "Member", ""]:
				has_job = true
				break
		if has_job:
			continue
		
		var org_type = _get_org_type_for_occupation(occupation)
		var district = identity.get("district", "central")
		var employer = _find_local_org(orgs_by_type_dist, org_type, district)
		
		if employer and not employer.is_empty():
			var role = occupation
			var weight = 1
			if "Manager" in role or "Director" in role:
				weight = 5
			if "CEO" in role or "Owner" in role:
				weight = 10
			
			DB.create_membership(npc.id, employer.id, role, weight, rng.randi_range(0, 10), rng.randi_range(40, 90), 50, 50)
			employer.filled_positions.append({"npc_id": npc.id, "title": role, "weight": weight})
			jobs_assigned += 1
	
	print("      ✅ %d adults assigned to jobs" % jobs_assigned)
	
	# 3. Assign religious affiliations
	var religious_assigned = 0
	for npc in all_npcs:
		var identity = npc.get("identity", {})
		if not identity is Dictionary:
			continue
		
		var religion = identity.get("religious_path", "none")
		if religion is Dictionary or religion == null:
			religion = "none"
		if religion == "none" or religion == "":
			continue
		
		var district = identity.get("district", "central")
		var church = _find_local_org(orgs_by_type_dist, "religious", district)
		
		if church and not church.is_empty():
			var existing = DB.get_npc_memberships(npc.id)
			var already = false
			for mem in existing:
				if mem.get("org_id") == church.id:
					already = true
					break
			
			if not already:
				DB.create_membership(npc.id, church.id, "Member", 1, rng.randi_range(0, 20), 80, 50, 80)
				religious_assigned += 1
	
	print("      ✅ %d religious affiliations created" % religious_assigned)

func _find_local_org(org_index: Dictionary, type: String, district: String) -> Dictionary:
	# Try local district first
	if org_index.has(type) and org_index[type].has(district):
		var options = org_index[type][district]
		if not options.is_empty():
			return options[rng.randi() % options.size()]
	
	# Fallback: any district
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
	if "teacher" in occupation or "professor" in occupation:
		return "education"
	if "doctor" in occupation or "nurse" in occupation:
		return "healthcare"
	if "priest" in occupation or "pastor" in occupation:
		return "religious"
	if "police" in occupation or "officer" in occupation:
		return "government"
	return "business"

# =============================================================================
# PHASE 6-8: RELATIONSHIP GENERATION
# =============================================================================

func generate_social_relationships():
	"""Generate social relationships between NPCs."""
	print("   🤝 Generating social relationships...")
	
	var school_count = _generate_school_relationships()
	print("      ✅ %d school friendships" % school_count)
	
	var work_count = _generate_work_relationships()
	print("      ✅ %d colleague relationships" % work_count)
	
	var neighbor_count = _generate_neighborhood_relationships()
	print("      ✅ %d neighborhood friendships" % neighbor_count)
	
	var romantic_count = _generate_romantic_relationships()
	print("      ✅ %d romantic/ex relationships" % romantic_count)
	
	# Pass 6: Fill isolated NPCs
	var isolated_count = _fill_isolated_npcs()
	print("      ✅ %d filler relationships for isolated NPCs" % isolated_count)

func _generate_school_relationships() -> int:
	var count = 0
	var processed = {}
	
	var all_orgs = DB.get_all_organizations()
	var schools = []
	for org in all_orgs:
		if org.type in ["education", "educational"]:
			schools.append(org)
	
	for school in schools:
		var members = DB.get_organization_members(school.id)
		if members.size() < 2:
			continue
		
		for member in members:
			var npc_id = member.npc_id
			var num_friends = rng.randi_range(1, min(3, members.size() - 1))
			
			for i in range(num_friends):
				var friend = members[rng.randi() % members.size()]
				var friend_id = friend.npc_id
				
				if friend_id == npc_id:
					continue
				
				var key = _pair_key(npc_id, friend_id)
				if processed.has(key):
					continue
				
				processed[key] = true
				DB.create_relationship(npc_id, friend_id, "friend", 60, 60, 0, 50)
				count += 1
	
	return count

func _generate_work_relationships() -> int:
	var count = 0
	var processed = {}
	
	var all_orgs = DB.get_all_organizations()
	var workplaces = []
	for org in all_orgs:
		if org.type not in ["education", "educational", "religious", "religion"]:
			workplaces.append(org)
	
	for workplace in workplaces:
		var members = DB.get_organization_members(workplace.id)
		if members.size() < 2:
			continue
		
		for member in members:
			var npc_id = member.npc_id
			var num_colleagues = rng.randi_range(1, min(2, members.size() - 1))
			
			for i in range(num_colleagues):
				var colleague = members[rng.randi() % members.size()]
				var colleague_id = colleague.npc_id
				
				if colleague_id == npc_id:
					continue
				
				var key = _pair_key(npc_id, colleague_id)
				if processed.has(key):
					continue
				
				processed[key] = true
				DB.create_relationship(npc_id, colleague_id, "colleague", 40, 50, 0, 40)
				count += 1
	
	return count

func _generate_neighborhood_relationships() -> int:
	var count = 0
	var processed = {}
	
	var npcs_by_district = {}
	var all_npcs = DB.get_all_npcs()
	
	for npc in all_npcs:
		var identity = npc.get("identity", {})
		var district = identity.get("district", "unknown")
		if not npcs_by_district.has(district):
			npcs_by_district[district] = []
		npcs_by_district[district].append(npc)
	
	for district_id in npcs_by_district.keys():
		var neighbors = npcs_by_district[district_id]
		if neighbors.size() < 2:
			continue
		
		for npc in neighbors:
			if rng.randf() > 0.4:
				continue
			
			var num_friends = rng.randi_range(1, min(2, neighbors.size() - 1))
			
			for i in range(num_friends):
				var neighbor = neighbors[rng.randi() % neighbors.size()]
				var neighbor_id = neighbor.id
				
				if neighbor_id == npc.id:
					continue
				
				var key = _pair_key(npc.id, neighbor_id)
				if processed.has(key):
					continue
				
				if DB.get_relationship(npc.id, neighbor_id).size() > 0:
					processed[key] = true
					continue
				
				processed[key] = true
				DB.create_relationship(npc.id, neighbor_id, "friend", 50, 50, 0, 40)
				count += 1
	
	return count

func _generate_romantic_relationships() -> int:
	var count = 0
	
	var singles = DB.get_single_adults()
	if singles.is_empty():
		return count
	
	var singles_by_district = {}
	for npc in singles:
		var district = npc.district if npc.district else "unknown"
		if not singles_by_district.has(district):
			singles_by_district[district] = []
		singles_by_district[district].append(npc)
	
	var processed = {}
	
	for npc in singles:
		if processed.has(npc.id):
			continue
		if rng.randf() > 0.30:
			continue
		
		var age = npc.age if npc.age else 25
		var gender = npc.gender if npc.gender else "male"
		var orientation = npc.orientation if npc.orientation else 50
		var district = npc.district if npc.district else "unknown"
		
		var candidates = []
		var districts_to_check = [district]
		for d in singles_by_district.keys():
			if d != district:
				districts_to_check.append(d)
		
		for d in districts_to_check:
			if not singles_by_district.has(d):
				continue
			for candidate in singles_by_district[d]:
				if candidate.id == npc.id or processed.has(candidate.id):
					continue
				
				var cand_age = candidate.age if candidate.age else 25
				var cand_gender = candidate.gender if candidate.gender else "female"
				
				if abs(age - cand_age) > 10:
					continue
				
				var compatible = false
				if gender == "male":
					compatible = (orientation >= 0 and cand_gender == "female") or (orientation < 0 and cand_gender == "male")
				else:
					compatible = (orientation >= 0 and cand_gender == "male") or (orientation < 0 and cand_gender == "female")
				
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
		
		var ex = candidates[rng.randi() % candidates.size()]
		processed[npc.id] = true
		processed[ex.id] = true
		
		DB.create_relationship(npc.id, ex.id, "ex", rng.randi_range(-20, 40), rng.randi_range(10, 50), rng.randi_range(20, 60), rng.randi_range(10, 50))
		DB.create_relationship(ex.id, npc.id, "ex", rng.randi_range(-20, 40), rng.randi_range(10, 50), rng.randi_range(20, 60), rng.randi_range(10, 50))
		count += 1
	
	return count

func _pair_key(id1: String, id2: String) -> String:
	if id1 < id2:
		return "%s_%s" % [id1, id2]
	else:
		return "%s_%s" % [id2, id1]

# =============================================================================
# PHASE 6: VALIDATION - School & Religious Affiliations
# =============================================================================

func validate_npc_affiliations():
	"""Validate and assign schools to educated NPCs and religious orgs to religious NPCs."""
	print("   🏫 Assigning schools to educated NPCs...")
	var schools_assigned = _assign_schools_to_npcs()
	print("      ✅ %d schools assigned" % schools_assigned)
	
	print("   ⛪ Assigning religious organizations to religious NPCs...")
	var religious_assigned = _assign_religious_orgs_to_npcs()
	print("      ✅ %d religious org memberships created" % religious_assigned)

func _assign_schools_to_npcs() -> int:
	var all_npcs = DB.get_all_npcs()
	var assigned_count = 0
	var school_orgs = {}  # Cache: district -> [school_ids]
	
	for npc in all_npcs:
		var identity = npc.get("identity", {})
		if not identity is Dictionary:
			continue
		
		var edu_level = identity.get("education", {}).get("level", "none")
		var current_school = identity.get("education", {}).get("institution", null)
		
		# Skip if no education or already has school
		if edu_level == "none" or current_school != null:
			continue
		
		var district = identity.get("district", "central")
		
		# Find or create appropriate school in district
		var school_id = _find_or_create_school(district, edu_level, school_orgs)
		
		if school_id != "":
			# Update NPC's education.institution
			if not identity.has("education"):
				identity["education"] = {}
			identity.education["institution"] = school_id
			DB.update_npc(npc.id, {"identity": identity})
			
			# Create student membership
			var existing = DB.get_npc_memberships(npc.id)
			var already = false
			for mem in existing:
				if mem.get("org_id") == school_id:
					already = true
					break
			
			if not already:
				DB.create_membership(npc.id, school_id, "Student", 1, 0, 50, 50, 50)
			
			assigned_count += 1
	
	return assigned_count

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
		"computed_values": JSON.stringify({
			"category": "education",
			"subcategory": school_type,
			"district_id": district
		})
	}
	
	DB.create_organization(school_data)
	school_cache[cache_key] = school_id
	stats.organizations = stats.get("organizations", 0) + 1
	
	return school_id

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
		var memberships = DB.get_npc_memberships(npc.id)
		var has_religious_membership = false
		for membership in memberships:
			var org = DB.get_organization(membership.org_id)
			if org != null:
				var org_type = org.get("type", "")
				var org_cv = org.get("computed_values")
				var org_category = org_cv.get("category", "") if org_cv is Dictionary else ""
				if org_type == "religious" or org_category == "religious":
					has_religious_membership = true
					break
		
		if has_religious_membership:
			continue  # Already has religious org
		
		# Find or create appropriate religious org in district
		var org_id = _find_or_create_religious_org(district, religious_path, religious_orgs)
		
		if org_id != "":
			# Create membership record
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
		var cv = org.get("computed_values")
		if not (cv is Dictionary):
			cv = {}
		
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
	stats.organizations = stats.get("organizations", 0) + 1
	
	return org_id

# =============================================================================
# PASS 6: Fill Isolated NPCs
# =============================================================================

func _fill_isolated_npcs() -> int:
	# Ensure all NPCs have at least 3 relationships
	var count = 0
	
	# Find NPCs with fewer than 3 relationships
	var isolated = DB.get_isolated_npcs(3)
	
	if isolated.is_empty():
		return count
	
	# Build pool of NPCs by district for matching
	var npcs_by_district = {}
	var all_npcs = DB.get_all_npcs()
	for npc in all_npcs:
		var identity = npc.get("identity", {})
		var district = identity.get("district", "unknown") if identity is Dictionary else "unknown"
		if not npcs_by_district.has(district):
			npcs_by_district[district] = []
		npcs_by_district[district].append(npc.id)
	
	var existing_rels = DB.get_all_relationship_pairs()
	
	for iso in isolated:
		var needed = 3 - iso.rel_count
		if needed <= 0:
			continue
		
		var identity = iso.get("identity", {}) if iso.has("identity") else {}
		var district = identity.get("district", "unknown") if identity is Dictionary else "unknown"
		
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
			existing_rels[key] = true
			existing_rels["%s-%s" % [cand_id, iso.id]] = true
			count += 1
			created += 1
	
	return count

