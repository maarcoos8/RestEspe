from typing import List, Optional
from sqlalchemy.orm import Session
from datetime import datetime

from app.models.resena import Resena
from app.models.usuario import Usuario
from app.models.establecimiento import Establecimiento
from app.schemas.resena import ResenaCreate, ResenaUpdate


def get_resena(db: Session, id_resena: int) -> Optional[Resena]:
    return db.query(Resena).filter(Resena.id_resena == id_resena).first()


def get_resenas(db: Session) -> List[Resena]:
    return db.query(Resena).all()


def get_resenas_por_establecimiento(db: Session, id_establecimiento: int) -> List[Resena]:
    return (
        db.query(Resena)
        .filter(Resena.id_establecimiento == id_establecimiento)
        .order_by(Resena.fecha_publicacion.desc())
        .all()
    )


def create_resena(db: Session, resena_in: ResenaCreate) -> Resena:
    # validate FK existence
    if not db.query(Usuario).filter(Usuario.id_usuario == resena_in.id_usuario).first():
        raise ValueError("Usuario no encontrado")
    if not db.query(Establecimiento).filter(Establecimiento.id_establecimiento == resena_in.id_establecimiento).first():
        raise ValueError("Establecimiento no encontrado")

    data = resena_in.model_dump(exclude_unset=True)
    db_obj = Resena(**data)
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj


def update_resena(db: Session, db_obj: Resena, resena_in: ResenaUpdate) -> Resena:
    data = resena_in.model_dump(exclude_unset=True)
    for field, value in data.items():
        setattr(db_obj, field, value)
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj


def remove_resena(db: Session, id_resena: int) -> Optional[Resena]:
    obj = get_resena(db, id_resena)
    if not obj:
        return None
    db.delete(obj)
    db.commit()
    return obj
