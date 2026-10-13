import asyncpg
import json
import os


async def _init_connection(conn: asyncpg.Connection) -> None:
    # Encode/decode json & jsonb as Python objects on every pooled connection,
    # so routers pass and receive dicts/lists — never call json.dumps/loads for DB columns.
    for typename in ("json", "jsonb"):
        await conn.set_type_codec(
            typename, encoder=json.dumps, decoder=json.loads, schema="pg_catalog",
        )


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
            init=_init_connection,
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
