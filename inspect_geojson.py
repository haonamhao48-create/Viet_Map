import json
import os

file_path = r"c:\Users\haona\OneDrive\Desktop\Viet_Map\assets\geo\communes.geojson"

try:
    with open(file_path, 'r', encoding='utf-8') as f:
        # We don't want to load the whole 178MB if we can avoid it, 
        # but json.load is easiest if memory allows. 178MB is fine for python.
        data = json.load(f)
        
    print(f"Type: {data.get('type')}")
    features = data.get('features', [])
    print(f"Number of features: {len(features)}")
    
    if features:
        print("\nProperties of the first feature:")
        print(json.dumps(features[0].get('properties', {}), indent=2, ensure_ascii=False))
        
except Exception as e:
    print(f"Error: {e}")
