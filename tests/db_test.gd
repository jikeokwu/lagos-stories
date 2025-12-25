extends Node
## Simple database test - checks if tables are created

func _ready():
	print("\n=== DATABASE TEST ===\n")
	await get_tree().process_frame
	test()

func test():
	# Initialize
	print("1. Initializing database...")
	if not DB.initialize():
		print("❌ FAILED")
		get_tree().quit()
		return
	print("✅ DB initialized at: %s\n" % DB.db_path)
	
	# Check tables
	print("2. Checking for tables...")
	DB.db.query("SELECT name FROM sqlite_master WHERE type='table';")
	var tables = DB.db.query_result
	
	if typeof(tables) == TYPE_ARRAY and tables.size() > 0:
		print("✅ Found %d tables:" % tables.size())
		for t in tables:
			print("   - %s" % t["name"])
	else:
		print("❌ No tables found!")
		print("   Result type: %s" % typeof(tables))
		print("   Result value: %s" % str(tables))
	
	print("\n=== TEST COMPLETE ===\n")
	await get_tree().create_timer(0.5).timeout
	get_tree().quit()

