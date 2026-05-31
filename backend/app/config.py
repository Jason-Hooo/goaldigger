"""Application configuration and environment settings."""

from functools import lru_cache
from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    """Typed settings loaded from environment variables."""
    
    supabase_url: str
    db_url: str
    environment: str = "development"

    model_config = SettingsConfigDict(
        env_file=Path(__file__).resolve().parents[1] / ".env",
        extra="ignore",
    )

@lru_cache
def get_settings() -> Settings:
    """Return cached application settings."""
    return Settings()
