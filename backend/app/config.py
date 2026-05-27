"""Application configuration and environment settings."""

from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    """Typed settings loaded from environment variables."""
    
    supabase_url: str
    db_url: str
    environment: str = "development"

    # 💡 只有這裡要改：加上 ../ 告訴系統去上一層找密碼檔
    model_config = SettingsConfigDict(env_file="../.env", extra="ignore")

@lru_cache
def get_settings() -> Settings:
    """Return cached application settings."""
    return Settings()