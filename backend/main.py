"""
3D Mirror — FastAPI Backend
Run locally: uvicorn main:app --reload --port 8000
"""

from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from database import Database
from routers import sessions, users
from auth.router import router as auth_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    await Database.connect()
    yield
    await Database.disconnect()


app = FastAPI(
    title="3D Mirror API",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router,          prefix="/auth",     tags=["auth"])
app.include_router(users.router,         prefix="/users",    tags=["users"])
app.include_router(sessions.router,      prefix="/sessions", tags=["sessions"])


@app.get("/health")
async def health():
    return {"status": "ok", "version": "0.1.0"}
