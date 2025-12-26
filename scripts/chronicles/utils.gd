extends RefCounted
## Chronicles Utilities - Shared utility functions

## Format Unix timestamp to readable date string
static func format_timestamp(timestamp: int) -> String:
	var date = Time.get_datetime_dict_from_unix_time(timestamp)
	return "%04d-%02d-%02d %02d:%02d" % [date.year, date.month, date.day, date.hour, date.minute]

