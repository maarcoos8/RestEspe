import os
from typing import Any

from fastapi import HTTPException, status
from google.auth.transport.requests import Request as GoogleRequest
from google.oauth2 import id_token as google_id_token


def verify_google_bearer_token(authorization_header: str | None) -> dict[str, Any]:
	"""Verifica un Bearer token de Google y devuelve sus claims.

	Esta función valida:
	- Presencia del header Authorization
	- Formato Bearer
	- Firma, expiración y audiencia del token
	"""
	if not authorization_header:
		raise HTTPException(
			status_code=status.HTTP_401_UNAUTHORIZED,
			detail="Falta header Authorization",
		)

	parts = authorization_header.split(" ", 1)
	if len(parts) != 2 or parts[0].lower() != "bearer" or not parts[1].strip():
		raise HTTPException(
			status_code=status.HTTP_401_UNAUTHORIZED,
			detail="Authorization debe usar formato Bearer <token>",
		)

	token = parts[1].strip()
	google_client_id = os.getenv("GOOGLE_WEB_CLIENT_ID")
	if not google_client_id:
		raise HTTPException(
			status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
			detail="GOOGLE_WEB_CLIENT_ID no está configurado en el backend",
		)

	try:
		claims = google_id_token.verify_oauth2_token(
			token,
			GoogleRequest(),
			google_client_id,
		)
	except ValueError as exc:
		raise HTTPException(
			status_code=status.HTTP_401_UNAUTHORIZED,
			detail="Token inválido o expirado",
		) from exc
	except Exception as exc:
		raise HTTPException(
			status_code=status.HTTP_401_UNAUTHORIZED,
			detail="No se pudo verificar el token",
		) from exc

	if not claims.get("email"):
		raise HTTPException(
			status_code=status.HTTP_401_UNAUTHORIZED,
			detail="Token sin email válido",
		)

	return claims
