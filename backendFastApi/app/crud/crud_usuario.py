from typing import Optional

from sqlalchemy.orm import Session

from app.models.usuario import Usuario
from app.core.roles import DEFAULT_ROLE_ID


def get_usuario_por_email(db: Session, email: str) -> Optional[Usuario]:
    return db.query(Usuario).filter(Usuario.email == email.lower()).first()


def upsert_usuario_google(
    db: Session,
    email: str,
    nombre_completo: str,
    foto_perfil: str | None = None,
) -> Usuario:
    email = email.lower()  # Normalizar email a minúsculas
    usuario = get_usuario_por_email(db, email)

    if usuario is None:
        usuario = Usuario(
            email=email,
            nombre_completo=nombre_completo,
            fotoPerfil=foto_perfil,
            id_rol=DEFAULT_ROLE_ID,  # Asignar rol de usuario por defecto en primer login
        )
        db.add(usuario)
    else:
        usuario.nombre_completo = nombre_completo
        usuario.fotoPerfil = foto_perfil
        # Asignar rol por defecto si el usuario aún no tiene rol
        if usuario.id_rol is None:
            usuario.id_rol = DEFAULT_ROLE_ID

    db.commit()
    db.refresh(usuario)
    return usuario