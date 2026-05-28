from typing import List, Optional

from sqlalchemy.orm import Session

from app.models.establecimiento import Establecimiento
from app.models.item_menu import ItemMenu
from app.models.tipo_item_menu import TipoItemMenu
from app.schemas.item_menu import ItemMenuCreate, ItemMenuUpdate
from typing import Set


def get_item_menu(db: Session, id_item_menu: int) -> Optional[ItemMenu]:
    return db.query(ItemMenu).filter(ItemMenu.id_item_menu == id_item_menu).first()


def get_items_menu(db: Session) -> List[ItemMenu]:
    return db.query(ItemMenu).all()


def get_items_menu_por_establecimiento(db: Session, id_establecimiento: int) -> List[ItemMenu]:
    return db.query(ItemMenu).filter(ItemMenu.id_establecimiento == id_establecimiento).all()


def create_item_menu(db: Session, item_in: ItemMenuCreate) -> ItemMenu:
    if not db.query(Establecimiento).filter(Establecimiento.id_establecimiento == item_in.id_establecimiento).first():
        raise ValueError("Establecimiento no encontrado")

    if item_in.id_tipo_item_menu is not None:
        tipo_item = db.query(TipoItemMenu).filter(TipoItemMenu.id_tipo_item == item_in.id_tipo_item_menu).first()
        if not tipo_item:
            raise ValueError("Tipo item menu no encontrado")
        if tipo_item.id_establecimiento != item_in.id_establecimiento:
            raise ValueError("El id_establecimiento del item_menu debe coincidir con el del tipo_item_menu")

    data = item_in.model_dump(exclude_unset=True)
    # `id_categorias` no es columna de ItemMenu; quitar antes de construir el ORM object
    id_categorias = data.pop("id_categorias", None)
    db_obj = ItemMenu(**data)
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)

    # Si se pasaron categorias, creamos las relaciones
    if id_categorias:
        from app.crud import crud_item_categoria

        for cat_id in set(id_categorias or []):
            try:
                crud_item_categoria.create_item_categoria(db, db_obj.id_item_menu, cat_id)
            except ValueError:
                # ignorar relaciones inválidas, ya que la validación puede ocurrir por separado
                continue
    return db_obj


def update_item_menu(db: Session, db_obj: ItemMenu, item_in: ItemMenuUpdate) -> ItemMenu:
    data = item_in.model_dump(exclude_unset=True)

    if "id_establecimiento" in data:
        if not db.query(Establecimiento).filter(Establecimiento.id_establecimiento == data["id_establecimiento"]).first():
            raise ValueError("Establecimiento no encontrado")

    if "id_tipo_item_menu" in data and data["id_tipo_item_menu"] is not None:
        tipo_item_id = data["id_tipo_item_menu"]
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

    # Si se proporcionan id_categorias, sincronizamos las relaciones (add/remove)
    if 'id_categorias' in data:
        from app.crud import crud_item_categoria

        desired: Set[int] = set(item_in.id_categorias or [])
        existing_objs = crud_item_categoria.get_categorias_por_item(db, db_obj.id_item_menu)
        existing: Set[int] = set([o.id_categoria for o in existing_objs])

        # Añadir los nuevos
        for cat_id in desired - existing:
            try:
                crud_item_categoria.create_item_categoria(db, db_obj.id_item_menu, cat_id)
            except ValueError:
                continue

        # Eliminar los que sobran
        for cat_id in existing - desired:
            try:
                crud_item_categoria.remove_item_categoria(db, db_obj.id_item_menu, cat_id)
            except Exception:
                continue
    return db_obj


def remove_item_menu(db: Session, id_item_menu: int) -> Optional[ItemMenu]:
    obj = get_item_menu(db, id_item_menu)
    if not obj:
        return None

    db.delete(obj)
    db.commit()
    return obj
