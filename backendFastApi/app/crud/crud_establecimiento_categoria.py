from typing import List, Optional

from sqlalchemy.orm import Session

from app.models.categoria_dieta import CategoriaDieta
from app.models.establecimiento import Establecimiento
from app.models.establecimiento_categoria import EstablecimientoCategoria


def get_establecimiento_categoria(
    db: Session, id_establecimiento: int, id_categoria: int
) -> Optional[EstablecimientoCategoria]:
    return (
        db.query(EstablecimientoCategoria)
        .filter(
            EstablecimientoCategoria.id_establecimiento == id_establecimiento,
            EstablecimientoCategoria.id_categoria == id_categoria,
        )
        .first()
    )


def get_establecimiento_categorias(db: Session) -> List[EstablecimientoCategoria]:
    return db.query(EstablecimientoCategoria).all()


def get_categorias_por_establecimiento(db: Session, id_establecimiento: int) -> List[EstablecimientoCategoria]:
    return (
        db.query(EstablecimientoCategoria)
        .filter(EstablecimientoCategoria.id_establecimiento == id_establecimiento)
        .all()
    )


def get_establecimientos_por_categoria(db: Session, id_categoria: int) -> List[EstablecimientoCategoria]:
    return (
        db.query(EstablecimientoCategoria)
        .filter(EstablecimientoCategoria.id_categoria == id_categoria)
        .all()
    )


def create_establecimiento_categoria(
    db: Session, id_establecimiento: int, id_categoria: int
) -> EstablecimientoCategoria:
    if not db.query(Establecimiento).filter(Establecimiento.id_establecimiento == id_establecimiento).first():
        raise ValueError("Establecimiento no encontrado")
    if not db.query(CategoriaDieta).filter(CategoriaDieta.id_categoria == id_categoria).first():
        raise ValueError("Categoria no encontrada")

    existing = get_establecimiento_categoria(db, id_establecimiento, id_categoria)
    if existing:
        raise ValueError("La relacion establecimiento-categoria ya existe")

    db_obj = EstablecimientoCategoria(
        id_establecimiento=id_establecimiento,
        id_categoria=id_categoria,
    )
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj


def remove_establecimiento_categoria(
    db: Session, id_establecimiento: int, id_categoria: int
) -> Optional[EstablecimientoCategoria]:
    obj = get_establecimiento_categoria(db, id_establecimiento, id_categoria)
    if not obj:
        return None

    db.delete(obj)
    db.commit()
    return obj
