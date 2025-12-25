extends RefCounted
## Phase 8: Historical Events and Memories
## Generates historical events (births, marriages, hirings, relationship formations) with memories

var rng = RandomNumberGenerator.new()
var stats: Dictionary

var event_stats = {
	"birth": 0,
	"marriage": 0,
	"hiring": 0,
	"relationship": 0,
	"memories": 0
}

func _init(p_stats: Dictionary):
	stats = p_stats
	rng.randomize()

func generate_historical_events():
	"""Generate historical events for all NPCs."""
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
		elif npc.has("identity") and npc.identity is Dictionary:
			var identity = npc.identity
			var dist = identity.get("district", "")
			if dist != "" and valid_districts.has(dist):
				district_id = dist
		
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
			"details": JSON.stringify({"npc_id": npc.id, "birth_year": birth_year}),
			"impact": JSON.stringify({"severity": 50, "public_knowledge": 30, "emotional_weight": 90}),
			"consequences": JSON.stringify({}),
			"ripple_depth": 0,
			"affected_nodes": JSON.stringify([npc.id]),
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
			"details": JSON.stringify({"spouse1": marriage.source_npc_id, "spouse2": marriage.target_npc_id}),
			"impact": JSON.stringify({"severity": 60, "public_knowledge": 70, "emotional_weight": 95}),
			"consequences": JSON.stringify({}),
			"ripple_depth": 1,
			"affected_nodes": JSON.stringify([marriage.source_npc_id, marriage.target_npc_id]),
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
			"details": JSON.stringify({"npc_id": emp.npc_id, "org_id": emp.org_id, "role": emp.role}),
			"impact": JSON.stringify({"severity": 30, "public_knowledge": 20, "emotional_weight": 60}),
			"consequences": JSON.stringify({}),
			"ripple_depth": 0,
			"affected_nodes": JSON.stringify([emp.npc_id, emp.org_id]),
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
			"details": JSON.stringify({"npc1": rel.source_npc_id, "npc2": rel.target_npc_id, "context": context}),
			"impact": JSON.stringify({"severity": 20, "public_knowledge": 10, "emotional_weight": 40}),
			"consequences": JSON.stringify({}),
			"ripple_depth": 0,
			"affected_nodes": JSON.stringify([rel.source_npc_id, rel.target_npc_id]),
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

