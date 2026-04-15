from datetime import datetime
from typing import List, Optional

from sqlalchemy.orm import Session
from geoalchemy2.elements import WKTElement

from app.models.establecimiento import Establecimiento
from app.schemas.establecimiento import EstablecimientoCreate, EstablecimientoUpdate


def get_establecimiento(db: Session, id_establecimiento: int) -> Optional[Establecimiento]:
    return db.query(Establecimiento).filter(Establecimiento.id_establecimiento == id_establecimiento).first()


def get_establecimientos(db: Session, skip: int = 0, limit: int = 100) -> List[Establecimiento]:
    return db.query(Establecimiento).offset(skip).limit(limit).all()


def create_establecimiento(
    db: Session, establecimiento_in: EstablecimientoCreate, verificador_id: Optional[int] = None
) -> Establecimiento:
    data = establecimiento_in.model_dump(exclude_unset=True)
    lat = data.pop("latitud", None)
    lon = data.pop("longitud", None)
    if lat is not None and lon is not None:
        data["coordenadas"] = WKTElement(f"POINT({lon} {lat})", srid=4326)
    if verificador_id is not None:
        data["verificador_id"] = verificador_id
        data["ultima_verificacion"] = datetime.utcnow()

    db_obj = Establecimiento(**data)
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj


def update_establecimiento(
    db: Session, db_obj: Establecimiento, establecimiento_in: EstablecimientoUpdate
) -> Establecimiento:
    data = establecimiento_in.model_dump(exclude_unset=True)
    lat = data.pop("latitud", None)
    lon = data.pop("longitud", None)
    if lat is not None and lon is not None:
        db_obj.coordenadas = WKTElement(f"POINT({lon} {lat})", srid=4326)

    for field, value in data.items():
        setattr(db_obj, field, value)

    if "verificador_id" in data:
        db_obj.ultima_verificacion = datetime.utcnow()

    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj


def remove_establecimiento(db: Session, id_establecimiento: int) -> Optional[Establecimiento]:
    obj = get_establecimiento(db, id_establecimiento)
    if not obj:
        return None
    db.delete(obj)
    db.commit()
    return obj
