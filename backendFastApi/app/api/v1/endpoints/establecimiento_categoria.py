from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app import crud
from app.db.session import get_db
from app.schemas.establecimiento_categoria import (
    EstablecimientoCategoriaCreate,
    EstablecimientoCategoriaOut,
    CategoriaDietaConteoOut,
)

router = APIRouter(prefix="/establecimiento_categoria", tags=["EstablecimientoCategoria"])


@router.get("/", response_model=List[EstablecimientoCategoriaOut])
def leer_relaciones(db: Session = Depends(get_db)):
    return crud.crud_establecimiento_categoria.get_establecimiento_categorias(db)


@router.get("/establecimiento/{id_establecimiento}", response_model=List[CategoriaDietaConteoOut])
def leer_categorias_por_establecimiento(id_establecimiento: int, db: Session = Depends(get_db)):
    return crud.crud_establecimiento.get_categorias_dieta_con_conteo_por_establecimiento(
        db, id_establecimiento
    )


@router.get("/categoria/{id_categoria}", response_model=List[EstablecimientoCategoriaOut])
def leer_establecimientos_por_categoria(id_categoria: int, db: Session = Depends(get_db)):
    return crud.crud_establecimiento_categoria.get_establecimientos_por_categoria(db, id_categoria)


@router.post("/", response_model=EstablecimientoCategoriaOut, status_code=status.HTTP_201_CREATED)
def crear_relacion(rel_in: EstablecimientoCategoriaCreate, db: Session = Depends(get_db)):
    try:
        return crud.crud_establecimiento_categoria.create_establecimiento_categoria(
            db,
            rel_in.id_establecimiento,
            rel_in.id_categoria,
        )
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.delete("/establecimiento/{id_establecimiento}/categoria/{id_categoria}", response_model=EstablecimientoCategoriaOut)
def eliminar_relacion(id_establecimiento: int, id_categoria: int, db: Session = Depends(get_db)):
    obj = crud.crud_establecimiento_categoria.remove_establecimiento_categoria(
        db,
        id_establecimiento,
        id_categoria,
    )
    if not obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Relacion no encontrada")
    return obj
