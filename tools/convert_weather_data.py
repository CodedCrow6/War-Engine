import pandas as pd
import json
import sys

def convert_excel_to_json(input_file, output_file):
    try:
        # Load the Excel file
        print(f"Loading {input_file}...")
        df = pd.read_excel(input_file)

        # Clean column names (remove spaces/lowercase for consistency)
        df.columns = [col.strip().lower() for col in df.columns]

        # Ensure 'date' column is datetime
        df['date'] = pd.to_datetime(df['date'])

        # Initialize the nested dictionary structure
        # Structure: { "month": { "day": { data } } }
        weather_data = {}

        print("Processing records...")
        for index, row in df.iterrows():
            month = str(row['date'].month)
            day = str(row['date'].day)
            
            # If month doesn't exist, create it
            if month not in weather_data:
                weather_data[month] = {}
            
            # Prepare the data record
            # We only keep the metrics needed for the simulation
            record = {
                "tavg": float(row['tavg']) if pd.notna(row['tavg']) else 0.0,
                "tmin": float(row['tmin']) if pd.notna(row['tmin']) else 0.0,
                "tmax": float(row['tmax']) if pd.notna(row['tmax']) else 0.0,
                "prcp": float(row['prcp']) if pd.notna(row['prcp']) else 0.0,
                "wspd": float(row['wspd']) if pd.notna(row['wspd']) else 0.0,
                "pres": float(row['pres']) if pd.notna(row['pres']) else 1013.0
            }
            
            # Store by day
            weather_data[month][day] = record

        # Save to JSON
        with open(output_file, 'w') as f:
            json.dump(weather_data, f, indent=2)
        
        print(f"Successfully converted {len(df)} records to {output_file}")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    convert_excel_to_json(r"C:\Users\Raven\Documents\War-Engine_v0.4\tools\export.xlsx", r"C:\Users\Raven\Documents\War-Engine_v0.4\tools\weather_data.json")