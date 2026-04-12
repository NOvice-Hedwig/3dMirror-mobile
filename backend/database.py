import asyncpg
import os


class Database:
    _pool: asyncpg.Pool | None = None

    @classmethod
    async def connect(cls):
        cls._pool = await asyncpg.create_pool(
            dsn=os.getenv(
                "DATABASE_URL",
                "postgresql://mirror:mirror@localhost/mirror_db",
            ),
            min_size=2,
            max_size=10,
        )

    @classmethod
    async def disconnect(cls):
        if cls._pool:
            await cls._pool.close()

    @classmethod
    def pool(cls) -> asyncpg.Pool:
        if not cls._pool:
            raise RuntimeError("Database not connected. Call Database.connect() first.")
        return cls._pool
