from typing import List, Optional

from sqlalchemy.orm import Session

from app.models.tipo_establecimiento import TipoEstablecimiento
from app.schemas.tipo_establecimiento import TipoEstablecimientoCreate, TipoEstablecimientoUpdate


def get_tipo_establecimiento(db: Session, id_tipo_establecimiento: int) -> Optional[TipoEstablecimiento]:
    return db.query(TipoEstablecimiento).filter(TipoEstablecimiento.id_tipo_establecimiento == id_tipo_establecimiento).first()


def get_tipos_establecimiento(db: Session) -> List[TipoEstablecimiento]:
    return db.query(TipoEstablecimiento).all()


def create_tipo_establecimiento(db: Session, tipo_in: TipoEstablecimientoCreate) -> TipoEstablecimiento:
    data = tipo_in.model_dump(exclude_unset=True)
    db_obj = TipoEstablecimiento(**data)
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj


def update_tipo_establecimiento(
    db: Session, db_obj: TipoEstablecimiento, tipo_in: TipoEstablecimientoUpdate
) -> TipoEstablecimiento:
    data = tipo_in.model_dump(exclude_unset=True)
    for field, value in data.items():
        setattr(db_obj, field, value)

    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj


def remove_tipo_establecimiento(db: Session, id_tipo_establecimiento: int) -> Optional[TipoEstablecimiento]:
    obj = get_tipo_establecimiento(db, id_tipo_establecimiento)
    if not obj:
        return None

    db.delete(obj)
    db.commit()
    return obj
