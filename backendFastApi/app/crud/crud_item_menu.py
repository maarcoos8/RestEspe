from typing import List, Optional

from sqlalchemy.orm import Session

from app.models.establecimiento import Establecimiento
from app.models.item_menu import ItemMenu
from app.models.tipo_item_menu import TipoItemMenu
from app.schemas.item_menu import ItemMenuCreate, ItemMenuUpdate


def get_item_menu(db: Session, id_item_menu: int) -> Optional[ItemMenu]:
    return db.query(ItemMenu).filter(ItemMenu.id_item_menu == id_item_menu).first()


def get_items_menu(db: Session) -> List[ItemMenu]:
    return db.query(ItemMenu).all()


def get_items_menu_por_establecimiento(db: Session, id_establecimiento: int) -> List[ItemMenu]:
    return db.query(ItemMenu).filter(ItemMenu.id_establecimiento == id_establecimiento).all()


def create_item_menu(db: Session, item_in: ItemMenuCreate) -> ItemMenu:
    if not db.query(Establecimiento).filter(Establecimiento.id_establecimiento == item_in.id_establecimiento).first():
        raise ValueError("Establecimiento no encontrado")
    tipo_item = db.query(TipoItemMenu).filter(TipoItemMenu.id_tipo_item == item_in.id_tipo_item_menu).first()
    if not tipo_item:
        raise ValueError("Tipo item menu no encontrado")
    if tipo_item.id_establecimiento != item_in.id_establecimiento:
        raise ValueError("El id_establecimiento del item_menu debe coincidir con el del tipo_item_menu")

    data = item_in.model_dump(exclude_unset=True)
    db_obj = ItemMenu(**data)
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj


def update_item_menu(db: Session, db_obj: ItemMenu, item_in: ItemMenuUpdate) -> ItemMenu:
    data = item_in.model_dump(exclude_unset=True)

    if "id_establecimiento" in data:
        if not db.query(Establecimiento).filter(Establecimiento.id_establecimiento == data["id_establecimiento"]).first():
            raise ValueError("Establecimiento no encontrado")

    tipo_item_id = data.get("id_tipo_item_menu", db_obj.id_tipo_item_menu)
    tipo_item = db.query(TipoItemMenu).filter(TipoItemMenu.id_tipo_item == tipo_item_id).first()
    if not tipo_item:
        raise ValueError("Tipo item menu no encontrado")

    establecimiento_id = data.get("id_establecimiento", db_obj.id_establecimiento)
    if tipo_item.id_establecimiento != establecimiento_id:
        raise ValueError("El id_establecimiento del item_menu debe coincidir con el del tipo_item_menu")

    for field, value in data.items():
        setattr(db_obj, field, value)

    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj


def remove_item_menu(db: Session, id_item_menu: int) -> Optional[ItemMenu]:
    obj = get_item_menu(db, id_item_menu)
    if not obj:
        return None

    db.delete(obj)
    db.commit()
    return obj
