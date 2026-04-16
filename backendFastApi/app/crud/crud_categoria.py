from typing import List, Optional
from sqlalchemy.orm import Session

from app.models.categoria_dieta import CategoriaDieta
from app.schemas.categoria_dieta import CategoriaDietaCreate, CategoriaDietaUpdate


def get_categoria(db: Session, id_categoria: int) -> Optional[CategoriaDieta]:
    return db.query(CategoriaDieta).filter(CategoriaDieta.id_categoria == id_categoria).first()


def get_categorias(db: Session) -> List[CategoriaDieta]:
    return db.query(CategoriaDieta).all()


def create_categoria(db: Session, cat_in: CategoriaDietaCreate) -> CategoriaDieta:
    data = cat_in.model_dump(exclude_unset=True)
    db_obj = CategoriaDieta(**data)
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj


def update_categoria(db: Session, db_obj: CategoriaDieta, cat_in: CategoriaDietaUpdate) -> CategoriaDieta:
    data = cat_in.model_dump(exclude_unset=True)
    for field, value in data.items():
        setattr(db_obj, field, value)
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj


def remove_categoria(db: Session, id_categoria: int) -> Optional[CategoriaDieta]:
    obj = get_categoria(db, id_categoria)
    if not obj:
        return None
    db.delete(obj)
    db.commit()
    return obj
