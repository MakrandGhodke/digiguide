import sqlite3
import pandas as pd
import os
from datetime import datetime

DB_FILE = "users.db"

def export_reviews():
    if not os.path.exists(DB_FILE):
        print(f"Database file {DB_FILE} not found.")
        return

    try:
        conn = sqlite3.connect(DB_FILE)
        
        # Query users and reviews
        query = """
        SELECT 
            r.id,
            r.user_id,
            u.email,
            u.name,
            r.landmark_slug,
            r.image_id,
            r.is_good,
            r.comments,
            r.created_at
        FROM reviews r
        LEFT JOIN users u ON r.user_id = u.id
        ORDER BY r.created_at DESC
        """
        
        df = pd.read_sql_query(query, conn)
        conn.close()
        
        if df.empty:
            print("No reviews found.")
            return

        # Print report
        print("\n=== REVIEWS REPORT ===")
        print(f"Total Reviews: {len(df)}")
        print(f"Good Reviews: {len(df[df['is_good'] == 1])}")
        print(f"Bad Reviews: {len(df[df['is_good'] == 0])}")
        print("\nLast 5 Reviews:")
        print(df[['created_at', 'email', 'landmark_slug', 'is_good', 'comments']].head().to_string())
        
        # Export to CSV
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"reviews_export_{timestamp}.csv"
        df.to_csv(filename, index=False)
        print(f"\nFull report exported to: {filename}")
        
    except Exception as e:
        print(f"Error exporting reviews: {e}")

if __name__ == "__main__":
    export_reviews()
