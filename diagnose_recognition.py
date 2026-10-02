"""
Diagnostic script to check raw model outputs and FAISS search results.
"""
import os
import sys
import faiss
import json
from PIL import Image

# Add parent dir to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from utils import image_to_embedding

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
INDEX_FILE = os.path.join(BASE_DIR, "vector_store.index")
METADATA_FILE = os.path.join(BASE_DIR, "metadata.json")

def diagnose(image_path):
    print("=" * 60)
    print("FAISS & CLIP DIAGNOSTIC")
    print("=" * 60)
    
    # Check files exist
    if not os.path.exists(INDEX_FILE):
        print(f"ERROR: Index file not found: {INDEX_FILE}")
        return
    if not os.path.exists(METADATA_FILE):
        print(f"ERROR: Metadata file not found: {METADATA_FILE}")
        return
    if not os.path.exists(image_path):
        print(f"ERROR: Image file not found: {image_path}")
        return
    
    print(f"Index file: {INDEX_FILE}")
    print(f"Metadata file: {METADATA_FILE}")
    print(f"Test image: {image_path}")
    print("-" * 60)
    
    # Load index
    print("Loading FAISS index...")
    index = faiss.read_index(INDEX_FILE)
    print(f"  Index total vectors: {index.ntotal}")
    print(f"  Index dimension: {index.d}")
    
    # Load metadata
    print("Loading metadata...")
    with open(METADATA_FILE, 'r') as f:
        metadata = json.load(f)
        metadata = {int(k): v for k, v in metadata.items()}
    print(f"  Metadata entries: {len(metadata)}")
    
    # Show first few metadata entries
    print("\nSample metadata entries:")
    for i, (k, v) in enumerate(list(metadata.items())[:5]):
        print(f"  [{k}] {v['landmark_name']}: {v['filename']}")
    
    print("-" * 60)
    
    # Load and embed test image
    print("Loading and embedding test image...")
    image = Image.open(image_path).convert("RGB")
    query_emb = image_to_embedding(image).astype('float32')
    print(f"  Embedding shape: {query_emb.shape}")
    print(f"  Embedding norm: {(query_emb ** 2).sum() ** 0.5:.4f}")
    
    print("-" * 60)
    
    # Search
    print("Running FAISS search (k=5)...")
    k = 5
    distances, indices = index.search(query_emb, k)
    
    print("\nRaw FAISS Results:")
    print(f"  Indices:   {indices[0]}")
    print(f"  Distances: {distances[0]}")
    
    print("\nDetailed Results:")
    for i in range(k):
        idx = int(indices[0][i])
        dist = float(distances[0][i])
        
        # Convert to similarity
        similarity = max(0.0, 1.0 - (dist ** 2) / 2.0)
        
        meta = metadata.get(idx, {"landmark_name": "UNKNOWN", "filename": "N/A"})
        
        print(f"\n  [Rank {i+1}]")
        print(f"    Index: {idx}")
        print(f"    L2 Distance: {dist:.4f}")
        print(f"    Similarity (1-d²/2): {similarity:.4f}")
        print(f"    Landmark: {meta.get('landmark_name', 'UNKNOWN')}")
        print(f"    Filename: {meta.get('filename', 'N/A')}")
        
        # Check thresholds
        if similarity >= 0.80:
            print(f"    STATUS: ✓ PASSES threshold 0.80")
        elif similarity >= 0.70:
            print(f"    STATUS: ~ Would pass 0.70, fails 0.80")
        else:
            print(f"    STATUS: ✗ Below 0.70 threshold")
    
    print("\n" + "=" * 60)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python diagnose_recognition.py <image_path>")
        print("Example: python diagnose_recognition.py dataset/darmstadium/1024px-Darmstadtium.jpg")
    else:
        diagnose(sys.argv[1])
