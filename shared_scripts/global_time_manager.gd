extends Node

# --- Configuration ---
const SAVE_PATH = "user://time_save.json"
const DEFAULT_TIME_SCALE = 120.0 # 120s real * 30 = 3600s game = 1 hour.
const BASE_TIME_SCALE = 30.0

# --- State Variables ---
var current_date: Dictionary = {
	"year": 2024,
	"month": 1, # May
	"day": 1,
	"hour": 1,
	"minute": 1
}

var time_scale_multiplier: float = 1.0 # Allows dynamic adjustment from base
var accumulated_time: float = 0.0
var is_initialized: bool = false

# --- Weather Data Structure (Placeholder) ---
# In production, load this from a JSON file generated from your spreadsheet
var weather_database: Dictionary = {}

func _ready():
	load_state()
	if not is_initialized:
		initialize_new_game()
	
	# Load weather data (Mocked for now, see _load_weather_data)
	_load_weather_data()

func _process(delta: float):
	# Handle Input for Time Scale Adjustment (Dev Only)
	if Input.is_action_just_pressed("time_speed_up"):
		time_scale_multiplier = min(time_scale_multiplier * 1.5, 10.0)
		print("Time Scale Multiplier: ", time_scale_multiplier)
		
	if Input.is_action_just_pressed("time_speed_down"):
		time_scale_multiplier = max(time_scale_multiplier / 1.5, 0.1)
		print("Time Scale Multiplier: ", time_scale_multiplier)

	# Calculate effective delta
	var effective_delta = delta * BASE_TIME_SCALE * time_scale_multiplier
	
	# Advance time
	accumulated_time += effective_delta
	
	# Update clock logic
	while accumulated_time >= 60.0: # 60 game seconds passed
		accumulated_time -= 60.0
		advance_minute()

func advance_minute():
	current_date["minute"] += 1
	if current_date["minute"] >= 60:
		current_date["minute"] = 0
		advance_hour()

func advance_hour():
	current_date["hour"] += 1
	if current_date["hour"] >= 24:
		current_date["hour"] = 0
		advance_day()

func advance_day():
	current_date["day"] += 1
	var days_in_month = _get_days_in_month(current_date["month"], current_date["year"])
	
	if current_date["day"] > days_in_month:
		current_date["day"] = 1
		advance_month()

func advance_month():
	current_date["month"] += 1
	if current_date["month"] > 12:
		current_date["month"] = 1
		advance_year()

func advance_year():
	current_date["year"] += 1

func _get_days_in_month(month: int, year: int) -> int:
	var days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	# Leap year check
	if month == 2:
		if (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0):
			return 29
	return days[month - 1]

# --- Persistence ---

func save_state():
	var save_dict = {
		"date": current_date,
		"time_scale_multiplier": time_scale_multiplier,
		"accumulated_time": accumulated_time
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_dict))
		file.close()

func load_state():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var json_text = file.get_as_text()
			var json_result = JSON.parse_string(json_text)
			if json_result != null:
				current_date = json_result["date"]
				time_scale_multiplier = json_result.get("time_scale_multiplier", 1.0)
				accumulated_time = json_result.get("accumulated_time", 0.0)
				is_initialized = true
				file.close()
				return
	is_initialized = false

func initialize_new_game():
	# Set starting date if no save exists
	current_date = {
		"year": 2026,
		"month": 5,
		"day": 19,
		"hour": 12,
		"minute": 0
	}
	time_scale_multiplier = 1.0
	accumulated_time = 0.0
	is_initialized = true
	save_state() # Create initial save

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_state()
		get_tree().quit()

# --- Weather Simulation Logic ---

func _load_weather_data():
	# TODO: Replace this with actual loading from a JSON file derived from your spreadsheet
	# Example structure:
	# weather_database = {
	#   "5": { # May
	#     "19": { # Day 19
	#       "avg_temp_c": 15.0,
	#       "precipitation_chance": 0.1,
	#       "cloud_cover": 0.4
	#     }
	#   }
	# }
	print("Weather database loaded (Mock)")

func get_current_weather() -> Dictionary:
	# Sample weather based on current date
	var month_str = str(current_date["month"])
	var day_str = str(current_date["day"])
	
	# Fallback defaults if data missing
	var weather = {
		"temperature": 20.0,
		"is_raining": false,
		"cloudiness": 0.5
	}
	
	if weather_database.has(month_str) and weather_database[month_str].has(day_str):
		var daily_data = weather_database[month_str][day_str]
		weather["temperature"] = daily_data.get("avg_temp_c", 20.0)
		
		# Simple randomization based on chance
		if randf() < daily_data.get("precipitation_chance", 0.0):
			weather["is_raining"] = true
			
		weather["cloudiness"] = daily_data.get("cloud_cover", 0.5)
	else:
		# Procedural fallback if no data for specific day
		weather["temperature"] = _procedural_temp_estimate()
		
	return weather

func _procedural_temp_estimate() -> float:
	# Very basic seasonal approximation for Johannesburg (Southern Hemisphere)
	var month = current_date["month"]
	# Summer (Dec-Feb) ~ 25C, Winter (Jun-Aug) ~ 15C
	var base_temp = 20.0
	var offset = sin((month - 3) / 12.0 * 2 * PI) * 5.0 # Shifted for S. Hemisphere
	return base_temp + offset
