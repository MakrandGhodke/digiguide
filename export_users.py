"""
Export Users Script
Generates a readable file with all registered users.
Note: Passwords are stored as hashes, not plain text.
"""
import json
import os
from datetime import datetime

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
USER_DB_FILE = os.path.join(BASE_DIR, "users.json")
OUTPUT_FILE = os.path.join(BASE_DIR, "users_export.txt")

def export_users():
    if not os.path.exists(USER_DB_FILE):
        print("No users.json found. No users registered yet.")
        return
    
    with open(USER_DB_FILE, 'r') as f:
        users = json.load(f)
    
    if not users:
        print("No users registered yet.")
        return
    
    output_lines = []
    output_lines.append("=" * 60)
    output_lines.append("DIGIGUIDE - REGISTERED USERS")
    output_lines.append(f"Exported: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    output_lines.append("=" * 60)
    output_lines.append("")
    
    for i, (email, data) in enumerate(users.items(), 1):
        output_lines.append(f"User #{i}")
        output_lines.append(f"  Email: {email}")
        output_lines.append(f"  Name: {data.get('name', 'N/A')}")
        output_lines.append(f"  Registered: {data.get('created_at', 'N/A')}")
        output_lines.append(f"  Password Hash: {data.get('password_hash', 'N/A')[:20]}...")
        output_lines.append("")
    
    output_lines.append("=" * 60)
    output_lines.append(f"Total Users: {len(users)}")
    output_lines.append("=" * 60)
    
    # Write to file
    with open(OUTPUT_FILE, 'w') as f:
        f.write("\n".join(output_lines))
    
    # Also print to console
    print("\n".join(output_lines))
    print(f"\nExported to: {OUTPUT_FILE}")

if __name__ == "__main__":
    export_users()
