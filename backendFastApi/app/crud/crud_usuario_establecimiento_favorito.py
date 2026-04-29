from typing import List, Optional

from sqlalchemy.orm import Session

from app.models.establecimiento import Establecimiento
from app.models.usuario import Usuario
from app.models.usuario_establecimiento_favorito import UsuarioEstablecimientoFavorito


def get_favorito(db: Session, id_usuario: int, id_establecimiento: int) -> Optional[UsuarioEstablecimientoFavorito]:
    return (
        db.query(UsuarioEstablecimientoFavorito)
        .filter(
            UsuarioEstablecimientoFavorito.id_usuario == id_usuario,
            UsuarioEstablecimientoFavorito.id_establecimiento == id_establecimiento,
        )
        .first()
    )


def get_favoritos(db: Session) -> List[UsuarioEstablecimientoFavorito]:
    return db.query(UsuarioEstablecimientoFavorito).all()


def get_establecimientos_favoritos_por_usuario(db: Session, id_usuario: int) -> List[Establecimiento]:
    return (
        db.query(Establecimiento)
        .join(
            UsuarioEstablecimientoFavorito,
            UsuarioEstablecimientoFavorito.id_establecimiento == Establecimiento.id_establecimiento,
        )
        .filter(UsuarioEstablecimientoFavorito.id_usuario == id_usuario)
        .all()
    )


def create_favorito(db: Session, id_usuario: int, id_establecimiento: int) -> UsuarioEstablecimientoFavorito:
    if not db.query(Usuario).filter(Usuario.id_usuario == id_usuario).first():
        raise ValueError("Usuario no encontrado")
    if not db.query(Establecimiento).filter(Establecimiento.id_establecimiento == id_establecimiento).first():
        raise ValueError("Establecimiento no encontrado")

    existing = get_favorito(db, id_usuario, id_establecimiento)
    if existing:
        raise ValueError("El favorito ya existe")

    db_obj = UsuarioEstablecimientoFavorito(
        id_usuario=id_usuario,
        id_establecimiento=id_establecimiento,
    )
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj


def remove_favorito(db: Session, id_usuario: int, id_establecimiento: int) -> Optional[UsuarioEstablecimientoFavorito]:
    obj = get_favorito(db, id_usuario, id_establecimiento)
    if not obj:
        return None

    db.delete(obj)
    db.commit()
    return obj