import psycopg2
import sqlparse
from psycopg2 import sql
import os

# PostgreSQL connection parameters
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")

def connect_to_db():
    return psycopg2.connect(
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        host=DB_HOST,
        port=DB_PORT
    )

def parse_query(query):
    parsed = sqlparse.parse(query)[0]
    print("Parsed Query Structure:")
    for token in parsed.tokens:
        if token.is_group:
            print(f"{token.ttype}: {token.value}")
        else:
            print(f"{token.ttype}: {token.value.strip()}")

def get_postgres_plan(conn, query):
    with conn.cursor() as cur:
        cur.execute(f"EXPLAIN {query}")
        return cur.fetchall()
    
