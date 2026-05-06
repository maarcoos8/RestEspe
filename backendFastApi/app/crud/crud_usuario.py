from typing import Optional, List

from sqlalchemy.orm import Session

from app.models.usuario import Usuario
from app.models.resena import Resena
from app.models.fotografia import Fotografia
from app.models.usuario_establecimiento_favorito import UsuarioEstablecimientoFavorito
from app.core.roles import DEFAULT_ROLE_ID
from app.schemas.usuario import UsuarioUpdate


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


def get_usuarios(db: Session) -> List[Usuario]:
    return db.query(Usuario).all()


def get_usuario(db: Session, id_usuario: int) -> Optional[Usuario]:
    return db.query(Usuario).filter(Usuario.id_usuario == id_usuario).first()


def update_usuario(db: Session, db_obj: Usuario, usuario_in: UsuarioUpdate) -> Usuario:
    data = usuario_in.model_dump(exclude_unset=True)
    for field, value in data.items():
        setattr(db_obj, field, value)
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj


def remove_usuario(db: Session, id_usuario: int) -> Optional[Usuario]:
    obj = get_usuario(db, id_usuario)
    if not obj:
        return None
    
    # Eliminar todas las reseñas del usuario
    db.query(Resena).filter(Resena.id_usuario == id_usuario).delete()
    
    # Eliminar todas las fotografías del usuario
    db.query(Fotografia).filter(Fotografia.id_usuario == id_usuario).delete()
    
    # Eliminar todos los favoritos del usuario
    db.query(UsuarioEstablecimientoFavorito).filter(
        UsuarioEstablecimientoFavorito.id_usuario == id_usuario
    ).delete()
    
    # Luego eliminar el usuario
    db.delete(obj)
    db.commit()
    return obj