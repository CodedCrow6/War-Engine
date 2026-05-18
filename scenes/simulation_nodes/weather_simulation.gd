extends Node

# --- Configuration ---
const WEATHER_DATA_PATH = "res://weather_data.json"

# --- State Variables ---
var weather_database: Dictionary = {}
var current_weather: Dictionary = {}
var last_updated_day: int = -1
var last_updated_month: int = -1

# --- Wind Randomization Settings ---
var wind_direction_degrees: float = 0.0

# --- References to Debug Panel Nodes ---
@onready var debug_panel = get_node_or_null("SimulationDebugPanel") # Adjust if this script is NOT on the root node
# If this script is attached to SimulationDebugPanel itself, use 'self' or remove the get_node
# Assuming this script is attached to the SimulationDebugPanel node based on previous instructions:
@onready var lbl_hours = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/TimeHbox/Hours
@onready var lbl_minutes = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/TimeHbox/Minutes
@onready var lbl_seconds = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/TimeHbox/Seconds
@onready var lbl_day = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/DateHbox/Day
@onready var lbl_month = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/DateHbox/Month
@onready var lbl_year = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/DateHbox/Year
@onready var lbl_time_scale = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/TimeScaleHbox/TimeScaleValue
@onready var lbl_season = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/SeasonHbox/SeasonValue
@onready var lbl_temp = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/TemperatureHbox/TemperatureValue
@onready var lbl_rain_chance = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/WeatherHbox/VBoxContainer/HBoxContainer/WeatherValue1
@onready var lbl_wind_dir = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/WeatherHbox/VBoxContainer/HBoxContainer2/WeatherValue2
@onready var lbl_wind_speed = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/WeatherHbox/VBoxContainer/HBoxContainer3/WeatherValue3

# Reference to the Singleton
var time_manager: Node

func _ready():
	# Get the TimeManager Singleton
	time_manager = get_node("/root/TimeManager")
	if not time_manager:
		push_error("TimeManager singleton not found! Ensure it is added in Project > Autoload.")
		return

	load_weather_data()
	
	# Initial update
	update_debug_panel()

func _process(delta):
	if not time_manager: return

	# Check if the date has changed since the last frame
	var current_month = time_manager.current_date["month"]
	var current_day = time_manager.current_date["day"]
	
	if current_month != last_updated_month or current_day != last_updated_day:
		sample_daily_weather(current_month, current_day)
		last_updated_month = current_month
		last_updated_day = current_day
	
	# Update UI every frame for time/seconds
	update_debug_panel()

func load_weather_data():
	var file = FileAccess.open(WEATHER_DATA_PATH, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		var json_result = JSON.parse_string(json_text)
		if json_result != null:
			weather_database = json_result
			print("Weather Database Loaded.")
		else:
			push_error("Failed to parse weather JSON.")
	else:
		push_error("Could not find weather_data.json at " + WEATHER_DATA_PATH)

func sample_daily_weather(month: int, day: int):
	var month_str = str(month)
	var day_str = str(day)
	
	var daily_data = {}
	if weather_database.has(month_str) and weather_database[month_str].has(day_str):
		daily_data = weather_database[month_str][day_str]
	else:
		# Fallback for missing data
		daily_data = {"tavg": 20.0, "prcp": 0.0, "wspd": 5.0, "pres": 1013.0}

	# 1. Temperature: Use tavg, but add slight hourly variation based on time of day
	var hour = time_manager.current_date["hour"]
	var temp_variation = sin((hour - 6) / 24.0 * 2 * PI) * 3.0 # Cooler at night, warmer mid-day
	current_weather["temperature"] = daily_data.get("tavg", 20.0) + temp_variation
	
	# 2. Rain Chance: Derived from precipitation amount (mm). 
	var prcp = daily_data.get("prcp", 0.0)
	current_weather["rain_chance"] = min(prcp * 10.0, 100.0) # Scale mm to % roughly
	
	# 3. Wind Speed: Direct from data
	current_weather["wind_speed"] = daily_data.get("wspd", 5.0)
	
	# 4. Wind Direction: RANDOMIZED as requested
	# We use a "random walk" so wind doesn't jump 180 degrees instantly
	var change = randf_range(-30.0, 30.0)
	wind_direction_degrees += change
	wind_direction_degrees = wrapf(wind_direction_degrees, 0.0, 360.0)
	current_weather["wind_dir_deg"] = wind_direction_degrees
	current_weather["wind_dir_cardinal"] = _degrees_to_cardinal(wind_direction_degrees)
	
	# 5. Pressure
	current_weather["pressure"] = daily_data.get("pres", 1013.0)

func _degrees_to_cardinal(degrees: float) -> String:
	var directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
	var index = int(round(degrees / 45.0)) % 8
	return directions[index]

func update_debug_panel():
	if not time_manager: return

	# Time
	lbl_hours.text = "%02d" % time_manager.current_date["hour"]
	lbl_minutes.text = "%02d" % time_manager.current_date["minute"]
	# Seconds are derived from accumulated_time in TimeManager
	var seconds = int(time_manager.accumulated_time)
	lbl_seconds.text = "%02d" % seconds

	# Date
	lbl_day.text = "%02d" % time_manager.current_date["day"]
	lbl_month.text = "%02d" % time_manager.current_date["month"]
	lbl_year.text = "%d" % time_manager.current_date["year"]

	# Time Scale
	var scale = time_manager.BASE_TIME_SCALE * time_manager.time_scale_multiplier
	lbl_time_scale.text = "%.1f" % scale

	# Season (Southern Hemisphere Approximation)
	var month = time_manager.current_date["month"]
	var season = ""
	if month >= 12 or month <= 2: season = "Summer"
	elif month >= 3 and month <= 5: season = "Autumn"
	elif month >= 6 and month <= 8: season = "Winter"
	else: season = "Spring"
	lbl_season.text = season

	# Weather Metrics
	lbl_temp.text = "%.1f" % current_weather.get("temperature", 0.0)
	lbl_rain_chance.text = "%.0f%%" % current_weather.get("rain_chance", 0.0)
	lbl_wind_dir.text = current_weather.get("wind_dir_cardinal", "N")
	lbl_wind_speed.text = "%.1f" % current_weather.get("wind_speed", 0.0)
