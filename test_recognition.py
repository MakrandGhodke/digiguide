"""
Direct Image Recognition Test Script
Uploads an image directly to the backend and shows detailed results.

Usage:
    python test_recognition.py path/to/image.jpg
    python test_recognition.py path/to/image.jpg --lat 49.8732 --lon 8.6558
"""
import sys
import os
import requests
import argparse

# Backend URL
BACKEND_URL = "http://127.0.0.1:8000"

def test_image(image_path, latitude=None, longitude=None):
    """Test an image against the recognition API."""
    
    if not os.path.exists(image_path):
        print(f"ERROR: File not found: {image_path}")
        return
    
    print("=" * 60)
    print("DIGIGUIDE - DIRECT RECOGNITION TEST")
    print("=" * 60)
    print(f"Image: {image_path}")
    print(f"Location: lat={latitude}, lon={longitude}")
    print("-" * 60)
    
    # Prepare request
    url = f"{BACKEND_URL}/predict"
    
    files = {
        'file': (os.path.basename(image_path), open(image_path, 'rb'), 'image/jpeg')
    }
    
    data = {}
    if latitude is not None:
        data['latitude'] = str(latitude)
    if longitude is not None:
        data['longitude'] = str(longitude)
    
    try:
        print("Sending request to backend...")
        response = requests.post(url, files=files, data=data, timeout=30)
        
        print(f"Status Code: {response.status_code}")
        print("-" * 60)
        
        if response.status_code == 200:
            result = response.json()
            predictions = result.get('predictions', [])
            
            print(f"Number of predictions: {len(predictions)}")
            print("-" * 60)
            
            for i, pred in enumerate(predictions):
                print(f"\n[RESULT #{i+1}]")
                print(f"  Name:        {pred.get('name', 'N/A')}")
                print(f"  ID:          {pred.get('id', 'N/A')}")
                print(f"  Match Type:  {pred.get('matchType', 'N/A')}")
                print(f"  Score:       {pred.get('score', 'N/A')}")
                print(f"  Distance:    {pred.get('distance', 'N/A')} km")
                print(f"  Image ID:    {pred.get('imageId', 'N/A')}")
                print(f"  Description: {pred.get('shortDescription', 'N/A')}")
            
            print("\n" + "=" * 60)
            
            if predictions:
                first = predictions[0]
                match_type = first.get('matchType', 'unknown')
                score = first.get('score', 0)
                
                if match_type == 'visual':
                    print(f"VERDICT: VISUAL MATCH - {first.get('name')} (Score: {score:.4f})")
                elif match_type == 'list':
                    print(f"VERDICT: NO VISUAL MATCH - Showing nearby landmarks")
                elif match_type == 'unknown':
                    print(f"VERDICT: UNKNOWN - Could not recognize")
                else:
                    print(f"VERDICT: {match_type.upper()} match")
        else:
            print(f"ERROR: {response.text}")
            
    except requests.exceptions.ConnectionError:
        print("ERROR: Cannot connect to backend. Is it running?")
        print("       Run: .\\start_all.bat")
    except Exception as e:
        print(f"ERROR: {e}")
    finally:
        files['file'][1].close()
    
    print("=" * 60)

def main():
    parser = argparse.ArgumentParser(description='Test image recognition directly')
    parser.add_argument('image', help='Path to image file')
    parser.add_argument('--lat', type=float, help='Latitude (optional)')
    parser.add_argument('--lon', type=float, help='Longitude (optional)')
    
    args = parser.parse_args()
    
    test_image(args.image, args.lat, args.lon)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python test_recognition.py <image_path> [--lat LAT] [--lon LON]")
        print("\nExamples:")
        print("  python test_recognition.py photo.jpg")
        print("  python test_recognition.py photo.jpg --lat 49.8732 --lon 8.6558")
        print("\nTest with dataset images:")
        print("  python test_recognition.py dataset/darmstadium/image1.jpg")
    else:
        main()
