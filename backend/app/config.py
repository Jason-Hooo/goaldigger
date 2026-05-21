"""Application configuration and environment settings."""

from functools import lru_cache

from pydantic import BaseSettings, Field


class Settings(BaseSettings):
	"""Typed settings loaded from environment variables."""

	supabase_url: str = Field(..., env="SUPABASE_URL")
	db_url: str = Field(..., env="DB_URL")
	environment: str = Field(default="development", env="ENVIRONMENT")

	class Config:
		"""Pydantic settings configuration."""

		env_file = ".env"
		case_sensitive = True


@lru_cache
def get_settings() -> Settings:
	"""Return cached application settings."""

	return Settings()
