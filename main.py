import logging
from dotenv import load_dotenv
import query_planner
import db_utils


def init():
    load_dotenv()

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    )
    logging.info("Initializing application...")
    logging.info("Loaded environment variables")


def main():
    logging.info("Running application...")
    query = "SELECT * FROM users WHERE age > 30"
    
    logging.info("Parsing the query:")
    db_utils.parse_query(query)
    
    # Get PostgreSQL's execution plan
    logging.info("Getting PostgreSQL Execution Plan:")
    with db_utils.connect_to_db() as conn:
        plan = db_utils.get_postgres_plan(conn, query)
        for row in plan:
            logging.info(row[0])

    # Run the query planner
    query_planner.run()


if __name__ == "__main__":
    init()
    main()
