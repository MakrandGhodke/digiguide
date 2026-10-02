
import os
import faiss
import json
import numpy as np
from fastapi import FastAPI, UploadFile, File, HTTPException, Form, Depends
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel
import requests

from contextlib import asynccontextmanager
from PIL import Image, ImageOps 
import io
from utils import image_to_embedding
import uuid
import bcrypt
from jose import jwt
from datetime import datetime, timedelta

# Auth Models
class SignUpRequest(BaseModel):
    email: str
    password: str
    name: str = ""

class SignInRequest(BaseModel):
    email: str
    password: str

# JWT Config
SECRET_KEY = "digiguide-secret-key-2024"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_DAYS = 30

security = HTTPBearer()

# Global variables for index and metadata
index = None
metadata = {}

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
INDEX_FILE = os.path.join(BASE_DIR, "vector_store.index")
METADATA_FILE = os.path.join(BASE_DIR, "metadata.json")
DATASET_DIR = os.path.join(BASE_DIR, "dataset")
TEMP_DIR = os.path.join(DATASET_DIR, "temp_uploads")
os.makedirs(TEMP_DIR, exist_ok=True)
USER_DB_FILE = os.path.join(BASE_DIR, "users.json")

def init_user_db():
    """Initialize user database if it doesn't exist."""
    if not os.path.exists(USER_DB_FILE):
        with open(USER_DB_FILE, 'w') as f:
            json.dump({}, f)
        print("User database initialized.")
    else:
        print("User database loaded.")

def load_users():
    """Load users from JSON file."""
    if os.path.exists(USER_DB_FILE):
        with open(USER_DB_FILE, 'r') as f:
            return json.load(f)
    return {}

def save_users(users: dict):
    """Save users to JSON file."""
    with open(USER_DB_FILE, 'w') as f:
        json.dump(users, f, indent=2)

def create_access_token(data: dict):
    """Create JWT token."""
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(days=ACCESS_TOKEN_EXPIRE_DAYS)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def load_index_and_metadata():
    global index, metadata
    if os.path.exists(INDEX_FILE) and os.path.exists(METADATA_FILE):
        print(f"Loading index from {INDEX_FILE}...")
        try:
            index = faiss.read_index(INDEX_FILE)
            with open(METADATA_FILE, 'r') as f:
                temp_metadata = json.load(f)
                metadata = {int(k): v for k, v in temp_metadata.items()}
            print("Index and metadata loaded successfully.")
        except Exception as e:
            print(f"Error loading index: {e}")
    else:
        print("Index or metadata file not found. Please run build_index.py.")


# Knowledge Base for Landmark Details
LANDMARK_INFO = {
    "darmstadium": {
        "name": "Darmstadtium",
        "city": "Darmstadt",
        "country": "Germany",
        "category": "urban",
        "short_description": "Science & Congress Center",
        "long_description": "The Darmstadtium is a science and congress center in Darmstadt, Germany. Its name is derived from the chemical element darmstadtium, which was discovered in the city.",
        "history": "Opened in 2007, the Darmstadtium was built to serve as a hub for science and conferences in the 'City of Science'. It stands on the site of the former medieval city walls, parts of which are integrated into the modern architecture. The building was named after the chemical element Darmstadtium (Ds, atomic number 110), discovered at the nearby GSI Helmholtz Centre for Heavy Ion Research in 1994.",
        "facts": [
            "Named after the element Darmstadtium (110).",
            "Integrates genuine medieval city walls.",
            "Certified for sustainability.",
            "Total area of 18,000 square meters."
        ],
        "speech_text": "You are standing in front of the darmstadtium — a place where science becomes part of city life. Right here, in the center of Darmstadt, research, technology, and public dialogue come together. Darmstadt is known as a city of science and innovation, and this building reflects that identity. Its modern, transparent design stands for openness — knowledge that is meant to be shared. Inside the darmstadtium, science is not presented behind closed doors. Complex topics like technology, data, and sustainability are translated into experiences that invite curiosity and interaction. What makes this place special is its focus on people. It’s not only about scientific progress, but about how innovation affects society, everyday decisions, and the future we are shaping together. The darmstadtium encourages visitors to ask questions — about technology, responsibility, and the role science plays in our lives. As you move on, take this thought with you: science is not something distant or abstract. It is present in the cities we live in, the tools we use, and the choices we make every day.",
        "lat": 49.8732,
        "lon": 8.6558
    },
    "mathildenhöhe": {
        "name": "Mathildenhöhe",
        "city": "Darmstadt",
        "country": "Germany",
        "category": "history",
        "short_description": "Art Nouveau artists' colony",
        "long_description": "Mathildenhöhe represents a major center of Art Nouveau (Jugendstil) and was recognized as a UNESCO World Heritage Site in 2021.",
        "history": "Founded in 1899 by Grand Duke Ernst Ludwig, Mathildenhöhe was established as an artists' colony to promote modern art and design. Seven exhibitions were held between 1901 and 1914, leaving behind a unique architectural ensemble. It became a UNESCO World Heritage site in 2021, recognized as a pioneer of modernism.",
        "facts": [
            "UNESCO World Heritage Site since 2021.",
            "Home to the iconic Wedding Tower (Hochzeitsturm).",
            "Features the Russian Chapel with golden domes.",
            "Center of the Jugendstil (Art Nouveau) movement."
        ],
        "speech_text": "You are standing on the Mathildenhöhe — a place where art, architecture, and ideas come together. At the beginning of the 20th century, this hill became an experimental space for a bold vision: shaping life through design. Mathildenhöhe is the heart of Jugendstil in Darmstadt. Artists and architects worked here not just to create buildings, but to rethink how people live, work, and experience beauty in everyday life. Look around. The forms, colors, and details are expressive and intentional. Nothing here is purely decorative — everything carries meaning. The famous Wedding Tower rises as a symbol of this movement. It represents a belief that creativity and craftsmanship can shape society. Mathildenhöhe was never meant to be a museum alone. It was a living laboratory for new ideas — where art, function, and innovation merged. As you continue your walk, remember this place as more than a historic site. It is a reminder that cities are shaped not only by technology and power, but by imagination, vision, and the courage to think differently.",
        "lat": 49.8775,
        "lon": 8.6675
    },
    "orangerie_park": {
        "name": "Orangerie Park",
        "city": "Darmstadt",
        "country": "Germany",
        "category": "nature",
        "short_description": "Baroque park in Bessungen",
        "long_description": "The Orangerie in Darmstadt is a baroque building designed by architect Louis Remy de la Fosse. It is surrounded by a beautiful park.",
        "history": "Built between 1719 and 1721 by architect Louis Remy de la Fosse for Landgrave Ernst Ludwig. Originally designed to house exotic citrus plants during winter, it later served as a summer residence. The surrounding park was laid out in the French Baroque style and remains a popular recreational area for locals.",
        "facts": [
            "Designed by Louis Remy de la Fosse.",
            "Originally a shelter for orange trees.",
            "Located in the Bessungen district.",
            "Popular for summer picnics and concerts."
        ],
        "speech_text": "You are now in the Orangerie — one of Darmstadt’s most peaceful and historic green spaces. Originally created as a Baroque garden, this park was designed to bring order, symmetry, and calm into everyday life. The long pathways, open lawns, and carefully arranged trees reflect an idea of harmony between nature and design. Nothing here is purely decorative — every line and axis was planned to guide the eye and slow the pace. At the center stands the Orangerie building, once used to protect citrus trees during the winter months. Today, it remains a quiet reminder of how architecture and nature were meant to work together. Over time, the Orangerie has changed from a private court garden into a public space for everyone. What was once reserved for royalty is now part of daily life — a place to walk, pause, and breathe. As you continue through the park, notice the contrast to the city beyond its edges. The Orangerie offers not spectacle, but balance — a space designed for reflection, movement, and calm.",
        "lat": 49.8596,
        "lon": 8.6565
    },
    "schloss": {
        "name": "Residenzschloss Darmstadt",
        "city": "Darmstadt",
        "country": "Germany",
        "category": "history",
        "short_description": "Former residence of Landgraves",
        "long_description": "The Residential Palace Darmstadt is located in the center of the city. It was the residence of the Landgraves and Grand Dukes of Hesse-Darmstadt.",
        "history": "The castle's origins date back to the 13th century as a moated castle. It was transformed into a Renaissance residence in the 16th century and later expanded with Baroque elements. It served as the seat of government for the Landgraves and Grand Dukes of Hesse-Darmstadt for centuries until 1918.",
        "facts": [
            "Served as a residence for over 400 years.",
            "Houses the Technical University of Darmstadt library.",
            "Combines Renaissance and Baroque architecture.",
            "Partially destroyed in WWII and rebuilt."
        ],
        "speech_text": "You are standing in front of the Darmstadt Schloss , a Schloss is a palace  and this one stands at the historic heart of the city For centuries, this Schloss was the seat of power for the rulers of Hesse and played a central role in shaping Darmstadt’s identity. The complex you see today reflects many layers of history. Medieval foundations combine with Renaissance and Baroque elements, revealing how the city evolved over time. Once, this Schloss was a place of residence, ceremony, and decision-making. Behind these walls, political power was exercised and court life followed strict traditions and rituals. Today, the Schloss serves a very different purpose. It is no longer an exclusive residence, but part of a living city — connected to education, culture, and public life. As you walk through the courtyard, notice how historical architecture and modern life exist side by side. The Darmstadt Schloss shows how cities move forward by giving their past a new role in the present.",
        "lat": 49.8728,
        "lon": 8.6552
    },
    "waldspirale": {
        "name": "Waldspirale",
        "city": "Darmstadt",
        "country": "Germany",
        "category": "urban",
        "short_description": "Hundertwasser residential complex",
        "long_description": "The Waldspirale is a residential building complex in Darmstadt, designed by Austrian artist Friedensreich Hundertwasser. It features a unique spiral forest roof.",
        "history": "Completed in 2000, the Waldspirale ('Forest Spiral') was the final architectural design by Friedensreich Hundertwasser before his death. The building rejects straight lines and right angles, featuring over 1,000 unique windows and a green roof that spirals up to 12 stories high, allowing residents to walk upon it.",
        "facts": [
            "Has 105 apartments and no two windows are alike.",
            "Roof is planted with grass and trees.",
            "Missing straight lines and sharp corners.",
            "Design promotes harmony with nature."
        ],
        "speech_text": "You are standing in front of the Waldspirale — one of Darmstadt’s most unusual buildings. Designed by the artist and architect Friedensreich Hundertwasser, this structure breaks almost every traditional rule of architecture. Look closely. There are no straight lines, no identical windows, and no sharp edges. Instead, the building curves, rises, and twists — more like a landscape than a house. The Waldspirale was created as a statement against uniform city design. Hundertwasser believed that people should live in spaces that feel natural, individual, and alive. Trees grow from balconies, grass covers parts of the roof, and colors change across the façade. Here, architecture blends with nature instead of standing apart from it. Although it looks playful and almost dreamlike, the Waldspirale carries a serious idea: cities should serve human creativity and well-being, not just efficiency. As you continue your walk, remember this place as a reminder that cities don’t have to look the same. The Waldspirale shows how imagination can turn everyday living into something expressive and deeply personal.",
        "lat": 49.8863,
        "lon": 8.6554
    },
    "Hessisches-Landesmuseum": {
        "name": "Hessisches Landesmuseum",
        "city": "Darmstadt",
        "country": "Germany",
        "category": "history",
        "short_description": "Universal museum in Darmstadt",
        "long_description": "The Hessisches Landesmuseum Darmstadt is a large multidisciplinary museum. It houses an extensive collection of art, cultural history, and natural history.",
        "history": "Founded in 1820 by Grand Duke Ludewig I, the museum is one of the oldest public museums in Germany. The current building was designed by Alfred Messel and opened in 1906. It combines collections of art, culture, and natural history under one roof.",
        "facts": [
            "One of the few remaining universal museums.",
            "Features a large mastodon skeleton.",
            "Houses the world's largest Beuys block.",
            "Located next to the Herrngarten."
        ],
        "speech_text": "Welcome to the Hessisches Landesmuseum Darmstadt. Take a slow breath. In front of you rises a grand sandstone building, dignified and steady, as if it has always belonged here in the heart of Darmstadt. The air feels calm. Perhaps you hear the muted rhythm of footsteps on stone, the soft echo beneath high ceilings. There’s a quiet confidence in this place — not loud, not dramatic — but deeply rooted. The museum opened in 1906, shaped by the vision of Grand Duke Ernst Ludwig. He imagined something unusual for his time: a house where art and science would stand side by side, equals in telling the human story. And that idea still defines what you see here today. Walk with me inside. On one level, prehistoric fossils from the Messel Pit — creatures that lived 47 million years ago, preserved in astonishing detail. Their delicate bones whisper of swamps and subtropical forests long vanished. Just a few rooms away, medieval altarpieces glow softly, painted with devotion and symbolism. Then, suddenly, the 20th century confronts you in the “Block Beuys,” an entire installation arranged exactly as Joseph Beuys intended — raw, intellectual, quietly provocative. This building has endured its own trials. During World War II, parts of it were damaged. Yet it was restored, rebuilt, and reopened — carrying memory in its very structure. Take a moment and look around… Everything here exists on a timeline far greater than any one life. Fossils older than humanity. Paintings centuries old. Ideas still unfolding. And here you are — standing in the middle of it all. Before you move on, pause. Notice how time feels different inside these walls. Slower. Deeper. This museum doesn’t just display history. It lets you stand inside it.",
        "lat": 49.8745,
        "lon": 8.6548
    },
    "Luisenplatz": {
        "name": "Luisenplatz",
        "city": "Darmstadt",
        "country": "Germany",
        "category": "urban",
        "short_description": "Central square of Darmstadt",
        "long_description": "Luisenplatz is the central square of Darmstadt and the hub of public transport. In its center stands the Ludwigsmonument, locally known as 'Langer Ludwig'.",
        "history": "Laid out in 1820, the square was named after Grand Duchess Luise. The prominent Ludwigsmonument was erected in 1844 to honor Grand Duke Ludewig I, the first Grand Duke of Hesse. It survived the destruction of WWII largely intact and remains the city's main meeting point.",
        "facts": [
            "Features the 39-meter tall 'Langer Ludwig'.",
            "Main hub for trams and buses.",
            "Named after Grand Duchess Luise.",
            "Traditional center of the city."
        ],
        "speech_text": "Pause right where you are. There’s movement all around you, isn’t there? The rhythmic arrival of trams. The soft electronic chime before the doors close. Conversations blending into the hum of traffic. Luisenplatz doesn’t whisper — it pulses. This is the beating heart of Darmstadt. At the center rises the “Langer Ludwig,” the tall column crowned with the statue of Grand Duke Ludwig I. Look up at him. Elevated. Watching. The monument was erected in 1844, not just as decoration, but as a symbol of civic pride. In the 19th century, this square represented progress — a growing city stepping confidently into modernity. But history here hasn’t been gentle. During World War II, large parts of Darmstadt were destroyed. The square you see today is not the one that stood centuries ago. It was rebuilt. Reimagined. Modern buildings replaced older facades. What once reflected royal ambition now reflects post-war resilience and contemporary life. Take a moment and slowly turn in a circle… You’ll notice something fascinating: everything connects here. Streets branch outward like arteries. Shops, cafés, offices, public transport — they all converge at this point. If Herrngarten is the city’s lungs, Luisenplatz is its heartbeat. And here you are, standing in the flow. Every tram that passes carries stories. Students heading to lectures. Workers returning home. Visitors discovering the city for the first time. The square doesn’t hold silence — it holds momentum. Before you move on, look up once more at the Langer Ludwig. He has watched this square transform from royal monument to wartime ruin to vibrant crossroads. Cities change. Buildings rise and fall. But places like this — where paths cross and life unfolds — remain the center of it all.",
        "lat": 49.8724,
        "lon": 8.6511
    },
    "Staatstheater": {
        "name": "Staatstheater Darmstadt",
        "city": "Darmstadt",
        "country": "Germany",
        "category": "urban",
        "short_description": "State theatre for opera and drama",
        "long_description": " The Staatstheater Darmstadt is a four-division theatre offering opera, dance, concerts, and drama. The current building is a prominent example of post-war architecture.",
        "history": "The history of theatre in Darmstadt dates back to the 17th century at the Residenzschloss. After the old theatre burned down in WWII, the current building on Georg-Büchner-Platz was opened in 1972, designed by architect Rolf Prange.",
        "facts": [
            "Opened in 1972.",
            "Features opera, drama, ballet, and concerts.",
            "Located on Georg-Büchner-Platz.",
            "Architectural landmark of the 1970s."
        ],
        "speech_text": "Let’s begin with a sound. Not traffic. Not footsteps. But the low murmur of an audience settling into red velvet seats. The faint tuning of an orchestra. A single violin testing a note. The lights dim… and suddenly, everything holds its breath. Welcome to the Staatstheater Darmstadt. Even if you’re listening from home, picture the building’s bold modern façade rising against the sky. It doesn’t look like an old opera house with golden balconies. This theatre was rebuilt in the 1970s after the original structure was destroyed during World War II. What you see today is a statement of renewal — clean lines, open design, a cultural heartbeat reborn. The original court theatre once served nobility. Performances were formal, exclusive. But like much of Darmstadt, destruction during the war forced reinvention. Instead of recreating the past exactly as it was, the city chose something forward-looking. Modern. Confident. Inside, three stages host opera, drama, ballet, and concerts. Thousands of stories have unfolded here — tragic heroes, rebellious lovers, political satire, experimental productions that challenge the audience. Take a moment and imagine sitting in the darkened hall… The curtain rises. A spotlight cuts through shadow. A human voice fills the space without a microphone. Theatre is one of the oldest art forms — live, fragile, unrepeatable. No two performances are ever the same. That’s what makes this place powerful. It’s not just a building. It’s a container for emotion. For risk. For imagination. And even now, whether you’re standing outside its doors or listening miles away, you’re part of that tradition — because theatre begins the moment someone listens. Before we end, pause. Imagine the applause swelling, echoing, rising to the ceiling. Then silence again. A stage empty — waiting for the next story.",
        "lat": 49.8688,
        "lon": 8.6516
    },
    "herrengarten": {
        "name": "Herrngarten",
        "city": "Darmstadt",
        "country": "Germany",
        "category": "nature",
        "short_description": "Oldest and largest park in Darmstadt",
        "long_description": "The Herrngarten is the largest and oldest park in Darmstadt, located just north of the city center. It is a popular recreational area for students and families.",
        "history": "Created in the 16th century, the Herrngarten began as three smaller gardens which were merged in 1766 by Landgravine Karoline. It was transformed into an English landscape garden in the early 19th century and has been open to the public ever since.",
        "facts": [
            "Darmstadt's largest inner-city park.",
            "Originally a kitchen garden for the castle.",
            "Transformed into an English garden in 1811.",
            "Popular meeting spot for university students."
        ],
        "speech_text": "Listen closely. Do you hear the wind moving gently through the trees? The faint laughter in the distance? Maybe the soft crunch of gravel under your shoes. The Herrngarten doesn’t greet you with grandeur — it welcomes you with space. With air. With room to breathe. This is Darmstadt’s oldest public park, opened in the 18th century. But it didn’t begin as a public space. Once, it was reserved for nobility — a formal garden designed for quiet promenades and aristocratic conversations. Picture powdered wigs, long coats, and careful etiquette beneath these very trees. Then time shifted. The walls came down. The park opened. And what was once exclusive became communal. That transformation — from privilege to public — is part of its quiet revolution. Walk a little further in your mind. The layout feels natural now, almost effortless, but it was intentionally designed in the English landscape style — curving paths, open meadows, clusters of trees placed as if by chance. Even the informality was carefully crafted. During warmer months, students from nearby universities spread out on the grass. Families picnic. Musicians practice beneath the trees. The park becomes a living room for the city. Take a moment and look around… Some of these trees have stood here for centuries. They’ve seen empires rise and fall, wars pass through, generations grow up beneath their branches. And yet today, the Herrngarten feels light. Unburdened. Alive. There’s something powerful about a space that simply allows people to exist — without tickets, without walls, without expectation. Before you leave, pause. Feel the openness. In a world that often moves too fast, the Herrngarten offers something rare — permission to slow down.",
        "lat": 49.8760,
        "lon": 8.6530
    },
    "prinz-emil-garten": {
        "name": "Prinz-Emil-Garten",
        "city": "Darmstadt",
        "country": "Germany",
        "category": "nature",
        "short_description": "Historic garden in Bessungen",
        "long_description": "The Prinz-Emil-Garten is a public park in the Bessungen district. It features a small palace, the Prinz-Emil-Schlösschen, and a beautiful pond.",
        "history": "The garden was laid out in the 1770s by Friedrich Karl von Moser. In 1830, it was acquired by Prince Emil of Hesse, who gave it its current name. The park is designed in the style of an English landscape garden and features a charming teahouse-style palace.",
        "facts": [
            "Located in the district of Bessungen.",
            "Features the Prinz-Emil-Schlösschen.",
            "Designed as an English landscape garden.",
            "Includes a pond and historic trees."
        ],
        "speech_text": "Close your eyes for a second. Imagine stepping through a quiet entrance and leaving the city noise behind. The air feels softer here. You can almost hear the gentle ripple of water in the pond… the rustle of leaves… maybe even birds tracing circles overhead. Prinz-Emil-Garten doesn’t rush to impress you. It reveals itself slowly. This garden was created in the 18th century, originally designed as a refined pleasure garden for Prince Emil of Hesse. Back then, it was a private retreat — symmetrical paths, carefully shaped greenery, a small pavilion placed with intention. It wasn’t meant for crowds. It was meant for reflection. Picture elegant coats brushing against trimmed hedges. Conversations about philosophy and politics drifting across still water. Gardens in that era weren’t just decoration — they were statements of order and harmony, a human attempt to shape nature into balance. But time reshaped it too. Wars passed. Ownership changed. And eventually, the garden opened to the public. What was once exclusive became shared. Today, locals walk dogs here, students sit by the pond, couples talk quietly on benches. Take a moment and imagine standing beside the water… Notice how the pavilion reflects on the surface. That mirror-like stillness feels almost symbolic. This garden has always been about reflection — literal and emotional. Even if you’re listening from home, let this place slow you down. Prinz-Emil-Garten isn’t grand like a palace park. It’s intimate. Thoughtful. A small, balanced world inside a larger city. Before this audio ends, pause wherever you are. Take one calm breath. Because sometimes the most powerful spaces are not the loudest ones — but the ones that gently invite you inward.",
        "lat": 49.8580,
        "lon": 8.6480
    },
    "jugendstilbad": {
        "name": "Jugendstilbad",
        "city": "Darmstadt",
        "country": "Germany",
        "category": "history",
        "short_description": "Historic Art Nouveau swimming complex",
        "long_description": "The Jugendstilbad Darmstadt is a historic Art Nouveau swimming and wellness complex built between 1907 and 1909, reflecting the city’s rich Jugendstil heritage. Over the years, the complex has been carefully restored and modernized to preserve its historic character while introducing contemporary wellness facilities.",
        "history": "The Jugendstilbad Darmstadt was built between 1907 and 1909 during a period when Darmstadt was an important center of the Jugendstil (Art Nouveau) movement. The city aimed to combine art, architecture, and everyday life, and the bath was designed as a modern public facility that reflected these ideals. In the early 2000s, it underwent major renovation and modernization, carefully preserving original Art Nouveau elements.",
        "facts": [
            "Built between 1907 and 1909.",
            "Designed in the Jugendstil (Art Nouveau) style.",
            "Recognized as a protected cultural monument.",
            "Modern wellness and spa complex.",
            "Combines historic architecture with modern facilities."
        ],
        "speech_text": "Take a moment and look around… Notice the elegant curves, the soft light reflecting on the water, and the quiet echo that fills the halls. Even today, the atmosphere feels calm and timeless, as if the building itself invites you to slow down and breathe a little deeper. You are standing inside the Jugendstilbad Darmstadt, a place where architecture, art, and everyday life have been connected for more than a century. Built between 1907 and 1909, the bath was created during a time when Darmstadt was one of the centers of the Jugendstil, or Art Nouveau, movement. Back then, public baths were more than just places to swim — they were symbols of modern living and public wellbeing. The designers wanted to bring beauty into daily routines, and you can still see that idea today in the flowing lines, decorative details, and harmonious proportions surrounding you. What makes this place special is how it tells a story through design. The building was not only a technical achievement of its time but also a social space where people from different backgrounds came together. Look closely, and you’ll notice how art and function blend seamlessly — a hallmark of Jugendstil philosophy. Over the decades, the bath remained a beloved landmark, even as the city around it changed. After careful restoration, the Jugendstilbad reopened as a modern wellness destination, preserving its historic charm while adding contemporary spa and relaxation areas. The result is a rare balance between past and present, where history feels alive rather than frozen. Before you move on, pause for a moment. Listen to the quiet, observe the details, and imagine the generations who have stood here before you. Perhaps you’ll see this place not just as a bath, but as a living piece of Darmstadt’s story.",
        "lat": 49.8727,
        "lon": 8.6601
    },
    "unknown": {
        "name": "Unknown Landmark",
        "city": "Unknown",
        "country": "Unknown",
        "category": "none",
        "short_description": "Could not recognize",
        "long_description": "The AI could not identify this landmark with high confidence. Please try again from a different angle.",
        "history": "No history available for this unrecognized location.",
        "facts": [],
        "lat": 0.0,
        "lon": 0.0
    }
}


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Load FAISS index and initialize User DB quickly (< 1 sec)
    try:
        load_index_and_metadata()
        init_user_db()
        print("Application initialized successfully.")
    except Exception as e:
        print(f"Warning during initialization: {e}")
    yield
    # Clean up (none needed yet)

app = FastAPI(lifespan=lifespan)

# CORS
from fastapi.middleware.cors import CORSMiddleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Serve static files (uploaded images)
app.mount("/static", StaticFiles(directory=DATASET_DIR), name="static")

# ---------------------------------------------------------
# AUTH ENDPOINTS
# ---------------------------------------------------------
@app.post("/auth/signup")
def signup(request: SignUpRequest):
    """Register a new user."""
    users = load_users()
    if request.email in users:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    # Hash password
    hashed = bcrypt.hashpw(request.password.encode('utf-8'), bcrypt.gensalt())
    
    users[request.email] = {
        "name": request.name,
        "password_hash": hashed.decode('utf-8'),
        "created_at": datetime.utcnow().isoformat()
    }
    save_users(users)
    
    # Generate token
    token = create_access_token({"sub": request.email})
    return {
        "access_token": token,
        "token_type": "bearer",
        "user": {
            "email": request.email,
            "name": request.name
        }
    }


@app.post("/auth/signin")
def signin(request: SignInRequest):
    """Sign in an existing user."""
    users = load_users()
    if request.email not in users:
        raise HTTPException(status_code=401, detail="Invalid email or password")
    
    user = users[request.email]
    # Support both password_hash and legacy password field
    stored_hash = user.get("password_hash") or user.get("password")
    if not stored_hash or not bcrypt.checkpw(request.password.encode('utf-8'), stored_hash.encode('utf-8')):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    
    token = create_access_token({"sub": request.email})
    return {
        "access_token": token,
        "token_type": "bearer",
        "user": {
            "email": request.email,
            "name": user.get("name", "")
        }
    }


@app.get("/auth/me")
def get_me(token: HTTPAuthorizationCredentials = Depends(security)):
    """Get current user details from JWT token."""
    try:
        payload = jwt.decode(token.credentials, SECRET_KEY, algorithms=[ALGORITHM])
        email = payload.get("sub")
        users = load_users()
        user = users.get(email)
        if user:
            return {"email": email, "name": user.get("name", "")}
    except Exception:
        pass
    raise HTTPException(status_code=401, detail="Invalid or expired token")


# ---------------------------------------------------------
# WEATHER ENDPOINT (Open-Meteo API)
# ---------------------------------------------------------
@app.get("/weather")
def get_weather(lat: float, lon: float):
    """Returns weather information and visit recommendations using Open-Meteo API."""
    try:
        url = f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&current=temperature_2m,relative_humidity_2m,weather_code&timezone=auto"
        response = requests.get(url, timeout=5)
        data = response.json()
        
        current = data.get("current", {})
        temp = int(current.get("temperature_2m", 0))
        humidity = int(current.get("relative_humidity_2m", 0))
        weather_code = current.get("weather_code", 0)
        
        weather_map = {
            0: ("Clear", "☀️"),
            1: ("Mainly Clear", "🌤️"),
            2: ("Partly Cloudy", "⛅"),
            3: ("Overcast", "☁️"),
            45: ("Foggy", "🌫️"),
            48: ("Foggy", "🌫️"),
            51: ("Light Drizzle", "🌧️"),
            53: ("Drizzle", "🌧️"),
            55: ("Dense Drizzle", "🌧️"),
            61: ("Light Rain", "🌧️"),
            63: ("Rain", "🌧️"),
            65: ("Heavy Rain", "🌧️"),
            71: ("Light Snow", "🌨️"),
            73: ("Snow", "🌨️"),
            75: ("Heavy Snow", "🌨️"),
            80: ("Rain Showers", "🌦️"),
            81: ("Rain Showers", "🌦️"),
            82: ("Heavy Showers", "🌧️"),
            95: ("Thunderstorm", "⛈️"),
        }
        
        condition, icon = weather_map.get(weather_code, ("Unknown", "🌡️"))
        
        if weather_code in [0, 1]:
            recommendation = "Perfect weather for outdoor sightseeing! Don't forget sunscreen."
            best_time = "Morning (9-11 AM) or Late Afternoon (4-6 PM)"
            rating = "Excellent"
        elif weather_code in [2]:
            recommendation = "Great conditions for exploring. Enjoy the pleasant weather!"
            best_time = "Any time during daylight hours"
            rating = "Very Good"
        elif weather_code in [3, 45, 48]:
            recommendation = "Good for visiting. Overcast skies provide natural shade."
            best_time = "Midday is fine - no harsh sun"
            rating = "Good"
        elif weather_code in [51, 53, 55, 61, 63, 80, 81]:
            recommendation = "Light rain expected. Bring an umbrella for outdoor sites."
            best_time = "Check for rain breaks or visit covered areas"
            rating = "Fair"
        elif weather_code in [65, 82, 95]:
            recommendation = "Heavy weather expected. Consider indoor attractions today."
            best_time = "Wait for better conditions or visit museums"
            rating = "Poor"
        elif weather_code in [71, 73, 75]:
            recommendation = "Snowy conditions. Bundle up if visiting outdoor landmarks!"
            best_time = "Midday when it's warmest"
            rating = "Moderate"
        else:
            recommendation = "Check local conditions before your visit."
            best_time = "Flexible"
            rating = "Moderate"
        
        return {
            "temperature": temp,
            "condition": condition,
            "icon": icon,
            "humidity": humidity,
            "recommendation": recommendation,
            "bestTime": best_time,
            "rating": rating
        }
        
    except Exception as e:
        print(f"Weather API error: {e}")
        return {
            "temperature": 15,
            "condition": "Unknown",
            "icon": "🌡️",
            "humidity": 50,
            "recommendation": "Weather data unavailable. Check local forecasts.",
            "bestTime": "Flexible",
            "rating": "Unknown"
        }


# ---------------------------------------------------------
# LANDMARKS & DISCOVERY ENDPOINTS
# ---------------------------------------------------------
@app.get("/landmarks")
def get_landmarks():
    """Returns a list of all known landmarks for the search bar and explore screen."""
    results = []
    for key, info in LANDMARK_INFO.items():
        if key == "unknown":
            continue
        
        # Find first existing image asset for this landmark from metadata
        img_asset = ""
        for m_id, m_data in metadata.items():
            if m_data['landmark_name'] == key:
                full_path = os.path.join(DATASET_DIR, key, m_data['filename'])
                if os.path.exists(full_path):
                    img_asset = f"{key}/{m_data['filename']}"
                    break
        
        results.append({
            "id": key,
            "name": info['name'],
            "shortDescription": info['short_description'],
            "longDescription": info['long_description'],
            "history": info.get('history', 'No history available.'),
            "facts": info.get('facts', []),
            "speechText": info.get('speech_text', ''),
            "lat": info['lat'],
            "lng": info['lon'],
            "imageAsset": img_asset,
            "matchType": "list",
            "distance": 0.0,
            "score": 1.0,
            "city": info.get('city', 'Unknown City'),
            "country": info.get('country', 'Unknown Country'),
            "category": info.get('category', 'none')
        })
    return {"landmarks": results}


@app.post("/nearby")
def get_nearby_landmarks(
    latitude: float = Form(...),
    longitude: float = Form(...)
):
    """Returns sorted list of nearby landmarks for Explore tab."""
    from math import radians, cos, sin, asin, sqrt
    def haversine(lon1, lat1, lon2, lat2):
        lon1, lat1, lon2, lat2 = map(radians, [lon1, lat1, lon2, lat2])
        dlon = lon2 - lon1 
        dlat = lat2 - lat1 
        a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
        c = 2 * asin(sqrt(a)) 
        r = 6371 
        return c * r

    results = []
    for key, info in LANDMARK_INFO.items():
        if key == "unknown":
            continue
        
        l_lat = info.get('lat')
        l_lon = info.get('lon')
        if not l_lat or not l_lon:
            continue
            
        dist = haversine(longitude, latitude, l_lon, l_lat)
        
        # Find first existing image asset
        img_asset = ""
        for m_id, m_data in metadata.items():
            if m_data['landmark_name'] == key:
                full_path = os.path.join(DATASET_DIR, key, m_data['filename'])
                if os.path.exists(full_path):
                    img_asset = f"{key}/{m_data['filename']}"
                    break
        
        results.append({
            "id": key,
            "name": info['name'],
            "shortDescription": info['short_description'],
            "longDescription": info['long_description'],
            "history": info.get('history', 'No history available.'),
            "facts": info.get('facts', []),
            "speechText": info.get('speech_text', ''),
            "lat": l_lat,
            "lng": l_lon,
            "imageAsset": img_asset,
            "matchType": "list",
            "distance": round(dist, 2),
            "score": 1.0,
            "city": info.get('city', 'Unknown City'),
            "country": info.get('country', 'Unknown Country'),
            "category": info.get('category', 'none')
        })
    
    # Sort by distance
    results.sort(key=lambda x: x['distance'])
    return {"landmarks": results}


# ---------------------------------------------------------
# AI PREDICTION ENDPOINT
# ---------------------------------------------------------
@app.post("/predict")
async def predict_endpoint(
    file: UploadFile = File(...),
    latitude: float = Form(None),
    longitude: float = Form(None)
):
    if index is None or not metadata:
        raise HTTPException(status_code=500, detail="Server not ready: Index not loaded.")

    try:
        print(f"DEBUG: Received request with lat={latitude}, lon={longitude}")
        
        # 1. Save Input Image (for feedback & diagnostics)
        contents = await file.read()
        image_id = str(uuid.uuid4())
        temp_path = os.path.join(TEMP_DIR, f"{image_id}.jpg")
        with open(temp_path, "wb") as f:
            f.write(contents)
        print(f"Saved temp image: {temp_path}")

        # 2. Process Image with EXIF orientation correction
        image = Image.open(io.BytesIO(contents)).convert("RGB")
        image = ImageOps.exif_transpose(image)
        
        # 3. Visual Search with Multi-Rotation Robustness
        VISUAL_THRESHOLD = 0.85
        k = 5 
        rotations = [0, 90, 180, 270] 
        best_overall_match_info = None
        max_similarity = -1.0          

        for angle in rotations:
            current_img = image if angle == 0 else image.rotate(angle, expand=True)
            query_emb = image_to_embedding(current_img).astype('float32')
            
            distances, indices = index.search(query_emb, k)
            idx = int(indices[0][0])
            l2_distance = float(distances[0][0])
            
            # Convert L2 Distance to Cosine Similarity: S = 1 - d^2 / 2
            similarity = max(0.0, 1.0 - (l2_distance ** 2) / 2.0)
            print(f"DEBUG: Rotation {angle}°: index={idx}, dist={l2_distance:.4f} -> similarity={similarity:.4f}")

            if similarity >= VISUAL_THRESHOLD and idx in metadata:
                if similarity > max_similarity:
                    max_similarity = similarity
                    best_overall_match_info = (idx, similarity, angle, current_img)

        # Distance helper
        from math import radians, cos, sin, asin, sqrt
        def haversine(lon1, lat1, lon2, lat2):
            lon1, lat1, lon2, lat2 = map(radians, [lon1, lat1, lon2, lat2])
            dlon = lon2 - lon1 
            dlat = lat2 - lat1 
            a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
            c = 2 * asin(sqrt(a)) 
            r = 6371 
            return c * r

        # PRIORITY 1: VISUAL MATCH
        if best_overall_match_info:
            idx, similarity, angle, matched_img = best_overall_match_info
            match = metadata[idx]
            key = match['landmark_name']
            info = LANDMARK_INFO.get(key, LANDMARK_INFO["unknown"])
            
            print(f"DEBUG: Returning VISUAL match: {key} (Similarity: {similarity:.4f}, Angle: {angle}°)")

            if angle != 0:
                print(f"DEBUG: Overwriting temp image with {angle}° rotated version.")
                matched_img.save(temp_path)

            dist = 0.0
            if latitude and longitude and info.get('lat') and info.get('lon'):
                dist = haversine(longitude, latitude, info['lon'], info['lat'])
            
            # Verify matched image exists on disk (Stale index protection)
            img_filename = match['filename']
            full_path = os.path.join(DATASET_DIR, key, img_filename)
            if not os.path.exists(full_path):
                print(f"WARNING: Matched image {img_filename} not found on disk. Searching fallback...")
                for m_id, m_data in metadata.items():
                    if m_data['landmark_name'] == key:
                        cand_path = os.path.join(DATASET_DIR, key, m_data['filename'])
                        if os.path.exists(cand_path):
                            img_filename = m_data['filename']
                            print(f"Fallback found: {img_filename}")
                            break
            
            return {"predictions": [{
                "id": key,
                "name": info['name'],
                "shortDescription": info['short_description'],
                "longDescription": info['long_description'],
                "history": info.get('history', 'No history available.'),
                "facts": info.get('facts', []),
                "speechText": info.get('speech_text', ''),
                "lat": info['lat'],
                "lng": info['lon'],
                "imageAsset": f"{key}/{img_filename}",
                "score": similarity, 
                "matchType": "visual",
                "distance": round(dist, 2),
                "imageId": image_id,
                "city": info.get('city', 'Unknown City'),
                "country": info.get('country', 'Unknown Country'),
                "category": info.get('category', 'none')
            }]}

        # PRIORITY 2: FALLBACK LIST (Sorted by distance when no visual match is found)
        candidates = []
        if latitude is not None and longitude is not None:
            SEARCH_RADIUS_KM = 50.0
            
            for key, info in LANDMARK_INFO.items():
                if key == "unknown":
                    continue
                
                l_lat = info.get('lat')
                l_lon = info.get('lon')
                
                if l_lat and l_lon:
                    dist = haversine(longitude, latitude, l_lon, l_lat)
                    if dist <= SEARCH_RADIUS_KM:
                        img_asset = ""
                        for m_id, m_data in metadata.items():
                            if m_data['landmark_name'] == key:
                                full_path = os.path.join(DATASET_DIR, key, m_data['filename'])
                                if os.path.exists(full_path):
                                    img_asset = f"{key}/{m_data['filename']}"
                                    break
                                
                        candidates.append({
                            "id": key,
                            "name": info['name'],
                            "shortDescription": info['short_description'],
                            "longDescription": info['long_description'],
                            "history": info.get('history', 'No history available.'),
                            "facts": info.get('facts', []),
                            "speechText": info.get('speech_text', ''),
                            "lat": l_lat,
                            "lng": l_lon,
                            "imageAsset": img_asset,
                            "score": 0.0, 
                            "matchType": "list",
                            "distance": round(dist, 2),
                            "imageId": image_id,
                            "city": info.get('city', 'Unknown City'),
                            "country": info.get('country', 'Unknown Country'),
                            "category": info.get('category', 'none')
                        })
            
            candidates.sort(key=lambda x: x['distance'])
            candidates = candidates[:5]

        if candidates:
            print(f"DEBUG: Returning LIST with {len(candidates)} items")
            return {"predictions": candidates}
            
        # PRIORITY 3: UNKNOWN (Nothing found)
        print("DEBUG: Returning UNKNOWN match")
        info = LANDMARK_INFO["unknown"]
        return {"predictions": [{
            "id": "-1",
            "name": info['name'],
            "shortDescription": info['short_description'],
            "longDescription": info['long_description'],
            "history": info.get('history', 'No history available.'),
            "facts": info.get('facts', []),
            "lat": latitude if latitude else 0.0,
            "lng": longitude if longitude else 0.0,
            "imageAsset": "",
            "score": 0.0,
            "matchType": "unknown",
            "distance": 0.0,
            "imageId": image_id,
            "city": "Unknown",
            "country": "Unknown",
            "category": "none"
        }]}

    except Exception as e:
        print(f"Prediction error: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


# ---------------------------------------------------------
# IMAGE SERVING & ROOT ENDPOINTS
# ---------------------------------------------------------
@app.get("/images/{landmark_name}/{filename}")
async def serve_image(landmark_name: str, filename: str):
    """Smart image serving endpoint with automatic fallback to any valid image in landmark folder."""
    base_path = os.path.join(DATASET_DIR, landmark_name)
    file_path = os.path.join(base_path, filename)
    
    # 1. Try to serve exact file
    if os.path.exists(file_path):
        return FileResponse(file_path)
    
    # 2. Fallback to any valid image in that folder
    print(f"WARNING: Image not found: {filename}. Searching fallback in {landmark_name}...")
    if os.path.exists(base_path):
        for f in os.listdir(base_path):
            if f.lower().endswith(('.jpg', '.jpeg', '.png')):
                fallback_path = os.path.join(base_path, f)
                print(f"Serving fallback: {f}")
                return FileResponse(fallback_path)
                
    raise HTTPException(status_code=404, detail="Image not found")


@app.get("/")
def root():
    return {"message": "DigiGuide backend running successfully!"}
