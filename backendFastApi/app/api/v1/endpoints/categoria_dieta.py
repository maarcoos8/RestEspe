from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app import crud
from app.schemas.categoria_dieta import (
    CategoriaDietaOut,
    CategoriaDietaCreate,
    CategoriaDietaUpdate,
)

router = APIRouter(prefix="/categoria_dieta", tags=["CategoriaDieta"])


@router.get("/", response_model=List[CategoriaDietaOut])
def leer_categorias(db: Session = Depends(get_db)):
    return crud.crud_categoria.get_categorias(db)


@router.get("/{id}", response_model=CategoriaDietaOut)
def leer_categoria(id: int, db: Session = Depends(get_db)):
    obj = crud.crud_categoria.get_categoria(db, id)
    if not obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Categoria no encontrada")
    return obj


@router.post("/", response_model=CategoriaDietaOut, status_code=status.HTTP_201_CREATED)
def crear_categoria(cat_in: CategoriaDietaCreate, db: Session = Depends(get_db)):
    return crud.crud_categoria.create_categoria(db, cat_in)


@router.put("/{id}", response_model=CategoriaDietaOut)
def actualizar_categoria(id: int, cat_in: CategoriaDietaUpdate, db: Session = Depends(get_db)):
    db_obj = crud.crud_categoria.get_categoria(db, id)
    if not db_obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Categoria no encontrada")
    return crud.crud_categoria.update_categoria(db, db_obj, cat_in)


@router.delete("/{id}", response_model=CategoriaDietaOut)
def eliminar_categoria(id: int, db: Session = Depends(get_db)):
    obj = crud.crud_categoria.remove_categoria(db, id)
    if not obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Categoria no encontrada")
    return obj
