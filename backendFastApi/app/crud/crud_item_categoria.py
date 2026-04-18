from typing import List, Optional

from sqlalchemy.orm import Session

from app.models.categoria_dieta import CategoriaDieta
from app.models.item_categoria import ItemCategoria
from app.models.item_menu import ItemMenu


def get_item_categoria(db: Session, id_item_menu: int, id_categoria: int) -> Optional[ItemCategoria]:
    return (
        db.query(ItemCategoria)
        .filter(
            ItemCategoria.id_item_menu == id_item_menu,
            ItemCategoria.id_categoria == id_categoria,
        )
        .first()
    )


def get_item_categorias(db: Session) -> List[ItemCategoria]:
    return db.query(ItemCategoria).all()


def get_categorias_por_item(db: Session, id_item_menu: int) -> List[ItemCategoria]:
    return db.query(ItemCategoria).filter(ItemCategoria.id_item_menu == id_item_menu).all()


def get_items_por_categoria(db: Session, id_categoria: int) -> List[ItemCategoria]:
    return db.query(ItemCategoria).filter(ItemCategoria.id_categoria == id_categoria).all()


def create_item_categoria(db: Session, id_item_menu: int, id_categoria: int) -> ItemCategoria:
    if not db.query(ItemMenu).filter(ItemMenu.id_item_menu == id_item_menu).first():
        raise ValueError("Item menu no encontrado")
    if not db.query(CategoriaDieta).filter(CategoriaDieta.id_categoria == id_categoria).first():
        raise ValueError("Categoria no encontrada")

    existing = get_item_categoria(db, id_item_menu, id_categoria)
    if existing:
        raise ValueError("La relacion item-categoria ya existe")

    db_obj = ItemCategoria(id_item_menu=id_item_menu, id_categoria=id_categoria)
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj


def remove_item_categoria(db: Session, id_item_menu: int, id_categoria: int) -> Optional[ItemCategoria]:
    obj = get_item_categoria(db, id_item_menu, id_categoria)
    if not obj:
        return None

    db.delete(obj)
    db.commit()
    return obj
