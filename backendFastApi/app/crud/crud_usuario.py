from typing import Optional

from sqlalchemy.orm import Session

from app.models.usuario import Usuario


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
        )
        db.add(usuario)
    else:
        usuario.nombre_completo = nombre_completo
        usuario.fotoPerfil = foto_perfil

    db.commit()
    db.refresh(usuario)
    return usuario