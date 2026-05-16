from typing import List, Optional
import random

from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.models.categoria_dieta import CategoriaDieta
from app.schemas.categoria_dieta import CategoriaDietaCreate, CategoriaDietaUpdate

# Paleta de colores agradables para las categorías de dieta
DIET_COLORS = [
    '#FF6B6B',  # Rojo coral
    '#4ECDC4',  # Turquesa
    '#45B7D1',  # Azul cielo
    '#FFA07A',  # Salmón
    '#98D8C8',  # Menta
    '#F7DC6F',  # Amarillo dorado
    '#BB8FCE',  # Púrpura
    '#85C1E2',  # Azul claro
    '#F8B195',  # Melocotón
    '#A6D5BA',  # Verde salvia
]


def get_categoria(db: Session, id_categoria: int) -> Optional[CategoriaDieta]:
    return db.query(CategoriaDieta).filter(CategoriaDieta.id_categoria == id_categoria).first()


def get_categorias(db: Session) -> List[CategoriaDieta]:
    return db.query(CategoriaDieta).all()


def create_categoria(db: Session, cat_in: CategoriaDietaCreate) -> CategoriaDieta:
    data = cat_in.model_dump(exclude_unset=True)
    existing = db.query(CategoriaDieta).filter(CategoriaDieta.nombre_dieta == data["nombre_dieta"]).first()
    if existing:
        raise ValueError("Ya existe una dieta con ese nombre")

    # Generar color random si no se proporciona
    if "color_hex" not in data or data["color_hex"] is None:
        data["color_hex"] = random.choice(DIET_COLORS)

    db_obj = CategoriaDieta(**data)
    db.add(db_obj)
    try:
        db.commit()
        db.refresh(db_obj)
    except IntegrityError:
        db.rollback()
        raise ValueError("Ya existe una dieta con ese nombre")
    return db_obj


def update_categoria(db: Session, db_obj: CategoriaDieta, cat_in: CategoriaDietaUpdate) -> CategoriaDieta:
    data = cat_in.model_dump(exclude_unset=True)
    if "nombre_dieta" in data:
        existing = (
            db.query(CategoriaDieta)
            .filter(
                CategoriaDieta.nombre_dieta == data["nombre_dieta"],
                CategoriaDieta.id_categoria != db_obj.id_categoria,
            )
            .first()
        )
        if existing:
            raise ValueError("Ya existe una dieta con ese nombre")

    for field, value in data.items():
        setattr(db_obj, field, value)
    db.add(db_obj)
    try:
        db.commit()
        db.refresh(db_obj)
    except IntegrityError:
        db.rollback()
        raise ValueError("Ya existe una dieta con ese nombre")
    return db_obj


def remove_categoria(db: Session, id_categoria: int) -> Optional[CategoriaDieta]:
    obj = get_categoria(db, id_categoria)
    if not obj:
        return None
    db.delete(obj)
    db.commit()
    return obj
