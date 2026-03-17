import aiosqlite
from config import DB_PATH


async def init_db() -> None:
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("""
            CREATE TABLE IF NOT EXISTS users (
                user_id          INTEGER PRIMARY KEY,
                home_lat         REAL,
                home_lon         REAL,
                home_address     TEXT,
                work_lat         REAL,
                work_lon         REAL,
                work_address     TEXT,
                auto_notify_time TEXT
            )
        """)
        await db.commit()


async def get_user(user_id: int) -> aiosqlite.Row | None:
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        async with db.execute(
            "SELECT * FROM users WHERE user_id = ?", (user_id,)
        ) as cursor:
            return await cursor.fetchone()


async def save_user(user_id: int, **kwargs) -> None:
    async with aiosqlite.connect(DB_PATH) as db:
        exists = await (
            await db.execute(
                "SELECT 1 FROM users WHERE user_id = ?", (user_id,)
            )
        ).fetchone()

        if not exists:
            await db.execute(
                "INSERT INTO users (user_id) VALUES (?)", (user_id,)
            )

        if kwargs:
            sets = ", ".join(f"{k} = ?" for k in kwargs)
            await db.execute(
                f"UPDATE users SET {sets} WHERE user_id = ?",
                (*kwargs.values(), user_id),
            )

        await db.commit()


async def get_all_users_with_schedule() -> list[aiosqlite.Row]:
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        async with db.execute(
            "SELECT * FROM users WHERE auto_notify_time IS NOT NULL"
        ) as cursor:
            return await cursor.fetchall()
