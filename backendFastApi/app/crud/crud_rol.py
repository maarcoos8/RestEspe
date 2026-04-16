from typing import List, Optional
from sqlalchemy.orm import Session
from app.models.rol import Rol
from app.schemas.rol import RolCreate, RolUpdate


def get_rol(db: Session, id_rol: int) -> Optional[Rol]:
    return db.query(Rol).filter(Rol.id_rol == id_rol).first()


def get_roles(db: Session) -> List[Rol]:
    return db.query(Rol).all()


def create_rol(db: Session, rol_in: RolCreate) -> Rol:
    data = rol_in.model_dump(exclude_unset=True)
    db_obj = Rol(**data)
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj


def update_rol(db: Session, db_obj: Rol, rol_in: RolUpdate) -> Rol:
    data = rol_in.model_dump(exclude_unset=True)
    for field, value in data.items():
        setattr(db_obj, field, value)
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj


def remove_rol(db: Session, id_rol: int) -> Optional[Rol]:
    obj = get_rol(db, id_rol)
    if not obj:
        return None
    db.delete(obj)
    db.commit()
    return obj
