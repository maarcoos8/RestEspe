import os

from fastapi import APIRouter, Depends, HTTPException, status
from google.auth.transport.requests import Request as GoogleRequest
from google.oauth2 import id_token as google_id_token
from sqlalchemy.orm import Session

from app import crud
from app.db.session import get_db
from app.schemas.auth import GoogleAuthIn, GoogleAuthOut

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post("/google", response_model=GoogleAuthOut)
def login_with_google(payload: GoogleAuthIn, db: Session = Depends(get_db)):
    google_client_id = os.getenv("GOOGLE_WEB_CLIENT_ID")
    if not google_client_id:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="GOOGLE_WEB_CLIENT_ID no está configurado en el backend",
        )

    try:
        id_info = google_id_token.verify_oauth2_token(
            payload.id_token,
            GoogleRequest(),
            google_client_id,
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token de Google inválido",
        ) from exc
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="No se pudo verificar el token de Google",
        ) from exc

    email = id_info.get("email")
    if not email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Google no devolvió un email válido",
        )

    nombre = id_info.get("name") or id_info.get("given_name") or email
    foto_perfil = id_info.get("picture")

    usuario = crud.crud_usuario.upsert_usuario_google(
        db=db,
        email=email,
        nombre_completo=nombre,
        foto_perfil=foto_perfil,
    )

    return usuario