from typing import List, Optional

from sqlalchemy.orm import Session

from app.models.establecimiento import Establecimiento
from app.models.establecimiento_tipo import EstablecimientoTipo
from app.models.tipo_establecimiento import TipoEstablecimiento


def get_establecimiento_tipo(
    db: Session, id_establecimiento: int, id_tipo_establecimiento: int
) -> Optional[EstablecimientoTipo]:
    return (
        db.query(EstablecimientoTipo)
        .filter(
            EstablecimientoTipo.id_establecimiento == id_establecimiento,
            EstablecimientoTipo.id_tipo_establecimiento == id_tipo_establecimiento,
        )
        .first()
    )


def get_establecimiento_tipos(db: Session) -> List[EstablecimientoTipo]:
    return db.query(EstablecimientoTipo).all()


def get_tipos_por_establecimiento(db: Session, id_establecimiento: int) -> List[EstablecimientoTipo]:
    return db.query(EstablecimientoTipo).filter(EstablecimientoTipo.id_establecimiento == id_establecimiento).all()


def get_establecimientos_por_tipo(db: Session, id_tipo_establecimiento: int) -> List[EstablecimientoTipo]:
    return db.query(EstablecimientoTipo).filter(EstablecimientoTipo.id_tipo_establecimiento == id_tipo_establecimiento).all()


def create_establecimiento_tipo(db: Session, id_establecimiento: int, id_tipo_establecimiento: int) -> EstablecimientoTipo:
    if not db.query(Establecimiento).filter(Establecimiento.id_establecimiento == id_establecimiento).first():
        raise ValueError("Establecimiento no encontrado")
    if not db.query(TipoEstablecimiento).filter(TipoEstablecimiento.id_tipo_establecimiento == id_tipo_establecimiento).first():
        raise ValueError("Tipo de establecimiento no encontrado")

    existing = get_establecimiento_tipo(db, id_establecimiento, id_tipo_establecimiento)
    if existing:
        raise ValueError("La relacion establecimiento-tipo ya existe")

    db_obj = EstablecimientoTipo(
        id_establecimiento=id_establecimiento,
        id_tipo_establecimiento=id_tipo_establecimiento,
    )
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj


def remove_establecimiento_tipo(
    db: Session, id_establecimiento: int, id_tipo_establecimiento: int
) -> Optional[EstablecimientoTipo]:
    obj = get_establecimiento_tipo(db, id_establecimiento, id_tipo_establecimiento)
    if not obj:
        return None

    db.delete(obj)
    db.commit()
    return obj
