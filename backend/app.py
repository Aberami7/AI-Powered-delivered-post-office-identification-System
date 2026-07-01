import os
import pandas as pd
import random
from flask import Flask, request, jsonify
from flask_cors import CORS
from google import genai

app = Flask(__name__)
CORS(app)

# --- AI Configuration (Using Environment Variable) ---
API_KEY = os.environ.get("GOOGLE_API_KEY")
client = genai.Client(api_key=API_KEY) if API_KEY else None
model_name = "gemini-2.0-flash"

# --- Smart Caching 
ai_cache = {}

# Dataset Loading
CSV_PATH = os.path.join("dataset", "post_offices.csv")
try:
    df = pd.read_csv(CSV_PATH, low_memory=False)
    # உங்கள் CSV காலம்களுக்கு ஏற்ப மாற்றி அமைக்கப்பட்டுள்ளது
    df.columns = ["CircleName", "RegionName", "DivisionName", "OfficeName", "Pincode", 
                  "OfficeType", "Delivery", "District", "StateName", "Latitude", "Longitude"]
    
    df["Pincode"] = df["Pincode"].astype(str).str.strip()
    df["Office_Lower"] = df["OfficeName"].astype(str).str.lower().str.strip()
    df["District_Lower"] = df["District"].astype(str).str.lower().str.strip()
    print(f"PostFinder AI Backend Ready! Loaded {len(df)} records.")
except Exception as e:
    print(f" Dataset Error: {e}")

# --- AI Insight Logic with Cache & Random Fallback ---
def get_smart_insight(o_name, o_type, dist, state):
    cache_key = f"{o_name}_{o_type}_{dist}"
    
  
    if cache_key in ai_cache:
        return ai_cache[cache_key]

  
    if client:
        try:
            prompt = f"Give a unique 10-word professional insight about {o_name} ({o_type}) post office in {dist}, {state}."
            response = client.models.generate_content(model=model_name, contents=prompt)
            if response.text:
                result = response.text.strip()
                ai_cache[cache_key] = result # சேமித்து வைத்துக்கொள்ளும்
                return result
        except Exception as e:
            print(f"⚠️ AI Quota Limit: Using Random Fallback.")


    fallbacks = [
        f"Critical {o_type} node in {dist} division for postal services.",
        f"A vital link for {o_name} residents, ensuring smooth delivery.",
        f"Key operational hub for {dist}, providing essential logistics.",
        f"Efficiently managed {o_type} facility handling regional mail.",
        f"Strategically located in {state} to boost local connectivity.",
        f"Dedicated {o_type} center focusing on community needs.",
        f"Ensuring reliable services and banking for {dist} region."
    ]
    return random.choice(fallbacks)

# --- 1. SEARCH ROUTE 
@app.route("/search", methods=["GET"])
def search():
    query = request.args.get("query", "").strip().lower()
    if not query: return jsonify({"postoffices": []})

    # Pincode
    if query.isdigit() and len(query) == 6:
        matches = df[df["Pincode"] == query]
    else:
  
        matches = df[df["Office_Lower"].str.contains(query, na=False)].head(20)

    results = []
    for _, row in matches.iterrows():
        o_name, o_type, dist, state = row['OfficeName'], row['OfficeType'], row['District'], row['StateName']
        results.append({
            "name": o_name,
            "pincode": row["Pincode"],
            "city": dist,
            "state": state,
            "type": str(o_type).upper(),
            "ai_insight": get_smart_insight(o_name, o_type, dist, state)
        })
    return jsonify({"postoffices": results})

# --- 2. NEARBY ROUTE ---
@app.route("/nearby", methods=["GET"])
def nearby():
    dist_query = request.args.get("district", "").strip().lower()
    if not dist_query: return jsonify({"offices": []})

    nearby_df = df[df["District_Lower"] == dist_query].head(8)
    offices = []
    for _, row in nearby_df.iterrows():
        o_name, o_type = row['OfficeName'], row['OfficeType']
        offices.append({
            "name": o_name,
            "pincode": row["Pincode"],
            "city": row["District"],
            "distance": f"{random.randint(1, 5)} km",
            "ai_analysis": get_smart_insight(o_name, o_type, row['District'], row['StateName']),
            "latitude": str(row["Latitude"]), "longitude": str(row["Longitude"])
        })
    return jsonify({"offices": offices})

# --- 3. CHATBOT ROUTE ---
@app.route("/chat", methods=["POST"])
def chat():
    msg = request.json.get("message", "")
    if client and msg:
        try:
            prompt = f"You are PostFinder AI. Briefly answer: {msg}"
            resp = client.models.generate_content(model=model_name, contents=prompt)
            return jsonify({"reply": resp.text.strip()})
        except:
            return jsonify({"reply": "AI is resting. How can I help you manually?"})
    return jsonify({"reply": "Hello! I am PostFinder AI. How can I assist you?"})

if __name__ == "__main__":
    # 0.0.0.0 என்பது லோக்கல் நெட்வொர்க்கில் மொபைல் கனெக்ட் செய்ய உதவும்
    app.run(host="0.0.0.0", port=5000, debug=True)
