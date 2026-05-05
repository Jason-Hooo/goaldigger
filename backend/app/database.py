"""Supabase client helpers."""

from functools import lru_cache
from typing import Any

from fastapi import HTTPException
from supabase import Client, create_client

from .config import get_settings


@lru_cache
def get_auth_client() -> Client:
	"""Return a Supabase client for auth lookups."""

	settings = get_settings()
	return create_client(settings.supabase_url, settings.supabase_anon_key)


@lru_cache
def get_data_client() -> Client:
	"""Return a Supabase client for data operations."""

	settings = get_settings()
	key = settings.supabase_service_role_key or settings.supabase_anon_key
	return create_client(settings.supabase_url, key)


def unwrap_response(response: Any, message: str) -> Any:
	"""Return response data or raise an HTTPException on errors."""

	error = getattr(response, "error", None)
	if error:
		raise HTTPException(status_code=400, detail=f"{message}: {error}")
	return getattr(response, "data", None)
