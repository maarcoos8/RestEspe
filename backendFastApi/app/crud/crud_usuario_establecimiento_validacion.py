from typing import Optional

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models.establecimiento import Establecimiento
from app.models.usuario import Usuario
from app.models.usuario_establecimiento_validacion import UsuarioEstablecimientoValidacion


def get_validacion(
    db: Session,
    id_usuario: int,
    id_establecimiento: int,
) -> Optional[UsuarioEstablecimientoValidacion]:
    return (
        db.query(UsuarioEstablecimientoValidacion)
        .filter(
            UsuarioEstablecimientoValidacion.id_usuario == id_usuario,
            UsuarioEstablecimientoValidacion.id_establecimiento == id_establecimiento,
        )
        .first()
    )


def get_resumen_validacion(
    db: Session,
    id_establecimiento: int,
    id_usuario: Optional[int] = None,
) -> dict:
    likes = (
        db.query(func.count(UsuarioEstablecimientoValidacion.id_usuario))
        .filter(
            UsuarioEstablecimientoValidacion.id_establecimiento == id_establecimiento,
            UsuarioEstablecimientoValidacion.valor == 1,
        )
        .scalar()
        or 0
    )
    dislikes = (
        db.query(func.count(UsuarioEstablecimientoValidacion.id_usuario))
        .filter(
            UsuarioEstablecimientoValidacion.id_establecimiento == id_establecimiento,
            UsuarioEstablecimientoValidacion.valor == -1,
        )
        .scalar()
        or 0
    )

    current_user_vote = None
    if id_usuario is not None:
        validacion = get_validacion(db, id_usuario, id_establecimiento)
        if validacion is not None:
            current_user_vote = validacion.valor

    return {
        "id_establecimiento": id_establecimiento,
        "likes": int(likes),
        "dislikes": int(dislikes),
        "current_user_vote": current_user_vote,
    }


def set_validacion(
    db: Session,
    id_usuario: int,
    id_establecimiento: int,
    valor: int,
) -> UsuarioEstablecimientoValidacion:
    if not db.query(Usuario).filter(Usuario.id_usuario == id_usuario).first():
        raise ValueError("Usuario no encontrado")
    if not db.query(Establecimiento).filter(Establecimiento.id_establecimiento == id_establecimiento).first():
        raise ValueError("Establecimiento no encontrado")

    existing = get_validacion(db, id_usuario, id_establecimiento)
    if existing is None:
        db_obj = UsuarioEstablecimientoValidacion(
            id_usuario=id_usuario,
            id_establecimiento=id_establecimiento,
            valor=valor,
        )
        db.add(db_obj)
    else:
        existing.valor = valor
        db_obj = existing

    db.commit()
    db.refresh(db_obj)
    return db_obj


def remove_validacion(
    db: Session,
    id_usuario: int,
    id_establecimiento: int,
) -> Optional[UsuarioEstablecimientoValidacion]:
    obj = get_validacion(db, id_usuario, id_establecimiento)
    if not obj:
        return None

    db.delete(obj)
    db.commit()
    return obj