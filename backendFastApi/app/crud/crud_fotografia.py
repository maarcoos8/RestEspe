from typing import List, Optional

from sqlalchemy.orm import Session

from app.models.establecimiento import Establecimiento
from app.models.fotografia import Fotografia
from app.models.usuario import Usuario
from app.schemas.fotografia import FotografiaCreate, FotografiaUpdate


def get_fotografia(db: Session, id_foto: int) -> Optional[Fotografia]:
    return db.query(Fotografia).filter(Fotografia.id_foto == id_foto).first()


def get_fotografias(db: Session) -> List[Fotografia]:
    return db.query(Fotografia).all()


def create_fotografia(db: Session, fotografia_in: FotografiaCreate) -> Fotografia:
    if not db.query(Usuario).filter(Usuario.id_usuario == fotografia_in.id_usuario).first():
        raise ValueError("Usuario no encontrado")
    if not db.query(Establecimiento).filter(Establecimiento.id_establecimiento == fotografia_in.id_establecimiento).first():
        raise ValueError("Establecimiento no encontrado")

    data = fotografia_in.model_dump(exclude_unset=True)
    db_obj = Fotografia(**data)
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj


def update_fotografia(db: Session, db_obj: Fotografia, fotografia_in: FotografiaUpdate) -> Fotografia:
    data = fotografia_in.model_dump(exclude_unset=True)

    if "id_usuario" in data:
        if not db.query(Usuario).filter(Usuario.id_usuario == data["id_usuario"]).first():
            raise ValueError("Usuario no encontrado")

    if "id_establecimiento" in data:
        if not db.query(Establecimiento).filter(Establecimiento.id_establecimiento == data["id_establecimiento"]).first():
            raise ValueError("Establecimiento no encontrado")

    for field, value in data.items():
        setattr(db_obj, field, value)

    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj


def remove_fotografia(db: Session, id_foto: int) -> Optional[Fotografia]:
    obj = get_fotografia(db, id_foto)
    if not obj:
        return None

    db.delete(obj)
    db.commit()
    return obj