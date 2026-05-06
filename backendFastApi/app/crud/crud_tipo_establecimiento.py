from typing import List, Optional

from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.models.tipo_establecimiento import TipoEstablecimiento
from app.schemas.tipo_establecimiento import TipoEstablecimientoCreate, TipoEstablecimientoUpdate


def get_tipo_establecimiento(db: Session, id_tipo_establecimiento: int) -> Optional[TipoEstablecimiento]:
    return db.query(TipoEstablecimiento).filter(TipoEstablecimiento.id_tipo_establecimiento == id_tipo_establecimiento).first()


def get_tipos_establecimiento(db: Session) -> List[TipoEstablecimiento]:
    return db.query(TipoEstablecimiento).all()


def create_tipo_establecimiento(db: Session, tipo_in: TipoEstablecimientoCreate) -> TipoEstablecimiento:
    data = tipo_in.model_dump(exclude_unset=True)
    existing = db.query(TipoEstablecimiento).filter(TipoEstablecimiento.nombre_categoria == data["nombre_categoria"]).first()
    if existing:
        raise ValueError("Ya existe un tipo de establecimiento con ese nombre")

    db_obj = TipoEstablecimiento(**data)
    db.add(db_obj)
    try:
        db.commit()
        db.refresh(db_obj)
    except IntegrityError:
        db.rollback()
        raise ValueError("Ya existe un tipo de establecimiento con ese nombre")
    return db_obj


def update_tipo_establecimiento(
    db: Session, db_obj: TipoEstablecimiento, tipo_in: TipoEstablecimientoUpdate
) -> TipoEstablecimiento:
    data = tipo_in.model_dump(exclude_unset=True)
    if "nombre_categoria" in data:
        existing = (
            db.query(TipoEstablecimiento)
            .filter(
                TipoEstablecimiento.nombre_categoria == data["nombre_categoria"],
                TipoEstablecimiento.id_tipo_establecimiento != db_obj.id_tipo_establecimiento,
            )
            .first()
        )
        if existing:
            raise ValueError("Ya existe un tipo de establecimiento con ese nombre")

    for field, value in data.items():
        setattr(db_obj, field, value)

    db.add(db_obj)
    try:
        db.commit()
        db.refresh(db_obj)
    except IntegrityError:
        db.rollback()
        raise ValueError("Ya existe un tipo de establecimiento con ese nombre")
    return db_obj


def remove_tipo_establecimiento(db: Session, id_tipo_establecimiento: int) -> Optional[TipoEstablecimiento]:
    obj = get_tipo_establecimiento(db, id_tipo_establecimiento)
    if not obj:
        return None

    db.delete(obj)
    db.commit()
    return obj
