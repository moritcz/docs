import os
from dotenv import load_dotenv

load_dotenv()

TELEGRAM_TOKEN: str = os.environ["TELEGRAM_TOKEN"]
GIS_API_KEY: str = os.environ["GIS_API_KEY"]
DB_PATH: str = os.getenv("DB_PATH", "bot.db")
