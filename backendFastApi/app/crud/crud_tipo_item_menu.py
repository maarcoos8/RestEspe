from typing import List, Optional

from sqlalchemy.orm import Session

from app.models.establecimiento import Establecimiento
from app.models.tipo_item_menu import TipoItemMenu
from app.schemas.tipo_item_menu import TipoItemMenuCreate, TipoItemMenuUpdate


def get_tipo_item_menu(db: Session, id_tipo_item: int) -> Optional[TipoItemMenu]:
    return db.query(TipoItemMenu).filter(TipoItemMenu.id_tipo_item == id_tipo_item).first()


def get_tipos_item_menu(db: Session) -> List[TipoItemMenu]:
    return db.query(TipoItemMenu).all()


def get_tipos_item_menu_por_establecimiento(db: Session, id_establecimiento: int) -> List[TipoItemMenu]:
    return db.query(TipoItemMenu).filter(TipoItemMenu.id_establecimiento == id_establecimiento).all()


def create_tipo_item_menu(db: Session, tipo_in: TipoItemMenuCreate) -> TipoItemMenu:
    if not db.query(Establecimiento).filter(Establecimiento.id_establecimiento == tipo_in.id_establecimiento).first():
        raise ValueError("Establecimiento no encontrado")

    data = tipo_in.model_dump(exclude_unset=True)
    db_obj = TipoItemMenu(**data)
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj


def update_tipo_item_menu(db: Session, db_obj: TipoItemMenu, tipo_in: TipoItemMenuUpdate) -> TipoItemMenu:
    data = tipo_in.model_dump(exclude_unset=True)

    if "id_establecimiento" in data:
        if not db.query(Establecimiento).filter(Establecimiento.id_establecimiento == data["id_establecimiento"]).first():
            raise ValueError("Establecimiento no encontrado")

    for field, value in data.items():
        setattr(db_obj, field, value)

    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj


def remove_tipo_item_menu(db: Session, id_tipo_item: int) -> Optional[TipoItemMenu]:
    obj = get_tipo_item_menu(db, id_tipo_item)
    if not obj:
        return None

    db.delete(obj)
    db.commit()
    return obj
